Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveSatisfactionHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_objective "campaign_repair.source_objective_satisfaction_report.rows"

  setup_all do
    source_report = read_json!("study_results/objective_satisfaction_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_objective_satisfaction_report"],
        source_report
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

  test "validates Repair source objective-satisfaction handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"target_coverage", "partial", nil},
      {"downlink_completion", "unmet", nil},
      {"target_commitment", "no_candidate_window", "target_b"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_objective))
             |> Enum.map(&{&1["objective"], &1["objective_status"], &1["target_id"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_objective))
             |> Enum.map(&{&1["objective"], &1["objective_status"], &1["target_id"]})
  end

  test "keeps additive source objective-satisfaction handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_objective,
            do: Map.delete(row, "source_objective_satisfaction"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_objective do
            row
            |> Map.delete("source_objective_satisfaction")
            |> update_in(
              ["source_review_row"],
              &Map.delete(&1, "source_objective_satisfaction")
            )
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source objective-satisfaction handoff drift", %{repair: repair} do
    review_index = objective_review_index(repair)
    import_index = objective_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_objective_satisfaction_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "source_objective_satisfaction_report.rows"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_objective_satisfaction",
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
          |> put_in(["source_objective_satisfaction", "rank"], 99)
          |> put_in(["source_review_row", "source_objective_satisfaction", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_objective_satisfaction",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_objective_satisfaction",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_objective_satisfaction",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp objective_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "objective_satisfaction_review" and
          row_source(&1) == @repair_source_objective)
    )
  end

  defp objective_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "objective_satisfaction_review" and
          row_source(&1) == @repair_source_objective)
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
