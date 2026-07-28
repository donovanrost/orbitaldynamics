Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceObjectiveTradeoffHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_tradeoff "campaign_repair.source_objective_tradeoff_report.tradeoffs"

  setup_all do
    source_report = read_json!("study_results/objective_tradeoff_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_objective_tradeoff_report"], source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair}
  end

  test "validates Repair source objective-tradeoff handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [{"leo_1", 1, 1417.2731832107565}]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_tradeoff))
             |> Enum.map(
               &{&1["scenario_id"], &1["source_objective_tradeoff"]["rank"], &1["score"]}
             )

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_tradeoff))
             |> Enum.map(
               &{&1["scenario_id"], &1["source_objective_tradeoff"]["rank"], &1["score"]}
             )
  end

  test "keeps additive source objective-tradeoff handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_tradeoff,
            do: Map.delete(row, "source_objective_tradeoff"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_tradeoff do
            row
            |> Map.delete("source_objective_tradeoff")
            |> update_in(
              ["source_review_row"],
              &Map.delete(&1, "source_objective_tradeoff")
            )
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source objective-tradeoff handoff drift", %{repair: repair} do
    review_index = tradeoff_review_index(repair)
    import_index = tradeoff_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_objective_tradeoff_report.tradeoffs"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "source_objective_tradeoff_report.tradeoffs"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_objective_tradeoff",
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
          |> put_in(["source_objective_tradeoff", "rank"], 99)
          |> put_in(["source_review_row", "source_objective_tradeoff", "rank"], 99)
        end
      )

    stale_handoffs = Map.delete(repair, "source_objective_tradeoff_report")

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_objective_tradeoff",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_objective_tradeoff",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_objective_tradeoff",
       cadence_copy_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp tradeoff_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "objective_tradeoff_review" and
          row_source(&1) == @repair_source_tradeoff)
    )
  end

  defp tradeoff_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "objective_tradeoff_review" and
          row_source(&1) == @repair_source_tradeoff)
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
