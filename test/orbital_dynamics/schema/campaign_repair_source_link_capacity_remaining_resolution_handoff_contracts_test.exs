Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceLinkCapacityRemainingResolutionHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @resolution_fields [
    {"unmatched_selected_contact_ids", "unmatched_selected_contact_count", ["missing_downlink"]},
    {"invalid_policy_required_downlink_station_ids",
     "invalid_policy_required_downlink_station_count", ["bad station"]}
  ]

  setup_all do
    source_report = source_report()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_link_capacity_report"],
        [source_report]
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: source_report}
  end

  test "validates remaining Repair source link-capacity resolution handoffs", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    for {id_field, count_field, expected_ids} <- @resolution_fields do
      source = source(id_field)
      expected_evidence = expected_evidence(source_report, id_field, count_field)
      review_rows = source_review_rows(repair, source)
      import_rows = source_import_rows(repair, source)

      assert Enum.map(review_rows, & &1[id_field]) == [expected_ids]
      assert Enum.map(import_rows, & &1[id_field]) == [expected_ids]
      assert Enum.all?(review_rows, &(row_source(&1) == source))
      assert Enum.all?(import_rows, &(row_source(&1) == source))

      assert Enum.map(review_rows, & &1["source_link_capacity"]) == [expected_evidence]
      assert Enum.map(import_rows, & &1["source_link_capacity"]) == [expected_evidence]

      assert Enum.map(
               import_rows,
               &get_in(&1, ["source_review_row", "source_link_capacity"])
             ) == [expected_evidence]
    end
  end

  test "keeps remaining source link-capacity resolution handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if resolution_row?(row),
            do: Map.delete(row, "source_link_capacity"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if resolution_row?(row) do
            row
            |> Map.delete("source_link_capacity")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_link_capacity"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects remaining Repair source link-capacity resolution handoff drift", %{
    repair: repair
  } do
    invalid_cases =
      Enum.flat_map(@resolution_fields, fn {id_field, _count_field, _expected_ids} ->
        source = source(id_field)
        review_index = source_review_index(repair, source)
        import_index = source_import_index(repair, source)
        wrong_source = source <> ".legacy"
        wrong_ids = ["legacy_id"]

        review_copy_drift =
          repair
          |> put_in(
            ["operator_review_package", "rows", Access.at(review_index), id_field],
            wrong_ids
          )
          |> put_in(
            [
              "operator_review_package",
              "rows",
              Access.at(review_index),
              "source_link_capacity",
              id_field
            ],
            wrong_ids
          )

        cadence_copy_drift =
          repair
          |> put_in(
            ["cadence_import_manifest", "rows", Access.at(import_index), id_field],
            wrong_ids
          )
          |> put_in(
            [
              "cadence_import_manifest",
              "rows",
              Access.at(import_index),
              "source_link_capacity",
              id_field
            ],
            wrong_ids
          )
          |> put_in(
            [
              "cadence_import_manifest",
              "rows",
              Access.at(import_index),
              "source_review_row",
              id_field
            ],
            wrong_ids
          )
          |> put_in(
            [
              "cadence_import_manifest",
              "rows",
              Access.at(import_index),
              "source_review_row",
              "source_link_capacity",
              id_field
            ],
            wrong_ids
          )

        [
          {
            "$.operator_review_package.rows[#{review_index}].source",
            put_in(
              repair,
              ["operator_review_package", "rows", Access.at(review_index), "source"],
              wrong_source
            )
          },
          {
            "$.operator_review_package.rows[#{review_index}].source_link_capacity",
            review_copy_drift
          },
          {
            "$.cadence_import_manifest.rows[#{import_index}].source",
            put_in(
              repair,
              ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
              wrong_source
            )
          },
          {
            "$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
            put_in(
              repair,
              [
                "cadence_import_manifest",
                "rows",
                Access.at(import_index),
                "source_review_row",
                "source"
              ],
              wrong_source
            )
          },
          {
            "$.cadence_import_manifest.rows[#{import_index}].source_link_capacity",
            cadence_copy_drift
          },
          {
            "$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_link_capacity",
            cadence_copy_drift
          }
        ]
      end)

    eligibility_drift =
      Map.put(repair, "source_link_capacity_report", clean_resolution_report())

    invalid_cases =
      invalid_cases ++
        [
          {"$.operator_review_package.rows", eligibility_drift},
          {"$.cadence_import_manifest.rows", eligibility_drift}
        ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp source_report do
    OrbitalDynamics.link_capacity_report(
      [
        %{
          id: :dl_1,
          type: :downlink,
          ground_station_id: :equator_prime,
          estimated_throughput_mb: 100.0
        }
      ],
      [
        %{
          id: :missing_downlink,
          type: :downlink,
          ground_station_id: :equator_prime
        }
      ],
      policy: %{
        required_downlink_mb_by_ground_station: %{
          "equator_prime" => 40.0,
          "bad station" => 15.0
        }
      }
    )
  end

  defp clean_resolution_report do
    OrbitalDynamics.link_capacity_report(
      [
        %{
          id: :dl_1,
          type: :downlink,
          ground_station_id: :equator_prime,
          estimated_throughput_mb: 100.0
        }
      ],
      [
        %{id: :dl_1, type: :downlink, ground_station_id: :equator_prime}
      ],
      policy: %{
        required_downlink_mb_by_ground_station: %{"equator_prime" => 40.0}
      }
    )
  end

  defp expected_evidence(report, id_field, count_field) do
    %{
      "schema_contract" => report["schema_contract"],
      "source" => report["source"],
      count_field => report[count_field],
      id_field => report[id_field]
    }
  end

  defp resolution_row?(row) do
    Enum.any?(@resolution_fields, fn {id_field, _count_field, _ids} ->
      row_source(row) == source(id_field)
    end)
  end

  defp source(id_field),
    do: "campaign_repair.source_link_capacity_report.#{id_field}"

  defp source_review_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_review_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
