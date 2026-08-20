defmodule OrbitalDynamics.CadenceImport.Capability do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{OuterAdmission, ProviderResultNormalization}
  alias OrbitalDynamics.OperatorReview

  @schema_contract "cadence_import_manifest.v1"
  @schema_version 1
  @import_statuses ~w(
    blocked_missing_cadence_import
    not_applicable
    ready_for_import
    review_required_before_import
  )
  @cadence_import_statuses ~w(invalid missing not_applicable present)
  def schema_contract, do: @schema_contract
  def schema_version, do: @schema_version
  def accepted_statuses, do: @cadence_import_statuses

  @doc """
  Declares the artifact-only import-manifest model and known limits.
  """
  def describe do
    %{
      artifact_contract: @schema_contract,
      model: :artifact_only_cadence_import_manifest,
      supported_sources: [
        "campaign_plan.v1",
        "campaign_repair.v2",
        "campaign_strategy.v3",
        "candidate_refresh.v1",
        "proposed_contact.v1",
        "planned_activity.v1",
        "realized_activity.v1",
        "realized_state_snapshot.v1",
        "result_artifact.v1",
        "timeline_feedback_report.v1",
        "operational_timeline_report.v1",
        "contact_contention_report.v1",
        "contact_contention_resolution_report.v1",
        "command_window_report.v1",
        "station_calendar_report.v1",
        "station_reservation_report.v1",
        "link_capacity_report.v1",
        "contact_allocation_report.v1",
        "contact_allocation_capacity_pack_summary.v1",
        "contact_allocation_reservation_conflict_summary.v1",
        "resource_projection_report.v1",
        "resource_projection_flow_summary.v1",
        "contact_intent.v1",
        "contact_filter_report.v1",
        "candidate_rejection_report.v1",
        "provider_counteroffer_report.v1",
        "candidate_diff_report.v1",
        "invalidated_candidate.v1",
        "resource_filter_report.v1",
        "freshness_report.v1",
        "refresh_budget_report.v1",
        "constraint_report.v1",
        "objective_satisfaction_report.v1",
        "maneuver_recommendation.v1",
        "maneuver_execution_delta.v1",
        "maneuver_review_report.v1",
        "timeline_diff_report.v1",
        "timeline_diff_summary.v1",
        "timeline_dependency_impact_summary.v1",
        "timeline_publication_summary.v1",
        "timeline_activity_precondition_summary.v1",
        "timeline_activity_state.v1",
        "timeline_activity_status_state.v1",
        "timeline_activity_approval_state.v1",
        "timeline_activity_lifecycle_state.v1",
        "timeline_lifecycle_state_summary.v1",
        "timeline_preservation_report.v1",
        "timeline_preservation_status.v1",
        "timeline_integrity_report.v1",
        "timeline_transition_application_summary.v1",
        "timeline_transition_application_report.v1",
        "approval_requirement.v1",
        "policy_decision.v1",
        "branch_comparison_report.v1",
        "ranking_comparison_report.v1",
        "score_term_report.v1",
        "objective_tradeoff_report.v1",
        "pareto_frontier_report.v1",
        "schema_validation_report.v1",
        "schema_validation_batch_report.v1",
        "execution_report.v1",
        "operational_readiness_report.v1",
        "quality_gate_report.v1",
        "operator_review_package.v1"
      ],
      import_actions: [
        "import_proposed_contact",
        "import_strategy_recommendation",
        "review_strategy_branch_alternative",
        "record_realized_feedback",
        "review_realized_feedback",
        "review_operational_timeline",
        "review_contact_contention",
        "review_contact_contention_resolution",
        "review_command_window",
        "review_station_calendar",
        "review_station_reservation",
        "review_link_capacity",
        "review_contact_allocation",
        "review_contact_allocation_capacity_pack",
        "review_provider_reservation_request",
        "review_contact_intent",
        "review_candidate_rejection",
        "review_provider_counteroffer",
        "review_candidate_diff",
        "review_refresh_freshness",
        "review_refresh_budget",
        "review_constraint",
        "review_objective_satisfaction",
        "review_resource_projection",
        "review_contact_suppression",
        "review_resource_suppression",
        "review_maneuver",
        "review_timeline_diff",
        "review_timeline_dependency_impact",
        "review_timeline_publication",
        "review_timeline_precondition",
        "review_timeline_lifecycle_state",
        "review_timeline_preservation",
        "review_timeline_integrity",
        "review_approval_requirement",
        "review_policy_escalation",
        "review_timeline_protection",
        "review_warning",
        "review_risk",
        "review_strategy_recommendation",
        "review_strategy_tradeoff",
        "review_local_search",
        "review_score_term",
        "review_objective_tradeoff",
        "review_ranking_comparison",
        "review_pareto_frontier",
        "review_schema_validation",
        "review_execution",
        "review_operational_readiness",
        "review_quality_gate",
        "review_operator_row",
        "import_replacement_activity",
        "cancel_source_activity",
        "suppress_source_activity",
        "record_preserved_executed_activity",
        "record_preserved_activity",
        "review_plan_delta"
      ],
      source_review_types: source_review_types(),
      import_statuses: @import_statuses,
      cadence_import_statuses: @cadence_import_statuses,
      provider_result_map_value_keys: ProviderResultNormalization.map_value_keys(),
      handoff_row_semantics: [
        :schema_validation_import_rows,
        :schema_validation_issue_context,
        :schema_validation_batch_nested_report_context,
        :operational_readiness_import_rows,
        :operational_readiness_gate_rows,
        :operational_readiness_resource_summary_context,
        :operational_readiness_resource_gate_context,
        :operational_readiness_adapter_boundary_context,
        :operational_readiness_cadence_import_gate_context,
        :quality_gate_import_rows,
        :quality_gate_resource_row_context,
        :campaign_plan_local_search_trace_consistency,
        :timeline_diff_summary_import_rows,
        :timeline_diff_summary_source_handoff_consistency,
        :timeline_dependency_impact_import_rows,
        :timeline_dependency_impact_source_handoff_consistency,
        :timeline_publication_import_rows,
        :timeline_publication_source_handoff_consistency,
        :timeline_lifecycle_state_import_rows,
        :timeline_lifecycle_state_source_handoff_consistency,
        :timeline_activity_precondition_import_rows,
        :timeline_activity_precondition_source_handoff_consistency,
        :timeline_preservation_import_rows,
        :timeline_preservation_source_handoff_consistency,
        :timeline_integrity_import_rows,
        :timeline_integrity_source_handoff_consistency,
        :timeline_transition_application_summary_import_rows,
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
        :suppression_source_handoff_consistency,
        :review_package_passthrough_rows
      ],
      consumer_conformance: %{
        model: :explicit_adapter_dry_run_only,
        adapter_contract: "cadence_consumer_dry_run_adapter.v1",
        operations: ["dry_run"],
        writes: false,
        supported_sources: ["campaign_strategy.v3", "cadence_import_manifest.v1"],
        result_type: "cadence_consumer_conformance.v1",
        idempotency: :deterministic_semantic_request_identity,
        outer_admission: OuterAdmission.limits(),
        known_limits: [
          :does_not_supply_a_cadence_consumer,
          :does_not_create_update_write_or_mutate,
          :does_not_replace_operator_authority,
          :adapter_executes_in_caller_process_without_timeout_or_isolation
        ]
      },
      known_limits: [
        :does_not_write_cadence,
        :does_not_approve_operator_actions,
        :does_not_resolve_schedule_conflicts,
        :review_rows_are_adapter_handoff_not_operator_approval
      ]
    }
  end

  defp source_review_types do
    OperatorReview.capabilities().review_types ++
      [
        "proposed_contact",
        "strategy_branch_comparison"
      ]
  end
end
