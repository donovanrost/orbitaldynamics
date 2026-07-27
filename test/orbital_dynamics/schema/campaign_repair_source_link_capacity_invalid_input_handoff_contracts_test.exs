Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceLinkCapacityInvalidInputHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @source_fields [
    {"invalid_contact_inputs",
     "campaign_repair.source_link_capacity_report.invalid_contact_inputs"},
    {"invalid_selected_contact_inputs",
     "campaign_repair.source_link_capacity_report.invalid_selected_contact_inputs"}
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

  test "validates Repair source link-capacity invalid-input handoffs in field order", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    for {field, source} <- @source_fields do
      review_rows = source_review_rows(repair, source)
      import_rows = source_import_rows(repair, source)

      assert Enum.map(review_rows, & &1["contact_id"]) ==
               Enum.map(source_report[field], & &1["contact_id"])

      assert Enum.map(import_rows, & &1["contact_id"]) ==
               Enum.map(source_report[field], & &1["contact_id"])

      assert Enum.all?(review_rows, &(row_source(&1) == source))
      assert Enum.all?(import_rows, &(row_source(&1) == source))

      assert Enum.map(review_rows, & &1["source_link_capacity"]) == source_report[field]
      assert Enum.map(import_rows, & &1["source_link_capacity"]) == source_report[field]

      assert Enum.map(
               import_rows,
               &get_in(&1, ["source_review_row", "source_link_capacity"])
             ) == source_report[field]
    end
  end

  test "keeps additive source link-capacity invalid-input handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if invalid_input_row?(row),
            do: Map.delete(row, "source_link_capacity"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if invalid_input_row?(row) do
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

  test "rejects Repair source link-capacity invalid-input handoff drift", %{
    repair: repair,
    source_report: source_report
  } do
    invalid_cases =
      Enum.flat_map(@source_fields, fn {_field, source} ->
        review_index = source_review_index(repair, source)
        import_index = source_import_index(repair, source)
        wrong_source = source <> ".legacy"

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
            put_in(
              repair,
              [
                "operator_review_package",
                "rows",
                Access.at(review_index),
                "source_link_capacity",
                "invalid_contact_input_reason"
              ],
              "legacy_reason"
            )
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
            put_in(
              repair,
              [
                "cadence_import_manifest",
                "rows",
                Access.at(import_index),
                "source_link_capacity",
                "invalid_contact_input_reason"
              ],
              "legacy_reason"
            )
          },
          {
            "$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_link_capacity",
            put_in(
              repair,
              [
                "cadence_import_manifest",
                "rows",
                Access.at(import_index),
                "source_review_row",
                "source_link_capacity",
                "invalid_contact_input_reason"
              ],
              "legacy_reason"
            )
          }
        ]
      end)

    eligibility_drift =
      Map.put(
        repair,
        "source_link_capacity_report",
        without_invalid_inputs(source_report)
      )

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
          id: :valid_dl,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          estimated_throughput_mb: 100.0
        },
        %{
          id: :missing_station,
          type: :downlink,
          scenario_id: :leo_1,
          estimated_throughput_mb: 50.0
        }
      ],
      [
        %{id: :valid_dl, type: :downlink, ground_station_id: :equator_prime},
        %{
          type: :downlink,
          ground_station_id: :equator_prime,
          actual_throughput_mb: 10.0
        }
      ],
      source: "invalid_test"
    )
  end

  defp without_invalid_inputs(report) do
    report
    |> Map.put("invalid_contact_inputs", [])
    |> Map.put("invalid_contact_input_count", 0)
    |> Map.put("invalid_contact_input_ids", [])
    |> Map.put("invalid_selected_contact_inputs", [])
    |> Map.put("invalid_selected_contact_input_count", 0)
    |> Map.put("invalid_selected_contact_input_ids", [])
  end

  defp invalid_input_row?(row) do
    row_source(row) in Enum.map(@source_fields, &elem(&1, 1))
  end

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
