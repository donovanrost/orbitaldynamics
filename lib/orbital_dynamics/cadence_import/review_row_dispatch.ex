defmodule OrbitalDynamics.CadenceImport.ReviewRowDispatch do
  @moduledoc false

  @builder_keys %{
    "approval_requirement" => :approval_requirement,
    "candidate_diff_review" => :candidate_diff,
    "command_window_review" => :command_window,
    "constraint_review" => :constraint,
    "contact_allocation_review" => :contact_allocation,
    "contact_contention_recommendation" => :contact_contention,
    "contact_contention_review" => :contact_contention,
    "contact_intent_review" => :contact_intent,
    "contact_suppression" => :contact_suppression,
    "execution_review" => :execution,
    "freshness_review" => :freshness,
    "link_capacity_review" => :link_capacity,
    "maneuver_review" => :maneuver_review,
    "objective_satisfaction_review" => :objective_satisfaction,
    "objective_tradeoff_review" => :objective_tradeoff,
    "operational_readiness_review" => :operational_readiness,
    "operational_timeline_review" => :operational_timeline,
    "pareto_frontier_review" => :pareto_frontier,
    "plan_delta_review" => :plan_delta,
    "policy_escalation" => :policy_escalation,
    "quality_gate_review" => :quality_gate,
    "ranking_comparison_review" => :ranking_comparison,
    "realized_feedback" => :realized_feedback,
    "refresh_budget_review" => :refresh_budget,
    "resource_projection_review" => :resource_projection,
    "resource_suppression" => :resource_suppression,
    "risk_explanation" => :risk,
    "schema_validation_review" => :schema_validation,
    "score_term_review" => :score_term,
    "station_calendar_review" => :station_calendar,
    "station_reservation_review" => :station_reservation,
    "strategy_recommendation" => :strategy_recommendation,
    "strategy_tradeoff" => :strategy_tradeoff,
    "timeline_diff_review" => :timeline_diff,
    "timeline_protection" => :timeline_protection,
    "warning" => :warning
  }

  def dispatch(row, rank, callbacks) do
    builder_key = Map.get(@builder_keys, row["review_type"], :generic)
    callbacks |> Map.fetch!(builder_key) |> then(& &1.(row, rank))
  end
end
