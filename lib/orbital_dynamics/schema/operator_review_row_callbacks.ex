defmodule OrbitalDynamics.Schema.OperatorReviewRowCallbacks do
  @moduledoc false

  def build(local) when is_list(local) do
    [
      validate_optional_activity_context: fetch!(local, :validate_optional_activity_context),
      validate_optional_protection_decision:
        fetch!(local, :validate_optional_protection_decision),
      validate_scoped_downlink_context_fields:
        &OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate/3,
      validate_observation_quality_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_observation_quality_handoff_fields/3,
      validate_feedback_maneuver_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_feedback_maneuver_handoff_fields/3,
      validate_link_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_link_handoff_fields/3,
      validate_completion_fraction_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_completion_fraction_fields/3,
      validate_eclipse_lighting_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_eclipse_lighting_handoff_fields/3,
      validate_thermal_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_thermal_handoff_fields/3,
      validate_semantic_change_details:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_semantic_change_details/3,
      validate_candidate_diff_changed_fields:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_changed_fields/3,
      validate_optional_source_window:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window/4,
      validate_optional_source_window_lineage:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window_lineage/4,
      validate_contact_allocation_capacity_pack_group:
        fetch!(local, :validate_contact_allocation_capacity_pack_group),
      validate_contact_allocation_capacity_pack_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_capacity_pack_matches_source/3,
      validate_station_capacity_fraction_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_station_capacity_fraction_fields/3,
      validate_resource_availability_variance_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_resource_availability_variance_fields/3,
      validate_optional_actual_data_rate_throughput_derivation:
        fetch!(local, :validate_optional_actual_data_rate_throughput_derivation),
      validate_optional_lifecycle_transition:
        fetch!(local, :validate_optional_lifecycle_transition),
      validate_contact_contention_deferred_priority:
        &OrbitalDynamics.Schema.ContactContentionReportContracts.validate_deferred_priority/3,
      validate_priority_field_evidence_counts:
        &OrbitalDynamics.Schema.PriorityOverrideContracts.validate_field_evidence_counts/3,
      validate_optional_branch_comparison_source_row:
        fetch!(local, :validate_optional_branch_comparison_source_row),
      validate_optional_policy_decision_evidence:
        fetch!(local, :validate_optional_policy_decision_evidence),
      validate_optional_policy_escalation: fetch!(local, :validate_optional_policy_escalation),
      validate_optional_timeline_dependency_impact_source_row:
        fetch!(local, :validate_optional_timeline_dependency_impact_source_row),
      validate_optional_timeline_publication_summary_source:
        &OrbitalDynamics.Schema.TimelineHandoffContracts.validate_optional_timeline_publication_summary_source/3,
      validate_timeline_publication_handoff_matches_source:
        &OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_publication_matches_source_summary/3,
      validate_source_evidence_fields: fetch!(local, :validate_source_evidence_fields),
      validate_source_operational_readiness_report_handoff_matches:
        &OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_report_matches_source/3,
      validate_source_quality_gate_report_handoff_matches:
        &OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_report_matches_source/3,
      validate_freshness_source_status_matches:
        fetch!(local, :validate_freshness_source_status_matches),
      validate_refresh_budget_handoff_matches_source:
        &OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_refresh_budget_matches_source/3,
      validate_schema_validation_source_status_matches:
        fetch!(local, :validate_schema_validation_source_status_matches),
      validate_execution_source_status_matches:
        fetch!(local, :validate_execution_source_status_matches),
      validate_selected_timeline_integrity_fields:
        fetch!(local, :validate_selected_timeline_integrity_fields),
      validate_optional_timeline_diff_summary_source:
        fetch!(local, :validate_optional_timeline_diff_summary_source),
      validate_optional_timeline_transition_application_summary_source:
        fetch!(local, :validate_optional_timeline_transition_application_summary_source),
      validate_optional_timeline_transition_application_row:
        fetch!(local, :validate_optional_timeline_transition_application_row),
      validate_optional_timeline_integrity_source_row:
        fetch!(local, :validate_optional_timeline_integrity_source_row),
      validate_optional_timeline_activity_state_source:
        fetch!(local, :validate_optional_timeline_activity_state_source),
      validate_optional_timeline_lifecycle_state_source_row:
        fetch!(local, :validate_optional_timeline_lifecycle_state_source_row),
      validate_optional_timeline_activity_precondition_summary_source:
        fetch!(local, :validate_optional_timeline_activity_precondition_summary_source),
      validate_optional_timeline_preservation_source_row:
        fetch!(local, :validate_optional_timeline_preservation_source_row),
      validate_branch_event_summary_fields:
        &OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields/3,
      validate_optional_timeline_identity: fetch!(local, :validate_optional_timeline_identity),
      validate_optional_timeline_link: fetch!(local, :validate_optional_timeline_link),
      validate_optional_timeline_protection_summary:
        fetch!(local, :validate_optional_timeline_protection_summary),
      validate_operational_readiness_resource_context:
        fetch!(local, :validate_operational_readiness_resource_context),
      validate_source_operational_readiness_gate_handoff_matches:
        &OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_gate_matches_source/3,
      validate_source_quality_gate_row_handoff_matches:
        &OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_row_matches_source/3,
      validate_resource_projection_battery_handoff_fields:
        &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_fields/3,
      validate_resource_projection_battery_handoff_matches_source:
        &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_matches_source/3,
      validate_resource_projection_count_handoff_matches_source:
        &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_count_handoff_matches_source/3,
      validate_resource_projection_flow_summary_context_matches_source:
        &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_flow_summary_context_matches_source/3,
      validate_link_capacity_handoff_count_lists:
        &OrbitalDynamics.Schema.LinkCapacityHandoffContracts.validate_count_lists/3,
      validate_link_capacity_handoff_matches_source:
        &OrbitalDynamics.Schema.LinkCapacityHandoffContracts.validate_matches_source/3,
      validate_contact_allocation_handoff_fields:
        fetch!(local, :validate_contact_allocation_handoff_fields),
      validate_contact_allocation_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_matches_source/3,
      validate_command_window_handoff_matches_source:
        &OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_command_window_matches_source/3,
      validate_maneuver_review_handoff_matches_source:
        &OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_maneuver_review_matches_source/3,
      validate_timeline_diff_handoff_matches_source:
        &OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_diff_matches_source/3,
      validate_timeline_transition_application_handoff_matches_source:
        &OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_transition_application_matches_source/3,
      validate_candidate_rejection_handoff_matches_source:
        &OrbitalDynamics.Schema.CandidateHandoffContracts.validate_candidate_rejection_matches_source/3,
      validate_candidate_diff_handoff_matches_source:
        &OrbitalDynamics.Schema.CandidateHandoffContracts.validate_candidate_diff_matches_source/3,
      validate_constraint_handoff_matches_source:
        &OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_constraint_matches_source/3,
      validate_objective_satisfaction_handoff_matches_source:
        &OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_objective_satisfaction_matches_source/3,
      validate_score_term_handoff_matches_source:
        &OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_score_term_matches_source/3,
      validate_objective_tradeoff_handoff_matches_source:
        &OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_objective_tradeoff_matches_source/3,
      validate_approval_requirement_handoff_matches_source:
        &OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_approval_requirement_matches_source/3,
      validate_plan_delta_handoff_matches_source:
        &OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_plan_delta_matches_source/3,
      validate_risk_explanation_handoff_matches_source:
        &OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_risk_explanation_matches_source/3,
      validate_operational_timeline_handoff_matches_source:
        &OrbitalDynamics.Schema.TimelineHandoffContracts.validate_operational_timeline_matches_source/3,
      validate_strategy_recommendation_handoff_matches_source:
        &OrbitalDynamics.Schema.StrategyHandoffContracts.validate_strategy_recommendation_matches_source/3,
      validate_strategy_tradeoff_handoff_matches_source:
        &OrbitalDynamics.Schema.StrategyHandoffContracts.validate_strategy_tradeoff_matches_source/3,
      validate_ranking_comparison_handoff_matches_source:
        &OrbitalDynamics.Schema.StrategyHandoffContracts.validate_ranking_comparison_matches_source/3,
      validate_pareto_frontier_handoff_matches_source:
        &OrbitalDynamics.Schema.StrategyHandoffContracts.validate_pareto_frontier_matches_source/3,
      validate_realized_feedback_handoff_matches_source:
        &OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_realized_feedback_matches_source/3,
      validate_provider_counteroffer_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_provider_counteroffer_matches_source/3,
      validate_contact_intent_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_contact_intent_matches_source/3,
      validate_station_calendar_handoff_matches_source:
        &OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_matches_source/3,
      validate_provider_calendar_contention_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_provider_calendar_contention_matches_source/3,
      validate_station_calendar_handoff_count_lists:
        &OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_count_lists/3,
      validate_suppression_duplicate_handoff_row_fields:
        &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_row_fields/3,
      validate_suppression_handoff_matches_source:
        &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_matches_source/3,
      validate_contact_contention_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactContentionHandoffContracts.validate_matches_source/3,
      validate_operator_review_row_links: fetch!(local, :validate_operator_review_row_links)
    ]
  end

  defp fetch!(local, name), do: Keyword.fetch!(local, name)
end
