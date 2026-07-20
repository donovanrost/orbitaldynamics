defmodule OrbitalDynamics.Schema do
  @moduledoc """
  Executable schema contracts for public OrbitalDynamics artifacts.

  This module is intentionally lighter than full JSON Schema. It gives the
  current campaign-planning artifacts a stable, testable contract boundary while
  the artifact shapes are still maturing.
  """

  alias OrbitalDynamics.Schema.{
    CandidateRejectionValidation,
    ContactAllocationValidation,
    ContactReportValidation,
    DecisionSupportValidation,
    OperationalReadinessValidation,
    OperationalTimelineValidation,
    OperatorReviewValidation,
    PolicyValidation,
    ResourceValidation,
    SourceEvidenceValidation,
    StationReservationValidation,
    TimelineContextJsonSchema,
    TimelineContextValidation,
    TimelineSourceValidation,
    TimelineTransitionValidation
  }

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_id_match: 7,
      validate_optional_stable_id_list: 4,
      validate_stable_ids: 4
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      require_nested: 4
    ]

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [
      validate_optional_rows: 4,
      validate_rows: 4
    ]

  import OrbitalDynamics.Schema.CommandWindowCapabilityContext,
    only: [command_window_report_model_limits: 0]

  import OrbitalDynamics.Schema.CadenceImportCapabilityContext,
    only: [
      cadence_import_capability: 0,
      cadence_import_manifest_model_limits: 0,
      cadence_import_supported_sources: 0
    ]

  import OrbitalDynamics.Schema.ContactFilterCapabilityContext,
    only: [
      contact_filter_report_assumptions_json_schema: 0,
      contact_filter_report_model_limits: 0,
      contact_filter_suppression_reasons: 0
    ]

  import OrbitalDynamics.Schema.ContactIntentCapabilityContext,
    only: [
      contact_intent_model_limits: 0,
      contact_intent_summary_assumptions_json_schema: 0
    ]

  import OrbitalDynamics.Schema.ContactAllocationCapabilityContext,
    only: [
      contact_allocation_capabilities: 0,
      contact_allocation_capacity_pack_summary_assumptions_json_schema: 0,
      contact_allocation_model_limits: 0,
      contact_allocation_provider_reservation_request_summary_assumptions_json_schema: 0,
      contact_allocation_reservation_conflict_summary_assumptions_json_schema: 0,
      contact_allocation_station_pressure_summary_assumptions_json_schema: 0,
      contact_allocation_summary_assumptions_json_schema: 0
    ]

  import OrbitalDynamics.Schema.ContactContentionCapabilityContext,
    only: [
      contact_contention_report_assumptions_json_schema: 0,
      contact_contention_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.LinkCapacityCapabilityContext,
    only: [link_capacity_assumptions_json_schema: 1]

  import OrbitalDynamics.Schema.ManeuverReviewCapabilityContext,
    only: [
      maneuver_recommendation_model_limits: 0,
      maneuver_review_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.OperatorReviewCapabilityContext,
    only: [
      operator_review_capabilities: 0,
      operator_review_package_model_limits: 0,
      operator_review_source_artifact_types: 0,
      operator_review_types: 0
    ]

  import OrbitalDynamics.Schema.OperationalReadinessCapabilityContext,
    only: [operational_readiness_capabilities: 0]

  import OrbitalDynamics.Schema.PolicyCapabilityContext,
    only: [policy_model_limits: 0]

  import OrbitalDynamics.Schema.ResourceFilterCapabilityContext,
    only: [
      resource_filter_report_assumptions_json_schema: 0,
      resource_filter_report_model_limits: 0,
      resource_filter_suppression_reasons: 0
    ]

  import OrbitalDynamics.Schema.StationCalendarCapabilityContext,
    only: [
      station_calendar_capabilities: 0,
      station_calendar_provider_counteroffer_actions: 0,
      station_calendar_provider_counteroffer_negotiation_states: 0,
      station_calendar_report_model: 0,
      station_calendar_report_model_limits: 0
    ]

  import OrbitalDynamics.Schema.TimelineCapabilityContext,
    only: [
      timeline_activity_precondition_statuses: 0,
      timeline_candidate_rejection_actions: 0,
      timeline_candidate_rejection_reasons: 0,
      timeline_capabilities: 0,
      timeline_feedback_capabilities: 0,
      timeline_feedback_report_model_limits: 0,
      timeline_integrity_issue_types: 0,
      timeline_report_model_limits: 0,
      timeline_required_operator_actions: 0,
      timeline_transition_decisions: 0
    ]

  import OrbitalDynamics.Schema.ValidationCapabilityContext,
    only: [
      model_acceptance_report_model_limits: 0,
      schema_migration_row_statuses: 0,
      schema_migration_statuses: 0
    ]

  @campaign_plan "campaign_plan.v1"
  @campaign_repair "campaign_repair.v2"
  @campaign_strategy "campaign_strategy.v3"
  @accepted_planning_state "accepted_planning_state.v1"
  @candidate_refresh "candidate_refresh.v1"
  @candidate_activity "candidate_activity.v1"
  @candidate_diff_report "candidate_diff_report.v1"
  @candidate_diff_row "candidate_diff_row.v1"
  @freshness_report "freshness_report.v1"
  @invalidated_candidate "invalidated_candidate.v1"
  @refresh_budget_report "refresh_budget_report.v1"
  @refreshed_window "refreshed_window.v1"
  @remaining_horizon "remaining_horizon.v1"
  @source_window_lineage "source_window_lineage.v1"
  @spacecraft_state_estimate "spacecraft_state_estimate.v1"
  @maneuver_execution_delta "maneuver_execution_delta.v1"
  @validation_reference_fixture_report "validation_reference_fixture_report.v1"
  @validation_reference_report "validation_reference_report.v1"
  @validation_check "validation_check.v1"
  @validation_record "validation_record.v1"
  @model_acceptance_report "model_acceptance_report.v1"
  @validation_safety_case_summary "validation_safety_case_summary.v1"
  @planned_activity "planned_activity.v1"
  @activity_template "activity_template.v1"
  @proposed_contact "proposed_contact.v1"
  @contact_intent "contact_intent.v1"
  @command_window_report "command_window_report.v1"
  @link_capacity_report "link_capacity_report.v1"
  @link_capacity_summary "link_capacity_summary.v1"
  @relay_data_path_summary "relay_data_path_summary.v1"
  @contact_intent_summary "contact_intent_summary.v1"
  @contact_allocation_report "contact_allocation_report.v1"
  @contact_allocation_summary "contact_allocation_summary.v1"
  @contact_allocation_reservation_conflict_summary "contact_allocation_reservation_conflict_summary.v1"
  @contact_allocation_station_pressure_summary "contact_allocation_station_pressure_summary.v1"
  @contact_allocation_capacity_pack_summary "contact_allocation_capacity_pack_summary.v1"
  @contact_filter_report "contact_filter_report.v1"
  @contact_contention_report "contact_contention_report.v1"
  @contact_contention_resolution_report "contact_contention_resolution_report.v1"
  @contact_contention_resolution_summary "contact_contention_resolution_summary.v1"
  @station_calendar_provider "station_calendar_provider.v1"
  @station_calendar_report "station_calendar_report.v1"
  @station_calendar_precedence_summary "station_calendar_precedence_summary.v1"
  @station_reservation_report "station_reservation_report.v1"
  @contact_allocation_provider_reservation_request_summary "contact_allocation_provider_reservation_request_summary.v1"
  @station_reservation_review_summary "station_reservation_review_summary.v1"
  @station_reservation_hold_summary "station_reservation_hold_summary.v1"
  @station_reservation_hold_import_readiness_summary "station_reservation_hold_import_readiness_summary.v1"
  @provider_counteroffer_report "provider_counteroffer_report.v1"
  @provider_counteroffer_review_summary "provider_counteroffer_review_summary.v1"
  @provider_counteroffer_import_readiness_summary "provider_counteroffer_import_readiness_summary.v1"
  @provider_counteroffer_plan_impact_summary "provider_counteroffer_plan_impact_summary.v1"
  @resource_summary "resource_summary.v1"
  @resource_filter_report "resource_filter_report.v1"
  @resource_filter_summary "resource_filter_summary.v1"
  @resource_projection_report "resource_projection_report.v1"
  @resource_projection_flow_summary "resource_projection_flow_summary.v1"
  @realized_activity "realized_activity.v1"
  @realized_state_snapshot "realized_state_snapshot.v1"
  @timeline_feedback_report "timeline_feedback_report.v1"
  @candidate_rejection_report "candidate_rejection_report.v1"
  @plan_delta "plan_delta.v1"
  @approval_requirement "approval_requirement.v1"
  @policy_decision "policy_decision.v1"
  @policy_bundle "policy_bundle.v1"
  @cadence_import_manifest "cadence_import_manifest.v1"
  @operational_readiness_report "operational_readiness_report.v1"
  @operational_import_eligibility_summary "operational_import_eligibility_summary.v1"
  @operational_readiness_gate_summary "operational_readiness_gate_summary.v1"
  @operational_execution_boundary_summary "operational_execution_boundary_summary.v1"
  @operational_quality_gate_summary "operational_quality_gate_summary.v1"
  @operational_quality_gate_unavailable_resource_summary "operational_quality_gate_unavailable_resource_summary.v1"
  @operational_quality_gate_operator_training_summary "operational_quality_gate_operator_training_summary.v1"
  @operational_quality_gate_schema_validation_summary "operational_quality_gate_schema_validation_summary.v1"
  @operational_quality_gate_import_readiness_summary "operational_quality_gate_import_readiness_summary.v1"
  @quality_gate_report "quality_gate_report.v1"
  @operator_review_package "operator_review_package.v1"
  @strategy_recommendation "strategy_recommendation.v1"
  @maneuver_recommendation "maneuver_recommendation.v1"
  @maneuver_review_report "maneuver_review_report.v1"
  @execution_report "execution_report.v1"
  @monte_carlo_reproducibility_report "monte_carlo_reproducibility_report.v1"
  @objective_tradeoff_report "objective_tradeoff_report.v1"
  @objective_satisfaction_report "objective_satisfaction_report.v1"
  @ranking_comparison_report "ranking_comparison_report.v1"
  @pareto_frontier_report "pareto_frontier_report.v1"
  @operational_timeline_report "operational_timeline_report.v1"
  @timeline_diff_report "timeline_diff_report.v1"
  @timeline_diff_summary "timeline_diff_summary.v1"
  @timeline_integrity_report "timeline_integrity_report.v1"
  @timeline_dependency_impact_summary "timeline_dependency_impact_summary.v1"
  @timeline_publication_summary "timeline_publication_summary.v1"
  @timeline_activity_state "timeline_activity_state.v1"
  @timeline_activity_precondition_summary "timeline_activity_precondition_summary.v1"
  @timeline_activity_status_state "timeline_activity_status_state.v1"
  @timeline_activity_approval_state "timeline_activity_approval_state.v1"
  @timeline_activity_lifecycle_state "timeline_activity_lifecycle_state.v1"
  @timeline_preservation_report "timeline_preservation_report.v1"
  @timeline_preservation_status "timeline_preservation_status.v1"
  @timeline_lifecycle_state_summary "timeline_lifecycle_state_summary.v1"
  @timeline_transition_application_report "timeline_transition_application_report.v1"
  @timeline_transition_application_summary "timeline_transition_application_summary.v1"
  @branch_comparison_report "branch_comparison_report.v1"
  @cadence_import_manifest_scalar_count_fields [
    "blocked_count",
    "missing_import_count",
    "ready_count",
    "review_required_count",
    "row_count"
  ]
  @optimizer_contract "optimizer_contract.v1"
  @constraint_report "constraint_report.v1"
  @score_term_report "score_term_report.v1"
  @environment_model_capability "environment_model_capability.v1"
  @environment_provider_capability "environment_provider_capability.v1"
  @subsystem_model_capability "subsystem_model_capability.v1"
  @schema_validation_report "schema_validation_report.v1"
  @schema_validation_batch_report "schema_validation_batch_report.v1"
  @schema_migration_report "schema_migration_report.v1"
  @study_benchmark "study_benchmark.v1"
  @manifest_field_reference "manifest_field_reference.v1"
  @study_manifest_lint "study_manifest_lint.v1"
  @result_artifact "result_artifact.v1"
  @campaign_request_lint "campaign_request_lint.v1"
  @strategy_branch "strategy_branch.v1"
  @validation_tolerance_policy "validation_tolerance_policy.v1"
  @backend_acceptance_policy "backend_acceptance_policy.v1"
  @capability_catalog "capability_catalog.v1"

  @json_schema_draft "https://json-schema.org/draft/2020-12/schema"
  @stable_id_pattern OrbitalDynamics.Schema.StableIdValidation.pattern()
  @sha256_pattern "^[0-9a-f]{64}$"
  @field_type_hints %{
    "accepted_at" => "string",
    "actual_ends_at_s" => "number",
    "actual_starts_at_s" => "number",
    "action" => "string",
    "activities" => "array",
    "affected_contact_count" => "integer",
    "affected_contacts" => "array",
    "added_count" => "integer",
    "activity_id" => "string",
    "activity_ids" => "array",
    "activity_count" => "integer",
    "activity_context" => "object",
    "activity_type" => "string",
    "attitude_confidence" => "number",
    "attitude_error_deg" => "number",
    "attitude_mode" => "string",
    "attitude_model" => "string",
    "attitude_source" => "string",
    "attitude_status" => "string",
    "attitude_target_id" => "string",
    "approval_policy" => "object",
    "approval_requirement_count" => "integer",
    "approval_requirements" => "array",
    "approval_rule_matches" => "array",
    "approval_status" => "string",
    "approval_transition" => "object",
    "application_count" => "integer",
    "application_status_counts" => "object",
    "accepted_count" => "integer",
    "approved_count" => "integer",
    "artifact_count" => "integer",
    "artifact_path" => "string",
    "artifact_type" => "string",
    "assumptions" => "object",
    "antenna_available" => "boolean",
    "battery_capacity_wh" => "number",
    "battery_energy_used_wh" => "number",
    "battery_energy_generated_wh" => "number",
    "battery_state_of_charge" => "number",
    "boresight_axis" => "string",
    "backend" => "string",
    "batch_propagation" => "boolean",
    "branch_id" => "string",
    "branch_comparison_report" => "object",
    "branch_count" => "integer",
    "branch_event_count" => "integer",
    "branch_event_types" => "array",
    "branch_event_trust_boundary_status_counts" => "object",
    "branch_image_quality_min_score" => "number",
    "branch_image_quality_statuses" => "array",
    "branch_image_quality_sources" => "array",
    "branch_cloud_cover_max_fraction" => "number",
    "branch_blur_max_score" => "number",
    "branch_probability" => "number",
    "cadence_import" => "object",
    "cadence_import_manifest" => "object",
    "cadence_import_status_counts" => "object",
    "candidate_activities" => "array",
    "candidate_activity_id" => "string",
    "candidate_activity_ids" => "array",
    "candidate_id" => "string",
    "planned_activity_id" => "string",
    "candidate_activity_count" => "integer",
    "candidate_count" => "integer",
    "candidate_rejection_report" => "object",
    "candidate_rejection_review_count" => "integer",
    "candidate_rejection_reason_count" => "integer",
    "candidate_rejection_reasons" => "array",
    "candidate_rejection_status" => "string",
    "candidate_diff_changed_field_count" => "integer",
    "candidate_diff_changed_fields" => "array",
    "candidate_diff_report" => "object",
    "cadence_import_type" => "string",
    "calendar_entry_count" => "integer",
    "provider_calendar_contention_group_count" => "integer",
    "provider_calendar_contention_groups" => "array",
    "category" => "string",
    "capacity_adjusted_throughput_mb" => "number",
    "changed_count" => "integer",
    "changed_field_counts" => "object",
    "changed_fields" => "array",
    "classification" => "string",
    "allocated_contact_count" => "integer",
    "allocation_reason_counts" => "object",
    "allocation_status_counts" => "object",
    "ambiguous_timeline_feedback_count" => "integer",
    "ambiguous_timeline_match_count" => "integer",
    "blocked_count" => "integer",
    "blocked_contact_count" => "integer",
    "blocked_gate_count" => "integer",
    "blocked_import_count" => "integer",
    "blocked_review_count" => "integer",
    "contact_intents" => "array",
    "contact_contention_report" => "object",
    "contact_contention_resolution_report" => "object",
    "contention_recommendation_count" => "integer",
    "contention_review_count" => "integer",
    "contact_filter_report" => "object",
    "constraint_count" => "integer",
    "constraint_id" => "string",
    "constraint_report" => "object",
    "contention_group_ids" => "array",
    "conflict_group_count" => "integer",
    "conflicted_contact_count" => "integer",
    "coverage" => "object",
    "coordinate_frame" => "string",
    "candidate_target_ids" => "array",
    "target_commitments" => "array",
    "target_id" => "string",
    "target_priority" => "number",
    "completed_fraction" => "number",
    "completed_scenario_count" => "integer",
    "combined_source_branch_ids" => "array",
    "command_count" => "integer",
    "command_result" => "string",
    "command_success" => "boolean",
    "command_success_factor" => "number",
    "command_success_factor_source" => "string",
    "command_authority_status" => "string",
    "planned_command_authority_status" => "string",
    "realized_command_authority_status" => "string",
    "command_authority_status_match_status" => "string",
    "planned_required_authority" => "string",
    "realized_required_authority" => "string",
    "required_authority_match_status" => "string",
    "command_safety_status" => "string",
    "planned_command_safety_status" => "string",
    "realized_command_safety_status" => "string",
    "command_safety_status_match_status" => "string",
    "command_authorized" => "boolean",
    "planned_command_authorized" => "boolean",
    "realized_command_authorized" => "boolean",
    "command_authorized_match_status" => "string",
    "command_safety_checked" => "boolean",
    "planned_command_safety_checked" => "boolean",
    "realized_command_safety_checked" => "boolean",
    "command_safety_checked_match_status" => "string",
    "command_window_count" => "integer",
    "command_window_report" => "object",
    "collection_ends_at_s" => "number",
    "collection_id" => "string",
    "contact_id" => "string",
    "contact_result" => "string",
    "contact_success" => "boolean",
    "contact_success_factor" => "number",
    "contact_success_factor_source" => "string",
    "current_epoch_s" => "number",
    "data_volume_mb" => "number",
    "data_volume_shortfall_mb" => "number",
    "deltas" => "array",
    "degraded" => "boolean",
    "deferred_contact_count" => "integer",
    "dependency_count" => "integer",
    "dependency_issue_count" => "integer",
    "effective_task_concurrency" => "integer",
    "description" => "string",
    "adapter" => "string",
    "adapter_version" => "string",
    "actual_margin" => "number",
    "deterministic_ordering" => "array",
    "deterministic_seed" => "boolean",
    "diff_status" => "string",
    "diff_status_counts" => "object",
    "direction" => "string",
    "directions" => "array",
    "downlink_margin" => "number",
    "duplicate_contact_candidate_count" => "integer",
    "duplicate_contact_id_count" => "integer",
    "duplicate_suppressed_candidate_id_count" => "integer",
    "duplicate_suppressed_candidate_row_count" => "integer",
    "ambiguous_selected_contact_id_count" => "integer",
    "ambiguous_selected_contact_ids" => "array",
    "approval_transition_counts" => "object",
    "activity_status_counts" => "object",
    "approval_status_counts" => "object",
    "analysis_gate_count" => "integer",
    "duplicate_replacement_timeline_identity_count" => "integer",
    "duplicate_source_timeline_identity_count" => "integer",
    "duplicate_timeline_identity_activity_count" => "integer",
    "duplicate_timeline_identity_count" => "integer",
    "duplicate_realized_feedback_count" => "integer",
    "duplicate_realized_match_count" => "integer",
    "actual_delta_v_km_s" => "array",
    "delta_v_3sigma_km_s" => "array",
    "delta_v_3sigma_magnitude_km_s" => "number",
    "delta_v_km_s" => "array",
    "delta_v_magnitude_km_s" => "number",
    "eclipse_overlap_fraction" => "number",
    "eclipse_overlap_s" => "number",
    "end_delta_s" => "number",
    "ends_at_s" => "number",
    "epoch_s" => "number",
    "epoch_scale" => "string",
    "errors" => "array",
    "escalations" => "array",
    "escalation_level" => "string",
    "escalation_queue" => "string",
    "escalation_role" => "string",
    "estimated_data_volume_mb" => "number",
    "estimated_downlink_mb" => "number",
    "estimated_storage_mb" => "number",
    "estimated_throughput_mb" => "number",
    "entries" => "array",
    "event_result_count" => "integer",
    "error_count" => "integer",
    "executed_count" => "integer",
    "execution_mode" => "string",
    "execution_uncertainty" => "object",
    "execution_uncertainty_declared_count" => "integer",
    "execution_uncertainty_missing_count" => "integer",
    "execution_uncertainty_source" => "string",
    "execution_uncertainty_status" => "string",
    "executed_delta_v_km_s" => "array",
    "external_id" => "string",
    "failed_scenario_count" => "integer",
    "failed_scenarios" => "array",
    "feedback_kind_counts" => "object",
    "feedback_status" => "string",
    "feedback_weight" => "number",
    "feedback_weight_source" => "string",
    "fallback_policy" => "object",
    "explanation" => "array",
    "evidence" => "object",
    "exclusivity_count" => "integer",
    "exclusivity_issue_count" => "integer",
    "file_count" => "integer",
    "field_count" => "integer",
    "fixture_id" => "string",
    "fixture_count" => "integer",
    "freshness_report" => "object",
    "fuel_margin" => "number",
    "frame" => "string",
    "generated_at" => "string",
    "gate_count" => "integer",
    "gate_classification_counts" => "object",
    "gate_id" => "string",
    "gate_status_counts" => "object",
    "gates" => "array",
    "generated_scenario_count" => "integer",
    "generated_scenario_ids" => "array",
    "generator" => "string",
    "ground_station_id" => "string",
    "ground_station_ids" => "array",
    "has_cadence_import" => "boolean",
    "has_source_window" => "boolean",
    "health_check_count" => "integer",
    "id" => "string",
    "id_prefix" => "string",
    "ingested_at" => "string",
    "invalidated_candidate_count" => "integer",
    "invalid_activity_input_count" => "integer",
    "invalid_candidate_input_count" => "integer",
    "invalid_candidate_input_ids" => "array",
    "invalid_contact_input_count" => "integer",
    "invalid_prior_candidate_input_count" => "integer",
    "invalid_prior_candidate_input_ids" => "array",
    "invalid_maneuver_recommendation_count" => "integer",
    "invalid_maneuver_recommendation_ids" => "array",
    "invalid_resource_summary_input_count" => "integer",
    "invalid_resource_summary_input_ids" => "array",
    "invalid_cadence_import_count" => "integer",
    "interpolation" => "string",
    "input_candidate_count" => "integer",
    "ignored_contact_count" => "integer",
    "ignored_contact_ids" => "array",
    "ignored_contact_reason_counts" => "object",
    "ignored_selected_contact_count" => "integer",
    "ignored_selected_contact_ids" => "array",
    "ignored_selected_contact_reason_counts" => "object",
    "import_action_counts" => "object",
    "import_classification" => "string",
    "import_row_count" => "integer",
    "import_status_counts" => "object",
    "input_dir" => "string",
    "incompatible_activity_types" => "array",
    "instrument_id" => "string",
    "invalid_contact_input_ids" => "array",
    "invalidated_candidates" => "array",
    "known_limits" => "array",
    "lighting_condition" => "string",
    "lighting_condition_detail" => "string",
    "lighting_condition_model" => "string",
    "lighting_confidence" => "number_or_string",
    "lighting_detail_model" => "string",
    "link_capacity_report" => "object",
    "link_capacity_review_count" => "integer",
    "locked" => "boolean",
    "locked_count" => "integer",
    "manifest_id" => "string",
    "max_latency_s" => "number",
    "match_strategy_counts" => "object",
    "mission_state_snapshot" => "object",
    "maneuver_model" => "string",
    "maneuver_recommendations" => "array",
    "maneuver_review_report" => "object",
    "maneuver_count" => "integer",
    "maneuver_execution_uncertainty" => "object",
    "maneuver_id" => "string",
    "maneuver_result" => "string",
    "maneuver_success" => "boolean",
    "maneuver_success_factor" => "number",
    "maneuver_success_factor_source" => "string",
    "maneuver_type" => "string",
    "maneuver_review_count" => "integer",
    "metadata" => "object",
    "mode" => "string",
    "model" => "string",
    "model_count" => "integer",
    "model_id" => "string",
    "model_limits" => "array",
    "monte_carlo_reproducibility_report" => "object",
    "missing_import_count" => "integer",
    "manifest_review_required_count" => "integer",
    "network_access" => "boolean",
    "new_candidate_count" => "integer",
    "node" => "string",
    "not_rejected_count" => "integer",
    "objective" => "string",
    "objective_count" => "integer",
    "objective_satisfaction_report" => "object",
    "objective_tradeoff_report" => "object",
    "observation_result" => "string",
    "observation_success" => "boolean",
    "observation_success_factor" => "number",
    "observation_success_factor_source" => "string",
    "image_quality_score" => "number",
    "image_quality_score_delta" => "number",
    "image_quality_source" => "string",
    "image_quality_status" => "string",
    "image_quality_status_match_status" => "string",
    "cloud_cover_fraction" => "number",
    "cloud_cover_fraction_delta" => "number",
    "blur_score" => "number",
    "blur_score_delta" => "number",
    "off_nadir_angle_deg" => "number",
    "optimizer" => "string",
    "optimizer_contract" => "object",
    "operational_feedback" => "object",
    "operational_feedback_excluded_count" => "integer",
    "operational_feedback_provenance" => "object",
    "operational_kind_counts" => "object",
    "operational_timeline_report" => "object",
    "operator_review_package" => "object",
    "operational_readiness_report" => "object",
    "operational_readiness_review_count" => "integer",
    "operational_readiness_status" => "string",
    "parameters" => "object",
    "actual_data_volume_mb" => "number",
    "actual_data_volume_shortfall_mb" => "number",
    "actual_volume_mb" => "number",
    "actual_delivery_at_s" => "number",
    "actual_latency_s" => "number",
    "actual_throughput_mb" => "number",
    "actual_throughput_contact_count" => "integer",
    "actual_data_rate_throughput_derivation" => "object",
    "actual_data_rate_throughput_derivations" => "array",
    "payload_available" => "boolean",
    "passed_gate_count" => "integer",
    "payload_id" => "string",
    "pitch_deg" => "number",
    "planner" => "string",
    "pointing_confidence" => "number",
    "pointing_error_deg" => "number",
    "pointing_mode" => "string",
    "pointing_model" => "string",
    "pointing_source" => "string",
    "pointing_status" => "string",
    "pointing_target_id" => "string",
    "plan_id" => "string",
    "plan_delta_count" => "integer",
    "policy" => "object",
    "policy_classification" => "string",
    "planned_count" => "integer",
    "planned_data_volume_mb" => "number",
    "planned_delivery_at_s" => "number",
    "planned_volume_mb" => "number",
    "planned_image_quality_score" => "number",
    "planned_image_quality_status" => "string",
    "planned_cloud_cover_fraction" => "number",
    "planned_blur_score" => "number",
    "planning_horizon" => "object",
    "planned_ends_at_s" => "number",
    "planned_estimated_throughput_mb" => "number",
    "planned_latency_s" => "number",
    "planned_protection_decision_counts" => "object",
    "planned_starts_at_s" => "number",
    "planned_status" => "string",
    "policy_decision" => "object",
    "policy_bundle_id" => "string",
    "policy_escalation_count" => "integer",
    "policy_blocked_allocated_contact_count" => "integer",
    "power_margin" => "number",
    "preserved_source_count" => "integer",
    "preserved_lineage_fields" => "array",
    "product_id" => "string",
    "product_ids" => "array",
    "provider" => "string",
    "provider_id" => "string",
    "proposed_contacts" => "array",
    "prior_candidate_count" => "integer",
    "primary_rejection_reason" => "string",
    "provenance" => "object",
    "quality" => "object",
    "raw_score" => "number",
    "requested_count" => "integer",
    "report_id" => "string",
    "review_required_count" => "integer",
    "review_gate_count" => "integer",
    "roll_deg" => "number",
    "ranked_branch_ids" => "array",
    "ranked_scenario_ids" => "array",
    "ranked_timeline_count" => "integer",
    "ranking_explanation" => "object",
    "ranking_count" => "integer",
    "ranking_comparison_report" => "object",
    "rank" => "integer",
    "ranked_timelines" => "array",
    "realized_count" => "integer",
    "realized_feedback_count" => "integer",
    "ranking_comparison_count" => "integer",
    "realized_image_quality_score" => "number",
    "realized_image_quality_status" => "string",
    "realized_cloud_cover_fraction" => "number",
    "realized_blur_score" => "number",
    "realized_status" => "string",
    "realized_state_snapshot" => "object",
    "received_at" => "string",
    "reason" => "string",
    "reason_count" => "integer",
    "remediation" => "array",
    "remediation_count" => "integer",
    "recommendation" => "object",
    "recommendation_count" => "integer",
    "recommended_branch_id" => "string",
    "readiness_level" => "string",
    "ready_for_import_count" => "integer",
    "intended_use" => "string",
    "unknown_model_count" => "integer",
    "validation_level_counts" => "object",
    "refresh_budget_report" => "object",
    "refresh_id" => "string",
    "review_row_count" => "integer",
    "refreshed_candidate_count" => "integer",
    "refreshed_windows" => "object",
    "remaining_horizon" => "object",
    "removed_count" => "integer",
    "repair_metadata" => "object",
    "repair_policy" => "object",
    "repair_action" => "string",
    "repair_delta_count" => "integer",
    "repair_id" => "string",
    "recorded_replacement_count" => "integer",
    "rejected_count" => "integer",
    "rejection_reason_counts" => "object",
    "rejection_reasons" => "array",
    "rejection_status" => "string",
    "replacement_activity_id" => "string",
    "replacement_activity_count" => "integer",
    "replacement_activity_type" => "string",
    "replacement_approval_status" => "string",
    "replacement_cadence_import_status_counts" => "object",
    "replacement_ends_at_s" => "number",
    "replacement_locked" => "boolean",
    "replacement_status" => "string",
    "replacement_starts_at_s" => "number",
    "replacement_timeline_id" => "string",
    "replacement_timeline_identity" => "object",
    "requirement_type" => "string",
    "required_downlink_mb" => "number",
    "required_volume_mb" => "number",
    "required_data_volume_mb" => "number",
    "required_data_volume_gap_mb" => "number",
    "required_authority" => "string",
    "required_count" => "integer",
    "required_margin" => "number",
    "required_operator_action" => "string",
    "required_operator_action_counts" => "object",
    "requires_approval" => "array",
    "requires_operator_review" => "boolean",
    "ready_count" => "integer",
    "reduced_capacity_pack_group_count" => "integer",
    "retained_candidate_count" => "integer",
    "returned_allocated_contact_count" => "integer",
    "review_count" => "integer",
    "reviewable" => "boolean",
    "reviewable_count" => "integer",
    "review_queue_counts" => "object",
    "review_type_counts" => "object",
    "review_type" => "string",
    "risk_count" => "integer",
    "risk_type" => "string",
    "row_count" => "integer",
    "rows" => "array",
    "risks_remaining" => "array",
    "rule_id" => "string",
    "rule_matches" => "array",
    "reports" => "array",
    "records" => "array",
    "resource_summaries" => "array",
    "resource_projection_report" => "object",
    "resource_projection_review_count" => "integer",
    "resource_filter_report" => "object",
    "contact_suppression_count" => "integer",
    "resource_projection_spacecraft_count" => "integer",
    "resource_projection_warning_count" => "integer",
    "resource_blocking_dimension" => "string",
    "resource_blocked_contact_ids" => "array",
    "resource_blocked_contact_count" => "integer",
    "resource_id" => "string",
    "resource_provenance" => "object",
    "resource_source_quality" => "string",
    "resource_source_quality_counts" => "object",
    "resource_suppression_count" => "integer",
    "resource_trust_boundary" => "string",
    "resource_trust_boundary_status" => "string",
    "resource_trust_boundary_status_counts" => "object",
    "input_resource_summary_count" => "integer",
    "input_contact_count" => "integer",
    "kept_candidate_count" => "integer",
    "lint_task" => "string",
    "manifest" => "object",
    "manifest_schema_contract" => "string",
    "manifest_schema_id" => "string",
    "projected_resources" => "array",
    "projected_downlink_margin" => "number",
    "projected_downlink_remaining_mb" => "number",
    "projected_storage_margin" => "number",
    "projected_storage_remaining_mb" => "number",
    "schema_contract" => "string",
    "schema_export_command" => "string",
    "schema_id" => "string",
    "schema_version" => "integer",
    "semantic_validator" => "string",
    "skipped_artifacts" => "array",
    "skipped_count" => "integer",
    "sla_s" => "number",
    "score" => "number",
    "score_delta_from_selected" => "number",
    "score_delta_from_recommended" => "number",
    "score_terms" => "object",
    "score_term_keys" => "array",
    "score_term_report" => "object",
    "selected" => "boolean",
    "selected_activity_count" => "integer",
    "selected_activity_ids" => "array",
    "selected_activities" => "array",
    "selected_contact_count" => "integer",
    "selected_contact_ids" => "array",
    "selected_capacity_adjusted_throughput_mb" => "number",
    "selected_capacity_utilization_fraction" => "number",
    "selection_utilization_status" => "string",
    "selected_downlink_mb" => "number",
    "selected_downlink_shortfall_mb" => "number",
    "selected_data_volume_mb" => "number",
    "selected_data_volume_shortfall_mb" => "number",
    "selected_volume_mb" => "number",
    "selected_estimated_throughput_mb" => "number",
    "selected_contact_id" => "string",
    "selected_target_ids" => "array",
    "selection_policy" => "string",
    "sampling_method" => "string",
    "scenario_id" => "string",
    "scenario_ids" => "array",
    "scenario_count" => "integer",
    "scoring_policy" => "object",
    "seed" => "integer",
    "seed_manifest" => "object",
    "selected_count" => "integer",
    "snapshot_id" => "string",
    "source" => "object",
    "source_artifact_id" => "string",
    "source_artifact_type" => "string",
    "source_activity_count" => "integer",
    "source_activity_id" => "string",
    "source_activity_type" => "string",
    "source_approval_status" => "string",
    "source_candidate_activities" => "array",
    "source_candidate_rejection" => "object",
    "source_candidate_rejection_report" => "object",
    "source_candidate_diff_report" => "object",
    "source_cadence_import_status_counts" => "object",
    "source_review_action_counts" => "object",
    "source_review_queue_counts" => "object",
    "source_review_type_counts" => "object",
    "source_command_window" => "object",
    "source_contact_filter_report" => "object",
    "source_contact_suppression" => "object",
    "source_contact_intents" => "array",
    "source_contention_group" => "object",
    "source_delta" => "object",
    "source_execution_report" => "object",
    "source_freshness_report" => "object",
    "source_plan_id" => "string",
    "source_policy_decision" => "object",
    "source_policy_escalation" => "object",
    "source_quality_gate_report" => "object",
    "source_invalid_contact_input" => "object",
    "source_provider_counteroffer_report" => "object",
    "source_readiness_report_id" => "string",
    "source_recommendation" => "object",
    "source_refresh_budget_report" => "object",
    "source_requirement" => "object",
    "source_resource_suppression" => "object",
    "source_resource_filter_report" => "object",
    "source_resource_projection_report" => "object",
    "source_resource_summaries" => "array",
    "source_risk" => "object",
    "source_schema_validation_report" => "object",
    "source_feedback" => "object",
    "source_locked" => "boolean",
    "source_maneuver_review" => "object",
    "source_station_calendar_review" => "object",
    "source_station_calendar_report" => "object",
    "source_status" => "string",
    "source_starts_at_s" => "number",
    "source_ends_at_s" => "number",
    "source_timeline_diff" => "object",
    "source_timeline_id" => "string",
    "source_timeline_identity" => "object",
    "source_timeline_protection" => "object",
    "source_window_lineage" => "array",
    "source_window_lineage_count" => "integer",
    "source_window_id" => "string",
    "source_window_ids" => "array",
    "source_window_type" => "string",
    "source_window" => "object",
    "spacecraft_states" => "array",
    "spacecraft_id" => "string",
    "satellite_id" => "string",
    "slew_angle_deg" => "number",
    "slew_rate_deg_s" => "number",
    "spacecraft_available" => "boolean",
    "status_blocked_contact_ids" => "array",
    "status_blocked_contact_count" => "integer",
    "starts_at_s" => "number",
    "start_delta_s" => "number",
    "timeline_id" => "string",
    "timeline_diff_count" => "integer",
    "timeline_diff_report" => "object",
    "timeline_identity" => "object",
    "timeline_integrity_issue_count" => "integer",
    "timeline_integrity_review_count" => "integer",
    "timeline_protection_count" => "integer",
    "station_id" => "string",
    "station_calendar_entry_id" => "string",
    "station_calendar_review_count" => "integer",
    "station_reservation_review_count" => "integer",
    "availability" => "string",
    "capacity_fraction" => "number",
    "capacity_fraction_max" => "number",
    "capacity_fraction_min" => "number",
    "capacity_requirement_rows" => "array",
    "contact_count" => "integer",
    "contact_ids" => "array",
    "start_s" => "number",
    "end_s" => "number",
    "station_calendar_report" => "object",
    "station_contention_status" => "string",
    "station_reservation_id" => "string",
    "station_reservation_expires_at_s" => "number",
    "station_reservation_status" => "string",
    "station_reserved_by" => "string",
    "storage_margin" => "number",
    "status" => "string",
    "status_counts" => "object",
    "contract_count" => "integer",
    "current_contract_count" => "integer",
    "deprecated_contract_count" => "integer",
    "future_contract_count" => "integer",
    "migration_row_count" => "integer",
    "deprecation_warning_count" => "integer",
    "compatible_change_rule_count" => "integer",
    "breaking_change_rule_count" => "integer",
    "required_field_count" => "integer",
    "optional_field_count" => "integer",
    "nested_contract_count" => "integer",
    "migration_action" => "string",
    "migration_action_counts" => "object",
    "replacement_contract" => "string",
    "deprecation_warning" => "string",
    "status_transition" => "object",
    "status_transition_category_counts" => "object",
    "status_transition_counts" => "object",
    "subject_id" => "string",
    "suppressed_activity_types" => "array",
    "suppressed_candidate_count" => "integer",
    "suppressed_candidates" => "array",
    "suppressed_resource_source_quality_counts" => "object",
    "suppressed_resource_trust_boundary_status_counts" => "object",
    "satisfied_count" => "integer",
    "strategy_metadata" => "object",
    "strategy_policy" => "object",
    "study_id" => "string",
    "supported_bodies" => "array",
    "position_sigma_km" => "array",
    "rng" => "string",
    "run" => "object",
    "run_id" => "string",
    "payload_metrics" => "object",
    "ground_track_crossings" => "array",
    "trajectories" => "array",
    "access_windows" => "array",
    "eclipse_intervals" => "array",
    "target_visibility_windows" => "array",
    "task_chunk_size" => "integer",
    "task_supervisor_node" => "string",
    "task_supervisor_nodes" => "array",
    "term_key" => "string",
    "temperature_c" => "number",
    "terminal_exception_count" => "integer",
    "timing_3sigma_s" => "number",
    "actual_temperature_c" => "number",
    "planned_temperature_c" => "number",
    "min_operating_temperature_c" => "number",
    "max_operating_temperature_c" => "number",
    "timeline_score" => "number",
    "time_span" => "string",
    "timeout" => "number",
    "total_delta_v_km_s" => "number",
    "tracking_count" => "integer",
    "tradeoff_count" => "integer",
    "tradeoffs" => "array",
    "transition_decision_counts" => "object",
    "approval_transition_category_counts" => "object",
    "type" => "string",
    "trust_boundary" => "string",
    "thermal_confidence" => "number",
    "thermal_margin_c" => "number",
    "thermal_model" => "string",
    "thermal_source" => "string",
    "thermal_status" => "string",
    "thermal_zone_id" => "string",
    "link_protocol" => "string",
    "frequency_band" => "string",
    "modulation" => "string",
    "coding_scheme" => "string",
    "polarization" => "string",
    "data_rate_mbps" => "number",
    "downlink_rate_mbps" => "number",
    "data_rate_mb_s" => "number",
    "downlink_rate_mb_s" => "number",
    "actual_data_rate_mbps" => "number",
    "actual_downlink_rate_mbps" => "number",
    "actual_data_rate_mb_s" => "number",
    "actual_downlink_rate_mb_s" => "number",
    "delivered_rate_mbps" => "number",
    "received_rate_mbps" => "number",
    "delivered_rate_mb_s" => "number",
    "received_rate_mb_s" => "number",
    "actual_duration_s" => "number",
    "actual_contact_duration_s" => "number",
    "contact_duration_s" => "number",
    "delivered_data_volume_mb" => "number",
    "received_data_volume_mb" => "number",
    "link_margin_db" => "number",
    "snr_db" => "number",
    "eb_no_db" => "number",
    "bit_error_rate" => "number",
    "packet_loss_rate" => "number",
    "frame_loss_rate" => "number",
    "carrier_lock" => "boolean",
    "symbol_lock" => "boolean",
    "link_quality_status" => "string",
    "unchanged_count" => "integer",
    "unmatched_selected_contact_count" => "integer",
    "unmatched_selected_contact_ids" => "array",
    "uplink_count" => "integer",
    "unused_capacity_adjusted_throughput_mb" => "number",
    "effective_contact_count" => "integer",
    "downlink_requirement_status" => "string",
    "downlink_completion_source" => "string",
    "downlink_completion_sources" => "array",
    "target_downlink_mb" => "number",
    "target_volume_mb" => "number",
    "target_data_volume_mb" => "number",
    "min_downlink_mb" => "number",
    "missing_data_volume_mb" => "number",
    "validation_records" => "array",
    "validation_level" => "string",
    "violated_constraint" => "string",
    "validation_mode" => "string",
    "valid_activity_count" => "integer",
    "valid_prior_candidate_count" => "integer",
    "valid_resource_summary_count" => "integer",
    "value" => "number",
    "validated_artifact_family" => "string",
    "validated_contract" => "string",
    "validated_schema_version" => "integer",
    "velocity_sigma_km_s" => "array",
    "warning_count" => "integer",
    "warnings" => "array",
    "withheld_review_count" => "integer",
    "window_count" => "integer",
    "window_type" => "string",
    "yaw_deg" => "number"
  }

  @contracts OrbitalDynamics.Schema.PlannedActivityRegistryContracts.contracts()
             |> Map.merge(OrbitalDynamics.Schema.ValidationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CampaignRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CandidateRefreshRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.AcceptedStateRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ValidationAcceptanceRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.ValidationPolicyRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.LintRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StudyResultRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OptimizationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelineTransitionRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.TimelinePreservationRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.TimelineActivityStateRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.TimelineDiffRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelineIntegrityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.TimelinePublicationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OperationalTimelineRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StrategyManeuverRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ExecutionReproducibilityRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.OperatorReviewRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.PlanChangeRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.TimelineFeedbackStateRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.RealizedStateRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceProjectionRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceFilterRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactFilterRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ResourceSummaryRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ModelCapabilityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.QualityGateRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.OperationalQualityGateRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.OperationalReadinessRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.CadenceImportRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ProviderCounterofferRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.StationReservationHoldRegistryContracts.contracts()
             )
             |> Map.merge(OrbitalDynamics.Schema.StationReservationRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.StationCalendarRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactContentionRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ActivityTemplateRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ProposedContactRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.ContactIntentRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.CommandWindowRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.LinkCapacityRegistryContracts.contracts())
             |> Map.merge(OrbitalDynamics.Schema.RelayDataPathRegistryContracts.contracts())
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationReportRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationSummaryRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationReservationConflictRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationStationPressureRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationCapacityPackRegistryContracts.contracts()
             )
             |> Map.merge(
               OrbitalDynamics.Schema.ContactAllocationProviderReservationRegistryContracts.contracts()
             )

  @doc """
  Returns the known executable artifact contracts.
  """
  def contracts, do: OrbitalDynamics.Schema.Registry.all(@contracts)

  @doc """
  Returns public capability metadata for the executable artifact registry.
  """
  def capabilities do
    OrbitalDynamics.Schema.RegistryCapability.build(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      json_schema_draft: @json_schema_draft,
      compatibility_policy: compatibility_policy(),
      identity_policy: identity_policy(),
      validation_report_contracts: [
        @schema_validation_report,
        @schema_validation_batch_report,
        @schema_migration_report
      ]
    )
  end

  @doc """
  Returns the schema export compatibility policy.

  The current JSON Schema documents are top-level compatibility exports. Nested
  and semantic checks remain in the executable Elixir validators, so published
  contract compatibility is evaluated against required fields, their coarse
  exported types, and schema contract/version identifiers.
  """
  def compatibility_policy, do: OrbitalDynamics.Schema.ExportPolicy.compatibility_policy()

  @doc """
  Returns the stable identity policy for public artifact IDs.
  """
  def identity_policy, do: OrbitalDynamics.Schema.ExportPolicy.identity_policy(@stable_id_pattern)

  @doc """
  Returns one known contract by name.
  """
  def contract(name) when is_binary(name),
    do: OrbitalDynamics.Schema.Registry.fetch(@contracts, name)

  @doc """
  Exports one executable contract as a machine-readable JSON Schema document.

  The generated schema is intentionally a top-level compatibility contract. The
  Elixir validators remain the source of truth for nested rows and semantic
  checks while artifact shapes are still maturing.
  """
  def json_schema(@candidate_activity) do
    {:ok,
     OrbitalDynamics.Schema.JsonDocument.candidate_activity(
       candidate_activity_json_schema(),
       @candidate_activity,
       json_schema_draft: @json_schema_draft,
       compatibility_policy: compatibility_policy(),
       identity_policy: identity_policy()
     )}
  end

  def json_schema(name) when is_binary(name) do
    with {:ok, contract} <- contract(name) do
      {:ok, json_schema_document(name, contract)}
    end
  end

  @doc """
  Exports all executable contracts as a deterministic registry bundle.
  """
  def json_schema_bundle do
    OrbitalDynamics.Schema.JsonExport.bundle(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      [
        json_schema_draft: @json_schema_draft,
        compatibility_policy: compatibility_policy(),
        identity_policy: identity_policy()
      ],
      &json_schema/1
    )
  end

  @doc """
  Writes one exported JSON Schema document to disk.
  """
  def write_json_schema!(name, path) when is_binary(name) and is_binary(path) do
    OrbitalDynamics.Schema.JsonExport.write_schema!(name, path, &json_schema/1)
  end

  @doc """
  Writes the exported JSON Schema registry bundle to disk.
  """
  def write_json_schema_bundle!(path) when is_binary(path) do
    OrbitalDynamics.Schema.JsonExport.write_bundle!(json_schema_bundle(), path)
  end

  @doc """
  Writes every exported contract schema to a directory.
  """
  def write_json_schema_files!(directory) when is_binary(directory) do
    OrbitalDynamics.Schema.JsonExport.write_files!(
      OrbitalDynamics.Schema.Registry.all(@contracts),
      directory,
      &json_schema/1
    )
  end

  @doc """
  Declares the model limits for schema validation reports.
  """
  def schema_validation_model_limits, do: OrbitalDynamics.Schema.RegistryCapability.model_limits()

  @doc """
  Validates an artifact map against the inferred or requested contract.

  Returns `{:ok, report}` when the artifact satisfies the contract and
  `{:error, report}` otherwise. Reports are JSON-serializable maps.
  """
  def validate_artifact(%{} = artifact, opts \\ []) do
    OrbitalDynamics.Schema.ArtifactValidation.validate(artifact, opts, contracts(),
      contract: &contract/1,
      error: &error/2,
      validate_contract: &validate_contract/3
    )
  end

  @doc """
  Wraps artifact validation in a `schema_validation_report.v1` artifact.
  """
  def validation_report(%{} = artifact, opts \\ []) do
    OrbitalDynamics.Schema.Report.validation_report_for_artifact(
      artifact,
      opts,
      &validate_artifact/2,
      schema_contract: @schema_validation_report,
      model_limits: schema_validation_model_limits()
    )
  end

  @doc """
  Validates a JSON artifact file.

  If the file is a study result artifact with an embedded `campaign_plan`, the
  nested campaign artifact is validated by default.
  """
  def lint_file(path, opts \\ []) when is_binary(path) do
    OrbitalDynamics.Schema.FileLint.lint_file(path, opts, &validate_artifact/2)
  end

  @doc """
  Validates a JSON artifact file and returns `schema_validation_report.v1`.
  """
  def lint_file_report(path, opts \\ []) when is_binary(path) do
    OrbitalDynamics.Schema.FileLint.lint_file_report(path, opts, &validation_report/2)
  end

  defp json_schema_document(name, contract) do
    attrs = [
      json_schema_draft: @json_schema_draft,
      compatibility_policy: compatibility_policy(),
      identity_policy: identity_policy(),
      contract_fun: &contract/1,
      property_fun: &json_schema_property/3,
      stable_id_pattern: @stable_id_pattern,
      constraint_report_model_limits_by_model_fun:
        &OrbitalDynamics.Schema.ConstraintReportContracts.model_limits_by_model/0,
      validation_record_registry_conditions_fun: &validation_record_registry_conditions/0,
      accepted_planning_state: @accepted_planning_state,
      constraint_report: @constraint_report,
      environment_model_capability: @environment_model_capability,
      environment_provider_capability: @environment_provider_capability,
      maneuver_execution_delta: @maneuver_execution_delta,
      planned_activity: @planned_activity,
      realized_activity: @realized_activity,
      spacecraft_state_estimate: @spacecraft_state_estimate,
      station_calendar_provider: @station_calendar_provider,
      subsystem_model_capability: @subsystem_model_capability,
      validation_record: @validation_record
    ]

    OrbitalDynamics.Schema.JsonDocument.build_from_attrs(name, contract, attrs)
  end

  defp registry_contract!(name), do: OrbitalDynamics.Schema.Registry.fetch!(@contracts, name)

  defp timeline_preservation_assumptions_json_schema(@timeline_preservation_report) do
    OrbitalDynamics.Schema.CommonJsonSchema.string_const_assumptions(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "lifecycle_lock_approval_and_executed_preservation_review"
    })
  end

  defp timeline_preservation_assumptions_json_schema(@timeline_preservation_status) do
    OrbitalDynamics.Schema.CommonJsonSchema.string_const_assumptions(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "single_activity_lifecycle_preservation_preflight"
    })
  end

  defp json_schema_property(field, @activity_template = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.activity_template(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {@activity_template, @stable_id_pattern}
    )
  end

  defp json_schema_property(field, @policy_bundle = contract_name, contract) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.bundle(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {&policy_action_rule_json_schema/0, &policy_model_limits/0}
    )
  end

  defp json_schema_property(field, @policy_decision = contract_name, contract) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.decision(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &policy_decision_rule_match_json_schema/0,
        &policy_escalation_json_schema/0,
        &policy_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @capability_catalog = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.capability_catalog(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @accepted_planning_state = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.accepted_state(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {&spacecraft_state_estimate_json_schema/0, &maneuver_execution_delta_json_schema/0}
    )
  end

  defp json_schema_property(field, @manifest_field_reference = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.manifest_field_reference(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @candidate_diff_report = contract_name, contract) do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.diff_report(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      {
        fn -> source_window_lineage_json_schema() end,
        fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
        fn -> candidate_diff_row_json_schema() end,
        fn -> invalidated_candidate_json_schema() end
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@candidate_diff_row, @invalidated_candidate, @source_window_lineage] do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.diff_family(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      fn -> candidate_refresh_scoped_context_json_schema_properties() end
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @freshness_report,
              @refresh_budget_report,
              @refreshed_window,
              @remaining_horizon
            ] do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.auxiliary(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      fn -> OrbitalDynamics.CandidateRefresh.model_limits() end
    )
  end

  defp json_schema_property(field, @campaign_plan = contract_name, contract) do
    OrbitalDynamics.Schema.CampaignArtifactPropertyDispatch.campaign_plan(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &proposed_contact_row_json_schema/0,
        &campaign_activity_json_schema/0,
        &contact_intent_row_json_schema/0,
        &ranked_timeline_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @campaign_repair = contract_name, contract) do
    timeline_transition_contract = registry_contract!(@timeline_transition_application_report)

    OrbitalDynamics.Schema.CampaignArtifactPropertyDispatch.campaign_repair(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      timeline_transition_contract,
      fn transition_field ->
        json_schema_property(
          transition_field,
          @timeline_transition_application_report,
          timeline_transition_contract
        )
      end,
      {
        &planned_activity_json_schema/0,
        &candidate_activity_json_schema/0,
        &plan_delta_json_schema/0,
        &approval_requirement_json_schema/0,
        &policy_action_rule_json_schema/0,
        &policy_decision_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @realized_state_snapshot = contract_name, contract) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.realized_state_snapshot(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &realized_activity_json_schema/0,
        &realized_spacecraft_state_json_schema/0,
        &realized_state_snapshot_metadata_json_schema/0,
        &OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @timeline_feedback_report = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.feedback(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &timeline_feedback_row_json_schema/0,
        &timeline_feedback_report_model_limits/0,
        &timeline_feedback_capabilities/0,
        &operational_feedback_json_schema/0,
        &timeline_feedback_operational_feedback_provenance_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @timeline_integrity_report = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.integrity(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @timeline_integrity_report,
      @stable_id_pattern,
      {
        &operational_timeline_row_json_schema/0,
        &timeline_integrity_issue_types/0,
        &stable_id_array_schema/0,
        &stable_id_array_map_schema/0,
        &timeline_report_model_limits/0
      }
    )
  end

  defp json_schema_property(
         field,
         @timeline_dependency_impact_summary = contract_name,
         contract
       ) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.dependency_impact(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @timeline_dependency_impact_summary,
      {
        &stable_id_array_schema/0,
        &timeline_dependency_impact_row_json_schema/0,
        &timeline_report_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @timeline_publication_summary = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.publication(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @timeline_publication_summary,
      @stable_id_pattern,
      {
        &timeline_diff_summary_source_json_schema/0,
        &timeline_dependency_impact_summary_source_json_schema/0,
        &stable_id_array_schema/0,
        &stable_id_array_map_schema/0,
        &timeline_report_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @timeline_activity_state = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.state(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @timeline_activity_state,
      @stable_id_pattern,
      {
        &timeline_feedback_row_json_schema/0,
        &timeline_feedback_capabilities/0,
        &stable_id_array_schema/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        &timeline_identity_json_schema/0,
        &activity_context_json_schema/0,
        &TimelineContextJsonSchema.lifecycle_transition/0,
        &protection_decision_json_schema/0,
        fn ->
          OrbitalDynamics.Schema.CommonJsonSchema.boolean_const_assumptions([
            "artifact_only",
            "no_schedule_mutation",
            "no_command_execution"
          ])
        end,
        &timeline_feedback_report_model_limits/0
      }
    )
  end

  defp json_schema_property(
         field,
         @timeline_activity_precondition_summary = contract_name,
         contract
       ) do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.precondition(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @timeline_activity_precondition_summary,
      @stable_id_pattern,
      {
        &timeline_report_model_limits/0,
        &timeline_activity_precondition_statuses/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        &timeline_precondition_json_schema/0,
        &stable_id_array_schema/0,
        &timeline_identity_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @execution_report = contract_name, contract) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.execution_report(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @execution_report,
        @stable_id_pattern,
        &OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @result_artifact = contract_name, contract) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.result_artifact(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {1, @stable_id_pattern, @execution_report, &embedded_contract_json_schema/1}
    )
  end

  defp json_schema_property(field, @resource_summary = contract_name, contract) do
    OrbitalDynamics.Schema.ResultArtifactPropertyDispatch.resource_summary(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {@resource_summary, @stable_id_pattern}
    )
  end

  defp json_schema_property(field, @contact_intent = contract_name, contract) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.intent(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &approval_requirement_json_schema/0,
        &policy_decision_rule_match_json_schema/0,
        &policy_decision_json_schema/0,
        &contact_intent_model_limits/0,
        &timeline_integrity_issue_types/0
      }
    )
  end

  defp json_schema_property(field, @contact_intent_summary = contract_name, contract) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.summary(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @contact_intent_summary,
        @stable_id_pattern,
        &contact_intent_model_limits/0,
        &contact_intent_summary_assumptions_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @approval_requirement = contract_name, contract) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.approval_requirement(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @stable_id_pattern,
        &policy_decision_rule_match_json_schema/0,
        &activity_context_json_schema/0,
        &policy_escalation_json_schema/0
      }
    )
  end

  defp json_schema_property(
         field,
         contract_name,
         contract
       )
       when contract_name in [
              @validation_reference_fixture_report,
              @validation_reference_report,
              @validation_record,
              @validation_check
            ] do
    OrbitalDynamics.Schema.ValidationEvidencePropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        reference_fixture_report: @validation_reference_fixture_report,
        reference_report: @validation_reference_report,
        record: @validation_record,
        check: @validation_check
      },
      reference_report_schema: &validation_reference_report_json_schema/0,
      stable_id_pattern: @stable_id_pattern,
      validation_check_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.check/0,
      validation_level_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.validation_level/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @model_acceptance_report,
              @validation_safety_case_summary
            ] do
    OrbitalDynamics.Schema.ValidationAssessmentPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        model_acceptance_report: @model_acceptance_report,
        validation_safety_case_summary: @validation_safety_case_summary
      },
      model_limits: &model_acceptance_report_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      validation_record_schema: &validation_record_json_schema/0,
      model_acceptance_row_schema: &model_acceptance_row_json_schema/0,
      safety_case_evidence_row_schema: &safety_case_evidence_row_json_schema/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @schema_validation_report,
              @schema_validation_batch_report
            ] do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: @schema_validation_report,
        batch: @schema_validation_batch_report
      },
      issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      remediation_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.remediation/0,
      model_limits: &schema_validation_model_limits/0,
      batch_entry_schema: &schema_validation_batch_entry_json_schema/0,
      skipped_artifact_schema:
        &OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.skipped_artifact/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @schema_migration_report = contract_name, contract) do
    OrbitalDynamics.Schema.SchemaValidationPropertyDispatch.migration(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @schema_migration_report,
        1,
        &schema_migration_statuses/0,
        &schema_migration_row_statuses/0,
        &OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.row/0,
        &OrbitalDynamics.Schema.SchemaMigrationContracts.model_limits/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @campaign_request_lint,
              @study_manifest_lint
            ] do
    OrbitalDynamics.Schema.LintReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        campaign_request: @campaign_request_lint,
        study_manifest: @study_manifest_lint
      },
      validation_issue_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.issue/0,
      sha256_schema: &sha256_json_schema/0,
      stable_id_pattern: @stable_id_pattern,
      manifest_lint_issue_schema:
        &OrbitalDynamics.Schema.ValidationJsonSchema.manifest_lint_issue/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @strategy_branch = contract_name, contract) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.branch(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @stable_id_pattern,
        &strategy_branch_event_json_schema/0,
        fn ->
          OrbitalDynamics.Schema.StrategyBranchJsonSchema.risk(
            @stable_id_pattern,
            scoped_downlink_context_json_schema_properties()
          )
        end,
        &approval_requirement_json_schema/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
        &policy_decision_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @optimizer_contract = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.optimizer_contract(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {@optimizer_contract, @stable_id_pattern}
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @environment_model_capability,
              @environment_provider_capability,
              @subsystem_model_capability
            ] do
    OrbitalDynamics.Schema.ModelCapabilityPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        environment_model: @environment_model_capability,
        environment_provider: @environment_provider_capability,
        subsystem_model: @subsystem_model_capability
      },
      stable_id_pattern: @stable_id_pattern,
      validation_level_schema: &OrbitalDynamics.Schema.ValidationJsonSchema.validation_level/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @monte_carlo_reproducibility_report = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.monte_carlo(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @monte_carlo_reproducibility_report,
        @stable_id_pattern,
        &OrbitalDynamics.Schema.MonteCarloReproducibilityContracts.model_limits/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0
      }
    )
  end

  defp json_schema_property(field, @strategy_recommendation = contract_name, contract) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.recommendation(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @strategy_recommendation,
        @stable_id_pattern,
        &strategy_branch_tradeoff_json_schema/0,
        &strategy_explanation_json_schema/0,
        &strategy_branch_risk_json_schema/0,
        &approval_requirement_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @realized_activity, contract) do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.RealizedActivityJsonSchema.property_fun_from_context(
          stable_id_pattern: @stable_id_pattern,
          numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
          ground_station_schema: fn -> ground_station_identity_json_schema() end,
          spacecraft_schema: fn -> spacecraft_identity_json_schema() end,
          target_schema: fn -> target_identity_json_schema() end
        ),
      execution_uncertainty_schema: &execution_uncertainty_json_schema/0,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        default_json_schema_property(field, @realized_activity, contract)
      end
    )
  end

  defp json_schema_property(field, @maneuver_recommendation = contract_name, contract) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.recommendation(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @maneuver_recommendation,
        @stable_id_pattern,
        &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
        &maneuver_recommendation_model_limits/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @provider_counteroffer_report,
              @provider_counteroffer_review_summary,
              @provider_counteroffer_import_readiness_summary,
              @provider_counteroffer_plan_impact_summary
            ] do
    OrbitalDynamics.Schema.ProviderCounterofferPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: @provider_counteroffer_report,
        review_summary: @provider_counteroffer_review_summary,
        import_readiness_summary: @provider_counteroffer_import_readiness_summary,
        plan_impact_summary: @provider_counteroffer_plan_impact_summary
      },
      row_schema: &provider_counteroffer_row_json_schema/0,
      models: &OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema.models/0,
      stable_id_pattern: @stable_id_pattern,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @candidate_rejection_report = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.candidate_rejection(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.model_limits/0,
        &candidate_rejection_row_json_schema/0,
        &timeline_candidate_rejection_reasons/0,
        &timeline_candidate_rejection_actions/0,
        @stable_id_pattern
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @operational_timeline_report,
              @timeline_diff_report,
              @timeline_diff_summary
            ] do
    OrbitalDynamics.Schema.TimelineReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        operational_timeline_report: @operational_timeline_report,
        timeline_diff_report: @timeline_diff_report,
        timeline_diff_summary: @timeline_diff_summary
      },
      model_limits: &timeline_report_model_limits/0,
      operational_timeline_row_schema: &operational_timeline_row_json_schema/0,
      timeline_diff_row_schema: &timeline_diff_row_json_schema/0,
      stable_id_pattern: @stable_id_pattern,
      capability: &timeline_capabilities/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @timeline_activity_status_state,
              @timeline_activity_approval_state,
              @timeline_activity_lifecycle_state
            ] do
    OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch.lifecycle(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      {
        &timeline_report_model_limits/0,
        &timeline_transition_decisions/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        &TimelineContextJsonSchema.lifecycle_transition/0,
        &protection_decision_json_schema/0,
        &activity_context_json_schema/0,
        &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.lifecycle_assumptions/0,
        &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.default_assumptions/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@timeline_preservation_report, @timeline_preservation_status] do
    OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch.preservation(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      timeline_report_model_limits(),
      {
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
        &stable_id_array_schema/0,
        &stable_id_array_map_schema/0,
        &protection_decision_json_schema/0,
        &timeline_identity_json_schema/0,
        &timeline_preservation_assumptions_json_schema/1
      }
    )
  end

  defp json_schema_property(field, @timeline_lifecycle_state_summary = contract_name, contract) do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.lifecycle_summary(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &timeline_lifecycle_state_row_json_schema/0,
        &timeline_report_model_limits/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
        &stable_id_array_schema/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @timeline_transition_application_report,
              @timeline_transition_application_summary
            ] do
    OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch.application(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &timeline_transition_application_row_json_schema/0,
        &timeline_transition_selected_activity_json_schema/0,
        &timeline_report_model_limits/0,
        &timeline_capabilities/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
        &stable_id_array_schema/0,
        &stable_id_array_map_schema/0
      }
    )
  end

  defp json_schema_property(field, @command_window_report = contract_name, contract) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.command_window(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {&command_window_report_model_limits/0, &command_window_row_json_schema/0}
    )
  end

  defp json_schema_property(field, @station_calendar_precedence_summary = contract_name, contract) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar_precedence(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      &station_calendar_report_model_limits/0
    )
  end

  defp json_schema_property(field, @station_reservation_report = contract_name, contract) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.reservation(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      @stable_id_pattern,
      {
        &OrbitalDynamics.Schema.StationReservationReportJsonSchema.models/0,
        &station_reservation_contact_json_schema/0,
        &station_reservation_provider_contention_group_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @station_calendar_report = contract_name, contract) do
    OrbitalDynamics.Schema.GroundNetworkReportPropertyDispatch.calendar(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &station_calendar_contact_json_schema/0,
        &station_calendar_report_model/0,
        &station_calendar_provider_contention_group_json_schema/0,
        &station_calendar_provider_entry_json_schema/0,
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
        &station_calendar_report_model_limits/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @station_reservation_review_summary,
              @station_reservation_hold_summary,
              @station_reservation_hold_import_readiness_summary
            ] do
    OrbitalDynamics.Schema.StationReservationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        review_summary: @station_reservation_review_summary,
        hold_summary: @station_reservation_hold_summary,
        hold_import_readiness_summary: @station_reservation_hold_import_readiness_summary
      },
      review_row_schema: &station_reservation_review_summary_row_json_schema/0,
      import_readiness_row_schema: &station_reservation_hold_import_readiness_row_json_schema/0,
      model_limits: &station_calendar_report_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @station_calendar_provider = contract_name, contract) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.station_calendar_provider(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      station_calendar_provider_entry_json_schema()
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@link_capacity_report, @link_capacity_summary] do
    OrbitalDynamics.Schema.LinkCapacityPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: @link_capacity_report,
        summary: @link_capacity_summary
      },
      row_schema: &link_capacity_row_json_schema/0,
      model_limits: &OrbitalDynamics.Schema.LinkCapacitySummaryContracts.model_limits/0,
      report_assumptions_schema: fn -> link_capacity_assumptions_json_schema([]) end,
      summary_assumptions_schema: fn ->
        link_capacity_assumptions_json_schema([
          "execution_boundary",
          "source",
          "operator_authority"
        ])
      end,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @relay_data_path_summary = contract_name, contract) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.relay_data_path(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &OrbitalDynamics.Schema.RelayDataPathSummaryContracts.model_limits/0,
        &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.assumptions/0,
        &relay_data_path_row_json_schema/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
        &stable_id_array_schema/0,
        &stable_id_array_map_schema/0
      }
    )
  end

  defp json_schema_property(field, @contact_allocation_report = contract_name, contract) do
    OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch.contact_allocation(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &contact_allocation_row_json_schema/0,
        &contact_allocation_capacity_pack_group_json_schema/0,
        &contact_allocation_model_limits/0,
        &stable_id_array_schema/0,
        &nested_stable_id_array_map_json_schema/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
        &contact_allocation_capabilities/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1,
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @contact_allocation_summary,
              @contact_allocation_reservation_conflict_summary,
              @contact_allocation_station_pressure_summary,
              @contact_allocation_capacity_pack_summary,
              @contact_allocation_provider_reservation_request_summary
            ] do
    OrbitalDynamics.Schema.ContactAllocationSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        summary: @contact_allocation_summary,
        reservation_conflict_summary: @contact_allocation_reservation_conflict_summary,
        station_pressure_summary: @contact_allocation_station_pressure_summary,
        capacity_pack_summary: @contact_allocation_capacity_pack_summary,
        provider_reservation_request_summary:
          @contact_allocation_provider_reservation_request_summary
      },
      assumptions: %{
        summary: &contact_allocation_summary_assumptions_json_schema/0,
        reservation_conflict_summary:
          &contact_allocation_reservation_conflict_summary_assumptions_json_schema/0,
        station_pressure_summary:
          &contact_allocation_station_pressure_summary_assumptions_json_schema/0,
        capacity_pack_summary:
          &contact_allocation_capacity_pack_summary_assumptions_json_schema/0,
        provider_reservation_request_summary:
          &contact_allocation_provider_reservation_request_summary_assumptions_json_schema/0
      },
      stable_id_pattern: @stable_id_pattern,
      model_limits: &contact_allocation_model_limits/0,
      row_schema: &contact_allocation_row_json_schema/0,
      capacity_pack_group_schema: &contact_allocation_capacity_pack_group_json_schema/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@contact_filter_report, @resource_filter_report] do
    OrbitalDynamics.Schema.FilterReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        contact: @contact_filter_report,
        resource: @resource_filter_report
      },
      stable_id_pattern: @stable_id_pattern,
      trust_boundary_count_map_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      contact_model_limits: &contact_filter_report_model_limits/0,
      contact_assumptions_schema: &contact_filter_report_assumptions_json_schema/0,
      resource_model_limits: &resource_filter_report_model_limits/0,
      resource_assumptions_schema: &resource_filter_report_assumptions_json_schema/0,
      suppressed_candidate_schema: &suppressed_candidate_json_schema/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @resource_projection_report,
              @resource_projection_flow_summary
            ] do
    OrbitalDynamics.Schema.ResourceProjectionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      contracts: %{
        report: @resource_projection_report,
        flow_summary: @resource_projection_flow_summary
      },
      stable_id_pattern: @stable_id_pattern,
      models: &ResourceValidation.resource_projection_report_models/0,
      model_limits: &ResourceValidation.resource_projection_report_model_limits/0,
      assumptions_schema:
        &OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.assumptions/0,
      projection_row_schema: &resource_projection_row_json_schema/0,
      flow_row_schema: &resource_projection_flow_row_json_schema/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @contact_contention_report,
              @contact_contention_resolution_report,
              @contact_contention_resolution_summary
            ] do
    OrbitalDynamics.Schema.ContactContentionPropertyDispatch.property(
      field,
      contract_name,
      contract,
      stable_id_pattern: @stable_id_pattern,
      model_limits: contact_contention_report_model_limits(),
      report_assumptions_schema: contact_contention_report_assumptions_json_schema(),
      conflict_group_schema: contact_contention_group_json_schema(),
      recommendation_schema: contact_contention_recommendation_json_schema(),
      resolution_policy_schema: contact_contention_resolution_policy_json_schema(),
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @objective_satisfaction_report,
              @objective_tradeoff_report
            ] do
    OrbitalDynamics.Schema.ObjectiveReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      satisfaction_row_schema: objective_satisfaction_row_json_schema(),
      satisfaction_model_limits:
        OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits(),
      tradeoff_row_schema: objective_tradeoff_row_json_schema(),
      tradeoff_models:
        OrbitalDynamics.Schema.OptimizerObjectiveContracts.objective_tradeoff_report_models(),
      score_report_model_limits: OrbitalDynamics.CampaignPlanner.score_report_model_limits(),
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @ranking_comparison_report,
              @pareto_frontier_report
            ] do
    OrbitalDynamics.Schema.OptimizerReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      ranking_row_schema: &ranking_comparison_row_json_schema/0,
      ranking_winner_schema: &ranking_comparison_winner_json_schema/0,
      ranking_model_limits: fn ->
        OrbitalDynamics.Optimizer.ranking_comparison_model_limits()
      end,
      pareto_row_schema: &pareto_frontier_row_json_schema/0,
      pareto_model_limits: fn -> OrbitalDynamics.Optimizer.pareto_frontier_model_limits() end,
      stable_id_pattern: @stable_id_pattern,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @score_term_report = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.score_term(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        OrbitalDynamics.Schema.OptimizerObjectiveContracts.score_term_report_models(),
        OrbitalDynamics.CampaignPlanner.score_report_model_limits(),
        score_term_row_json_schema()
      }
    )
  end

  defp json_schema_property(field, @resource_filter_summary = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.resource_filter_summary(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        @resource_filter_summary,
        @resource_filter_report,
        @stable_id_pattern,
        fn -> resource_filter_report_model_limits() end,
        %{"type" => "object"},
        fn -> suppressed_candidate_json_schema() end
      }
    )
  end

  defp json_schema_property(field, @constraint_report = contract_name, contract) do
    OrbitalDynamics.Schema.PlanningAnalysisPropertyDispatch.constraint(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        OrbitalDynamics.Schema.ConstraintReportContracts.models(),
        OrbitalDynamics.Schema.ConstraintReportContracts.model_limit_values(),
        constraint_row_json_schema()
      }
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @operational_import_eligibility_summary,
              @operational_readiness_gate_summary,
              @operational_execution_boundary_summary
            ] do
    OrbitalDynamics.Schema.OperationalReadinessGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: &operational_readiness_capabilities/0,
      gate_schema: &operational_readiness_gate_json_schema/0,
      import_eligibility_model_limits:
        &OperationalReadinessValidation.operational_import_eligibility_summary_model_limits/0,
      readiness_gate_model_limits:
        &OperationalReadinessValidation.operational_readiness_gate_summary_model_limits/0,
      execution_boundary_model_limits:
        &OperationalReadinessValidation.operational_execution_boundary_summary_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@operational_quality_gate_summary, @quality_gate_report] do
    OrbitalDynamics.Schema.QualityGateReportPropertyDispatch.property(
      field,
      contract_name,
      contract,
      capability: &operational_readiness_capabilities/0,
      operational_summary_model_limits:
        &OperationalReadinessValidation.quality_gate_summary_model_limits/0,
      report_model_limits: &OperationalReadinessValidation.quality_gate_report_model_limits/0,
      row_schema: &quality_gate_report_row_json_schema/0,
      stable_id_pattern: @stable_id_pattern,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @operational_quality_gate_unavailable_resource_summary,
              @operational_quality_gate_operator_training_summary,
              @operational_quality_gate_schema_validation_summary,
              @operational_quality_gate_import_readiness_summary
            ] do
    OrbitalDynamics.Schema.SpecializedQualityGateSummaryPropertyDispatch.property(
      field,
      contract_name,
      contract,
      unavailable_resource_model_limits:
        &OperationalReadinessValidation.quality_gate_unavailable_resource_summary_model_limits/0,
      operator_training_model_limits:
        &OperationalReadinessValidation.quality_gate_operator_training_summary_model_limits/0,
      schema_validation_model_limits:
        &OperationalReadinessValidation.quality_gate_schema_validation_summary_model_limits/0,
      import_readiness_model_limits:
        &OperationalReadinessValidation.quality_gate_import_readiness_summary_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      default_property: &default_json_schema_property/3
    )
  end

  defp json_schema_property(field, @operational_readiness_report = contract_name, contract) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.readiness(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        operational_readiness_capabilities(),
        operational_readiness_gate_json_schema(),
        operational_readiness_evidence_json_schema(),
        OperationalReadinessValidation.operational_readiness_model_limits()
      }
    )
  end

  defp json_schema_property(field, @operator_review_package = contract_name, contract) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.operator_review(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        operator_review_capabilities(),
        operator_review_package_model_limits(),
        operational_readiness_capabilities(),
        operator_review_row_json_schema(),
        OrbitalDynamics.Schema.OperatorReviewPackageContracts.scalar_count_fields(),
        @stable_id_pattern
      }
    )
  end

  defp json_schema_property(field, @cadence_import_manifest = contract_name, contract) do
    OrbitalDynamics.Schema.OperationalHandoffPropertyDispatch.cadence_import(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        cadence_import_capability(),
        cadence_import_manifest_model_limits(),
        operational_readiness_capabilities(),
        cadence_import_manifest_row_json_schema(),
        @cadence_import_manifest_scalar_count_fields,
        @stable_id_pattern
      }
    )
  end

  defp json_schema_property(field, @maneuver_review_report = contract_name, contract) do
    OrbitalDynamics.Schema.ManeuverArtifactPropertyDispatch.review(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &maneuver_review_row_json_schema/0,
        @stable_id_pattern,
        &maneuver_review_report_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @branch_comparison_report = contract_name, contract) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.branch_comparison(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &branch_comparison_row_json_schema/0,
        &OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits/0
      }
    )
  end

  defp json_schema_property(field, @campaign_strategy = contract_name, contract) do
    OrbitalDynamics.Schema.StrategyArtifactPropertyDispatch.campaign_strategy(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &strategy_branch_json_schema/0,
        &strategy_recommendation_json_schema/0,
        &operational_feedback_json_schema/0,
        &policy_action_rule_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @planned_activity, contract) do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.PlannedActivityJsonSchema.property_fun_from_context(
          cadence_import_schema: cadence_import_json_schema("planned_activity.v1"),
          source_window_schema: candidate_activity_source_window_json_schema(),
          stable_id_pattern: @stable_id_pattern,
          timeline_identity_schema: timeline_identity_json_schema()
        ),
      execution_uncertainty_schema: &execution_uncertainty_json_schema/0,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        default_json_schema_property(field, @planned_activity, contract)
      end
    )
  end

  defp json_schema_property(field, @plan_delta, contract) do
    OrbitalDynamics.Schema.PlanDeltaJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.PlanDeltaJsonSchema.property_fun_from_context(
          activity_context_schema: activity_context_json_schema(),
          planned_activity_schema: planned_activity_json_schema(),
          realized_activity_schema: realized_activity_json_schema()
        ),
      execution_uncertainty_schema: &execution_uncertainty_json_schema/0,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      default_property: fn field, contract ->
        default_json_schema_property(field, @plan_delta, contract)
      end
    )
  end

  defp json_schema_property("lighting_confidence", _name, _contract) do
    OrbitalDynamics.Schema.CommonJsonSchema.number_or_string()
  end

  defp json_schema_property(field, @proposed_contact = contract_name, contract) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.proposed_contact(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        fn -> cadence_import_json_schema("proposed_contact.v1") end,
        &OrbitalDynamics.Schema.ProposedContactContracts.model_limits/0,
        &candidate_activity_source_window_json_schema/0,
        &timeline_identity_json_schema/0
      }
    )
  end

  defp json_schema_property(field, @candidate_refresh = contract_name, contract) do
    OrbitalDynamics.Schema.CandidateRefreshPropertyDispatch.candidate_refresh(
      field,
      contract_name,
      contract,
      &default_json_schema_property/3,
      {
        &source_window_lineage_json_schema/0,
        &invalidated_candidate_json_schema/0,
        &candidate_activity_json_schema/0,
        &contact_intent_row_json_schema/0,
        &resource_summary_row_json_schema/0,
        &validation_record_json_schema/0,
        fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
        @stable_id_pattern,
        &operational_feedback_json_schema/0,
        &station_calendar_provider_counteroffer_actions/0,
        &OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.safety_case_count_fields/0,
        &embedded_contract_json_schema/1
      }
    )
  end

  defp json_schema_property(field, name, contract) do
    default_json_schema_property(field, name, contract)
  end

  defp default_json_schema_property(field, name, contract) do
    OrbitalDynamics.Schema.FallbackPropertyJsonSchema.property(field, name, contract,
      field_type_hints: @field_type_hints,
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp embedded_contract_json_schema(contract_name) do
    OrbitalDynamics.Schema.EmbeddedContractJsonSchema.build(contract_name,
      contract: &registry_contract!/1,
      property: &json_schema_property/3
    )
  end

  defp relay_data_path_row_json_schema do
    OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      custody_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.custody_statuses/0,
      latency_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.latency_statuses/0,
      risk_statuses: &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.risk_statuses/0
    )
  end

  defp policy_decision_json_schema do
    @policy_decision
    |> json_schema_document(registry_contract!(@policy_decision))
    |> Map.take(["type", "additionalProperties", "required", "properties"])
  end

  defp policy_decision_evidence_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionJsonSchema.evidence(
      stable_id_pattern: @stable_id_pattern,
      policy_escalation_schema: policy_escalation_json_schema()
    )
  end

  defp source_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.source_evidence(source_evidence_schema_deps())
  end

  defp operational_readiness_source_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.operational_readiness_source_report(
      source_evidence_schema_deps()
    )
  end

  defp quality_gate_source_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.quality_gate_source_report(
      quality_gate_source_report_schema_deps()
    )
  end

  defp source_freshness_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.freshness_report(
      source_evidence_schema_deps(),
      SourceEvidenceValidation.freshness_statuses()
    )
  end

  defp source_schema_validation_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.schema_validation_report(
      source_evidence_schema_deps(),
      SourceEvidenceValidation.schema_validation_statuses()
    )
  end

  defp source_execution_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.execution_report(
      source_evidence_schema_deps(),
      OrbitalDynamics.Schema.ExecutionReportContracts.statuses()
    )
  end

  defp source_evidence_schema_deps do
    %{
      stable_id_pattern: @stable_id_pattern,
      battery_handoff_properties: resource_projection_battery_handoff_json_schema_properties()
    }
  end

  defp quality_gate_source_report_schema_deps do
    source_evidence_schema_deps()
    |> Map.merge(%{
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      stable_id_array_map_schema: stable_id_array_map_schema()
    })
  end

  defp policy_action_rule_json_schema do
    action_rule_fields = OrbitalDynamics.Schema.PolicyFieldGroups.action_rule()

    OrbitalDynamics.Schema.PolicyActionRuleJsonSchema.action_rule(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema(),
      number_fields: Keyword.fetch!(action_rule_fields, :number_fields),
      integer_fields: Keyword.fetch!(action_rule_fields, :integer_fields)
    )
  end

  defp policy_decision_rule_match_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.rule_match_from_context(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: OrbitalDynamics.Schema.PolicyFieldGroups.json_schema()
    )
  end

  defp policy_escalation_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.escalation_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp scoped_downlink_context_json_schema_properties do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.scoped_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp candidate_refresh_scoped_context_json_schema_properties do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.candidate_refresh_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp branch_scoped_downlink_context_json_schema_properties do
    OrbitalDynamics.Schema.ScopedDownlinkContextJsonSchema.branch_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp branch_comparison_row_json_schema do
    OrbitalDynamics.Schema.BranchComparisonRowJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      branch_event_trust_boundary_status_counts_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      non_negative_integer_properties: fn ->
        OrbitalDynamics.Schema.BranchComparisonReportContracts.row_count_fields()
        |> OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_properties()
      end,
      branch_scoped_downlink_context_properties:
        &branch_scoped_downlink_context_json_schema_properties/0
    )
  end

  defp score_term_row_json_schema do
    OrbitalDynamics.Schema.ScoreTermReportJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp link_capacity_row_json_schema do
    OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      probability_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp contact_allocation_row_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivation_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivation/0,
      approval_requirement_schema: &approval_requirement_json_schema/0,
      policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0,
      source_contention_recommendation_schema: &contact_contention_recommendation_json_schema/0,
      contact_allocation_capability:
        &OrbitalDynamics.Communications.ContactAllocation.capabilities/0,
      station_calendar_capability: &station_calendar_capabilities/0,
      deferred_priority_schema: &contact_contention_deferred_priority_json_schema/0,
      priority_field_evidence_counts_schema: &priority_field_evidence_counts_json_schema/0
    )
  end

  defp contact_allocation_capacity_pack_group_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_pack_group_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      capacity_requirement_row_schema: &contact_allocation_capacity_requirement_row_json_schema/0,
      source_contention_recommendation_schema: &contact_contention_recommendation_json_schema/0
    )
  end

  defp contact_allocation_capacity_requirement_row_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_requirement_row_from_deps(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp contact_contention_group_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.group_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      source_contact_candidate_schema: &contact_contention_source_contact_candidate_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp contact_contention_recommendation_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.recommendation_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      actual_data_rate_throughput_derivations_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivations/0,
      deferred_priority_schema: &contact_contention_deferred_priority_json_schema/0,
      source_contact_candidate_schema: &contact_contention_source_contact_candidate_json_schema/0,
      priority_field_evidence_counts_schema: &priority_field_evidence_counts_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp contact_contention_source_contact_candidate_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.source_contact_candidate_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp contact_contention_resolution_policy_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.resolution_policy_from_context(
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp contact_contention_deferred_priority_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.deferred_priority_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp priority_field_evidence_counts_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  defp objective_satisfaction_row_json_schema do
    OrbitalDynamics.Schema.ObjectiveReportJsonSchema.satisfaction_row_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0
    )
  end

  defp objective_tradeoff_row_json_schema do
    OrbitalDynamics.Schema.ObjectiveReportJsonSchema.tradeoff_row_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp ranking_comparison_row_json_schema do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.ranking_comparison_row_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp ranking_comparison_winner_json_schema do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.ranking_comparison_winner_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp pareto_frontier_row_json_schema do
    OrbitalDynamics.Schema.OptimizerReportJsonSchema.pareto_frontier_row_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_map/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp constraint_row_json_schema do
    OrbitalDynamics.Schema.ConstraintReportJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp resource_projection_row_json_schema do
    OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      resource_projection_flow_row_schema: &resource_projection_flow_row_json_schema/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      approval_requirement_schema: &approval_requirement_json_schema/0,
      policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp resource_projection_flow_row_json_schema do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      resource_capability: &OrbitalDynamics.ResourceSummary.capabilities/0
    )
  end

  defp suppressed_candidate_json_schema do
    OrbitalDynamics.Schema.SuppressedCandidateJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      suppression_reasons: &suppressed_candidate_suppression_reasons/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp suppressed_candidate_suppression_reasons do
    (contact_filter_suppression_reasons() ++ resource_filter_suppression_reasons())
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sha256_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.sha256(@sha256_pattern)
  end

  defp stable_id_array_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array(@stable_id_pattern)
  end

  defp stable_id_array_map_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.stable_id_array_map(@stable_id_pattern)
  end

  defp nested_stable_id_array_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.nested_stable_id_array_map(@stable_id_pattern)
  end

  defp spacecraft_state_estimate_json_schema do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.spacecraft_state_estimate_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0
    )
  end

  defp maneuver_execution_delta_json_schema do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.maneuver_execution_delta_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0
    )
  end

  defp source_window_lineage_json_schema do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.source_window_lineage_from_context(
      stable_id_pattern: @stable_id_pattern,
      scoped_context_properties: &candidate_refresh_scoped_context_json_schema_properties/0
    )
  end

  defp invalidated_candidate_json_schema do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.invalidated_candidate_from_context(
      stable_id_pattern: @stable_id_pattern,
      scoped_context_properties: &candidate_refresh_scoped_context_json_schema_properties/0
    )
  end

  defp candidate_diff_row_json_schema do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      scoped_context_properties: &candidate_refresh_scoped_context_json_schema_properties/0
    )
  end

  defp candidate_activity_json_schema do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      probability_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      number_or_string_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp campaign_activity_json_schema do
    candidate_activity_json_schema()
  end

  defp planned_activity_json_schema do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
      source_window_schema: candidate_activity_source_window_json_schema(),
      timeline_identity_schema: timeline_identity_json_schema(),
      cadence_import_schema: cadence_import_json_schema("planned_activity.v1"),
      execution_uncertainty_schema: execution_uncertainty_json_schema()
    )
  end

  defp plan_delta_json_schema do
    OrbitalDynamics.Schema.CampaignRepairJsonSchema.plan_delta_from_deps(
      stable_id_pattern: @stable_id_pattern,
      planned_activity_schema: &planned_activity_json_schema/0,
      realized_activity_schema: &realized_activity_json_schema/0,
      timeline_link_schema: &timeline_link_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp approval_requirement_json_schema do
    OrbitalDynamics.Schema.ApprovalRequirementJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      rule_match_schema: &policy_decision_rule_match_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      policy_escalation_schema: &policy_escalation_json_schema/0
    )
  end

  defp realized_activity_json_schema do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
      number_or_string_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_or_string(),
      execution_uncertainty_schema: execution_uncertainty_json_schema(),
      ground_station_schema: ground_station_identity_json_schema(),
      spacecraft_schema: spacecraft_identity_json_schema(),
      target_schema: target_identity_json_schema()
    )
  end

  defp realized_spacecraft_state_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["scenario_id"],
      "properties" => %{
        "spacecraft_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "mode" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "payload_status" => %{"type" => "string"},
        "degraded" => %{"type" => "boolean"},
        "payload_available" => %{"type" => "boolean"},
        "antenna_available" => %{"type" => "boolean"},
        "incompatible_activity_types" => OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
        "source" => %{"type" => "object", "additionalProperties" => true},
        "metadata" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  defp realized_state_snapshot_metadata_json_schema do
    OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema.metadata(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp target_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.target_from_context(@stable_id_pattern)
  end

  defp ground_station_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.ground_station_from_context(@stable_id_pattern)
  end

  defp spacecraft_identity_json_schema do
    OrbitalDynamics.Schema.IdentityJsonSchema.spacecraft_from_context(@stable_id_pattern)
  end

  defp operational_feedback_json_schema do
    OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.operational_feedback(%{
      probability_map: OrbitalDynamics.Schema.CommonJsonSchema.probability_map(),
      string_value_map: OrbitalDynamics.Schema.CommonJsonSchema.string_value_map(),
      non_negative_number_map: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map(),
      string_list_map: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map(),
      nested_object_map: OrbitalDynamics.Schema.CommonJsonSchema.nested_object_map(),
      realized_activity: realized_activity_json_schema()
    })
  end

  defp timeline_feedback_operational_feedback_provenance_json_schema do
    OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.timeline_feedback_provenance(
      @timeline_feedback_report,
      %{
        string_array: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
        count_map: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
        string_list_map: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map()
      }
    )
  end

  defp timeline_feedback_row_json_schema do
    OrbitalDynamics.Schema.TimelineFeedbackRowJsonSchema.row(
      stable_id_pattern: @stable_id_pattern,
      capability: timeline_feedback_capabilities(),
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      number_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_array(),
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability(),
      number_or_string_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_or_string(),
      protection_decision_schema: protection_decision_json_schema(),
      lifecycle_transition_schema: TimelineContextJsonSchema.lifecycle_transition(),
      actual_data_rate_throughput_derivation_schema:
        TimelineContextJsonSchema.actual_data_rate_throughput_derivation(),
      numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
      timeline_identity_schema: timeline_identity_json_schema(),
      activity_context_schema: activity_context_json_schema(),
      planned_activity_schema: planned_activity_json_schema(),
      realized_activity_schema: realized_activity_json_schema()
    )
  end

  defp schema_validation_batch_entry_json_schema do
    report_schema =
      json_schema_document(
        @schema_validation_report,
        registry_contract!(@schema_validation_report)
      )

    OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.batch_entry(report_schema)
  end

  defp validation_record_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.record(
      @stable_id_pattern,
      OrbitalDynamics.Schema.ValidationJsonSchema.validation_level()
    )
  end

  defp validation_record_registry_conditions do
    OrbitalDynamics.Schema.ValidationJsonSchema.registry_conditions(@stable_id_pattern)
  end

  defp model_acceptance_row_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.model_acceptance_row(
      @stable_id_pattern,
      validation_record_json_schema()
    )
  end

  defp safety_case_evidence_row_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.safety_case_evidence_row(@stable_id_pattern)
  end

  defp validation_reference_report_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.reference_report(
      @stable_id_pattern,
      OrbitalDynamics.Schema.ValidationJsonSchema.validation_level(),
      OrbitalDynamics.Schema.ValidationJsonSchema.check()
    )
  end

  defp strategy_branch_tradeoff_json_schema,
    do: OrbitalDynamics.Schema.StrategyContextJsonSchema.tradeoff()

  defp strategy_branch_risk_json_schema,
    do:
      OrbitalDynamics.Schema.StrategyContextJsonSchema.risk(
        @stable_id_pattern,
        scoped_downlink_context_json_schema_properties()
      )

  defp strategy_recommendation_json_schema do
    @strategy_recommendation
    |> json_schema_document(registry_contract!(@strategy_recommendation))
    |> Map.take(["type", "additionalProperties", "required", "properties"])
  end

  defp strategy_branch_json_schema,
    do:
      OrbitalDynamics.Schema.StrategyContextJsonSchema.branch(
        strategy_context_json_schema_inputs()
      )

  defp strategy_branch_event_json_schema,
    do:
      OrbitalDynamics.Schema.StrategyContextJsonSchema.event(
        strategy_context_json_schema_inputs()
      )

  defp strategy_context_json_schema_inputs do
    [
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      numeric_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_map(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      semantic_change_details_schema:
        OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details(),
      string_list_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_list_map(),
      non_negative_integer_count_map_schema:
        OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      provider_counteroffer_negotiation_states:
        station_calendar_provider_counteroffer_negotiation_states(),
      scoped_downlink_context_properties: scoped_downlink_context_json_schema_properties(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema(),
      policy_decision_schema: policy_decision_json_schema()
    ]
  end

  defp branch_comparison_source_row_json_schema do
    branch_comparison_row_json_schema()
    |> Map.delete("required")
  end

  defp strategy_explanation_json_schema,
    do:
      OrbitalDynamics.Schema.StrategyContextJsonSchema.explanation(
        @stable_id_pattern,
        branch_scoped_downlink_context_json_schema_properties()
      )

  defp timeline_identity_json_schema,
    do: TimelineContextJsonSchema.timeline_identity(@stable_id_pattern)

  defp execution_uncertainty_json_schema,
    do:
      TimelineContextJsonSchema.execution_uncertainty(
        OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet()
      )

  defp protection_decision_json_schema,
    do: TimelineContextJsonSchema.protection_decision(@stable_id_pattern)

  defp timeline_preservation_source_json_schema do
    OrbitalDynamics.Schema.TimelinePreservationJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_link_json_schema,
    do: TimelineContextJsonSchema.timeline_link(@stable_id_pattern)

  defp timeline_protection_summary_json_schema,
    do: TimelineContextJsonSchema.timeline_protection_summary(stable_id_array_schema())

  defp activity_context_json_schema,
    do:
      TimelineContextJsonSchema.activity_context(
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: stable_id_array_schema(),
        string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
        number_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.number_array(),
        numeric_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_map(),
        candidate_activity_source_window_schema: candidate_activity_source_window_json_schema(),
        numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
        probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
      )

  defp ranked_timeline_json_schema do
    OrbitalDynamics.Schema.CampaignPlanJsonSchema.ranked_timeline_from_context(
      stable_id_pattern: @stable_id_pattern,
      campaign_activity_schema: &campaign_activity_json_schema/0
    )
  end

  defp candidate_activity_source_window_json_schema do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.source_window_from_context(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp contact_intent_row_json_schema do
    OrbitalDynamics.Schema.ContactIntentJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_identity_schema: &timeline_identity_json_schema/0,
      approval_requirement_schema: &approval_requirement_json_schema/0,
      policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
      model_limits: &contact_intent_model_limits/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp proposed_contact_row_json_schema do
    OrbitalDynamics.Schema.ProposedContactJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      cadence_import_schema: fn -> cadence_import_json_schema("proposed_contact.v1") end
    )
  end

  defp cadence_import_json_schema(schema_contract) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["external_id", "activity_type"],
      "properties" => %{
        "external_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "schema_contract" => %{"type" => "string", "const" => schema_contract}
      }
    }
  end

  defp resource_summary_row_json_schema do
    OrbitalDynamics.Schema.ResourceSummaryJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0
    )
  end

  defp operational_timeline_row_json_schema do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.row_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      timeline_precondition_schema: &timeline_precondition_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      timeline_integrity_issue_schema: &timeline_integrity_issue_json_schema/0
    )
  end

  defp candidate_rejection_row_json_schema do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_capability: &timeline_capabilities/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp candidate_rejection_source_json_schema do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_capability: &timeline_capabilities/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp provider_counteroffer_row_json_schema do
    OrbitalDynamics.Schema.ProviderCounterofferJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      station_calendar: &station_calendar_capabilities/0
    )
  end

  defp timeline_precondition_json_schema do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.precondition_from_context(
      capability: &timeline_capabilities/0
    )
  end

  defp timeline_integrity_issue_json_schema do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.integrity_issue_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp timeline_diff_row_json_schema do
    OrbitalDynamics.Schema.TimelineDiffReportJsonSchema.row_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &protection_decision_json_schema/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_lifecycle_state_row_json_schema do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.row_from_context(
      model_limits: &timeline_report_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      transition_decisions: &timeline_transition_decisions/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &protection_decision_json_schema/0
    )
  end

  defp timeline_lifecycle_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      transition_decisions: &timeline_transition_decisions/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &lifecycle_state_source_protection_decision_json_schema/0
    )
  end

  defp timeline_activity_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: &protection_decision_json_schema/0
    )
  end

  defp timeline_activity_precondition_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema.summary_source_from_context(
      @timeline_activity_precondition_summary,
      registry_contract!(@timeline_activity_precondition_summary),
      [
        model_limits: &timeline_report_model_limits/0,
        precondition_statuses: &timeline_activity_precondition_statuses/0,
        string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        precondition_schema: &timeline_precondition_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0
      ],
      &default_json_schema_property/3
    )
  end

  defp lifecycle_state_source_protection_decision_json_schema do
    %{
      "oneOf" => [
        protection_decision_json_schema(),
        %{"type" => "string"}
      ]
    }
  end

  defp timeline_diff_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema.summary_source_from_context(
      @timeline_diff_summary,
      registry_contract!(@timeline_diff_summary),
      [
        model_limits: &timeline_report_model_limits/0,
        row_schema: &timeline_diff_row_json_schema/0,
        capability: &timeline_capabilities/0,
        stable_id_pattern: @stable_id_pattern
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_dependency_impact_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.summary_source_from_context(
      @timeline_dependency_impact_summary,
      registry_contract!(@timeline_dependency_impact_summary),
      [
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        required_operator_actions: &timeline_required_operator_actions/0,
        model_limits: &timeline_report_model_limits/0
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_publication_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema.summary_source_from_context(
      @timeline_publication_summary,
      registry_contract!(@timeline_publication_summary),
      [
        stable_id_pattern: @stable_id_pattern,
        timeline_diff_summary_source_schema: &timeline_diff_summary_source_json_schema/0,
        timeline_dependency_impact_summary_source_schema:
          &timeline_dependency_impact_summary_source_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        model_limits: &timeline_report_model_limits/0
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_transition_application_row_json_schema do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.application_row_from_context(
      timeline_capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      protection_decision_schema: &protection_decision_json_schema/0,
      timeline_diff_row_schema: &timeline_diff_row_json_schema/0
    )
  end

  defp timeline_transition_application_summary_source_json_schema do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.summary_source_from_context(
      @timeline_transition_application_summary,
      registry_contract!(@timeline_transition_application_summary),
      [
        timeline_capability: &timeline_capabilities/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
        lifecycle_transition_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        timeline_diff_row_schema: &timeline_diff_row_json_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        model_limits: &timeline_report_model_limits/0,
        enum_count_map_schema: &OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map/1
      ],
      &default_json_schema_property/3
    )
  end

  defp timeline_dependency_impact_row_json_schema do
    OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      required_operator_actions: &timeline_required_operator_actions/0
    )
  end

  defp timeline_transition_selected_activity_json_schema do
    OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.selected_activity_from_context(
      timeline_capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      timeline_identity_schema: &timeline_identity_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp maneuver_review_row_json_schema do
    OrbitalDynamics.Schema.ManeuverReviewReportJsonSchema.row(
      stable_id_pattern: @stable_id_pattern,
      numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
      policy_decision_schema: policy_decision_json_schema()
    )
  end

  defp command_window_row_json_schema do
    OrbitalDynamics.Schema.CommandWindowReportJsonSchema.row(
      stable_id_pattern: @stable_id_pattern,
      activity_context_schema: activity_context_json_schema(),
      policy_decision_schema: policy_decision_json_schema()
    )
  end

  defp station_calendar_contact_json_schema do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.contact(
      stable_id_pattern: @stable_id_pattern,
      provider_counteroffer_negotiation_states:
        station_calendar_provider_counteroffer_negotiation_states(),
      source_entry_schema: station_calendar_report_source_entry_json_schema(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema(),
      policy_decision_schema: policy_decision_json_schema()
    )
  end

  defp station_reservation_contact_json_schema do
    OrbitalDynamics.Schema.StationReservationReportJsonSchema.contact(
      stable_id_pattern: @stable_id_pattern,
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema(),
      policy_decision_schema: policy_decision_json_schema()
    )
  end

  defp station_reservation_provider_contention_group_json_schema do
    OrbitalDynamics.Schema.StationReservationReportJsonSchema.provider_contention_group(
      calendar_group_schema: station_calendar_provider_contention_group_json_schema()
    )
  end

  defp station_reservation_review_summary_row_json_schema do
    OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema.review_row(
      stable_id_pattern: @stable_id_pattern,
      base_schema: station_reservation_contact_json_schema()
    )
  end

  defp station_reservation_hold_import_readiness_row_json_schema do
    OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema.import_readiness_row(
      review_row_schema: station_reservation_review_summary_row_json_schema()
    )
  end

  defp station_calendar_report_source_entry_json_schema do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.source_entry(
      stable_id_pattern: @stable_id_pattern,
      provider_counteroffer_negotiation_states:
        station_calendar_provider_counteroffer_negotiation_states()
    )
  end

  defp station_calendar_provider_contention_group_json_schema do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_contention_group(
      stable_id_pattern: @stable_id_pattern,
      policy_decision_schema: policy_decision_json_schema(),
      provider_contention_pair_schema: station_calendar_provider_contention_pair_json_schema(),
      provider_entry_schema: station_calendar_provider_entry_json_schema()
    )
  end

  defp station_calendar_provider_contention_pair_json_schema do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_contention_pair(
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp station_calendar_provider_entry_json_schema do
    OrbitalDynamics.Schema.StationCalendarReportJsonSchema.provider_entry(
      stable_id_pattern: @stable_id_pattern,
      provider_counteroffer_negotiation_states:
        station_calendar_provider_counteroffer_negotiation_states()
    )
  end

  defp operational_readiness_gate_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessGateJsonSchema.gate(
      capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp quality_gate_report_row_json_schema do
    OrbitalDynamics.Schema.QualityGateReportJsonSchema.row(
      capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      gate_schema: operational_readiness_gate_json_schema()
    )
  end

  defp cadence_import_operational_readiness_evidence_json_schema_properties do
    OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.evidence_properties(%{
      gate_schema: operational_readiness_gate_json_schema(),
      evidence_schema: operational_readiness_evidence_json_schema()
    })
  end

  defp resource_projection_battery_handoff_json_schema_properties do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.battery_properties(
      OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.battery_handoff_number_fields()
    )
  end

  defp cadence_import_resource_projection_evidence_json_schema_properties do
    OrbitalDynamics.Schema.ResourceProjectionHandoffJsonSchema.evidence_properties(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema()
    )
  end

  defp operational_readiness_evidence_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceJsonSchema.schema(
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      stable_id_array_schema: stable_id_array_schema(),
      branch_event_trust_boundary_status_counts_schema:
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map(),
      timeline_publication_context_properties:
        OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
          stable_id_pattern: @stable_id_pattern
        )
    )
  end

  defp cadence_import_manifest_row_json_schema do
    OrbitalDynamics.Schema.CadenceImportManifestJsonSchema.row(
      capability: cadence_import_capability(),
      readiness_capability: operational_readiness_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema_providers: cadence_import_manifest_row_json_schema_providers(),
      property_providers: cadence_import_manifest_row_json_schema_property_providers()
    )
  end

  defp cadence_import_manifest_row_json_schema_providers do
    [
      activity_context_json_schema: &activity_context_json_schema/0,
      branch_comparison_source_row_json_schema: &branch_comparison_source_row_json_schema/0,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      cadence_import_status_json_schema:
        &OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.status/0,
      cadence_source_review_row_json_schema: &cadence_source_review_row_json_schema/0,
      candidate_activity_source_window_json_schema:
        &candidate_activity_source_window_json_schema/0,
      candidate_rejection_source_json_schema: &candidate_rejection_source_json_schema/0,
      contact_allocation_capacity_requirement_row_json_schema:
        &contact_allocation_capacity_requirement_row_json_schema/0,
      contact_contention_deferred_priority_json_schema:
        &contact_contention_deferred_priority_json_schema/0,
      non_negative_number_map_json_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      number_or_number_array_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.number_or_number_array/0,
      number_or_string_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      operational_readiness_evidence_json_schema: &operational_readiness_evidence_json_schema/0,
      operational_readiness_gate_json_schema: &operational_readiness_gate_json_schema/0,
      operational_readiness_source_report_evidence_json_schema:
        &operational_readiness_source_report_evidence_json_schema/0,
      operational_timeline_row_json_schema: &operational_timeline_row_json_schema/0,
      policy_decision_evidence_json_schema: &policy_decision_evidence_json_schema/0,
      policy_escalation_json_schema: &policy_escalation_json_schema/0,
      priority_field_evidence_counts_json_schema: &priority_field_evidence_counts_json_schema/0,
      probability_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      quality_gate_report_row_json_schema: &quality_gate_report_row_json_schema/0,
      quality_gate_source_report_evidence_json_schema:
        &quality_gate_source_report_evidence_json_schema/0,
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: &source_evidence_json_schema/0,
      source_execution_report_evidence_json_schema:
        &source_execution_report_evidence_json_schema/0,
      source_freshness_report_evidence_json_schema:
        &source_freshness_report_evidence_json_schema/0,
      source_schema_validation_report_evidence_json_schema:
        &source_schema_validation_report_evidence_json_schema/0,
      source_window_lineage_json_schema: &source_window_lineage_json_schema/0,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        &timeline_activity_precondition_summary_source_json_schema/0,
      timeline_activity_state_source_json_schema: &timeline_activity_state_source_json_schema/0,
      timeline_diff_summary_source_json_schema: &timeline_diff_summary_source_json_schema/0,
      timeline_identity_json_schema: &timeline_identity_json_schema/0,
      timeline_lifecycle_state_source_json_schema: &timeline_lifecycle_state_source_json_schema/0,
      timeline_link_json_schema: &timeline_link_json_schema/0,
      timeline_preservation_source_json_schema: &timeline_preservation_source_json_schema/0,
      timeline_protection_summary_json_schema: &timeline_protection_summary_json_schema/0,
      timeline_transition_application_row_json_schema:
        &timeline_transition_application_row_json_schema/0,
      timeline_transition_application_summary_source_json_schema:
        &timeline_transition_application_summary_source_json_schema/0
    ]
  end

  defp cadence_import_manifest_row_json_schema_property_providers do
    [
      branch_scoped_downlink_context_json_schema_properties:
        &branch_scoped_downlink_context_json_schema_properties/0,
      cadence_import_operational_readiness_evidence_json_schema_properties:
        &cadence_import_operational_readiness_evidence_json_schema_properties/0,
      cadence_import_resource_projection_evidence_json_schema_properties:
        &cadence_import_resource_projection_evidence_json_schema_properties/0,
      command_authority_handoff_json_schema_properties:
        &OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema.properties/0,
      feedback_maneuver_handoff_json_schema_properties:
        &feedback_maneuver_handoff_json_schema_properties/0,
      link_handoff_json_schema_properties: &link_handoff_json_schema_properties/0,
      resource_availability_variance_json_schema_properties:
        &OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema.properties/0,
      resource_projection_battery_handoff_json_schema_properties:
        &resource_projection_battery_handoff_json_schema_properties/0,
      scoped_downlink_context_json_schema_properties:
        &scoped_downlink_context_json_schema_properties/0,
      thermal_handoff_json_schema_properties: &thermal_handoff_json_schema_properties/0,
      timeline_activity_precondition_handoff_json_schema_properties:
        &timeline_activity_precondition_handoff_json_schema_properties/0,
      timeline_dependency_impact_handoff_json_schema_properties:
        &timeline_dependency_impact_handoff_json_schema_properties/0,
      timeline_publication_handoff_json_schema_properties:
        &timeline_publication_handoff_json_schema_properties/0
    ]
  end

  defp timeline_dependency_impact_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.dependency_impact_properties(
      stable_id_array_schema: stable_id_array_schema(),
      timeline_dependency_impact_row_schema: timeline_dependency_impact_row_json_schema()
    )
  end

  defp timeline_publication_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.publication_properties(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      stable_id_array_map_schema: stable_id_array_map_schema(),
      count_map_schema: OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map(),
      timeline_publication_summary_source_schema:
        timeline_publication_summary_source_json_schema()
    )
  end

  defp timeline_activity_precondition_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.activity_precondition_properties(
      timeline_capability: timeline_capabilities(),
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: OrbitalDynamics.Schema.CommonJsonSchema.string_array(),
      timeline_precondition_schema: timeline_precondition_json_schema(),
      timeline_activity_precondition_summary_source_schema:
        timeline_activity_precondition_summary_source_json_schema()
    )
  end

  defp link_handoff_json_schema_properties do
    OrbitalDynamics.Schema.LinkHandoffJsonSchema.properties(
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp feedback_maneuver_handoff_json_schema_properties do
    OrbitalDynamics.Schema.FeedbackManeuverHandoffJsonSchema.properties(
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp thermal_handoff_json_schema_properties do
    OrbitalDynamics.Schema.ThermalHandoffJsonSchema.properties(
      stable_id_pattern: @stable_id_pattern,
      probability_schema: OrbitalDynamics.Schema.CommonJsonSchema.probability()
    )
  end

  defp cadence_source_review_row_json_schema do
    OrbitalDynamics.Schema.CadenceSourceReviewRowJsonSchema.row(
      cadence_capability: cadence_import_capability(),
      readiness_capability: operational_readiness_capabilities(),
      timeline_capability: timeline_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema_providers: cadence_source_review_row_json_schema_providers(),
      property_providers: cadence_source_review_row_json_schema_property_providers()
    )
  end

  defp cadence_source_review_row_json_schema_providers do
    [
      activity_context_json_schema: &activity_context_json_schema/0,
      branch_comparison_source_row_json_schema: &branch_comparison_source_row_json_schema/0,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      candidate_activity_source_window_json_schema:
        &candidate_activity_source_window_json_schema/0,
      candidate_rejection_source_json_schema: &candidate_rejection_source_json_schema/0,
      contact_allocation_capacity_requirement_row_json_schema:
        &contact_allocation_capacity_requirement_row_json_schema/0,
      contact_contention_deferred_priority_json_schema:
        &contact_contention_deferred_priority_json_schema/0,
      non_negative_number_map_json_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0,
      number_or_string_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      operational_readiness_source_report_evidence_json_schema:
        &operational_readiness_source_report_evidence_json_schema/0,
      operational_timeline_row_json_schema: &operational_timeline_row_json_schema/0,
      policy_decision_evidence_json_schema: &policy_decision_evidence_json_schema/0,
      policy_escalation_json_schema: &policy_escalation_json_schema/0,
      priority_field_evidence_counts_json_schema: &priority_field_evidence_counts_json_schema/0,
      probability_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      quality_gate_source_report_evidence_json_schema:
        &quality_gate_source_report_evidence_json_schema/0,
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: &source_evidence_json_schema/0,
      source_execution_report_evidence_json_schema:
        &source_execution_report_evidence_json_schema/0,
      source_freshness_report_evidence_json_schema:
        &source_freshness_report_evidence_json_schema/0,
      source_schema_validation_report_evidence_json_schema:
        &source_schema_validation_report_evidence_json_schema/0,
      source_window_lineage_json_schema: &source_window_lineage_json_schema/0,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        &timeline_activity_precondition_summary_source_json_schema/0,
      timeline_activity_state_source_json_schema: &timeline_activity_state_source_json_schema/0,
      timeline_diff_summary_source_json_schema: &timeline_diff_summary_source_json_schema/0,
      timeline_identity_json_schema: &timeline_identity_json_schema/0,
      timeline_lifecycle_state_source_json_schema: &timeline_lifecycle_state_source_json_schema/0,
      timeline_link_json_schema: &timeline_link_json_schema/0,
      timeline_preservation_source_json_schema: &timeline_preservation_source_json_schema/0,
      timeline_protection_summary_json_schema: &timeline_protection_summary_json_schema/0,
      timeline_transition_application_row_json_schema:
        &timeline_transition_application_row_json_schema/0,
      timeline_transition_application_summary_source_json_schema:
        &timeline_transition_application_summary_source_json_schema/0
    ]
  end

  defp cadence_source_review_row_json_schema_property_providers do
    [
      branch_scoped_downlink_context_json_schema_properties:
        &branch_scoped_downlink_context_json_schema_properties/0,
      cadence_import_operational_readiness_evidence_json_schema_properties:
        &cadence_import_operational_readiness_evidence_json_schema_properties/0,
      cadence_import_resource_projection_evidence_json_schema_properties:
        &cadence_import_resource_projection_evidence_json_schema_properties/0,
      command_authority_handoff_json_schema_properties:
        &OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema.properties/0,
      feedback_maneuver_handoff_json_schema_properties:
        &feedback_maneuver_handoff_json_schema_properties/0,
      link_handoff_json_schema_properties: &link_handoff_json_schema_properties/0,
      resource_availability_variance_json_schema_properties:
        &OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema.properties/0,
      resource_projection_battery_handoff_json_schema_properties:
        &resource_projection_battery_handoff_json_schema_properties/0,
      scoped_downlink_context_json_schema_properties:
        &scoped_downlink_context_json_schema_properties/0,
      thermal_handoff_json_schema_properties: &thermal_handoff_json_schema_properties/0,
      timeline_activity_precondition_handoff_json_schema_properties:
        &timeline_activity_precondition_handoff_json_schema_properties/0,
      timeline_dependency_impact_handoff_json_schema_properties:
        &timeline_dependency_impact_handoff_json_schema_properties/0,
      timeline_publication_handoff_json_schema_properties:
        &timeline_publication_handoff_json_schema_properties/0
    ]
  end

  defp operator_review_row_json_schema do
    OrbitalDynamics.Schema.OperatorReviewRowJsonSchema.row(
      operator_review_capability: operator_review_capabilities(),
      readiness_capability: operational_readiness_capabilities(),
      timeline_capability: timeline_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema_providers: operator_review_row_json_schema_providers(),
      property_providers: operator_review_row_json_schema_property_providers()
    )
  end

  defp operator_review_row_json_schema_providers do
    [
      activity_context_json_schema: &activity_context_json_schema/0,
      actual_data_rate_throughput_derivation_json_schema:
        &TimelineContextJsonSchema.actual_data_rate_throughput_derivation/0,
      approval_requirement_json_schema: &approval_requirement_json_schema/0,
      branch_comparison_source_row_json_schema: &branch_comparison_source_row_json_schema/0,
      branch_event_trust_boundary_status_counts_json_schema:
        &OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.trust_boundary_status_count_map/0,
      candidate_activity_source_window_json_schema:
        &candidate_activity_source_window_json_schema/0,
      contact_allocation_capacity_requirement_row_json_schema:
        &contact_allocation_capacity_requirement_row_json_schema/0,
      contact_contention_deferred_priority_json_schema:
        &contact_contention_deferred_priority_json_schema/0,
      lifecycle_transition_json_schema: &TimelineContextJsonSchema.lifecycle_transition/0,
      non_negative_number_map_json_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map/0,
      number_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_array/0,
      number_or_number_array_schema:
        &OrbitalDynamics.Schema.CommonJsonSchema.number_or_number_array/0,
      number_or_string_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.number_or_string/0,
      numeric_triplet_schema: &OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet/0,
      operational_readiness_evidence_json_schema: &operational_readiness_evidence_json_schema/0,
      operational_readiness_gate_json_schema: &operational_readiness_gate_json_schema/0,
      operational_readiness_source_report_evidence_json_schema:
        &operational_readiness_source_report_evidence_json_schema/0,
      operational_timeline_row_json_schema: &operational_timeline_row_json_schema/0,
      policy_decision_evidence_json_schema: &policy_decision_evidence_json_schema/0,
      policy_decision_rule_match_json_schema: &policy_decision_rule_match_json_schema/0,
      policy_escalation_json_schema: &policy_escalation_json_schema/0,
      priority_field_evidence_counts_json_schema: &priority_field_evidence_counts_json_schema/0,
      probability_json_schema: &OrbitalDynamics.Schema.CommonJsonSchema.probability/0,
      protection_decision_json_schema: &protection_decision_json_schema/0,
      quality_gate_report_row_json_schema: &quality_gate_report_row_json_schema/0,
      quality_gate_source_report_evidence_json_schema:
        &quality_gate_source_report_evidence_json_schema/0,
      semantic_change_details_json_schema:
        &OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details/0,
      source_evidence_json_schema: &source_evidence_json_schema/0,
      source_window_lineage_json_schema: &source_window_lineage_json_schema/0,
      stable_id_array_map_schema: &stable_id_array_map_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &OrbitalDynamics.Schema.CommonJsonSchema.string_array/0,
      timeline_activity_precondition_summary_source_json_schema:
        &timeline_activity_precondition_summary_source_json_schema/0,
      timeline_activity_state_source_json_schema: &timeline_activity_state_source_json_schema/0,
      timeline_diff_summary_source_json_schema: &timeline_diff_summary_source_json_schema/0,
      timeline_identity_json_schema: &timeline_identity_json_schema/0,
      timeline_lifecycle_state_source_json_schema: &timeline_lifecycle_state_source_json_schema/0,
      timeline_link_json_schema: &timeline_link_json_schema/0,
      timeline_preservation_source_json_schema: &timeline_preservation_source_json_schema/0,
      timeline_protection_summary_json_schema: &timeline_protection_summary_json_schema/0,
      timeline_transition_application_row_json_schema:
        &timeline_transition_application_row_json_schema/0,
      timeline_transition_application_summary_source_json_schema:
        &timeline_transition_application_summary_source_json_schema/0
    ]
  end

  defp operator_review_row_json_schema_property_providers do
    [
      branch_scoped_downlink_context_json_schema_properties:
        &branch_scoped_downlink_context_json_schema_properties/0,
      command_authority_handoff_json_schema_properties:
        &OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema.properties/0,
      feedback_maneuver_handoff_json_schema_properties:
        &feedback_maneuver_handoff_json_schema_properties/0,
      link_handoff_json_schema_properties: &link_handoff_json_schema_properties/0,
      resource_availability_variance_json_schema_properties:
        &OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema.properties/0,
      resource_projection_battery_handoff_json_schema_properties:
        &resource_projection_battery_handoff_json_schema_properties/0,
      scoped_downlink_context_json_schema_properties:
        &scoped_downlink_context_json_schema_properties/0,
      thermal_handoff_json_schema_properties: &thermal_handoff_json_schema_properties/0,
      timeline_activity_precondition_handoff_json_schema_properties:
        &timeline_activity_precondition_handoff_json_schema_properties/0,
      timeline_dependency_impact_handoff_json_schema_properties:
        &timeline_dependency_impact_handoff_json_schema_properties/0,
      timeline_publication_handoff_json_schema_properties:
        &timeline_publication_handoff_json_schema_properties/0
    ]
  end

  defp validate_contract(@activity_template, contract, artifact) do
    OrbitalDynamics.Schema.ActivityTemplateContracts.validate(
      [],
      "$",
      artifact,
      contract,
      timeline_capabilities()
    )
  end

  defp validate_contract(@planned_activity, contract, artifact) do
    OrbitalDynamics.Schema.PlannedActivityContracts.validate(
      [],
      "$",
      artifact,
      contract
    )
  end

  defp validate_contract(@proposed_contact, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ProposedContactContracts.validate("$", artifact)
  end

  defp validate_contract(@contact_intent, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ContactIntentContracts.validate("$", artifact)
  end

  defp validate_contract(@contact_intent_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ContactIntentSummaryContracts.validate_summary("$", artifact)
  end

  defp validate_contract(@candidate_activity, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.CandidateActivityContracts.validate("$", artifact)
  end

  defp validate_contract(@candidate_diff_report, _contract, artifact) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report([], "$", artifact)
  end

  defp validate_contract(@link_capacity_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LinkCapacityReportContracts.validate("$", artifact)
  end

  defp validate_contract(@link_capacity_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LinkCapacitySummaryContracts.validate_summary("$", artifact)
  end

  defp validate_contract(@relay_data_path_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.RelayDataPathSummaryContracts.validate_summary("$", artifact)
  end

  defp validate_contract(@contact_contention_report, _contract, artifact) do
    []
    |> OrbitalDynamics.Schema.ContactContentionReportContracts.validate_report("$", artifact)
  end

  defp validate_contract(@contact_contention_resolution_report, _contract, artifact) do
    []
    |> OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@contact_contention_resolution_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ContactContentionResolutionSummaryContracts.validate(
      "$",
      artifact,
      contact_contention_report_model_limits(),
      &OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_policy/3
    )
  end

  defp validate_contract(@contact_allocation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_report("$", artifact)
  end

  defp validate_contract(@contact_allocation_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_summary("$", artifact)
  end

  defp validate_contract(@contact_allocation_reservation_conflict_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_reservation_conflict_summary("$", artifact)
  end

  defp validate_contract(@contact_allocation_station_pressure_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_station_pressure_summary("$", artifact)
  end

  defp validate_contract(@contact_allocation_capacity_pack_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_capacity_pack_summary("$", artifact)
  end

  defp validate_contract(
         @contact_allocation_provider_reservation_request_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_allocation_provider_reservation_request_summary("$", artifact)
  end

  defp validate_contract(@station_calendar_provider, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StationCalendarProviderContracts.validate("$", artifact)
  end

  defp validate_contract(@station_calendar_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> StationReservationValidation.validate_optional_calendar_report("$", artifact)
  end

  defp validate_contract(@station_calendar_precedence_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryContracts.validate(
      "$",
      artifact,
      station_calendar_report_model_limits()
    )
  end

  defp validate_contract(@station_reservation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StationReservationReportContracts.validate(
      "$",
      artifact,
      OrbitalDynamics.Schema.StationReservationReportJsonSchema.models()
    )
  end

  defp validate_contract(@station_reservation_review_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> StationReservationValidation.validate_review_summary("$", artifact)
  end

  defp validate_contract(@station_reservation_hold_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> StationReservationValidation.validate_hold_summary("$", artifact)
  end

  defp validate_contract(@station_reservation_hold_import_readiness_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> StationReservationValidation.validate_hold_import_readiness_summary("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ProviderCounterofferReportContracts.validate("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_review_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_review("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_import_readiness_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_import_readiness(
      "$",
      artifact
    )
  end

  defp validate_contract(@provider_counteroffer_plan_impact_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_plan_impact(
      "$",
      artifact
    )
  end

  defp validate_contract(@resource_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ResourceSummaryContracts.validate("$", artifact)
  end

  defp validate_contract(@resource_projection_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> ResourceValidation.validate_resource_projection_report("$", artifact)
  end

  defp validate_contract(@resource_projection_flow_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> ResourceValidation.validate_resource_projection_flow_summary("$", artifact)
  end

  defp validate_contract(@contact_filter_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> ContactReportValidation.validate_filter_report("$", artifact)
  end

  defp validate_contract(@resource_filter_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> ResourceValidation.validate_resource_filter_report("$", artifact)
  end

  defp validate_contract(@resource_filter_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ResourceFilterSummaryContracts.validate(
      "$",
      artifact,
      resource_filter_report_model_limits(),
      &ResourceValidation.validate_suppressed_candidate/3,
      &ResourceValidation.validate_invalid_resource_summary_input/3
    )
  end

  defp validate_contract(@realized_activity, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.RealizedActivityContracts.validate("$", artifact)
  end

  defp validate_contract(@realized_state_snapshot, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.RealizedStateSnapshotContracts.validate("$", artifact)
  end

  defp validate_contract(@timeline_feedback_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineFeedbackReportContracts.validate(
      "$",
      artifact,
      timeline_feedback_report_model_limits(),
      &validate_optional_operator_review_package/2
    )
  end

  defp validate_contract(@candidate_rejection_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> CandidateRejectionValidation.validate_report("$", artifact)
  end

  defp validate_contract(@plan_delta, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.PlanDeltaContracts.validate("$", artifact)
  end

  defp validate_contract(@approval_requirement, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> PolicyValidation.validate_approval_requirement("$", artifact)
  end

  defp validate_contract(@policy_decision, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> PolicyValidation.validate_decision("$", artifact)
  end

  defp validate_contract(@policy_bundle, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> PolicyValidation.validate_bundle("$", artifact)
  end

  defp validate_contract(@operator_review_package, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operator_review_package("$", artifact)
  end

  defp validate_contract(@cadence_import_manifest, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_cadence_import_manifest("$", artifact)
  end

  defp validate_contract(@operational_readiness_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_readiness_report("$", artifact)
  end

  defp validate_contract(@operational_import_eligibility_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_import_eligibility_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(@operational_readiness_gate_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_readiness_gate_summary("$", artifact)
  end

  defp validate_contract(@operational_execution_boundary_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_execution_boundary_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(@operational_quality_gate_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_quality_gate_summary("$", artifact)
  end

  defp validate_contract(
         @operational_quality_gate_unavailable_resource_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_quality_gate_unavailable_resource_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(
         @operational_quality_gate_operator_training_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_quality_gate_operator_training_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(
         @operational_quality_gate_schema_validation_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_quality_gate_schema_validation_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(
         @operational_quality_gate_import_readiness_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OperationalReadinessValidation.validate_operational_quality_gate_import_readiness_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(@quality_gate_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.QualityGateReportContracts.validate_report(
      "$",
      artifact,
      OperationalReadinessValidation.quality_gate_report_model_limits(),
      &OperationalReadinessValidation.validate_quality_gate_row/3
    )
  end

  defp validate_contract(@environment_model_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_model("$", artifact)
  end

  defp validate_contract(@environment_provider_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_provider(
      "$",
      artifact
    )
  end

  defp validate_contract(@subsystem_model_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ModelCapabilityContracts.validate_subsystem_model("$", artifact)
  end

  defp validate_contract(@schema_validation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReportContracts.validate_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@schema_validation_batch_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReportContracts.validate_batch(
      "$",
      artifact
    )
  end

  defp validate_contract(@schema_migration_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.SchemaMigrationContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@campaign_request_lint, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LintContracts.validate_campaign_request(
      "$",
      artifact
    )
  end

  defp validate_contract(@study_manifest_lint, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LintContracts.validate_study_manifest(
      "$",
      artifact
    )
  end

  defp validate_contract(@strategy_branch, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "strategy_branch.v1")
    |> validate_branch("$", artifact)
  end

  defp validate_contract(@study_benchmark, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StudyBenchmarkContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@manifest_field_reference, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ManifestFieldReferenceContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@validation_tolerance_policy, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationPolicyContracts.validate_tolerance_policy(
      "$",
      artifact
    )
  end

  defp validate_contract(@backend_acceptance_policy, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationPolicyContracts.validate_backend_acceptance_policy(
      "$",
      artifact
    )
  end

  defp validate_contract(@capability_catalog, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.CapabilityCatalogContracts.validate(
      "$",
      artifact,
      @contracts
    )
  end

  defp validate_contract(@result_artifact, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ResultArtifactContracts.validate(
      "$",
      artifact,
      &validate_nested_execution_report/1
    )
  end

  defp validate_contract(@strategy_recommendation, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_recommendation("$", artifact)
  end

  defp validate_contract(@maneuver_recommendation, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> DecisionSupportValidation.validate_maneuver_recommendation("$", artifact)
  end

  defp validate_contract(@maneuver_review_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> DecisionSupportValidation.validate_maneuver_review_report("$", artifact)
  end

  defp validate_contract(@execution_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ExecutionReportContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@monte_carlo_reproducibility_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.MonteCarloReproducibilityContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@objective_tradeoff_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_objective_tradeoff_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@objective_satisfaction_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_objective_satisfaction_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@ranking_comparison_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_ranking_comparison_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@pareto_frontier_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ParetoFrontierContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@operational_timeline_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OperationalTimelineReportContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits(),
      &validate_operational_timeline_row/3
    )
  end

  defp validate_contract(@timeline_diff_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDiffReportContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_diff_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDiffSummaryContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_integrity_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_dependency_impact_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_publication_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePublicationSummaryContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@timeline_activity_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityStateContracts.validate(
      "$",
      artifact,
      timeline_feedback_report_model_limits()
    )
  end

  defp validate_contract(@timeline_activity_precondition_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_activity_status_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_status_state(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_activity_approval_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_approval_state(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_activity_lifecycle_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_lifecycle_state(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_preservation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePreservationContracts.validate_report(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_preservation_status, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePreservationContracts.validate_status(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_lifecycle_state_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineLifecycleStateSummaryContracts.validate(
      "$",
      artifact,
      timeline_report_model_limits()
    )
  end

  defp validate_contract(@timeline_transition_application_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> TimelineTransitionValidation.validate_timeline_transition_application_report("$", artifact)
  end

  defp validate_contract(@timeline_transition_application_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> TimelineTransitionValidation.validate_timeline_transition_application_summary(
      "$",
      artifact
    )
  end

  defp validate_contract(@command_window_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.CommandWindowReportContracts.validate(
      "$",
      artifact,
      command_window_report_model_limits()
    )
  end

  defp validate_contract(@branch_comparison_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.BranchComparisonReportContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@optimizer_contract, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerContractContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@constraint_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ConstraintReportContracts.validate(
      "$",
      artifact
    )
  end

  defp validate_contract(@score_term_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_score_term_report(
      "$",
      artifact
    )
  end

  defp validate_contract(@accepted_planning_state, contract, artifact) do
    OrbitalDynamics.Schema.AcceptedStateContracts.validate_planning_state(
      [],
      "$",
      artifact,
      contract["required_fields"]
    )
  end

  defp validate_contract(@spacecraft_state_estimate, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.AcceptedStateContracts.validate_spacecraft_state_estimate(
      "$",
      artifact
    )
  end

  defp validate_contract(@maneuver_execution_delta, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.AcceptedStateContracts.validate_maneuver_execution_delta(
      "$",
      artifact
    )
  end

  defp validate_contract(@candidate_refresh, contract, artifact) do
    OrbitalDynamics.Schema.CandidateRefreshContracts.validate(
      [],
      artifact,
      contract["required_fields"],
      &validate_optional_contact_allocation_report/2,
      &CandidateRejectionValidation.validate_optional_report/3
    )
  end

  defp validate_contract(@candidate_diff_row, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "candidate_diff_row.v1")
    |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_row("$", artifact)
  end

  defp validate_contract(@freshness_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.FreshnessReportContracts.validate_optional("$", artifact)
  end

  defp validate_contract(@invalidated_candidate, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "invalidated_candidate.v1")
    |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_invalidated_candidate(
      "$",
      artifact
    )
  end

  defp validate_contract(@refresh_budget_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.RefreshBudgetReportContracts.validate("$", artifact)
  end

  defp validate_contract(@refreshed_window, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "refreshed_window.v1")
    |> OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_refreshed_window(
      "$",
      artifact
    )
  end

  defp validate_contract(@remaining_horizon, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_remaining_horizon(
      "$",
      artifact
    )
  end

  defp validate_contract(@source_window_lineage, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "source_window_lineage.v1")
    |> OrbitalDynamics.Schema.CandidateDiffContracts.validate_source_window_lineage(
      "$",
      artifact
    )
  end

  defp validate_contract(@validation_reference_fixture_report, contract, artifact) do
    OrbitalDynamics.Schema.ValidationReferenceContracts.validate_fixture_report(
      [],
      "$",
      artifact,
      contract
    )
  end

  defp validate_contract(@validation_reference_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReferenceContracts.validate_report("$", artifact)
  end

  defp validate_contract(@validation_check, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReferenceContracts.validate_check("$", artifact)
  end

  defp validate_contract(@validation_record, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationRecordContracts.validate("$", artifact)
  end

  defp validate_contract(@model_acceptance_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.validate_model_acceptance_report(
      "$",
      artifact,
      model_acceptance_report_model_limits()
    )
  end

  defp validate_contract(@validation_safety_case_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.validate_validation_safety_case_summary(
      "$",
      artifact,
      model_acceptance_report_model_limits()
    )
  end

  defp validate_contract(@campaign_plan, contract, artifact) do
    OrbitalDynamics.Schema.CampaignPlanContracts.validate(
      [],
      artifact,
      contract["required_fields"],
      campaign_plan_contract_callbacks()
    )
  end

  defp validate_contract(@campaign_repair, contract, artifact) do
    OrbitalDynamics.Schema.CampaignRepairContracts.validate(
      [],
      artifact,
      contract["required_fields"],
      campaign_repair_contract_callbacks()
    )
  end

  defp validate_contract(@campaign_strategy, contract, artifact) do
    OrbitalDynamics.Schema.CampaignStrategyContracts.validate(
      [],
      artifact,
      contract["required_fields"],
      &OrbitalDynamics.Schema.OperationalFeedbackContracts.validate/3,
      &validate_branch/3,
      &validate_recommendation/3,
      &validate_optional_branch_comparison_report/2,
      &validate_optional_ranking_comparison_report/2,
      &validate_optional_operator_review_package/2
    )
  end

  defp validate_contract(_name, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
  end

  defp contact_allocation_report_domain_callbacks do
    [
      validate_optional_station_calendar_report:
        &StationReservationValidation.validate_optional_calendar_report/2,
      validate_optional_contact_filter_report:
        &ContactReportValidation.validate_optional_filter_report/2,
      validate_optional_contact_contention_report:
        &ContactReportValidation.validate_optional_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &ContactReportValidation.validate_optional_contention_resolution_report/2,
      validate_contact_allocation_report_counts: &validate_contact_allocation_report_counts/3,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_optional_actual_data_rate_throughput_derivation:
        &OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation/4,
      validate_contact_contention_deferred_priority:
        &OrbitalDynamics.Schema.ContactContentionReportContracts.validate_deferred_priority/3,
      validate_priority_field_evidence_counts:
        &OrbitalDynamics.Schema.PriorityOverrideContracts.validate_field_evidence_counts/3,
      validate_override_count_matches_ids:
        &OrbitalDynamics.Schema.PriorityOverrideContracts.validate_count_matches_ids/5,
      validate_station_calendar_contact_counts:
        &OrbitalDynamics.Schema.StationCalendarContactCountContracts.validate/3
    ]
  end

  defp validate_nested_execution_report(execution_report),
    do:
      validate_contract(
        @execution_report,
        registry_contract!(@execution_report),
        execution_report
      )

  defp campaign_plan_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_contact_contention_report:
        &ContactReportValidation.validate_optional_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &ContactReportValidation.validate_optional_contention_resolution_report/2,
      validate_optional_station_calendar_report:
        &StationReservationValidation.validate_optional_calendar_report/2,
      validate_optional_objective_tradeoff_report: &validate_optional_objective_tradeoff_report/2,
      validate_optional_objective_satisfaction_report:
        &validate_optional_objective_satisfaction_report/2,
      validate_optional_operational_timeline_report:
        &validate_optional_operational_timeline_report/2,
      validate_optional_timeline_transition_application_report:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_report/3,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      validate_optional_operational_readiness_report:
        &OperationalReadinessValidation.validate_optional_operational_readiness_report/3,
      validate_optional_quality_gate_report:
        &OperationalReadinessValidation.validate_optional_quality_gate_report/3,
      validate_optional_optimizer_contract: &validate_optional_optimizer_contract/2,
      validate_optional_link_capacity_report: &validate_optional_link_capacity_report/2,
      validate_optional_resource_projection_report:
        &ResourceValidation.validate_optional_resource_projection_report/3,
      validate_optional_resource_projection_flow_summary:
        &ResourceValidation.validate_optional_resource_projection_flow_summary/3,
      validate_optional_timeline_activity_precondition_summaries:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summaries/3,
      validate_optional_timeline_integrity_report:
        &TimelineSourceValidation.validate_optional_timeline_integrity_report/3,
      validate_optional_resource_filter_report:
        &ResourceValidation.validate_optional_resource_filter_report/3,
      validate_optional_score_term_report: &validate_optional_score_term_report/2,
      validate_rows: &validate_rows/4,
      validate_activity: &OrbitalDynamics.Schema.ActivityContracts.validate/3,
      validate_proposed_contact: &OrbitalDynamics.Schema.ProposedContactContracts.validate/3,
      validate_contact_intent: &OrbitalDynamics.Schema.ContactIntentContracts.validate/3,
      validate_optional_contact_filter_report:
        &ContactReportValidation.validate_optional_filter_report/2
    ]
  end

  defp campaign_repair_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_one_of: &expect_one_of/5,
      validate_realized_state_snapshot:
        &OrbitalDynamics.Schema.RealizedStateSnapshotContracts.validate/3,
      validate_rows: &validate_rows/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_activity: &OrbitalDynamics.Schema.ActivityContracts.validate/3,
      validate_contact_intent: &OrbitalDynamics.Schema.ContactIntentContracts.validate/3,
      validate_resource_summary: &OrbitalDynamics.Schema.ResourceSummaryContracts.validate/3,
      validate_optional_contact_filter_report:
        &ContactReportValidation.validate_optional_filter_report/3,
      validate_optional_resource_filter_report:
        &ResourceValidation.validate_optional_resource_filter_report/3,
      validate_optional_resource_projection_report:
        &ResourceValidation.validate_optional_resource_projection_report/3,
      validate_optional_operational_timeline_report:
        &validate_optional_operational_timeline_report/2,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      validate_optional_objective_tradeoff_report: &validate_optional_objective_tradeoff_report/2,
      validate_optional_score_term_report: &validate_optional_score_term_report/2,
      validate_optional_link_capacity_report: &validate_optional_link_capacity_report/2,
      validate_optional_candidate_diff_report:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report/3,
      validate_optional_candidate_rejection_report:
        &CandidateRejectionValidation.validate_optional_report/3,
      validate_optional_freshness_report:
        &OrbitalDynamics.Schema.FreshnessReportContracts.validate_optional/3,
      validate_optional_station_calendar_report:
        &StationReservationValidation.validate_optional_calendar_report/3,
      validate_plan_delta: &OrbitalDynamics.Schema.PlanDeltaContracts.validate/3,
      validate_approval_requirement: &PolicyValidation.validate_approval_requirement/3,
      validate_policy_decision: &PolicyValidation.validate_decision/3,
      require_nested: &require_nested/4,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      expect_field_equals_with_message: &expect_field_equals/6
    ]
  end

  defp validate_optional_link_capacity_report(issues, nil), do: issues

  defp validate_optional_link_capacity_report(issues, %{} = report) do
    validate_contract(@link_capacity_report, registry_contract!(@link_capacity_report), report) ++
      issues
  end

  defp validate_optional_link_capacity_report(issues, _report),
    do: [error("$.link_capacity_report", "must be an object") | issues]

  defp validate_optional_contact_allocation_report(issues, value),
    do:
      ContactAllocationValidation.validate_optional_report(
        issues,
        value,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_report(issues, path, report),
    do:
      ContactAllocationValidation.validate_report(
        issues,
        path,
        report,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_row(issues, path, row),
    do:
      ContactAllocationValidation.validate_row(
        issues,
        path,
        row,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_capacity_pack_group(issues, path, group),
    do:
      ContactAllocationValidation.validate_capacity_pack_group(
        issues,
        path,
        group,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_optional_objective_tradeoff_report(issues, report),
    do:
      DecisionSupportValidation.validate_optional_objective_tradeoff_report(
        issues,
        report,
        &validate_registered_contract(@objective_tradeoff_report, &1)
      )

  defp validate_optional_objective_satisfaction_report(issues, report),
    do:
      DecisionSupportValidation.validate_optional_objective_satisfaction_report(
        issues,
        report,
        &validate_registered_contract(@objective_satisfaction_report, &1)
      )

  defp validate_registered_contract(name, artifact),
    do: validate_contract(name, registry_contract!(name), artifact)

  defp validate_optional_operational_timeline_report(issues, report),
    do:
      OperationalTimelineValidation.validate_optional_report(
        issues,
        report,
        &validate_registered_contract(@operational_timeline_report, &1)
      )

  defp validate_optional_operator_review_package(issues, package),
    do:
      OperatorReviewValidation.validate_optional_package(
        issues,
        package,
        &validate_registered_contract(@operator_review_package, &1)
      )

  defp validate_operational_timeline_row(issues, path, row),
    do:
      OperationalTimelineValidation.validate_row(
        issues,
        path,
        row,
        validate_optional_timeline_preconditions:
          &TimelineContextValidation.validate_optional_timeline_preconditions/4,
        validate_optional_activity_context:
          &TimelineContextValidation.validate_optional_activity_context/4,
        validate_timeline_identity: &TimelineContextValidation.validate_timeline_identity/3
      )

  defp validate_optional_branch_comparison_report(issues, value) do
    DecisionSupportValidation.validate_optional_branch_comparison_report(
      issues,
      value,
      fn report ->
        validate_contract(
          @branch_comparison_report,
          registry_contract!(@branch_comparison_report),
          report
        )
      end
    )
  end

  defp validate_optional_ranking_comparison_report(issues, value) do
    DecisionSupportValidation.validate_optional_ranking_comparison_report(
      issues,
      value,
      fn report ->
        validate_contract(
          @ranking_comparison_report,
          registry_contract!(@ranking_comparison_report),
          report
        )
      end
    )
  end

  defp validate_optional_optimizer_contract(issues, value) do
    DecisionSupportValidation.validate_optional_optimizer_contract(
      issues,
      value,
      fn contract ->
        validate_contract(@optimizer_contract, registry_contract!(@optimizer_contract), contract)
      end
    )
  end

  defp validate_optional_score_term_report(issues, value) do
    DecisionSupportValidation.validate_optional_score_term_report(
      issues,
      value,
      fn report ->
        validate_contract(@score_term_report, registry_contract!(@score_term_report), report)
      end
    )
  end

  defp validate_contact_allocation_report_counts(issues, path, report),
    do:
      ContactAllocationValidation.validate_counts(
        issues,
        path,
        report,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_summary(issues, path, summary),
    do:
      ContactAllocationValidation.validate_summary(
        issues,
        path,
        summary,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_reservation_conflict_summary(issues, path, summary),
    do:
      ContactAllocationValidation.validate_reservation_conflict_summary(
        issues,
        path,
        summary,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_station_pressure_summary(issues, path, summary),
    do:
      ContactAllocationValidation.validate_station_pressure_summary(
        issues,
        path,
        summary,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_capacity_pack_summary(issues, path, summary),
    do:
      ContactAllocationValidation.validate_capacity_pack_summary(
        issues,
        path,
        summary,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_provider_reservation_request_summary(issues, path, summary),
    do:
      ContactAllocationValidation.validate_provider_reservation_request_summary(
        issues,
        path,
        summary,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_contact_allocation_duplicate_evidence(issues, path, row),
    do:
      ContactAllocationValidation.validate_duplicate_evidence(
        issues,
        path,
        row,
        contact_allocation_report_domain_callbacks()
      )

  defp validate_cadence_import_manifest(issues, path, manifest) do
    OrbitalDynamics.Schema.CadenceImportManifestContracts.validate(
      issues,
      path,
      manifest,
      cadence_import_supported_sources(),
      cadence_import_manifest_model_limits(),
      @cadence_import_manifest_scalar_count_fields,
      &validate_cadence_import_row/3,
      &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_expiration_summary/3,
      &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups/3
    )
  end

  defp cadence_source_review_row_contract_callbacks do
    OrbitalDynamics.Schema.CadenceSourceReviewRowCallbacks.build(
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_probability: &expect_optional_probability/4,
      validate_selected_timeline_integrity_fields:
        &TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3,
      validate_stable_ids: &validate_stable_ids/4,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_policy_decision_evidence:
        &PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation: &PolicyValidation.validate_optional_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &CandidateRejectionValidation.validate_optional_source_row/3,
      validate_optional_timeline_dependency_impact_source_row:
        &TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_branch_comparison_source_row:
        &DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_operational_readiness_resource_context:
        &OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_operator_review_row_links: &OperatorReviewValidation.validate_row_links/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_optional_timeline_link:
        &TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_identity:
        &TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_activity_state_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_activity_context:
        &TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_timeline_diff_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      error: &error/2
    )
  end

  defp validate_cadence_import_row(issues, path, row) do
    capability = cadence_import_capability()

    issues
    |> OrbitalDynamics.Schema.CadenceImportRowContracts.validate_import_station_and_target_fields(
      path,
      row,
      capability,
      cadence_import_row_contract_callbacks()
    )
    |> OrbitalDynamics.Schema.CadenceImportRowContracts.validate_source_context_fields(
      path,
      row,
      cadence_import_row_contract_callbacks()
    )
    |> OrbitalDynamics.Schema.CadenceImportRowContracts.validate_handoff_and_timeline_source_fields(
      path,
      row,
      cadence_import_row_contract_callbacks()
    )
  end

  defp cadence_import_row_contract_callbacks do
    OrbitalDynamics.Schema.CadenceImportRowCallbacks.build(
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_optional_policy_decision_evidence:
        &PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation: &PolicyValidation.validate_optional_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &CandidateRejectionValidation.validate_optional_source_row/3,
      validate_optional_branch_comparison_source_row:
        &DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_nested_id_match: &validate_nested_id_match/7,
      validate_optional_activity_context:
        &TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_timeline_link:
        &TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_identity:
        &TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_cadence_source_review_row: &validate_cadence_source_review_row/3,
      validate_operational_readiness_resource_context:
        &OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_operational_readiness_cadence_import_context:
        &OperationalReadinessValidation.validate_operational_readiness_cadence_import_context/3
    )
    |> Keyword.merge(cadence_import_row_handoff_contract_callbacks())
  end

  defp cadence_import_row_handoff_contract_callbacks do
    OrbitalDynamics.Schema.CadenceImportRowHandoffCallbacks.build(
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_operator_review_row_links: &OperatorReviewValidation.validate_row_links/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_activity_state_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_dependency_impact_source_row:
        &TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_timeline_diff_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_integrity_source_row:
        &TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_preservation_source_row:
        &TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_transition_application_row:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_selected_timeline_integrity_fields:
        &TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3
    )
  end

  defp validate_cadence_source_review_row(issues, path, row) do
    OrbitalDynamics.Schema.CadenceSourceReviewRowContracts.validate(
      issues,
      path,
      row,
      cadence_source_review_row_contract_callbacks()
    )
  end

  defp validate_contact_allocation_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_fields(
      issues,
      path,
      row,
      &validate_contact_allocation_duplicate_evidence/3
    )
  end

  defp validate_branch(issues, path, branch) do
    OrbitalDynamics.Schema.StrategyBranchContracts.validate(
      issues,
      path,
      branch,
      &OrbitalDynamics.Schema.BranchEventContracts.validate_event/3,
      &ResourceValidation.validate_optional_resource_projection_report/3,
      &PolicyValidation.validate_decision/3,
      &PolicyValidation.validate_approval_requirement/3
    )
  end

  defp validate_recommendation(issues, path, recommendation) do
    OrbitalDynamics.Schema.StrategyRecommendationContracts.validate(
      issues,
      path,
      recommendation,
      &OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields/3,
      &OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate/3
    )
  end

  defp validate_operator_review_package(issues, path, package),
    do:
      OperatorReviewValidation.validate_package(
        issues,
        path,
        package,
        operator_review_source_artifact_types(),
        operator_review_package_model_limits(),
        operator_review_package_contract_callbacks()
      )

  defp operator_review_package_contract_callbacks do
    [
      validate_contact_allocation_expiration_handoff_summary:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_expiration_summary/3,
      validate_quality_gate_handoff_summary:
        &OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_summary/3,
      validate_operator_review_row: &validate_operator_review_row/3,
      validate_suppression_duplicate_handoff_groups:
        &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups/3
    ]
  end

  defp validate_operator_review_row(issues, path, row),
    do:
      OperatorReviewValidation.validate_row(
        issues,
        path,
        row,
        operator_review_types(),
        station_calendar_provider_counteroffer_negotiation_states(),
        operator_review_row_domain_callbacks()
      )

  defp operator_review_row_domain_callbacks do
    OrbitalDynamics.Schema.OperatorReviewRowCallbacks.build(
      validate_optional_activity_context:
        &TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_protection_decision:
        &TimelineContextValidation.validate_optional_protection_decision/4,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_optional_actual_data_rate_throughput_derivation:
        &OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation/4,
      validate_optional_lifecycle_transition:
        &TimelineContextValidation.validate_optional_lifecycle_transition/4,
      validate_optional_branch_comparison_source_row:
        &DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_optional_policy_decision_evidence:
        &PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation: &PolicyValidation.validate_optional_escalation/4,
      validate_optional_timeline_dependency_impact_source_row:
        &TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_source_evidence_fields: &SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_selected_timeline_integrity_fields:
        &TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3,
      validate_optional_timeline_diff_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_activity_state_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_timeline_identity:
        &TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_optional_timeline_link:
        &TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_operational_readiness_resource_context:
        &OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_operator_review_row_links: &OperatorReviewValidation.validate_row_links/3
    )
  end
end
