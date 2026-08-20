defmodule OrbitalDynamics.CadenceImport.GenericReviewActionPolicy do
  @moduledoc false

  def resolve("link_capacity_review"), do: "review_link_capacity"
  def resolve("operational_timeline_review"), do: "review_operational_timeline"
  def resolve("contact_allocation_review"), do: "review_contact_allocation"

  def resolve("contact_allocation_capacity_pack_review"),
    do: "review_contact_allocation_capacity_pack"

  def resolve("contact_intent_review"), do: "review_contact_intent"
  def resolve("candidate_rejection_review"), do: "review_candidate_rejection"
  def resolve("provider_counteroffer_review"), do: "review_provider_counteroffer"
  def resolve("station_reservation_review"), do: "review_station_reservation"
  def resolve("candidate_diff_review"), do: "review_candidate_diff"
  def resolve("freshness_review"), do: "review_refresh_freshness"
  def resolve("refresh_budget_review"), do: "review_refresh_budget"
  def resolve("constraint_review"), do: "review_constraint"
  def resolve("score_term_review"), do: "review_score_term"
  def resolve("objective_tradeoff_review"), do: "review_objective_tradeoff"
  def resolve("objective_satisfaction_review"), do: "review_objective_satisfaction"
  def resolve("local_search_review"), do: "review_local_search"
  def resolve("resource_projection_review"), do: "review_resource_projection"
  def resolve("contact_suppression"), do: "review_contact_suppression"
  def resolve("resource_suppression"), do: "review_resource_suppression"
  def resolve("maneuver_review"), do: "review_maneuver"
  def resolve("timeline_diff_review"), do: "review_timeline_diff"

  def resolve("timeline_dependency_impact_review"),
    do: "review_timeline_dependency_impact"

  def resolve("timeline_publication_review"), do: "review_timeline_publication"
  def resolve("timeline_activity_precondition_review"), do: "review_timeline_precondition"
  def resolve("timeline_lifecycle_state_review"), do: "review_timeline_lifecycle_state"
  def resolve("timeline_preservation_review"), do: "review_timeline_preservation"
  def resolve("timeline_integrity_review"), do: "review_timeline_integrity"
  def resolve("approval_requirement"), do: "review_approval_requirement"
  def resolve("policy_escalation"), do: "review_policy_escalation"
  def resolve("timeline_protection"), do: "review_timeline_protection"
  def resolve("warning"), do: "review_warning"
  def resolve("risk_explanation"), do: "review_risk"
  def resolve("strategy_recommendation"), do: "review_strategy_recommendation"
  def resolve("strategy_tradeoff"), do: "review_strategy_tradeoff"
  def resolve("ranking_comparison_review"), do: "review_ranking_comparison"
  def resolve("pareto_frontier_review"), do: "review_pareto_frontier"
  def resolve("schema_validation_review"), do: "review_schema_validation"
  def resolve("operational_readiness_review"), do: "review_operational_readiness"
  def resolve("quality_gate_review"), do: "review_quality_gate"
  def resolve(_review_type), do: "review_operator_row"
end
