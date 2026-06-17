defmodule OrbitalDynamics.CampaignPlanner.RecommendationTradeoff do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch

  def dimensions(%PlanBranch{} = recommended, %PlanBranch{} = baseline) do
    [
      %{
        "dimension" => "expected_score",
        "baseline" => baseline.score,
        "recommended" => recommended.score,
        "delta" => recommended.score - baseline.score
      },
      %{
        "dimension" => "mission_value",
        "baseline" => baseline.score_terms["mission_value_score"],
        "recommended" => recommended.score_terms["mission_value_score"],
        "delta" =>
          recommended.score_terms["mission_value_score"] -
            baseline.score_terms["mission_value_score"]
      }
    ] ++
      score_term_dimensions(recommended, baseline, [
        {"coverage", "coverage_score"},
        {"revisit", "revisit_score"},
        {"latency", "latency_penalty"},
        {"downlink_completion", "downlink_completion_score"},
        {"fuel_preservation", "fuel_preservation_score"},
        {"asset_balance", "asset_balance_score"},
        {"priority_commitment", "priority_commitment_score"},
        {"resource_score", "resource_score"},
        {"feedback_adjustment", "feedback_adjustment_score"},
        {"contact_allocation_pressure", "contact_allocation_pressure_penalty"},
        {"provider_reservation_request_pressure",
         "provider_reservation_request_pressure_penalty"},
        {"station_reservation_conflict_pressure",
         "station_reservation_conflict_pressure_penalty"},
        {"candidate_diff_pressure", "candidate_diff_pressure_penalty"},
        {"timeline_diff_pressure", "timeline_diff_pressure_penalty"},
        {"link_capacity_pressure", "link_capacity_pressure_penalty"},
        {"contact_intent_pressure", "contact_intent_pressure_penalty"},
        {"contact_contention_pressure", "contact_contention_pressure_penalty"},
        {"contact_filter_pressure", "contact_filter_pressure_penalty"},
        {"command_window_pressure", "command_window_pressure_penalty"},
        {"objective_gap_pressure", "objective_gap_pressure_penalty"},
        {"timeline_feedback_pressure", "timeline_feedback_pressure_penalty"},
        {"operational_timeline_pressure", "operational_timeline_pressure_penalty"},
        {"maneuver_review_pressure", "maneuver_review_pressure_penalty"},
        {"operational_readiness_pressure", "operational_readiness_pressure_penalty"},
        {"operator_training_pressure", "operator_training_pressure_penalty"},
        {"import_readiness_pressure", "import_readiness_pressure_penalty"},
        {"quality_gate_pressure", "quality_gate_pressure_penalty"},
        {"approval_boundary_pressure", "approval_boundary_pressure_penalty"},
        {"timeline_integrity_pressure", "timeline_integrity_pressure_penalty"},
        {"timeline_dependency_impact_pressure", "timeline_dependency_impact_pressure_penalty"},
        {"timeline_publication_pressure", "timeline_publication_pressure_penalty"},
        {"timeline_transition_application_pressure",
         "timeline_transition_application_pressure_penalty"},
        {"timeline_activity_state_pressure", "timeline_activity_state_pressure_penalty"},
        {"timeline_lifecycle_pressure", "timeline_lifecycle_pressure_penalty"},
        {"timeline_precondition_pressure", "timeline_precondition_pressure_penalty"},
        {"timeline_preservation_pressure", "timeline_preservation_pressure_penalty"},
        {"timeline_pressure", "timeline_pressure_penalty"},
        {"storage_downlink_pressure", "storage_downlink_pressure_penalty"},
        {"resource_projection_pressure", "resource_projection_pressure_penalty"},
        {"resource_availability_pressure", "resource_availability_pressure_penalty"},
        {"resource_margin_pressure", "resource_margin_pressure_penalty"},
        {"battery_depletion_pressure", "battery_depletion_pressure_penalty"},
        {"station_calendar_pressure", "station_calendar_pressure_penalty"},
        {"station_reservation_expiration_pressure",
         "station_reservation_expiration_pressure_penalty"},
        {"candidate_rejection_pressure", "candidate_rejection_pressure_penalty"},
        {"provider_counteroffer_pressure", "provider_counteroffer_pressure_penalty"},
        {"model_acceptance_pressure", "model_acceptance_pressure_penalty"},
        {"validation_safety_case_pressure", "validation_safety_case_pressure_penalty"},
        {"schema_validation_pressure", "schema_validation_pressure_penalty"},
        {"refresh_budget_pressure", "refresh_budget_pressure_penalty"},
        {"refresh_freshness_pressure", "refresh_freshness_pressure_penalty"},
        {"validation_refresh_pressure", "validation_refresh_pressure_penalty"},
        {"relay_data_path_pressure", "relay_data_path_pressure_penalty"},
        {"execution_feedback_pressure", "execution_feedback_pressure_penalty"}
      ]) ++
      [
        %{
          "dimension" => "risk_count",
          "baseline" => length(baseline.risk_indicators),
          "recommended" => length(recommended.risk_indicators),
          "delta" => length(recommended.risk_indicators) - length(baseline.risk_indicators)
        },
        %{
          "dimension" => "approval_count",
          "baseline" => length(baseline.approval_requirements),
          "recommended" => length(recommended.approval_requirements),
          "delta" =>
            length(recommended.approval_requirements) - length(baseline.approval_requirements)
        },
        %{
          "dimension" => "schedule_stability",
          "baseline" => baseline.score_terms["schedule_stability_penalty"],
          "recommended" => recommended.score_terms["schedule_stability_penalty"],
          "delta" =>
            recommended.score_terms["schedule_stability_penalty"] -
              baseline.score_terms["schedule_stability_penalty"]
        }
      ]
  end

  def dimensions(_recommended, _baseline), do: []

  def rows(%PlanBranch{} = recommended, %PlanBranch{} = baseline) do
    [
      %{
        "type" => "branch_tradeoff",
        "summary" => branch_tradeoff_summary(recommended, baseline),
        "recommended_branch_id" => recommended.id,
        "baseline_branch_id" => baseline.id
      }
    ]
  end

  def rows(_recommended, _baseline), do: []

  defp score_term_dimensions(recommended, baseline, dimensions) do
    Enum.map(dimensions, fn {dimension, score_key} ->
      baseline_score = numeric_score_term(baseline, score_key)
      recommended_score = numeric_score_term(recommended, score_key)

      %{
        "dimension" => dimension,
        "baseline" => baseline_score,
        "recommended" => recommended_score,
        "delta" => recommended_score - baseline_score
      }
    end)
  end

  defp numeric_score_term(branch, score_key) do
    case get_in(branch.score_terms, [score_key]) do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  defp branch_tradeoff_summary(recommended, baseline) do
    score_delta = recommended.score - baseline.score
    risk_delta = length(recommended.risk_indicators) - length(baseline.risk_indicators)

    approval_delta =
      length(recommended.approval_requirements) - length(baseline.approval_requirements)

    cond do
      score_delta >= 0 and risk_delta <= 0 ->
        "recommended branch improves expected score without increasing risk count"

      score_delta < 0 and risk_delta < 0 ->
        "recommended branch accepts lower expected score to reduce risk"

      approval_delta < 0 ->
        "recommended branch reduces approval burden"

      true ->
        "recommended branch has the best selectable expected score under policy"
    end
  end
end
