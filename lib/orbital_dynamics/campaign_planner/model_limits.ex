defmodule OrbitalDynamics.CampaignPlanner.ModelLimits do
  @moduledoc false

  @score_report_model_limits [
    "deterministic_score_explainability_only",
    "score_policy_supplied_by_request",
    "no_solver_execution",
    "not_calibrated_from_operational_outcomes"
  ]
  @objective_satisfaction_model_limits [
    "selected_activity_summary_only",
    "planned_not_executed",
    "no_solver_execution",
    "not_calibrated_from_operational_outcomes"
  ]
  @branch_comparison_model_limits [
    "deterministic_branch_score_explainability_only",
    "branch_probabilities_are_input_confidence_multipliers",
    "no_autonomous_execution",
    "score_terms_are_planning_heuristics"
  ]
  @realized_state_snapshot_model_limits [
    "provider_feedback_snapshot_only",
    "no_ground_truth_reconstruction",
    "no_schedule_mutation",
    "no_subsystem_state_estimation"
  ]

  def score_report_model_limits, do: @score_report_model_limits
  def objective_satisfaction_model_limits, do: @objective_satisfaction_model_limits
  def branch_comparison_model_limits, do: @branch_comparison_model_limits
  def realized_state_snapshot_model_limits, do: @realized_state_snapshot_model_limits
end
