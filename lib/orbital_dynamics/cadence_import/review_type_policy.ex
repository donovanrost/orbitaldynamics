defmodule OrbitalDynamics.CadenceImport.ReviewTypePolicy do
  @moduledoc false

  @import_manifest_review_types [
    "plan_delta_review",
    "realized_feedback",
    "operational_timeline_review",
    "contact_contention_recommendation",
    "contact_contention_review",
    "command_window_review",
    "station_calendar_review",
    "station_reservation_review",
    "link_capacity_review",
    "contact_allocation_review",
    "contact_allocation_capacity_pack_review",
    "contact_intent_review",
    "candidate_rejection_review",
    "provider_counteroffer_review",
    "candidate_diff_review",
    "freshness_review",
    "refresh_budget_review",
    "constraint_review",
    "objective_satisfaction_review",
    "resource_projection_review",
    "contact_suppression",
    "resource_suppression",
    "maneuver_review",
    "timeline_diff_review",
    "timeline_dependency_impact_review",
    "timeline_publication_review",
    "timeline_activity_precondition_review",
    "timeline_lifecycle_state_review",
    "timeline_preservation_review",
    "timeline_integrity_review",
    "approval_requirement",
    "policy_escalation",
    "timeline_protection",
    "warning",
    "risk_explanation",
    "strategy_recommendation",
    "strategy_tradeoff",
    "score_term_review",
    "objective_tradeoff_review",
    "ranking_comparison_review",
    "pareto_frontier_review",
    "schema_validation_review",
    "execution_review",
    "operational_readiness_review",
    "quality_gate_review"
  ]

  def strategy_manifest?(%{"review_type" => "strategy_recommendation"}), do: false
  def strategy_manifest?(row), do: import_manifest?(row)

  def import_manifest?(%{"review_type" => review_type})
      when review_type in @import_manifest_review_types,
      do: true

  def import_manifest?(_row), do: false
end
