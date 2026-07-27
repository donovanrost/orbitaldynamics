Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelinePreservationStatusHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_prefix "campaign_repair.source_timeline_preservation_statuses"

  setup_all do
    source_status = read_json!("study_results/timeline_preservation_status_v1.json")

    canonical_status =
      source_status
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> String.replace("dl_locked", "cmd_preservation_canonical")
      |> :json.decode()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_timeline_preservation_status"],
        [source_status]
      )
      |> put_in(
        ["candidate_refresh", "timeline_preservation_status"],
        canonical_status
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair}
  end

  test "validates Repair source timeline preservation-status handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"#{@repair_source_prefix}[0].status", "timeline:dl_locked"},
      {"#{@repair_source_prefix}[1].status", "timeline:cmd_preservation_canonical"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&preservation_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&preservation_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})
  end

  test "keeps additive source timeline preservation-status handoffs optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if preservation_source?(row),
            do: Map.delete(row, "source_timeline_preservation"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if preservation_source?(row) do
            row
            |> Map.delete("source_timeline_preservation")
            |> update_in(
              ["source_review_row"],
              &Map.delete(&1, "source_timeline_preservation")
            )
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source timeline preservation-status handoff drift", %{
    repair: repair
  } do
    review_index = preservation_review_index(repair)
    import_index = preservation_import_index(repair)
    second_source = "#{@repair_source_prefix}[1].status"

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_timeline_preservation_status"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "campaign_repair.source_timeline_preservation_status"
      )

    review_index_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        second_source
      )

    cadence_index_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.put("source", second_source)
          |> put_in(["source_review_row", "source"], second_source)
        end
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_preservation",
          "rank"
        ],
        99
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_timeline_preservation", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_preservation", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source", review_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_index_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_preservation",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_preservation",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_preservation",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp preservation_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_preservation_review" and
          row_source(&1) == "#{@repair_source_prefix}[0].status")
    )
  end

  defp preservation_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_preservation_review" and
          row_source(&1) == "#{@repair_source_prefix}[0].status")
    )
  end

  defp preservation_source?(row) do
    String.starts_with?(row_source(row) || "", @repair_source_prefix <> "[")
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
