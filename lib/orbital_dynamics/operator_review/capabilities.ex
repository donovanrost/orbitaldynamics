defmodule OrbitalDynamics.OperatorReview.Capabilities do
  @moduledoc false

  @schema_contract "operator_review_package.v1"
  @cadence_import_statuses ~w(invalid missing not_applicable present)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @source_artifact_types ~w(
    campaign_plan.v1
    campaign_repair.v2
    campaign_strategy.v3
    candidate_refresh.v1
    proposed_contact.v1
    planned_activity.v1
    realized_activity.v1
    realized_state_snapshot.v1
    result_artifact.v1
    timeline_feedback_report.v1
    operational_timeline_report.v1
    contact_contention_report.v1
    contact_contention_resolution_report.v1
    command_window_report.v1
    station_calendar_report.v1
    station_reservation_report.v1
    link_capacity_report.v1
    contact_allocation_report.v1
    contact_allocation_capacity_pack_summary.v1
    contact_allocation_reservation_conflict_summary.v1
    resource_projection_report.v1
    resource_projection_flow_summary.v1
    contact_intent.v1
    contact_filter_report.v1
    candidate_rejection_report.v1
    provider_counteroffer_report.v1
    candidate_diff_report.v1
    invalidated_candidate.v1
    resource_filter_report.v1
    freshness_report.v1
    refresh_budget_report.v1
    model_acceptance_report.v1
    validation_safety_case_summary.v1
    constraint_report.v1
    objective_satisfaction_report.v1
    maneuver_recommendation.v1
    maneuver_execution_delta.v1
    maneuver_review_report.v1
    timeline_diff_report.v1
    timeline_diff_summary.v1
    timeline_dependency_impact_summary.v1
    timeline_publication_summary.v1
    timeline_activity_precondition_summary.v1
    timeline_activity_state.v1
    timeline_activity_status_state.v1
    timeline_activity_approval_state.v1
    timeline_activity_lifecycle_state.v1
    timeline_lifecycle_state_summary.v1
    timeline_preservation_report.v1
    timeline_preservation_status.v1
    timeline_integrity_report.v1
    timeline_transition_application_summary.v1
    timeline_transition_application_report.v1
    approval_requirement.v1
    policy_decision.v1
    branch_comparison_report.v1
    ranking_comparison_report.v1
    score_term_report.v1
    objective_tradeoff_report.v1
    pareto_frontier_report.v1
	    schema_validation_report.v1
    schema_validation_batch_report.v1
    execution_report.v1
    operational_readiness_report.v1
    quality_gate_report.v1
    operator_review_package.v1
  )

  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_operator_review_package,
      validation_level: :artifact_contract,
      review_types: [
        "contact_contention_recommendation",
        "contact_contention_review",
        "operational_timeline_review",
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
        "model_acceptance_review",
        "validation_safety_case_review",
        "contact_suppression",
        "realized_feedback",
        "timeline_diff_review",
        "timeline_dependency_impact_review",
        "timeline_publication_review",
        "timeline_activity_precondition_review",
        "timeline_lifecycle_state_review",
        "timeline_preservation_review",
        "timeline_integrity_review",
        "maneuver_review",
        "plan_delta_review",
        "timeline_protection",
        "approval_requirement",
        "policy_escalation",
        "resource_projection_review",
        "resource_suppression",
        "warning",
        "risk_explanation",
        "strategy_recommendation",
        "strategy_tradeoff",
        "local_search_review",
        "score_term_review",
        "objective_tradeoff_review",
        "ranking_comparison_review",
        "pareto_frontier_review",
        "constraint_review",
        "objective_satisfaction_review",
        "schema_validation_review",
        "execution_review",
        "operational_readiness_review",
        "quality_gate_review"
      ],
      required_context: [
        :stable_ids,
        :source_artifact_id,
        :source_artifact_type,
        :required_operator_action,
        :reason,
        :provenance
      ],
      provider_result_map_value_keys: @provider_result_map_value_keys,
      handoff_row_semantics: [
        :schema_validation_review_rows,
        :schema_validation_issue_context,
        :schema_validation_remediation_context,
        :schema_validation_batch_nested_report_context,
        :operational_readiness_summary_rows,
        :operational_readiness_gate_rows,
        :operational_readiness_resource_summary_context,
        :operational_readiness_resource_gate_context,
        :operational_readiness_adapter_boundary_context,
        :operational_readiness_cadence_import_gate_context,
        :quality_gate_review_rows,
        :quality_gate_resource_row_context,
        :campaign_plan_local_search_trace_consistency,
        :model_acceptance_review_rows,
        :model_acceptance_source_handoff_consistency,
        :validation_safety_case_review_rows,
        :validation_safety_case_source_handoff_consistency,
        :timeline_diff_summary_review_rows,
        :timeline_diff_summary_source_handoff_consistency,
        :timeline_dependency_impact_review_rows,
        :timeline_dependency_impact_source_handoff_consistency,
        :timeline_publication_review_rows,
        :timeline_publication_source_handoff_consistency,
        :timeline_activity_precondition_review_rows,
        :timeline_activity_precondition_source_handoff_consistency,
        :timeline_lifecycle_state_review_rows,
        :timeline_lifecycle_state_source_handoff_consistency,
        :timeline_preservation_review_rows,
        :timeline_preservation_source_handoff_consistency,
        :timeline_integrity_review_rows,
        :timeline_integrity_source_handoff_consistency,
        :timeline_transition_application_summary_review_rows,
        :timeline_transition_application_summary_source_handoff_consistency,
        :resource_projection_count_handoff_consistency,
        :station_calendar_count_handoff_consistency,
        :link_capacity_count_handoff_consistency,
        :link_capacity_source_handoff_consistency,
        :contact_allocation_handoff_consistency,
        :contact_allocation_source_handoff_consistency,
        :contact_allocation_capacity_pack_source_handoff_consistency,
        :contact_contention_source_handoff_consistency,
        :command_window_source_handoff_consistency,
        :provider_counteroffer_source_handoff_consistency,
        :contact_intent_source_handoff_consistency,
        :station_calendar_source_handoff_consistency,
        :provider_calendar_contention_source_handoff_consistency,
        :suppression_duplicate_handoff_consistency,
        :suppression_source_handoff_consistency
      ],
      known_limits: [
        :no_schedule_mutation,
        :no_command_execution,
        :no_external_import,
        :no_provider_reservation
      ],
      source_artifact_types: @source_artifact_types,
      cadence_import_statuses: @cadence_import_statuses
    }
  end

  def model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
