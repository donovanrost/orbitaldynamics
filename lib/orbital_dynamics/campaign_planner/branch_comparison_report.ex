defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonReport do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchComparisonContext,
    BranchComparisonResourceProjection,
    BranchComparisonRowFields,
    StrategyRecommendation
  }

  alias OrbitalDynamics.Optimizer

  def report(branches, %StrategyRecommendation{} = recommendation, model_limits) do
    recommended_score =
      branches
      |> Enum.find(&(&1.id == recommendation.recommended_branch_id))
      |> case do
        nil -> 0.0
        branch -> branch.score
      end

    rows =
      branches
      |> Enum.with_index(1)
      |> Enum.map(fn {branch, rank} ->
        %{
          "id" => "branch_comparison:#{branch.id}",
          "rank" => rank,
          "branch_id" => branch.id,
          "score" => branch.score,
          "score_delta_from_recommended" => branch.score - recommended_score,
          "raw_score" => Map.get(branch.score_terms, "raw_score"),
          "branch_probability" => branch.probability,
          "expected_score" => Map.get(branch.score_terms, "expected_score", branch.score),
          "selected" => branch.id == recommendation.recommended_branch_id,
          "approval_status" => branch.approval_status,
          "risk_count" => length(branch.risk_indicators),
          "risk_types" => branch_risk_types(branch.risk_indicators),
          "high_risk_types" => branch_risk_types(branch.risk_indicators, "high"),
          "approval_requirement_count" => length(branch.approval_requirements),
          "candidate_activity_count" =>
            branch.candidate_plan |> Map.get("strategic_additions", []) |> length(),
          "repair_delta_count" => branch.repair_result |> Map.get("deltas", []) |> length(),
          "score_terms" => branch.score_terms
        }
        |> Map.merge(BranchComparisonRowFields.objective_fields(branch.objective_satisfaction))
        |> Map.merge(BranchComparisonRowFields.feedback_fields(branch.feedback_adjustments))
        |> Map.merge(BranchComparisonRowFields.resource_fields(branch.resource_impacts))
        |> Map.merge(BranchComparisonRowFields.repair_fields(branch.repair_result))
        |> Map.merge(BranchComparisonContext.event_fields(branch))
        |> Map.merge(BranchComparisonContext.risk_fields(branch.risk_indicators))
        |> Map.merge(BranchComparisonRowFields.target_branch_fields(branch))
        |> Map.merge(BranchComparisonResourceProjection.fields(branch.resource_projection_report))
      end)

    %{
      "schema_contract" => "branch_comparison_report.v1",
      "model" => "deterministic_strategy_branch_score_comparison",
      "source" => "campaign_strategy.branches",
      "branch_count" => length(branches),
      "recommended_branch_id" => recommendation.recommended_branch_id,
      "model_limits" => model_limits,
      "rows" => rows,
      "assumptions" => %{
        "branch_order" => "score_descending_then_branch_id",
        "score_delta_from_recommended" => "row_score_minus_recommended_branch_score",
        "score" => "probability_weighted_expected_score",
        "raw_score" => "score_before_branch_probability_multiplier",
        "branch_probability" => "independent branch likelihood or confidence multiplier in [0,1]",
        "expected_score" => "raw_score_times_branch_probability_times_probability_weight",
        "blocked_branches_remain_visible" => true
      }
    }
  end

  def ranking_report(input_order_branches, score_ranked_branches) do
    Optimizer.ranking_comparison_report(
      Enum.map(input_order_branches, &branch_ranking_row/1),
      Enum.map(score_ranked_branches, &branch_ranking_row/1),
      source: "campaign_strategy.branch_comparison_report",
      objective: "strategy_branch_score",
      objective_direction: "maximize",
      left_label: "normalized_branch_order",
      right_label: "score_ranked_branches"
    )
  end

  def pareto_frontier_report(%{"rows" => rows}) do
    rows
    |> Enum.map(&branch_pareto_objective_row/1)
    |> Optimizer.pareto_frontier_report(
      source: "campaign_strategy.branch_comparison_report",
      objective_directions: branch_pareto_objective_directions()
    )
  end

  defp branch_risk_types(risk_indicators, severity \\ nil) do
    risk_indicators
    |> List.wrap()
    |> Enum.filter(fn risk -> is_nil(severity) or Map.get(risk, "severity") == severity end)
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_ranking_row(branch) do
    %{
      scenario_id: branch.id,
      objective: "strategy_branch_score",
      value: branch.score
    }
  end

  defp branch_pareto_objective_row(%{} = row) do
    branch_id = Map.get(row, "branch_id")

    %{
      "id" => branch_id,
      "scenario_id" => branch_id,
      "objectives" =>
        row
        |> Map.take(Map.keys(branch_pareto_objective_directions()))
        |> Enum.filter(fn {_key, value} -> is_number(value) end)
        |> Map.new()
    }
  end

  defp branch_pareto_objective_directions do
    %{
      "score" => "maximize",
      "raw_score" => "maximize",
      "expected_score" => "maximize",
      "risk_count" => "minimize",
      "approval_requirement_count" => "minimize",
      "repair_delta_count" => "minimize",
      "collection_latency_ratio" => "maximize",
      "collection_latency_unsatisfied_observation_count" => "minimize",
      "projected_storage_margin" => "maximize",
      "projected_storage_remaining_mb" => "maximize",
      "projected_downlink_margin" => "maximize",
      "projected_downlink_remaining_mb" => "maximize",
      "projected_power_margin" => "maximize",
      "projected_battery_overuse_wh" => "minimize",
      "resource_projection_peak_storage_overflow_mb" => "minimize",
      "resource_projection_peak_downlink_shortfall_mb" => "minimize",
      "resource_projection_peak_battery_overuse_wh" => "minimize",
      "resource_projection_peak_unused_downlink_capacity_mb" => "minimize",
      "downlink_completion_ratio" => "maximize",
      "priority_commitment_satisfied_target_count" => "maximize",
      "priority_commitment_missed_target_count" => "minimize",
      "coverage_observed_target_count" => "maximize",
      "revisit_count" => "maximize",
      "repair_constraint_warning_count" => "minimize",
      "repair_constraint_fail_count" => "minimize"
    }
  end
end
