Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineDiffHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_timeline_diff "campaign_repair.source_timeline_diff_report.rows"

  setup_all do
    source_report = read_json!("study_results/timeline_diff_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_timeline_diff_report"], source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair}
  end

  test "validates Repair source timeline-diff handoffs in producer order", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"timeline:cmd_added", "added"},
      {"timeline:dl_removed", "removed"},
      {"timeline:obs_1", "changed"},
      {"timeline:raise_apogee", "changed"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_timeline_diff))
             |> Enum.map(&{&1["timeline_id"], &1["diff_status"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_timeline_diff))
             |> Enum.map(&{&1["timeline_id"], &1["diff_status"]})
  end

  test "keeps additive source timeline-diff handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_timeline_diff,
            do: Map.delete(row, "source_timeline_diff"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_timeline_diff do
            row
            |> Map.delete("source_timeline_diff")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_timeline_diff"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source timeline-diff handoff drift", %{repair: repair} do
    review_index = timeline_diff_review_index(repair)
    import_index = timeline_diff_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_timeline_diff_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "source_timeline_diff_report.rows"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_diff",
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
          |> put_in(["source_timeline_diff", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_diff", "rank"], 99)
        end
      )

    stale_handoffs = Map.delete(repair, "source_timeline_diff_report")

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_diff", review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_diff",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_diff",
       cadence_copy_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp timeline_diff_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_diff_review" and
          row_source(&1) == @repair_source_timeline_diff)
    )
  end

  defp timeline_diff_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_diff_review" and
          row_source(&1) == @repair_source_timeline_diff)
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
