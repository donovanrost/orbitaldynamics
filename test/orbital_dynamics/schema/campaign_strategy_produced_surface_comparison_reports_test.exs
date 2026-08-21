Code.require_file(
  "../../support/schema/campaign_strategy_produced_surface_case.ex",
  __DIR__
)

defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceComparisonReportsTest do
  use OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase, async: true

  alias OrbitalDynamics.Schema

  test "rejects CampaignStrategy branch comparison identity drift", %{strategy: strategy} do
    report = strategy["branch_comparison_report"]
    [first, second, third | rest] = report["rows"]

    reordered =
      put_in(
        strategy,
        ["branch_comparison_report", "rows"],
        [first, third, second | rest]
      )

    alternate_recommended_branch_id = second["branch_id"]
    alternate_recommended_score = second["score"]

    alternate_report =
      report
      |> Map.put("recommended_branch_id", alternate_recommended_branch_id)
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("selected", row["branch_id"] == alternate_recommended_branch_id)
          |> Map.put(
            "score_delta_from_recommended",
            row["score"] - alternate_recommended_score
          )
        end)
      end)

    invalid_cases = [
      {"$.branch_comparison_report.rows", reordered},
      {"$.branch_comparison_report.recommended_branch_id",
       Map.put(strategy, "branch_comparison_report", alternate_report)},
      {"$.branch_comparison_report.rows[1].id",
       put_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "id"],
         "branch_comparison:stale_identity"
       )},
      {"$.branch_comparison_report.rows[1].rank",
       update_in(
         strategy,
         ["branch_comparison_report", "rows", Access.at(1), "rank"],
         &(&1 + 10)
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy branch comparison assumption drift", %{strategy: strategy} do
    assumptions = strategy["branch_comparison_report"]["assumptions"]

    for {field, value} <- assumptions do
      drift = if is_boolean(value), do: not value, else: value <> ".schema_valid_drift"

      invalid =
        put_in(
          strategy,
          ["branch_comparison_report", "assumptions", field],
          drift
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.branch_comparison_report.assumptions.#{field}" and
                   &1["message"] ==
                     "must match the deterministic branch comparison assumption")
             )
    end
  end

  test "rejects CampaignStrategy ranking comparison identity drift", %{strategy: strategy} do
    report = strategy["ranking_comparison_report"]

    for field <- ["source", "objective", "objective_direction", "left_label", "right_label"] do
      invalid =
        put_in(
          strategy,
          ["ranking_comparison_report", field],
          report[field] <> ".schema_valid_drift"
        )

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.ranking_comparison_report.#{field}")
             )
    end

    for {field, value} <- report["assumptions"] do
      drift = if is_boolean(value), do: not value, else: value <> ".schema_valid_drift"
      invalid = put_in(strategy, ["ranking_comparison_report", "assumptions", field], drift)

      assert {:error, validation_report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.ranking_comparison_report.assumptions.#{field}")
             )
    end
  end

  test "rejects CampaignStrategy score-ranked comparison evidence drift", %{
    strategy: strategy
  } do
    report = strategy["ranking_comparison_report"]
    row = hd(report["rows"])
    right_rank = row["right_rank"] + 100
    right_value = row["right_value"] + 1.0
    left_value = row["left_value"] + 1.0

    coherent_rank_drift =
      strategy
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "right_rank"], right_rank)
      |> put_in(
        ["ranking_comparison_report", "rows", Access.at(0), "rank_delta"],
        row["left_rank"] - right_rank
      )

    coherent_right_value_drift =
      strategy
      |> put_in(
        ["ranking_comparison_report", "rows", Access.at(0), "right_value"],
        right_value
      )
      |> put_in(
        ["ranking_comparison_report", "rows", Access.at(0), "value_delta"],
        right_value - row["left_value"]
      )

    coherent_left_value_drift =
      strategy
      |> put_in(
        ["ranking_comparison_report", "rows", Access.at(0), "left_value"],
        left_value
      )
      |> put_in(
        ["ranking_comparison_report", "rows", Access.at(0), "value_delta"],
        row["right_value"] - left_value
      )

    coherent_status_drift =
      strategy
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "status"], "left_only")
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "right_rank"], nil)
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "rank_delta"], nil)
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "right_value"], nil)
      |> put_in(["ranking_comparison_report", "rows", Access.at(0), "value_delta"], nil)
      |> update_in(["ranking_comparison_report", "matched_count"], &(&1 - 1))
      |> update_in(["ranking_comparison_report", "left_only_count"], &(&1 + 1))
      |> update_in(["ranking_comparison_report", "right_count"], &(&1 - 1))

    reordered =
      update_in(strategy, ["ranking_comparison_report", "rows"], fn [first, second | rest] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.ranking_comparison_report.rows[0].scenario_id",
       put_in(
         strategy,
         ["ranking_comparison_report", "rows", Access.at(0), "scenario_id"],
         "stale_branch"
       )},
      {"$.ranking_comparison_report.rows[0].right_rank", coherent_rank_drift},
      {"$.ranking_comparison_report.rows[0].right_value", coherent_right_value_drift},
      {"$.ranking_comparison_report.rows[0].left_value", coherent_left_value_drift},
      {"$.ranking_comparison_report.winner.right_scenario_id",
       put_in(
         strategy,
         ["ranking_comparison_report", "winner", "right_scenario_id"],
         "stale_branch"
       )},
      {"$.ranking_comparison_report.rows[0].scenario_id", reordered},
      {"$.ranking_comparison_report.rows[0].status", coherent_status_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy Pareto-frontier evidence drift", %{strategy: strategy} do
    report = strategy["pareto_frontier_report"]
    row = hd(report["rows"])

    direction_key = report["objective_directions"] |> Map.keys() |> hd()

    flipped_direction =
      if report["objective_directions"][direction_key] == "maximize",
        do: "minimize",
        else: "maximize"

    coherent_identity_drift =
      strategy
      |> put_in(["pareto_frontier_report", "rows", Access.at(0), "id"], "stale_branch")
      |> put_in(
        ["pareto_frontier_report", "rows", Access.at(0), "scenario_id"],
        "stale_branch"
      )
      |> update_in(["pareto_frontier_report", "frontier_ids"], fn ids ->
        ids
        |> Enum.map(&if(&1 == row["id"], do: "stale_branch", else: &1))
        |> Enum.sort()
      end)

    reordered =
      update_in(strategy, ["pareto_frontier_report", "rows"], fn [first, second | rest] ->
        [second, first | rest]
      end)

    invalid_cases = [
      {"$.pareto_frontier_report.source",
       put_in(strategy, ["pareto_frontier_report", "source"], "schema_valid_drift")},
      {"$.pareto_frontier_report.assumptions",
       update_in(
         strategy,
         ["pareto_frontier_report", "assumptions", "external_solver"],
         &(!&1)
       )},
      {"$.pareto_frontier_report.objective_directions",
       put_in(
         strategy,
         ["pareto_frontier_report", "objective_directions", direction_key],
         flipped_direction
       )},
      {"$.pareto_frontier_report.rows[0].objective_values",
       update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "objective_values", "score"],
         &(&1 + 1.0)
       )},
      {"$.pareto_frontier_report.rows[0].id", coherent_identity_drift},
      {"$.pareto_frontier_report.rows[0].id", reordered},
      {"$.pareto_frontier_report.rows[0].dominates_ids",
       update_in(
         strategy,
         ["pareto_frontier_report", "rows", Access.at(0), "dominates_ids"],
         &(&1 ++ ["stale_branch"])
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end
end
