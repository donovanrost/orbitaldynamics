defmodule OrbitalDynamics.Schema do
  @moduledoc """
  Executable schema contracts for public OrbitalDynamics artifacts.

  This module is intentionally lighter than full JSON Schema. It gives the
  current campaign-planning artifacts a stable, testable contract boundary while
  the artifact shapes are still maturing.
  """

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_nested_id_match: 7,
      validate_optional_stable_id_list: 4,
      validate_optional_stable_ids: 4,
      validate_stable_id: 3,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_field_matches_list_count: 6,
      expect_number: 4,
      expect_non_negative_integer: 4,
      expect_number_vector: 3,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_field_equals: 6,
      expect_optional_list: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_number_or_number_list: 4,
      expect_optional_number_or_string: 4,
      expect_optional_number_vector: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_probability_range: 4,
      expect_type: 5,
      require_fields: 4,
      require_nested: 4,
      validate_interval: 3,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_integer_list_items: 4,
      validate_number_list_items: 4,
      validate_optional_exact_model_limits: 5,
      validate_optional_string_lists: 4,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [
      expect_list_count_equals: 5,
      validate_numeric_map: 3,
      validate_optional_rows: 4,
      validate_optional_string_list: 4,
      validate_rows: 4
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
  @operator_review_package_required_scalar_count_fields [
    "review_count",
    "approval_requirement_count",
    "contention_recommendation_count",
    "realized_feedback_count",
    "warning_count",
    "risk_count",
    "recommendation_count"
  ]
  @operator_review_package_optional_scalar_count_fields [
    "plan_delta_count",
    "timeline_protection_count",
    "policy_escalation_count",
    "contact_suppression_count",
    "resource_projection_review_count",
    "command_window_count",
    "station_calendar_review_count",
    "station_reservation_review_count",
    "link_capacity_review_count",
    "contention_review_count",
    "resource_suppression_count",
    "contact_allocation_review_count",
    "contact_allocation_capacity_pack_review_count",
    "contact_intent_review_count",
    "candidate_rejection_review_count",
    "provider_counteroffer_review_count",
    "candidate_diff_review_count",
    "freshness_review_count",
    "refresh_budget_review_count",
    "model_acceptance_review_count",
    "validation_safety_case_review_count",
    "timeline_diff_count",
    "maneuver_review_count",
    "score_term_review_count",
    "objective_tradeoff_review_count",
    "constraint_review_count",
    "objective_satisfaction_review_count",
    "schema_validation_review_count",
    "execution_review_count",
    "operational_timeline_count",
    "pareto_frontier_count",
    "tradeoff_count",
    "ranking_comparison_count",
    "operational_readiness_review_count",
    "quality_gate_review_count"
  ]
  @operator_review_package_scalar_count_fields @operator_review_package_required_scalar_count_fields ++
                                                 @operator_review_package_optional_scalar_count_fields
  @strategy_recommendation_pressure_handoff_string_list_fields [
    "operational_readiness_report_ids",
    "operational_readiness_source_artifact_types",
    "operational_readiness_source_artifact_ids",
    "operational_readiness_levels",
    "operational_readiness_import_classifications",
    "operational_readiness_statuses",
    "operational_readiness_gate_ids",
    "operational_readiness_gate_statuses",
    "operational_readiness_gate_classifications",
    "operational_readiness_required_operator_actions",
    "operational_readiness_feedback_sources",
    "operational_readiness_feedback_scopes",
    "operational_readiness_feedback_keys",
    "operational_readiness_trust_boundaries",
    "quality_gate_report_ids",
    "quality_gate_source_artifact_types",
    "quality_gate_source_artifact_ids",
    "quality_gate_source_readiness_report_ids",
    "quality_gate_readiness_levels",
    "quality_gate_import_classifications",
    "quality_gate_pressure_statuses",
    "quality_gate_ids",
    "quality_gate_statuses",
    "quality_gate_classifications",
    "quality_gate_required_operator_actions",
    "quality_gate_feedback_sources",
    "quality_gate_feedback_scopes",
    "quality_gate_feedback_keys",
    "quality_gate_trust_boundaries",
    "quality_gate_resource_availability_reason_ids",
    "quality_gate_unavailable_resource_reason_ids"
  ]
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
  @branch_comparison_row_count_fields [
    "approval_requirement_count",
    "branch_event_count",
    "branch_requires_operator_review_count",
    "candidate_activity_count",
    "coverage_observed_target_count",
    "priority_commitment_missed_target_count",
    "priority_commitment_required_target_count",
    "priority_commitment_satisfied_target_count",
    "repair_delta_count",
    "repair_link_contact_count",
    "repair_link_selected_contact_count",
    "repair_score_term_count",
    "resource_projection_antenna_unavailable_count",
    "resource_projection_degraded_payload_unavailable_count",
    "resource_projection_flow_count",
    "resource_projection_payload_unavailable_count",
    "resource_projection_spacecraft_count",
    "resource_projection_unavailable_spacecraft_count",
    "resource_projection_warning_count",
    "revisit_count",
    "risk_count"
  ]
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
  @policy_context_string_fields [
    "action",
    "activity_type",
    "requirement_type",
    "risk_type",
    "risk_reason",
    "event_type",
    "feasibility_status",
    "direction",
    "spacecraft_id",
    "target_id",
    "ground_station_id",
    "station_id",
    "station_availability",
    "station_contention_status",
    "station_reservation_id",
    "station_reserved_by",
    "station_reservation_status",
    "station_reservation_match_status",
    "station_calendar_reservation_status",
    "station_calendar_ambiguous_entry_id",
    "station_calendar_trust_boundary_status",
    "station_calendar_direction",
    "resource_scope",
    "selection_reason",
    "selected_priority_source",
    "priority_field_without_numeric_evidence",
    "resolution_status",
    "resolution_issue",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "station_calendar_reservation_id",
    "required_operator_action",
    "operator_action_reason",
    "allocation_status",
    "effective_allocation_status",
    "allocation_reason",
    "suppressed_reason",
    "resource_blocking_dimension",
    "transition_decision",
    "application_status",
    "planned_protection_decision",
    "planned_protection_category",
    "timeline_integrity_status",
    "timeline_integrity_issue_type",
    "source_timeline_integrity_status",
    "source_timeline_integrity_issue_type",
    "replacement_timeline_integrity_status",
    "replacement_timeline_integrity_issue_type",
    "source_protection_decision",
    "source_protection_category",
    "replacement_protection_decision",
    "replacement_protection_category",
    "review_queue",
    "review_queue_key",
    "cadence_import_status",
    "status",
    "approval_status",
    "policy_classification",
    "contact_success_factor_source",
    "contact_result",
    "command_success_factor_source",
    "command_result",
    "observation_success_factor_source",
    "observation_result",
    "maneuver_success_factor_source",
    "maneuver_result",
    "resource_pressure_status",
    "resource_pressure_type",
    "resource_source_quality",
    "resource_trust_boundary",
    "resource_trust_boundary_status",
    "first_resource_pressure_kind",
    "feedback_source",
    "feedback_scope",
    "trust_boundary",
    "source_event_type"
  ]
  @policy_context_string_array_fields [
    "actions",
    "activity_types",
    "requirement_types",
    "risk_types",
    "event_types",
    "directions",
    "spacecraft_ids",
    "target_ids",
    "ground_station_ids",
    "station_ids",
    "station_availabilities",
    "station_contention_statuses",
    "station_reservation_ids",
    "station_reserved_bys",
    "station_reservation_statuses",
    "station_reservation_match_statuses",
    "station_calendar_reserved_bys",
    "station_calendar_reservation_statuses",
    "station_calendar_ambiguous_entry_ids",
    "station_calendar_trust_boundary_statuses",
    "station_calendar_directions",
    "resource_scopes",
    "selection_reasons",
    "selected_priority_sources",
    "priority_fields_without_numeric_evidence",
    "resolution_statuses",
    "resolution_issues",
    "station_calendar_provider_ids",
    "station_calendar_provider_entry_ids",
    "station_calendar_reservation_ids",
    "required_operator_actions",
    "operator_action_reasons",
    "allocation_statuses",
    "effective_allocation_statuses",
    "allocation_reasons",
    "suppressed_reasons",
    "resource_blocking_dimensions",
    "transition_decisions",
    "application_statuses",
    "planned_protection_decisions",
    "planned_protection_categories",
    "timeline_integrity_statuses",
    "timeline_integrity_issue_types",
    "source_timeline_integrity_statuses",
    "source_timeline_integrity_issue_types",
    "replacement_timeline_integrity_statuses",
    "replacement_timeline_integrity_issue_types",
    "source_protection_decisions",
    "source_protection_categories",
    "replacement_protection_decisions",
    "replacement_protection_categories",
    "review_queues",
    "review_queue_keys",
    "cadence_import_statuses",
    "statuses",
    "approval_statuses",
    "policy_classifications",
    "contact_results",
    "command_results",
    "observation_results",
    "maneuver_results",
    "resource_pressure_statuses",
    "resource_pressure_types",
    "resource_source_qualities",
    "resource_trust_boundaries",
    "resource_trust_boundary_statuses",
    "first_resource_pressure_kinds",
    "feedback_sources",
    "feedback_scopes",
    "trust_boundaries",
    "source_event_types"
  ]
  @policy_context_string_or_array_fields ["station_calendar_reserved_by"]
  @policy_context_number_fields [
    "capacity_fraction",
    "station_reservation_expires_at_s",
    "required_capacity_fraction",
    "actual_completion_fraction",
    "actual_downlink_completion_ratio",
    "contention_window_s",
    "total_contact_duration_s",
    "overlap_duration_s",
    "max_concurrent_contacts",
    "overlap_contact_pair_count",
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "maneuver_success_factor"
  ]
  @policy_context_integer_fields [
    "station_calendar_ambiguous_entry_count",
    "priority_fields_without_numeric_evidence_count"
  ]
  @policy_context_non_negative_integer_fields [
    "max_concurrent_contacts",
    "overlap_contact_pair_count",
    "station_calendar_ambiguous_entry_count",
    "priority_fields_without_numeric_evidence_count"
  ]
  @policy_context_boolean_fields [
    "station_calendar_entry_ambiguous",
    "locked",
    "degraded",
    "payload_available",
    "antenna_available",
    "contact_success",
    "command_success"
  ]
  @policy_action_rule_number_fields [
    "capacity_fraction_min",
    "capacity_fraction_max",
    "actual_completion_fraction_min",
    "actual_completion_fraction_max",
    "contact_success_factor_min",
    "contact_success_factor_max",
    "command_success_factor_min",
    "command_success_factor_max",
    "observation_success_factor_min",
    "observation_success_factor_max",
    "maneuver_success_factor_min",
    "maneuver_success_factor_max",
    "contention_window_s_min",
    "total_contact_duration_s_min",
    "overlap_duration_s_min"
  ]
  @policy_action_rule_integer_fields [
    "station_calendar_ambiguous_entry_count_min",
    "station_calendar_ambiguous_entry_count_max",
    "max_concurrent_contacts_min",
    "overlap_contact_pair_count_min",
    "priority_fields_without_numeric_evidence_count_min"
  ]

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
    timeline_string_assumptions_json_schema(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "lifecycle_lock_approval_and_executed_preservation_review"
    })
  end

  defp timeline_preservation_assumptions_json_schema(@timeline_preservation_status) do
    timeline_string_assumptions_json_schema(%{
      "execution_boundary" => "artifact_only_no_schedule_mutation",
      "scope" => "single_activity_lifecycle_preservation_preflight"
    })
  end

  defp focused_json_schema_property(field, contract_name, contract, property_field?, property) do
    if property_field?.(field) do
      property.(field)
    else
      default_json_schema_property(field, contract_name, contract)
    end
  end

  defp json_schema_property(field, @activity_template = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ActivityTemplateJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ActivityTemplateJsonSchema.property_fun_from_context(
        schema_contract: @activity_template,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @policy_bundle = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.PolicyBundleJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.PolicyBundleJsonSchema.property_fun_from_context(
        policy_action_rule_schema: &policy_action_rule_json_schema/0,
        policy_model_limits: &policy_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @policy_decision = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.PolicyDecisionJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.PolicyDecisionJsonSchema.property_fun_from_context(
        policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
        policy_escalation_schema: &policy_escalation_json_schema/0,
        policy_model_limits: &policy_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @capability_catalog = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CapabilityCatalogJsonSchema.property_field?/1,
      &OrbitalDynamics.Schema.CapabilityCatalogJsonSchema.property/1
    )
  end

  defp json_schema_property(field, @accepted_planning_state = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.AcceptedStateJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.AcceptedStateJsonSchema.property_fun_from_context(
        spacecraft_state_estimate_schema: &spacecraft_state_estimate_json_schema/0,
        maneuver_execution_delta_schema: &maneuver_execution_delta_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @manifest_field_reference = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ManifestFieldReferenceJsonSchema.property_field?/1,
      &OrbitalDynamics.Schema.ManifestFieldReferenceJsonSchema.property/1
    )
  end

  defp json_schema_property(field, @candidate_diff_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CandidateDiffJsonSchema.report_property_field?/1,
      OrbitalDynamics.Schema.CandidateDiffJsonSchema.report_property_fun_from_context(
        source_window_lineage_schema: fn -> source_window_lineage_json_schema() end,
        stable_id_pattern: @stable_id_pattern,
        model_limits: fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
        candidate_diff_row_schema: fn -> candidate_diff_row_json_schema() end,
        invalidated_candidate_schema: fn -> invalidated_candidate_json_schema() end
      )
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@candidate_diff_row, @invalidated_candidate, @source_window_lineage] do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CandidateDiffJsonSchema.family_property_field?(&1, contract_name),
      OrbitalDynamics.Schema.CandidateDiffJsonSchema.family_property_fun_from_context(
        contract_name: contract_name,
        stable_id_pattern: @stable_id_pattern,
        scoped_context_properties: fn ->
          candidate_refresh_scoped_context_json_schema_properties()
        end
      )
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @freshness_report,
              @refresh_budget_report,
              @refreshed_window,
              @remaining_horizon
            ] do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.auxiliary_report_property_field?(
        &1,
        contract_name
      ),
      OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.auxiliary_report_property_fun_from_context(
        contract_name: contract_name,
        stable_id_pattern: @stable_id_pattern,
        model_limits: fn -> OrbitalDynamics.CandidateRefresh.model_limits() end
      )
    )
  end

  defp json_schema_property(field, @campaign_plan = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CampaignPlanJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.CampaignPlanJsonSchema.property_fun_from_context(
        proposed_contact_schema: &proposed_contact_row_json_schema/0,
        campaign_activity_schema: &campaign_activity_json_schema/0,
        contact_intent_schema: &contact_intent_row_json_schema/0,
        ranked_timeline_schema: &ranked_timeline_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @campaign_repair = contract_name, contract) do
    timeline_transition_contract = registry_contract!(@timeline_transition_application_report)

    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CampaignRepairJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.CampaignRepairJsonSchema.property_fun_from_context(
        planned_activity_schema: &planned_activity_json_schema/0,
        candidate_activity_schema: &candidate_activity_json_schema/0,
        plan_delta_schema: &plan_delta_json_schema/0,
        approval_requirement_schema: &approval_requirement_json_schema/0,
        policy_action_rule_schema: &policy_action_rule_json_schema/0,
        policy_decision_schema: &policy_decision_json_schema/0,
        timeline_transition_required_fields: timeline_transition_contract["required_fields"],
        timeline_transition_optional_fields: timeline_transition_contract["optional_fields"],
        timeline_transition_property_fun: fn transition_field ->
          json_schema_property(
            transition_field,
            @timeline_transition_application_report,
            timeline_transition_contract
          )
        end
      )
    )
  end

  defp json_schema_property(field, @realized_state_snapshot = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema.property_fun_from_context(
        realized_activity_schema: &realized_activity_json_schema/0,
        realized_spacecraft_state_schema: &realized_spacecraft_state_json_schema/0,
        metadata_schema: &realized_state_snapshot_metadata_json_schema/0,
        model_limits: &OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @timeline_feedback_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineFeedbackReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineFeedbackReportJsonSchema.property_fun_from_context(
        row_schema: &timeline_feedback_row_json_schema/0,
        model_limits: &timeline_feedback_report_model_limits/0,
        capability: &OrbitalDynamics.TimelineFeedback.capabilities/0,
        operational_feedback_schema: &operational_feedback_json_schema/0,
        operational_feedback_provenance_schema:
          &timeline_feedback_operational_feedback_provenance_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @timeline_integrity_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineIntegrityReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineIntegrityReportJsonSchema.property_fun_from_context(
        row_schema: &operational_timeline_row_json_schema/0,
        schema_contract: @timeline_integrity_report,
        stable_id_pattern: @stable_id_pattern,
        timeline_integrity_issue_types: &timeline_integrity_issue_types/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        model_limits: &timeline_report_model_limits/0
      )
    )
  end

  defp json_schema_property(
         field,
         @timeline_dependency_impact_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineDependencyImpactSummaryJsonSchema.property_fun_from_context(
        schema_contract: @timeline_dependency_impact_summary,
        stable_id_array_schema: &stable_id_array_schema/0,
        row_schema: &timeline_dependency_impact_row_json_schema/0,
        model_limits: &timeline_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @timeline_publication_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelinePublicationSummaryJsonSchema.property_fun_from_context(
        schema_contract: @timeline_publication_summary,
        stable_id_pattern: @stable_id_pattern,
        timeline_diff_summary_source_schema: &timeline_diff_summary_source_json_schema/0,
        timeline_dependency_impact_summary_source_schema:
          &timeline_dependency_impact_summary_source_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        model_limits: &timeline_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @timeline_activity_state = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.property_fun_from_context(
        row_schema: &timeline_feedback_row_json_schema/0,
        schema_contract: @timeline_activity_state,
        capability: &OrbitalDynamics.TimelineFeedback.capabilities/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        string_array_schema: &string_array_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        assumptions_schema: fn ->
          timeline_activity_state_assumptions_json_schema([
            "artifact_only",
            "no_schedule_mutation",
            "no_command_execution"
          ])
        end,
        model_limits: &timeline_feedback_report_model_limits/0
      )
    )
  end

  defp json_schema_property(
         field,
         @timeline_activity_precondition_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryJsonSchema.property_fun_from_context(
        schema_contract: @timeline_activity_precondition_summary,
        model_limits: &timeline_report_model_limits/0,
        precondition_statuses: &timeline_activity_precondition_statuses/0,
        string_array_schema: &string_array_schema/0,
        precondition_schema: &timeline_precondition_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        stable_id_array_schema: &stable_id_array_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @execution_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ExecutionReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ExecutionReportJsonSchema.property_fun_from_context(
        schema_contract: @execution_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @result_artifact = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResultArtifactJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResultArtifactJsonSchema.property_fun_from_context(
        schema_version: 1,
        stable_id_pattern: @stable_id_pattern,
        execution_report_contract: @execution_report,
        embedded_contract_schema: &embedded_contract_json_schema/1
      )
    )
  end

  defp json_schema_property(field, @resource_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResourceSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResourceSummaryJsonSchema.property_fun_from_context(
        schema_contract: @resource_summary,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @contact_intent = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactIntentJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactIntentJsonSchema.property_fun_from_context(
        approval_requirement_schema: &approval_requirement_json_schema/0,
        policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
        policy_decision_schema: &policy_decision_json_schema/0,
        model_limits: &contact_intent_model_limits/0,
        timeline_integrity_issue_types: &timeline_integrity_issue_types/0
      )
    )
  end

  defp json_schema_property(field, @contact_intent_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactIntentSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactIntentSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_intent_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_intent_model_limits/0,
        assumptions_schema: &contact_intent_summary_assumptions_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @approval_requirement = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ApprovalRequirementJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ApprovalRequirementJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        rule_match_schema: &policy_decision_rule_match_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        policy_escalation_schema: &policy_escalation_json_schema/0
      )
    )
  end

  defp json_schema_property(
         field,
         @validation_reference_fixture_report = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ValidationJsonSchema.reference_fixture_report_property_field?/1,
      OrbitalDynamics.Schema.ValidationJsonSchema.reference_fixture_report_property_fun_from_context(
        schema_contract: @validation_reference_fixture_report,
        reference_report_schema: &validation_reference_report_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @validation_reference_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ValidationJsonSchema.reference_report_property_field?/1,
      OrbitalDynamics.Schema.ValidationJsonSchema.reference_report_property_fun_from_context(
        schema_contract: @validation_reference_report,
        stable_id_pattern: @stable_id_pattern,
        validation_check_schema: &validation_check_json_schema/0,
        validation_level_schema: &validation_level_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @validation_record = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ValidationJsonSchema.record_property_field?/1,
      OrbitalDynamics.Schema.ValidationJsonSchema.record_property_fun_from_context(
        schema_contract: @validation_record,
        stable_id_pattern: @stable_id_pattern,
        validation_level_schema: &validation_level_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @model_acceptance_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ModelAcceptanceReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ModelAcceptanceReportJsonSchema.property_fun_from_context(
        intended_uses: fn -> OrbitalDynamics.Validation.capabilities().intended_uses end,
        acceptance_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().acceptance_statuses
        end,
        row_statuses: fn -> OrbitalDynamics.Validation.capabilities().row_statuses end,
        model_limits: &model_acceptance_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern,
        validation_record_schema: &validation_record_json_schema/0,
        row_schema: &model_acceptance_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @validation_safety_case_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ValidationSafetyCaseSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ValidationSafetyCaseSummaryJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        model_limits: &model_acceptance_report_model_limits/0,
        safety_case_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().safety_case_statuses
        end,
        evidence_row_schema: &safety_case_evidence_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @validation_check = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ValidationJsonSchema.check_property_field?/1,
      OrbitalDynamics.Schema.ValidationJsonSchema.check_property_fun_from_context(
        schema_contract: @validation_check
      )
    )
  end

  defp json_schema_property(field, @schema_validation_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.property_field?(&1, :report),
      OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.property_fun_from_context(
        :report,
        schema_contract: fn
          :report -> @schema_validation_report
          :batch -> @schema_validation_batch_report
        end,
        issue_schema: &validation_issue_json_schema/0,
        remediation_schema: &validation_remediation_json_schema/0,
        model_limits: &schema_validation_model_limits/0,
        batch_entry_schema: &schema_validation_batch_entry_json_schema/0,
        skipped_artifact_schema: &skipped_schema_validation_artifact_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @schema_validation_batch_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.property_field?(&1, :batch),
      OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.property_fun_from_context(
        :batch,
        schema_contract: fn
          :report -> @schema_validation_report
          :batch -> @schema_validation_batch_report
        end,
        issue_schema: &validation_issue_json_schema/0,
        remediation_schema: &validation_remediation_json_schema/0,
        model_limits: &schema_validation_model_limits/0,
        batch_entry_schema: &schema_validation_batch_entry_json_schema/0,
        skipped_artifact_schema: &skipped_schema_validation_artifact_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @schema_migration_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.property_fun_from_context(
        schema_contract: @schema_migration_report,
        schema_version: 1,
        schema_migration_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().schema_migration_statuses
        end,
        schema_migration_row_statuses: fn ->
          OrbitalDynamics.Validation.capabilities().schema_migration_row_statuses
        end,
        row_schema: &schema_migration_row_json_schema/0,
        model_limits: &schema_migration_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @campaign_request_lint = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.LintReportJsonSchema.campaign_request_property_field?/1,
      OrbitalDynamics.Schema.LintReportJsonSchema.campaign_request_property_fun_from_context(
        validation_issue_schema: &validation_issue_json_schema/0,
        sha256_schema: &sha256_json_schema/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @study_manifest_lint = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.LintReportJsonSchema.study_manifest_property_field?/1,
      OrbitalDynamics.Schema.LintReportJsonSchema.study_manifest_property_fun_from_context(
        schema_version: 1,
        stable_id_pattern: @stable_id_pattern,
        manifest_lint_issue_schema: &manifest_lint_issue_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @strategy_branch = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StrategyBranchJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StrategyBranchJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        event_schema: &strategy_branch_event_json_schema/0,
        risk_schema: fn ->
          OrbitalDynamics.Schema.StrategyBranchJsonSchema.risk(
            @stable_id_pattern,
            scoped_downlink_context_json_schema_properties()
          )
        end,
        approval_requirement_schema: &approval_requirement_json_schema/0,
        numeric_map_schema: &numeric_map_json_schema/0,
        policy_decision_schema: &policy_decision_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @optimizer_contract = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OptimizerContractJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OptimizerContractJsonSchema.property_fun_from_context(
        schema_contract: @optimizer_contract,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @environment_model_capability = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CapabilityJsonSchema.property_field?(&1, :environment_model),
      OrbitalDynamics.Schema.CapabilityJsonSchema.property_fun_from_context(
        kind: :environment_model,
        schema_contract: @environment_model_capability,
        stable_id_pattern: @stable_id_pattern,
        validation_level_schema: &validation_level_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @environment_provider_capability = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CapabilityJsonSchema.property_field?(&1, :environment_provider),
      OrbitalDynamics.Schema.CapabilityJsonSchema.property_fun_from_context(
        kind: :environment_provider,
        schema_contract: @environment_provider_capability,
        stable_id_pattern: @stable_id_pattern,
        validation_level_schema: &validation_level_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @subsystem_model_capability = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CapabilityJsonSchema.property_field?(&1, :subsystem_model),
      OrbitalDynamics.Schema.CapabilityJsonSchema.property_fun_from_context(
        kind: :subsystem_model,
        schema_contract: @subsystem_model_capability,
        stable_id_pattern: @stable_id_pattern,
        validation_level_schema: &validation_level_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @monte_carlo_reproducibility_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.MonteCarloReproducibilityReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.MonteCarloReproducibilityReportJsonSchema.property_fun_from_context(
        schema_contract: @monte_carlo_reproducibility_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &OrbitalDynamics.Schema.MonteCarloReproducibilityContracts.model_limits/0,
        numeric_triplet_schema: &numeric_triplet_schema/0
      )
    )
  end

  defp json_schema_property(field, @strategy_recommendation = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.property_fun_from_context(
        schema_contract: @strategy_recommendation,
        stable_id_pattern: @stable_id_pattern,
        tradeoff_schema: &strategy_branch_tradeoff_json_schema/0,
        explanation_schema: &strategy_explanation_json_schema/0,
        risk_schema: &strategy_branch_risk_json_schema/0,
        approval_requirement_schema: &approval_requirement_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @realized_activity, contract) do
    OrbitalDynamics.Schema.RealizedActivityJsonSchema.dispatch_property(field, contract,
      focused_property:
        OrbitalDynamics.Schema.RealizedActivityJsonSchema.property_fun_from_context(
          stable_id_pattern: @stable_id_pattern,
          numeric_triplet_schema: fn -> numeric_triplet_schema() end,
          ground_station_schema: fn -> ground_station_identity_json_schema() end,
          spacecraft_schema: fn -> spacecraft_identity_json_schema() end,
          target_schema: fn -> target_identity_json_schema() end
        ),
      execution_uncertainty_schema: &execution_uncertainty_json_schema/0,
      number_or_string_schema: &number_or_string_json_schema/0,
      default_property: fn field, contract ->
        default_json_schema_property(field, @realized_activity, contract)
      end
    )
  end

  defp json_schema_property(field, @maneuver_recommendation = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ManeuverRecommendationJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ManeuverRecommendationJsonSchema.property_fun_from_context(
        schema_contract: @maneuver_recommendation,
        stable_id_pattern: @stable_id_pattern,
        numeric_triplet_schema: &numeric_triplet_schema/0,
        model_limits: &maneuver_recommendation_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @provider_counteroffer_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema.property_fun_from_context(
        row_schema: &provider_counteroffer_row_json_schema/0,
        models: &provider_counteroffer_report_models/0,
        negotiation_states: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states
        end,
        operator_actions: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_actions
        end
      )
    )
  end

  defp json_schema_property(
         field,
         @provider_counteroffer_review_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ProviderCounterofferReviewSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ProviderCounterofferReviewSummaryJsonSchema.property_fun_from_context(
        row_schema: &provider_counteroffer_row_json_schema/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @provider_counteroffer_import_readiness_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ProviderCounterofferImportReadinessSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ProviderCounterofferImportReadinessSummaryJsonSchema.property_fun_from_context(
        row_schema: &provider_counteroffer_row_json_schema/0,
        readiness_statuses: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_import_readiness_statuses
        end,
        import_classifications: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_import_classifications
        end,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @provider_counteroffer_plan_impact_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ProviderCounterofferPlanImpactSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ProviderCounterofferPlanImpactSummaryJsonSchema.property_fun_from_context(
        row_schema: &provider_counteroffer_row_json_schema/0,
        plan_impact_statuses: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_plan_impact_statuses
        end,
        lock_deadline_statuses: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_lock_deadline_statuses
        end,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @candidate_rejection_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.property_fun_from_context(
        model_limits: &candidate_rejection_report_model_limits/0,
        row_schema: &candidate_rejection_row_json_schema/0,
        rejection_reasons: &timeline_candidate_rejection_reasons/0,
        required_operator_actions: &timeline_candidate_rejection_actions/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @operational_timeline_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.property_fun_from_context(
        model_limits: &timeline_report_model_limits/0,
        row_schema: &operational_timeline_row_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        capability: &timeline_capabilities/0
      )
    )
  end

  defp json_schema_property(field, @timeline_diff_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineDiffReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineDiffReportJsonSchema.property_fun_from_context(
        model_limits: &timeline_report_model_limits/0,
        row_schema: &timeline_diff_row_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        capability: &timeline_capabilities/0
      )
    )
  end

  defp json_schema_property(field, @timeline_diff_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineDiffSummaryJsonSchema.property_fun_from_context(
        model_limits: &timeline_report_model_limits/0,
        row_schema: &timeline_diff_row_json_schema/0,
        capability: &timeline_capabilities/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @timeline_activity_status_state,
              @timeline_activity_approval_state,
              @timeline_activity_lifecycle_state
            ] do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        model_limits: &timeline_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern,
        transition_decisions: &timeline_transition_decisions/0,
        string_array_schema: &string_array_schema/0,
        lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        lifecycle_assumptions_schema:
          &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.lifecycle_assumptions/0,
        default_assumptions_schema:
          &OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.default_assumptions/0
      )
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [@timeline_preservation_report, @timeline_preservation_status] do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelinePreservationJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.TimelinePreservationJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        model_limits: timeline_report_model_limits(),
        count_map_schema: &non_negative_integer_count_map_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        timeline_identity_schema: &timeline_identity_json_schema/0,
        assumptions_schema: &timeline_preservation_assumptions_json_schema/1
      )
    )
  end

  defp json_schema_property(field, @timeline_lifecycle_state_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineLifecycleStateSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.TimelineLifecycleStateSummaryJsonSchema.property_fun_from_context(
        &timeline_lifecycle_state_row_json_schema/0,
        &timeline_report_model_limits/0,
        &non_negative_integer_count_map_json_schema/0,
        &stable_id_array_schema/0
      )
    )
  end

  defp json_schema_property(field, contract_name, contract)
       when contract_name in [
              @timeline_transition_application_report,
              @timeline_transition_application_summary
            ] do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.property_field?(
        &1,
        contract_name
      ),
      OrbitalDynamics.Schema.TimelineTransitionApplicationJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        application_row_schema: &timeline_transition_application_row_json_schema/0,
        selected_activity_schema: &timeline_transition_selected_activity_json_schema/0,
        model_limits: &timeline_report_model_limits/0,
        timeline_capability: &timeline_capabilities/0,
        enum_count_map_schema: &enum_count_map_json_schema/1,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0
      )
    )
  end

  defp json_schema_property(field, @command_window_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CommandWindowReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.CommandWindowReportJsonSchema.property_fun_from_context(
        model_limits: &command_window_report_model_limits/0,
        row_schema: &command_window_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @station_calendar_precedence_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryJsonSchema.property_fun_from_context(
        model_limits: &station_calendar_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @station_reservation_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationReservationReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationReservationReportJsonSchema.property_fun_from_context(
        models: &station_reservation_report_models/0,
        contact_schema: &station_reservation_contact_json_schema/0,
        provider_contention_group_schema:
          &station_reservation_provider_contention_group_json_schema/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @station_calendar_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationCalendarReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationCalendarReportJsonSchema.property_fun_from_context(
        contact_schema: &station_calendar_contact_json_schema/0,
        model: &station_calendar_report_model/0,
        provider_contention_group_schema:
          &station_calendar_provider_contention_group_json_schema/0,
        entry_schema: &station_calendar_provider_entry_json_schema/0,
        trust_boundary_status_count_schema:
          &branch_event_trust_boundary_status_counts_json_schema/0,
        model_limits: &station_calendar_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @station_reservation_review_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationReservationReviewSummaryJsonSchema.property_fun_from_context(
        row_schema: &station_reservation_review_summary_row_json_schema/0,
        model_limits: &station_calendar_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @station_reservation_hold_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationReservationHoldSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationReservationHoldSummaryJsonSchema.property_fun_from_context(
        row_schema: &station_reservation_review_summary_row_json_schema/0,
        model_limits: &station_calendar_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @station_reservation_hold_import_readiness_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationReservationHoldImportReadinessSummaryJsonSchema.property_fun_from_context(
        row_schema: &station_reservation_hold_import_readiness_row_json_schema/0,
        model_limits: &station_calendar_report_model_limits/0,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @station_calendar_provider = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.StationCalendarProviderJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.StationCalendarProviderJsonSchema.property_fun_from_context(
        entry_schema: station_calendar_provider_entry_json_schema()
      )
    )
  end

  defp json_schema_property(field, @link_capacity_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.property_fun_from_context(
        row_schema: &link_capacity_row_json_schema/0,
        model_limits: &link_capacity_model_limits/0,
        assumptions_schema: fn -> link_capacity_assumptions_json_schema([]) end,
        stable_id_array_schema: &stable_id_array_schema/0,
        string_array_schema: &string_array_schema/0,
        count_map_schema: &non_negative_integer_count_map_json_schema/0,
        number_array_schema: &number_array_schema/0,
        actual_data_rate_throughput_derivations_schema:
          &actual_data_rate_throughput_derivations_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @link_capacity_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.LinkCapacitySummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.LinkCapacitySummaryJsonSchema.property_fun_from_context(
        model_limits: &link_capacity_model_limits/0,
        assumptions_schema: fn ->
          link_capacity_assumptions_json_schema([
            "execution_boundary",
            "source",
            "operator_authority"
          ])
        end,
        count_map_schema: &non_negative_integer_count_map_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        string_array_schema: &string_array_schema/0,
        number_array_schema: &number_array_schema/0,
        numeric_map_schema: &numeric_map_json_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0
      )
    )
  end

  defp json_schema_property(field, @relay_data_path_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.property_fun_from_context(
        model_limits: &relay_data_path_model_limits/0,
        assumptions_schema: &relay_data_path_assumptions_json_schema/0,
        row_schema: &relay_data_path_row_json_schema/0,
        count_map_schema: &non_negative_integer_count_map_json_schema/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        stable_id_array_map_schema: &stable_id_array_map_schema/0
      )
    )
  end

  defp json_schema_property(field, @contact_allocation_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.property_fun_from_context(
        row_schema: &contact_allocation_row_json_schema/0,
        capacity_pack_group_schema: &contact_allocation_capacity_pack_group_json_schema/0,
        model_limits: &contact_allocation_model_limits/0,
        stable_id_array_schema: &stable_id_array_schema/0,
        nested_stable_id_array_map_schema: &nested_stable_id_array_map_json_schema/0,
        string_array_schema: &string_array_schema/0,
        trust_boundary_count_map_schema: &branch_event_trust_boundary_status_counts_json_schema/0,
        contact_allocation_capability: fn ->
          OrbitalDynamics.Communications.ContactAllocation.capabilities()
        end,
        enum_count_map_schema: &enum_count_map_json_schema/1,
        count_map_schema: &non_negative_integer_count_map_json_schema/0,
        non_negative_number_map_schema: &non_negative_number_map_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @contact_allocation_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_allocation_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_allocation_model_limits/0,
        assumptions_schema: &contact_allocation_summary_assumptions_json_schema/0,
        row_schema: &contact_allocation_row_json_schema/0,
        capacity_pack_group_schema: &contact_allocation_capacity_pack_group_json_schema/0
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_allocation_reservation_conflict_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_allocation_reservation_conflict_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_allocation_model_limits/0,
        assumptions_schema:
          &contact_allocation_reservation_conflict_summary_assumptions_json_schema/0,
        row_schema: &contact_allocation_row_json_schema/0
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_allocation_station_pressure_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_allocation_station_pressure_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_allocation_model_limits/0,
        assumptions_schema:
          &contact_allocation_station_pressure_summary_assumptions_json_schema/0,
        row_schema: &contact_allocation_row_json_schema/0
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_allocation_capacity_pack_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_allocation_capacity_pack_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_allocation_model_limits/0,
        assumptions_schema: &contact_allocation_capacity_pack_summary_assumptions_json_schema/0,
        row_schema: &contact_allocation_row_json_schema/0,
        capacity_pack_group_schema: &contact_allocation_capacity_pack_group_json_schema/0
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_allocation_provider_reservation_request_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema.property_fun_from_context(
        schema_contract: @contact_allocation_provider_reservation_request_summary,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &contact_allocation_model_limits/0,
        assumptions_schema:
          &contact_allocation_provider_reservation_request_summary_assumptions_json_schema/0,
        row_schema: &contact_allocation_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @contact_filter_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactFilterReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ContactFilterReportJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        trust_boundary_count_map_schema: &branch_event_trust_boundary_status_counts_json_schema/0,
        model_limits: &contact_filter_report_model_limits/0,
        assumptions_schema: &contact_filter_report_assumptions_json_schema/0,
        suppressed_candidate_schema: &suppressed_candidate_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @resource_filter_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResourceFilterReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResourceFilterReportJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        model_limits: &resource_filter_report_model_limits/0,
        assumptions_schema: &resource_filter_report_assumptions_json_schema/0,
        suppressed_candidate_schema: &suppressed_candidate_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @resource_projection_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        models: &resource_projection_report_models/0,
        model_limits: &resource_projection_report_model_limits/0,
        assumptions_schema: &resource_projection_assumptions_json_schema/0,
        resource_projection_row_schema: &resource_projection_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @resource_projection_flow_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema.property_fun_from_context(
        stable_id_pattern: @stable_id_pattern,
        model_limits: &resource_projection_report_model_limits/0,
        assumptions_schema: &resource_projection_assumptions_json_schema/0,
        activity_resource_flow_row_schema: &resource_projection_flow_row_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @contact_contention_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactContentionJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.ContactContentionJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        schema_contract: @contact_contention_resolution_summary,
        source_artifact_type: @contact_contention_resolution_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: contact_contention_report_model_limits(),
        report_assumptions_schema: contact_contention_report_assumptions_json_schema(),
        conflict_group_schema: contact_contention_group_json_schema(),
        recommendation_schema: contact_contention_recommendation_json_schema(),
        resolution_policy_schema: contact_contention_resolution_policy_json_schema()
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_contention_resolution_report = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactContentionJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.ContactContentionJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        schema_contract: @contact_contention_resolution_summary,
        source_artifact_type: @contact_contention_resolution_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: contact_contention_report_model_limits(),
        report_assumptions_schema: contact_contention_report_assumptions_json_schema(),
        conflict_group_schema: contact_contention_group_json_schema(),
        recommendation_schema: contact_contention_recommendation_json_schema(),
        resolution_policy_schema: contact_contention_resolution_policy_json_schema()
      )
    )
  end

  defp json_schema_property(
         field,
         @contact_contention_resolution_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ContactContentionJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.ContactContentionJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        schema_contract: @contact_contention_resolution_summary,
        source_artifact_type: @contact_contention_resolution_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: contact_contention_report_model_limits(),
        report_assumptions_schema: contact_contention_report_assumptions_json_schema(),
        conflict_group_schema: contact_contention_group_json_schema(),
        recommendation_schema: contact_contention_recommendation_json_schema(),
        resolution_policy_schema: contact_contention_resolution_policy_json_schema()
      )
    )
  end

  defp json_schema_property(field, @objective_satisfaction_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ObjectiveReportJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.ObjectiveReportJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        satisfaction_row_schema: objective_satisfaction_row_json_schema(),
        satisfaction_model_limits:
          OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits(),
        tradeoff_row_schema: objective_tradeoff_row_json_schema(),
        tradeoff_models: objective_tradeoff_report_models(),
        score_report_model_limits: OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )
    )
  end

  defp json_schema_property(field, @objective_tradeoff_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ObjectiveReportJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.ObjectiveReportJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        satisfaction_row_schema: objective_satisfaction_row_json_schema(),
        satisfaction_model_limits:
          OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits(),
        tradeoff_row_schema: objective_tradeoff_row_json_schema(),
        tradeoff_models: objective_tradeoff_report_models(),
        score_report_model_limits: OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )
    )
  end

  defp json_schema_property(field, @ranking_comparison_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OptimizerReportJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.OptimizerReportJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        ranking_row_schema: &ranking_comparison_row_json_schema/0,
        ranking_winner_schema: &ranking_comparison_winner_json_schema/0,
        ranking_model_limits: fn ->
          OrbitalDynamics.Optimizer.ranking_comparison_model_limits()
        end,
        pareto_row_schema: &pareto_frontier_row_json_schema/0,
        pareto_model_limits: fn -> OrbitalDynamics.Optimizer.pareto_frontier_model_limits() end,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @pareto_frontier_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OptimizerReportJsonSchema.property_field?(&1, contract_name),
      OrbitalDynamics.Schema.OptimizerReportJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        ranking_row_schema: &ranking_comparison_row_json_schema/0,
        ranking_winner_schema: &ranking_comparison_winner_json_schema/0,
        ranking_model_limits: fn ->
          OrbitalDynamics.Optimizer.ranking_comparison_model_limits()
        end,
        pareto_row_schema: &pareto_frontier_row_json_schema/0,
        pareto_model_limits: fn -> OrbitalDynamics.Optimizer.pareto_frontier_model_limits() end,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @score_term_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ScoreTermReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ScoreTermReportJsonSchema.property_fun_from_context(
        models: score_term_report_models(),
        model_limits: OrbitalDynamics.CampaignPlanner.score_report_model_limits(),
        row_schema: score_term_row_json_schema()
      )
    )
  end

  defp json_schema_property(field, @resource_filter_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ResourceFilterSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ResourceFilterSummaryJsonSchema.property_fun_from_context(
        schema_contract: @resource_filter_summary,
        source_artifact_type: @resource_filter_report,
        stable_id_pattern: @stable_id_pattern,
        model_limits: fn -> resource_filter_report_model_limits() end,
        assumptions_schema: %{"type" => "object"},
        suppressed_candidate_schema: fn -> suppressed_candidate_json_schema() end
      )
    )
  end

  defp json_schema_property(field, @constraint_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ConstraintReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ConstraintReportJsonSchema.property_fun_from_context(
        models: OrbitalDynamics.Schema.ConstraintReportContracts.models(),
        model_limits: OrbitalDynamics.Schema.ConstraintReportContracts.model_limit_values(),
        row_schema: constraint_row_json_schema()
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_import_eligibility_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalImportEligibilitySummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalImportEligibilitySummaryJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        gate_schema: operational_readiness_gate_json_schema(),
        model_limits: operational_import_eligibility_summary_model_limits()
      )
    )
  end

  defp json_schema_property(field, @operational_readiness_gate_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalReadinessGateSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalReadinessGateSummaryJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        gate_schema: operational_readiness_gate_json_schema(),
        model_limits: operational_readiness_gate_summary_model_limits(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @operational_quality_gate_summary = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalQualityGateSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalQualityGateSummaryJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        model_limits: quality_gate_summary_model_limits(),
        row_schema: quality_gate_report_row_json_schema(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_quality_gate_unavailable_resource_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryJsonSchema.property_fun_from_context(
        model_limits: quality_gate_unavailable_resource_summary_model_limits(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_quality_gate_operator_training_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryJsonSchema.property_fun_from_context(
        model_limits: quality_gate_operator_training_summary_model_limits(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_quality_gate_schema_validation_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryJsonSchema.property_fun_from_context(
        model_limits: quality_gate_schema_validation_summary_model_limits(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_quality_gate_import_readiness_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryJsonSchema.property_fun_from_context(
        model_limits: quality_gate_import_readiness_summary_model_limits(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(
         field,
         @operational_execution_boundary_summary = contract_name,
         contract
       ) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        gate_schema: operational_readiness_gate_json_schema(),
        model_limits: operational_execution_boundary_summary_model_limits(),
        string_array_schema: string_array_schema()
      )
    )
  end

  defp json_schema_property(field, @operational_readiness_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperationalReadinessReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.OperationalReadinessReportJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        gate_schema: operational_readiness_gate_json_schema(),
        evidence_schema: operational_readiness_evidence_json_schema(),
        model_limits: operational_readiness_model_limits()
      )
    )
  end

  defp json_schema_property(field, @quality_gate_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.QualityGateReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.QualityGateReportJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        model_limits: quality_gate_report_model_limits(),
        row_schema: quality_gate_report_row_json_schema(),
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @operator_review_package = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.OperatorReviewPackageJsonSchema.property_field?(
        &1,
        @operator_review_package_scalar_count_fields
      ),
      OrbitalDynamics.Schema.OperatorReviewPackageJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.OperatorReview.capabilities(),
        model_limits: operator_review_package_model_limits(),
        readiness_capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        row_schema: operator_review_row_json_schema(),
        scalar_count_fields: @operator_review_package_scalar_count_fields,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @cadence_import_manifest = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CadenceImportManifestJsonSchema.property_field?(
        &1,
        @cadence_import_manifest_scalar_count_fields
      ),
      OrbitalDynamics.Schema.CadenceImportManifestJsonSchema.property_fun_from_context(
        capability: OrbitalDynamics.CadenceImport.capability(),
        model_limits: cadence_import_manifest_model_limits(),
        readiness_capability: OrbitalDynamics.OperationalReadiness.capabilities(),
        row_schema: cadence_import_manifest_row_json_schema(),
        scalar_count_fields: @cadence_import_manifest_scalar_count_fields,
        stable_id_pattern: @stable_id_pattern
      )
    )
  end

  defp json_schema_property(field, @maneuver_review_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ManeuverReviewReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ManeuverReviewReportJsonSchema.property_fun_from_context(
        row_schema: &maneuver_review_row_json_schema/0,
        stable_id_pattern: @stable_id_pattern,
        model_limits: &maneuver_review_report_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @branch_comparison_report = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.BranchComparisonReportJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.BranchComparisonReportJsonSchema.property_fun_from_context(
        row_schema: &branch_comparison_row_json_schema/0,
        model_limits: &OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits/0
      )
    )
  end

  defp json_schema_property(field, @campaign_strategy = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CampaignStrategyJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.CampaignStrategyJsonSchema.property_fun_from_context(
        strategy_branch_schema: &strategy_branch_json_schema/0,
        strategy_recommendation_schema: &strategy_recommendation_json_schema/0,
        operational_feedback_schema: &operational_feedback_json_schema/0,
        policy_action_rule_schema: &policy_action_rule_json_schema/0
      )
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
      number_or_string_schema: &number_or_string_json_schema/0,
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
      number_or_string_schema: &number_or_string_json_schema/0,
      default_property: fn field, contract ->
        default_json_schema_property(field, @plan_delta, contract)
      end
    )
  end

  defp json_schema_property("lighting_confidence", _name, _contract) do
    number_or_string_json_schema()
  end

  defp json_schema_property(field, @proposed_contact = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.ProposedContactJsonSchema.property_field?/1,
      OrbitalDynamics.Schema.ProposedContactJsonSchema.property_fun_from_context(
        cadence_import_schema: fn -> cadence_import_json_schema("proposed_contact.v1") end,
        model_limits: &OrbitalDynamics.Schema.ProposedContactContracts.model_limits/0,
        source_window_schema: &candidate_activity_source_window_json_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0
      )
    )
  end

  defp json_schema_property(field, @candidate_refresh = contract_name, contract) do
    focused_json_schema_property(
      field,
      contract_name,
      contract,
      &OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.candidate_refresh_property_field?/1,
      OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.candidate_refresh_property_fun_from_context(
        source_window_lineage_schema: &source_window_lineage_json_schema/0,
        invalidated_candidate_schema: &invalidated_candidate_json_schema/0,
        candidate_activity_schema: &candidate_activity_json_schema/0,
        contact_intent_schema: &contact_intent_row_json_schema/0,
        resource_summary_schema: &resource_summary_row_json_schema/0,
        validation_record_schema: &validation_record_json_schema/0,
        model_limits: fn -> OrbitalDynamics.CandidateRefresh.model_limits() end,
        stable_id_pattern: @stable_id_pattern,
        operational_feedback_schema: &operational_feedback_json_schema/0,
        provider_counteroffer_actions: fn ->
          OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_actions
        end,
        safety_case_count_fields: &safety_case_count_fields/0,
        embedded_contract_schema: &embedded_contract_json_schema/1
      )
    )
  end

  defp json_schema_property(field, name, contract) do
    default_json_schema_property(field, name, contract)
  end

  defp default_json_schema_property(field, name, contract) do
    type = Map.get(@field_type_hints, field, "object")

    %{"type" => type}
    |> maybe_add_const(field, name, contract)
    |> maybe_add_stable_id_pattern(field)
  end

  defp embedded_contract_json_schema(contract_name) do
    contract = registry_contract!(contract_name)
    required_fields = contract["required_fields"]
    optional_fields = Map.get(contract, "optional_fields", [])

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required_fields,
      "properties" =>
        (required_fields ++ optional_fields)
        |> Enum.uniq()
        |> Enum.sort()
        |> Map.new(&{&1, json_schema_property(&1, contract_name, contract)})
    }
  end

  defp relay_data_path_row_json_schema do
    OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      custody_statuses: &relay_custody_statuses/0,
      latency_statuses: &relay_latency_statuses/0,
      risk_statuses: &relay_risk_statuses/0
    )
  end

  defp relay_data_path_assumptions_json_schema do
    OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema.assumptions()
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
      freshness_statuses()
    )
  end

  defp source_schema_validation_report_evidence_json_schema do
    OrbitalDynamics.Schema.SourceEvidenceJsonSchema.schema_validation_report(
      source_evidence_schema_deps(),
      schema_validation_statuses()
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
      count_map_schema: non_negative_integer_count_map_json_schema(),
      stable_id_array_map_schema: stable_id_array_map_schema()
    })
  end

  defp freshness_statuses, do: ["current", "stale", "unknown"]

  defp schema_validation_statuses, do: ["pass", "fail"]

  defp policy_action_rule_json_schema do
    OrbitalDynamics.Schema.PolicyActionRuleJsonSchema.action_rule(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: policy_context_field_groups(),
      number_fields: @policy_action_rule_number_fields,
      integer_fields: @policy_action_rule_integer_fields
    )
  end

  defp policy_decision_rule_match_json_schema do
    OrbitalDynamics.Schema.PolicyDecisionRuleMatchJsonSchema.rule_match_from_context(
      stable_id_pattern: @stable_id_pattern,
      policy_context_fields: policy_context_field_groups()
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
      string_array_schema: &string_array_schema/0,
      numeric_map_schema: &numeric_map_json_schema/0,
      branch_event_trust_boundary_status_counts_schema:
        &branch_event_trust_boundary_status_counts_json_schema/0,
      non_negative_integer_properties: fn ->
        non_negative_integer_property_schemas(@branch_comparison_row_count_fields)
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
      probability_schema: &probability_json_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      count_map_schema: &non_negative_integer_count_map_json_schema/0,
      actual_data_rate_throughput_derivations_schema:
        &actual_data_rate_throughput_derivations_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp contact_allocation_row_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.row_from_deps(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      number_array_schema: &number_array_schema/0,
      actual_data_rate_throughput_derivation_schema:
        &actual_data_rate_throughput_derivation_json_schema/0,
      approval_requirement_schema: &approval_requirement_json_schema/0,
      policy_decision_rule_match_schema: &policy_decision_rule_match_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0,
      source_contention_recommendation_schema: &contact_contention_recommendation_json_schema/0,
      contact_allocation_capability:
        &OrbitalDynamics.Communications.ContactAllocation.capabilities/0,
      station_calendar_capability: &OrbitalDynamics.Communications.StationCalendar.capabilities/0,
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
      string_array_schema: &string_array_schema/0,
      number_array_schema: &number_array_schema/0,
      actual_data_rate_throughput_derivations_schema:
        &actual_data_rate_throughput_derivations_json_schema/0,
      source_contact_candidate_schema: &contact_contention_source_contact_candidate_json_schema/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp contact_contention_recommendation_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.recommendation_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      number_array_schema: &number_array_schema/0,
      actual_data_rate_throughput_derivations_schema:
        &actual_data_rate_throughput_derivations_json_schema/0,
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
      string_array_schema: &string_array_schema/0
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
      numeric_map_schema: &numeric_map_json_schema/0,
      string_array_schema: &string_array_schema/0
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
      numeric_map_schema: &numeric_map_json_schema/0,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0
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
      string_array_schema: &string_array_schema/0,
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
      string_array_schema: &string_array_schema/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      resource_capability: &OrbitalDynamics.ResourceSummary.capabilities/0
    )
  end

  defp suppressed_candidate_json_schema do
    OrbitalDynamics.Schema.SuppressedCandidateJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      suppression_reasons: &suppressed_candidate_suppression_reasons/0,
      policy_decision_schema: &policy_decision_json_schema/0
    )
  end

  defp suppressed_candidate_suppression_reasons do
    (OrbitalDynamics.Communications.ContactFilter.capabilities().suppression_reasons ++
       OrbitalDynamics.ResourceFilter.capabilities().suppression_reasons)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp string_array_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.string_array()
  end

  defp sha256_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.sha256(@sha256_pattern)
  end

  defp number_array_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.number_array()
  end

  defp number_or_number_array_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.number_or_number_array()
  end

  defp non_negative_integer_property_schemas(fields) do
    OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_properties(fields)
  end

  defp policy_context_field_groups do
    %{
      string: @policy_context_string_fields,
      string_array: @policy_context_string_array_fields,
      string_or_array: @policy_context_string_or_array_fields,
      number: @policy_context_number_fields,
      integer: @policy_context_integer_fields,
      non_negative_integer: @policy_context_non_negative_integer_fields,
      boolean: @policy_context_boolean_fields
    }
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

  defp numeric_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.numeric_map()
  end

  defp non_negative_integer_count_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.non_negative_integer_count_map()
  end

  defp enum_count_map_json_schema(values) do
    OrbitalDynamics.Schema.CommonJsonSchema.enum_count_map(values)
  end

  defp branch_event_trust_boundary_status_counts_json_schema do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => ["declared", "missing", "untrusted"]},
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  defp numeric_triplet_schema do
    %{
      "type" => "array",
      "items" => %{"type" => "number"},
      "minItems" => 3,
      "maxItems" => 3
    }
  end

  defp spacecraft_state_estimate_json_schema do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.spacecraft_state_estimate_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_triplet_schema: &numeric_triplet_schema/0
    )
  end

  defp maneuver_execution_delta_json_schema do
    OrbitalDynamics.Schema.AcceptedStateJsonSchema.maneuver_execution_delta_from_context(
      stable_id_pattern: @stable_id_pattern,
      numeric_triplet_schema: &numeric_triplet_schema/0
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

  defp semantic_change_details_json_schema do
    OrbitalDynamics.Schema.CandidateDiffJsonSchema.semantic_change_details()
  end

  defp candidate_activity_json_schema do
    OrbitalDynamics.Schema.CandidateActivityJsonSchema.schema_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      source_window_schema: &candidate_activity_source_window_json_schema/0,
      probability_schema: &probability_json_schema/0,
      number_or_string_schema: &number_or_string_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp campaign_activity_json_schema do
    candidate_activity_json_schema()
  end

  defp operator_review_package_model_limits do
    OrbitalDynamics.OperatorReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp cadence_import_manifest_model_limits do
    OrbitalDynamics.CadenceImport.capability()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp operational_readiness_model_limits do
    OrbitalDynamics.OperationalReadiness.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp operational_readiness_gate_summary_model_limits do
    [
      "operational_readiness_gate_summary_routes_only",
      "operational_readiness_gate_summary_does_not_approve_or_import"
    ]
  end

  defp operational_execution_boundary_summary_model_limits do
    [
      "operational_execution_boundary_summary_routes_only",
      "operational_execution_boundary_summary_does_not_execute_or_import"
    ]
  end

  defp operational_import_eligibility_summary_model_limits do
    [
      "operational_import_eligibility_summary_routes_only",
      "operational_import_eligibility_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_report_model_limits do
    [
      "quality_gate_report_derives_classification_from_gate_rows",
      "quality_gate_report_does_not_approve_or_import"
    ]
  end

  defp quality_gate_summary_model_limits do
    [
      "quality_gate_summary_derives_classification_from_gate_rows",
      "quality_gate_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_unavailable_resource_summary_model_limits do
    [
      "quality_gate_unavailable_resource_summary_routes_only",
      "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_operator_training_summary_model_limits do
    [
      "quality_gate_operator_training_summary_routes_only",
      "quality_gate_operator_training_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_schema_validation_summary_model_limits do
    [
      "quality_gate_schema_validation_summary_routes_only",
      "quality_gate_schema_validation_summary_does_not_approve_or_import"
    ]
  end

  defp quality_gate_import_readiness_summary_model_limits do
    [
      "quality_gate_import_readiness_summary_routes_only",
      "quality_gate_import_readiness_summary_does_not_approve_or_import"
    ]
  end

  defp model_acceptance_report_model_limits do
    OrbitalDynamics.Validation.capabilities()
    |> Map.fetch!(:known_limits)
  end

  defp schema_migration_report_model_limits do
    [
      "artifact_only_schema_registry_snapshot",
      "deprecation_hints_are_caller_declared",
      "no_automatic_artifact_migration",
      "no_backward_compatibility_certification"
    ]
  end

  defp contact_intent_model_limits do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
  end

  defp contact_intent_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactIntentSummaryJsonSchema.assumptions(
      station_capacity_value_paths: contact_intent_station_capacity_value_path_assumptions(),
      required_capacity_value_paths: contact_intent_required_capacity_value_path_assumptions(),
      required_capacity_fraction_source_values:
        contact_intent_required_capacity_fraction_source_values()
    )
  end

  defp contact_intent_station_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
    |> contact_intent_capacity_value_path_assumptions()
  end

  defp contact_intent_required_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:required_capacity_value_paths)
    |> contact_intent_capacity_value_path_assumptions()
  end

  defp contact_intent_capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp contact_intent_required_capacity_fraction_source_values do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:required_capacity_fraction_source_values)
  end

  defp contact_filter_report_model_limits do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_filter_suppressed_directions do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:suppressed_directions)
  end

  defp contact_filter_suppression_reasons do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:suppression_reasons)
  end

  defp contact_filter_station_unavailable_aliases do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  defp contact_filter_station_availability_precedence do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  defp contact_filter_station_capacity_value_paths do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
  end

  defp contact_filter_contact_capacity_value_paths do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:contact_capacity_value_paths)
  end

  defp contact_filter_station_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
    |> contact_filter_capacity_value_path_assumptions()
  end

  defp contact_filter_contact_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:contact_capacity_value_paths)
    |> contact_filter_capacity_value_path_assumptions()
  end

  defp contact_filter_capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp contact_filter_provider_direction_aliases do
    OrbitalDynamics.Communications.ContactFilter.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  defp contact_filter_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactFilterReportJsonSchema.assumptions_from_context(
      &contact_filter_suppressed_directions/0,
      &contact_filter_suppression_reasons/0,
      &contact_filter_station_unavailable_aliases/0,
      &contact_filter_station_availability_precedence/0,
      &contact_filter_station_capacity_value_paths/0,
      &contact_filter_contact_capacity_value_paths/0,
      &contact_filter_provider_direction_aliases/0
    )
  end

  defp contact_allocation_model_limits do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_allocation_capacity_pack_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:capacity_pack_statuses)
  end

  defp contact_allocation_reduced_capacity_pack_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:reduced_capacity_pack_statuses)
  end

  defp contact_allocation_station_reservation_match_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_reservation_match_statuses)
  end

  defp contact_allocation_reservation_conflict_match_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:reservation_conflict_match_statuses)
  end

  defp contact_allocation_station_reservation_expiration_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_reservation_expiration_statuses)
  end

  defp contact_allocation_provider_reservation_request_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:provider_reservation_request_statuses)
  end

  defp contact_allocation_row_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:row_statuses)
  end

  defp contact_allocation_effective_row_statuses do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:effective_row_statuses)
  end

  defp contact_allocation_station_unavailable_aliases do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  defp contact_allocation_station_blocking_availability do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_blocking_availability)
  end

  defp contact_allocation_station_availability_precedence do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  defp contact_allocation_provider_direction_aliases do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  defp contact_allocation_required_capacity_fraction_source_values do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:required_capacity_fraction_source_values)
  end

  defp contact_allocation_required_capacity_value_paths do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:required_capacity_value_paths)
  end

  defp contact_allocation_default_required_capacity_value_paths do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:default_required_capacity_value_paths)
  end

  defp contact_allocation_required_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:required_capacity_value_paths)
    |> contact_allocation_capacity_value_path_assumptions()
  end

  defp contact_allocation_default_required_capacity_value_path_assumptions do
    OrbitalDynamics.Communications.ContactAllocation.capabilities()
    |> Map.fetch!(:default_required_capacity_value_paths)
    |> contact_allocation_capacity_value_path_assumptions()
  end

  defp contact_allocation_capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp contact_allocation_capacity_pack_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_capacity_pack_statuses/0,
      &contact_allocation_reduced_capacity_pack_statuses/0,
      &contact_allocation_required_capacity_fraction_source_values/0,
      &contact_allocation_required_capacity_value_paths/0,
      &contact_allocation_default_required_capacity_value_paths/0
    )
  end

  defp contact_allocation_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.summary_assumptions_from_context(
      &contact_allocation_row_statuses/0,
      &contact_allocation_effective_row_statuses/0,
      &contact_allocation_station_unavailable_aliases/0,
      &contact_allocation_station_blocking_availability/0,
      &contact_allocation_station_availability_precedence/0,
      &contact_allocation_capacity_pack_statuses/0,
      &contact_allocation_reduced_capacity_pack_statuses/0,
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_station_reservation_expiration_statuses/0,
      &contact_allocation_required_capacity_fraction_source_values/0,
      &contact_allocation_required_capacity_value_paths/0,
      &contact_allocation_default_required_capacity_value_paths/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  defp contact_allocation_station_pressure_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_station_unavailable_aliases/0,
      &contact_allocation_station_blocking_availability/0,
      &contact_allocation_station_availability_precedence/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  defp contact_allocation_reservation_conflict_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_reservation_conflict_match_statuses/0,
      &contact_allocation_station_reservation_expiration_statuses/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  defp contact_allocation_provider_reservation_request_summary_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema.assumptions_from_context(
      &contact_allocation_provider_reservation_request_statuses/0,
      &contact_allocation_station_reservation_match_statuses/0,
      &contact_allocation_provider_direction_aliases/0
    )
  end

  defp link_capacity_model_limits do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp link_capacity_station_unavailable_aliases do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_unavailable_aliases)
  end

  defp link_capacity_station_availability_precedence do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_availability_precedence)
  end

  defp link_capacity_provider_direction_aliases do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  defp link_capacity_station_capacity_value_paths do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:station_capacity_value_paths)
  end

  defp link_capacity_source_station_capacity_value_paths do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:source_station_capacity_value_paths)
  end

  defp link_capacity_assumptions_json_schema(required_properties) do
    OrbitalDynamics.Schema.LinkCapacityReportJsonSchema.assumptions_from_deps(
      [
        station_unavailable_aliases: &link_capacity_station_unavailable_aliases/0,
        station_availability_precedence: &link_capacity_station_availability_precedence/0,
        station_capacity_value_paths: &link_capacity_station_capacity_value_paths/0,
        source_station_capacity_value_paths: &link_capacity_source_station_capacity_value_paths/0,
        provider_direction_aliases: &link_capacity_provider_direction_aliases/0
      ],
      required_properties
    )
  end

  defp relay_data_path_model_limits do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:relay_data_path_model_limits)
  end

  defp candidate_rejection_report_model_limits do
    [
      "artifact_only",
      "does_not_select_candidates",
      "does_not_mutate_schedules",
      "derived_reasons_use_declared_candidate_fields"
    ]
  end

  defp resource_filter_report_model_limits do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp resource_filter_policy_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_filter_policy_fields)
  end

  defp resource_filter_availability_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_aliases)
  end

  defp resource_filter_degraded_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_degraded_aliases)
  end

  defp resource_filter_margin_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_margin_aliases)
  end

  defp resource_filter_power_margin_source_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_power_margin_source_aliases)
  end

  defp resource_filter_availability_true_tokens do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_true_tokens)
  end

  defp resource_filter_availability_false_tokens do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:resource_availability_false_tokens)
  end

  defp resource_filter_provider_direction_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:provider_direction_aliases)
  end

  defp resource_filter_station_calendar_direction_aliases do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:station_calendar_direction_aliases)
  end

  defp resource_filter_provider_result_map_value_keys do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:provider_result_map_value_keys)
  end

  defp resource_filter_candidate_stable_identity_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:candidate_stable_identity_fields)
  end

  defp resource_filter_station_calendar_id_list_fields do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:station_calendar_id_list_fields)
  end

  defp resource_filter_suppression_reasons do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:suppression_reasons)
  end

  defp resource_filter_row_review_statuses do
    OrbitalDynamics.ResourceFilter.capabilities()
    |> Map.fetch!(:row_review_statuses)
  end

  defp resource_filter_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ResourceFilterReportJsonSchema.assumptions_from_context(
      &string_array_schema/0,
      &resource_filter_policy_fields/0,
      &resource_filter_availability_aliases/0,
      &resource_filter_degraded_aliases/0,
      &resource_filter_margin_aliases/0,
      &resource_filter_power_margin_source_aliases/0,
      &resource_filter_availability_true_tokens/0,
      &resource_filter_availability_false_tokens/0,
      &resource_filter_provider_direction_aliases/0,
      &resource_filter_station_calendar_direction_aliases/0,
      &resource_filter_provider_result_map_value_keys/0,
      &resource_filter_candidate_stable_identity_fields/0,
      &resource_filter_station_calendar_id_list_fields/0,
      &resource_filter_suppression_reasons/0,
      &resource_filter_row_review_statuses/0
    )
  end

  defp timeline_activity_state_assumptions_json_schema(fields) do
    OrbitalDynamics.Schema.CommonJsonSchema.boolean_const_assumptions(fields)
  end

  defp timeline_string_assumptions_json_schema(values) do
    OrbitalDynamics.Schema.CommonJsonSchema.string_const_assumptions(values)
  end

  defp timeline_feedback_report_model_limits do
    OrbitalDynamics.TimelineFeedback.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp timeline_report_model_limits do
    timeline_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp timeline_capabilities do
    OrbitalDynamics.Timeline.capabilities()
  end

  defp timeline_candidate_rejection_reasons do
    timeline_capabilities().candidate_rejection_reasons
  end

  defp timeline_candidate_rejection_actions do
    timeline_capabilities().candidate_rejection_actions
  end

  defp timeline_transition_decisions do
    timeline_capabilities().transition_decisions
  end

  defp timeline_integrity_issue_types do
    timeline_capabilities().timeline_integrity_issue_types
  end

  defp timeline_activity_precondition_statuses do
    timeline_capabilities().activity_precondition_statuses
  end

  defp timeline_required_operator_actions do
    timeline_capabilities().required_operator_actions
  end

  defp contact_contention_report_model_limits do
    OrbitalDynamics.Communications.ContactContention.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_contention_report_assumptions_json_schema do
    OrbitalDynamics.Schema.ContactContentionJsonSchema.report_assumptions_from_capabilities(
      OrbitalDynamics.Communications.ContactContention.capabilities()
    )
  end

  defp command_window_report_model_limits do
    OrbitalDynamics.Communications.CommandWindow.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp maneuver_recommendation_model_limits do
    OrbitalDynamics.ManeuverReview.recommendation_model_limits()
  end

  defp maneuver_review_report_model_limits do
    OrbitalDynamics.ManeuverReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp policy_model_limits do
    OrbitalDynamics.Policy.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp station_calendar_report_model_limits do
    OrbitalDynamics.Communications.StationCalendar.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp station_calendar_report_model, do: "campaign_ground_network_interval_overlay"

  defp station_reservation_report_models do
    [
      "artifact_only_station_reservation_summary",
      "preserved_station_reservation_hold_summary",
      "preserved_station_reservation_hold_import_readiness_summary"
    ]
  end

  defp provider_counteroffer_report_models do
    [
      "artifact_only_provider_counteroffer_review",
      "preserved_provider_counteroffer_rows",
      "preserved_provider_counteroffer_plan_impact_summary",
      "preserved_provider_counteroffer_import_readiness_summary"
    ]
  end

  defp activity_template_activity_types do
    timeline_capabilities().supported_activity_types
  end

  defp activity_template_activity_statuses do
    timeline_capabilities().activity_statuses
  end

  defp activity_template_approval_statuses do
    timeline_capabilities().approval_statuses
  end

  defp activity_template_precondition_types do
    timeline_capabilities().activity_precondition_types
  end

  defp activity_template_precondition_statuses do
    timeline_activity_precondition_statuses()
  end

  defp planned_activity_json_schema do
    OrbitalDynamics.Schema.PlannedActivityJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: string_array_schema(),
      probability_schema: probability_json_schema(),
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
      string_array_schema: string_array_schema(),
      numeric_triplet_schema: numeric_triplet_schema(),
      probability_schema: probability_json_schema(),
      number_or_string_schema: number_or_string_json_schema(),
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
        "incompatible_activity_types" => string_array_schema(),
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
      probability_map: probability_map_json_schema(),
      string_value_map: string_value_map_json_schema(),
      non_negative_number_map: non_negative_number_map_json_schema(),
      string_list_map: string_list_map_json_schema(),
      nested_object_map: nested_object_map_json_schema(),
      realized_activity: realized_activity_json_schema()
    })
  end

  defp timeline_feedback_operational_feedback_provenance_json_schema do
    OrbitalDynamics.Schema.OperationalFeedbackJsonSchema.timeline_feedback_provenance(
      @timeline_feedback_report,
      %{
        string_array: string_array_schema(),
        count_map: non_negative_integer_count_map_json_schema(),
        string_list_map: string_list_map_json_schema()
      }
    )
  end

  defp probability_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.probability_map()
  end

  defp probability_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.probability()
  end

  defp number_or_string_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.number_or_string()
  end

  defp non_negative_number_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.non_negative_number_map()
  end

  defp string_value_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.string_value_map()
  end

  defp string_list_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.string_list_map()
  end

  defp nested_object_map_json_schema do
    OrbitalDynamics.Schema.CommonJsonSchema.nested_object_map()
  end

  defp timeline_feedback_row_json_schema do
    OrbitalDynamics.Schema.TimelineFeedbackRowJsonSchema.row(
      stable_id_pattern: @stable_id_pattern,
      capability: OrbitalDynamics.TimelineFeedback.capabilities(),
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: string_array_schema(),
      number_array_schema: number_array_schema(),
      probability_schema: probability_json_schema(),
      number_or_string_schema: number_or_string_json_schema(),
      protection_decision_schema: protection_decision_json_schema(),
      lifecycle_transition_schema: lifecycle_transition_json_schema(),
      actual_data_rate_throughput_derivation_schema:
        actual_data_rate_throughput_derivation_json_schema(),
      numeric_triplet_schema: numeric_triplet_schema(),
      timeline_identity_schema: timeline_identity_json_schema(),
      activity_context_schema: activity_context_json_schema(),
      planned_activity_schema: planned_activity_json_schema(),
      realized_activity_schema: realized_activity_json_schema()
    )
  end

  defp validation_issue_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.issue()
  end

  defp manifest_lint_issue_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.manifest_lint_issue()
  end

  defp validation_remediation_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.remediation()
  end

  defp schema_validation_batch_entry_json_schema do
    report_schema =
      json_schema_document(
        @schema_validation_report,
        registry_contract!(@schema_validation_report)
      )

    OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.batch_entry(report_schema)
  end

  defp schema_migration_row_json_schema do
    OrbitalDynamics.Schema.SchemaMigrationReportJsonSchema.row()
  end

  defp skipped_schema_validation_artifact_json_schema do
    OrbitalDynamics.Schema.SchemaValidationReportJsonSchema.skipped_artifact()
  end

  defp validation_record_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.record(
      @stable_id_pattern,
      validation_level_json_schema()
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
      validation_level_json_schema(),
      validation_check_json_schema()
    )
  end

  defp validation_check_json_schema do
    OrbitalDynamics.Schema.ValidationJsonSchema.check()
  end

  defp strategy_branch_tradeoff_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.tradeoff()
  end

  defp strategy_branch_risk_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.risk(
      @stable_id_pattern,
      scoped_downlink_context_json_schema_properties()
    )
  end

  defp strategy_recommendation_json_schema do
    @strategy_recommendation
    |> json_schema_document(registry_contract!(@strategy_recommendation))
    |> Map.take(["type", "additionalProperties", "required", "properties"])
  end

  defp strategy_branch_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.branch(
      stable_id_pattern: @stable_id_pattern,
      numeric_map_schema: numeric_map_json_schema(),
      string_array_schema: string_array_schema(),
      event_schema: strategy_branch_event_json_schema(),
      risk_schema: strategy_branch_risk_json_schema(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema(),
      tradeoff_schema: strategy_branch_tradeoff_json_schema(),
      policy_decision_schema: policy_decision_json_schema(),
      assumptions_schema: strategy_branch_assumptions_json_schema(),
      provenance_schema: strategy_branch_provenance_json_schema()
    )
  end

  defp strategy_branch_assumptions_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.assumptions(
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: string_array_schema(),
      event_schema: strategy_branch_event_json_schema()
    )
  end

  defp strategy_branch_provenance_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.provenance(
      stable_id_pattern: @stable_id_pattern,
      string_array_schema: string_array_schema()
    )
  end

  defp strategy_branch_event_json_schema do
    OrbitalDynamics.Schema.StrategyBranchJsonSchema.event(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      semantic_change_details_schema: semantic_change_details_json_schema(),
      numeric_map_schema: numeric_map_json_schema(),
      string_list_map_schema: string_list_map_json_schema(),
      non_negative_integer_count_map_schema: non_negative_integer_count_map_json_schema(),
      provider_counteroffer_negotiation_states:
        OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states
    )
  end

  defp branch_comparison_source_row_json_schema do
    branch_comparison_row_json_schema()
    |> Map.delete("required")
  end

  defp strategy_explanation_json_schema do
    OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.explanation(
      @stable_id_pattern,
      branch_event_summary_json_schema_properties()
    )
  end

  defp branch_event_summary_json_schema_properties do
    OrbitalDynamics.Schema.StrategyRecommendationJsonSchema.branch_event_summary_properties(
      @stable_id_pattern,
      branch_scoped_downlink_context_json_schema_properties()
    )
  end

  defp timeline_identity_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "timeline_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "activity_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "activity_type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => @stable_id_pattern},
        "subject_id" => %{"type" => "string"},
        "source_window_id" => %{"type" => "string", "pattern" => @stable_id_pattern}
      }
    }
  end

  defp provenance_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source" => %{"type" => "string"},
        "adapter" => %{"type" => "string"},
        "import_adapter" => %{"type" => "string"},
        "trust_boundary" => %{"type" => "string"},
        "trust_boundary_status" => %{"type" => "string"}
      }
    }
  end

  defp actual_data_rate_throughput_derivation_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "derivation" => %{"type" => "string"},
        "rate_unit" => %{"type" => "string"},
        "actual_data_rate_mbps" => %{"type" => "number"},
        "actual_data_rate_mb_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "actual_throughput_mb" => %{"type" => "number"}
      }
    }
  end

  defp actual_data_rate_throughput_derivations_json_schema do
    %{
      "type" => "array",
      "items" => actual_data_rate_throughput_derivation_json_schema()
    }
  end

  defp execution_uncertainty_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "timing_3sigma_s" => %{"type" => "number"},
        "delta_v_3sigma_km_s" => numeric_triplet_schema(),
        "delta_v_3sigma_magnitude_km_s" => %{"type" => "number"},
        "source" => %{"type" => "string"},
        "model" => %{"type" => "string"}
      }
    }
  end

  defp protection_decision_json_schema do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.protection_decision_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_preservation_source_json_schema do
    OrbitalDynamics.Schema.TimelinePreservationJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp lifecycle_transition_json_schema do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.lifecycle_transition_from_context()
  end

  defp timeline_link_json_schema do
    OrbitalDynamics.Schema.TimelineSupportJsonSchema.timeline_link_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_protection_summary_json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "preserved_locked_or_approved_count" => %{"type" => "integer", "minimum" => 0},
        "preserved_executed_count" => %{"type" => "integer", "minimum" => 0},
        "changed_locked_or_approved_count" => %{"type" => "integer", "minimum" => 0},
        "changed_executed_count" => %{"type" => "integer", "minimum" => 0},
        "preserved_locked_or_approved_activity_ids" => stable_id_array_schema(),
        "preserved_executed_activity_ids" => stable_id_array_schema(),
        "changed_locked_or_approved_activity_ids" => stable_id_array_schema(),
        "changed_executed_activity_ids" => stable_id_array_schema()
      }
    }
  end

  defp activity_context_json_schema do
    OrbitalDynamics.Schema.ActivityContextJsonSchema.schema(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: string_array_schema(),
      number_array_schema: number_array_schema(),
      numeric_map_schema: numeric_map_json_schema(),
      provenance_schema: provenance_json_schema(),
      timeline_identity_schema: timeline_identity_json_schema(),
      candidate_activity_source_window_schema: candidate_activity_source_window_json_schema(),
      actual_data_rate_throughput_derivation_schema:
        actual_data_rate_throughput_derivation_json_schema(),
      execution_uncertainty_schema: execution_uncertainty_json_schema(),
      numeric_triplet_schema: numeric_triplet_schema(),
      probability_schema: probability_json_schema()
    )
  end

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
      string_array_schema: &string_array_schema/0,
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
      string_array_schema: &string_array_schema/0
    )
  end

  defp operational_timeline_row_json_schema do
    OrbitalDynamics.Schema.OperationalTimelineReportJsonSchema.row_from_context(
      capability: &timeline_capabilities/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      number_array_schema: &number_array_schema/0,
      timeline_precondition_schema: &timeline_precondition_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      timeline_integrity_issue_schema: &timeline_integrity_issue_json_schema/0
    )
  end

  defp candidate_rejection_row_json_schema do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_capability: &timeline_capabilities/0,
      string_array_schema: &string_array_schema/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp candidate_rejection_source_json_schema do
    OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      timeline_capability: &timeline_capabilities/0,
      string_array_schema: &string_array_schema/0,
      activity_context_schema: &activity_context_json_schema/0
    )
  end

  defp provider_counteroffer_row_json_schema do
    OrbitalDynamics.Schema.ProviderCounterofferJsonSchema.row_from_context(
      stable_id_pattern: @stable_id_pattern,
      station_calendar: &OrbitalDynamics.Communications.StationCalendar.capabilities/0
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
      lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
      string_array_schema: &string_array_schema/0,
      timeline_identity_schema: &timeline_identity_json_schema/0
    )
  end

  defp timeline_lifecycle_state_row_json_schema do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.row_from_context(
      model_limits: &timeline_report_model_limits/0,
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      transition_decisions: &timeline_transition_decisions/0,
      string_array_schema: &string_array_schema/0,
      lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &protection_decision_json_schema/0
    )
  end

  defp timeline_lifecycle_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityLifecycleStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      transition_decisions: &timeline_transition_decisions/0,
      string_array_schema: &string_array_schema/0,
      lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
      activity_context_schema: &activity_context_json_schema/0,
      protection_decision_schema: &lifecycle_state_source_protection_decision_json_schema/0
    )
  end

  defp timeline_activity_state_source_json_schema do
    OrbitalDynamics.Schema.TimelineActivityStateJsonSchema.source_from_context(
      stable_id_pattern: @stable_id_pattern,
      stable_id_array_schema: &stable_id_array_schema/0,
      string_array_schema: &string_array_schema/0,
      lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
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
        string_array_schema: &string_array_schema/0,
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
      string_array_schema: &string_array_schema/0,
      lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
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
        string_array_schema: &string_array_schema/0,
        lifecycle_transition_schema: &lifecycle_transition_json_schema/0,
        protection_decision_schema: &protection_decision_json_schema/0,
        timeline_diff_row_schema: &timeline_diff_row_json_schema/0,
        timeline_identity_schema: &timeline_identity_json_schema/0,
        activity_context_schema: &activity_context_json_schema/0,
        model_limits: &timeline_report_model_limits/0,
        enum_count_map_schema: &enum_count_map_json_schema/1
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
      numeric_triplet_schema: numeric_triplet_schema(),
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
        OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states,
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
        OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states
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
        OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states
    )
  end

  defp operational_readiness_gate_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessGateJsonSchema.gate(
      capability: OrbitalDynamics.OperationalReadiness.capabilities(),
      stable_id_pattern: @stable_id_pattern
    )
  end

  defp quality_gate_report_row_json_schema do
    OrbitalDynamics.Schema.QualityGateReportJsonSchema.row(
      capability: OrbitalDynamics.OperationalReadiness.capabilities(),
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
      string_array_schema: string_array_schema(),
      approval_requirement_schema: approval_requirement_json_schema(),
      policy_decision_rule_match_schema: policy_decision_rule_match_json_schema()
    )
  end

  defp operational_readiness_evidence_json_schema do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceJsonSchema.schema(
      count_map_schema: non_negative_integer_count_map_json_schema(),
      string_array_schema: string_array_schema(),
      stable_id_array_schema: stable_id_array_schema(),
      branch_event_trust_boundary_status_counts_schema:
        branch_event_trust_boundary_status_counts_json_schema(),
      timeline_publication_context_properties:
        OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema.timeline_publication_context_properties(
          stable_id_pattern: @stable_id_pattern
        )
    )
  end

  defp cadence_import_manifest_row_json_schema do
    OrbitalDynamics.Schema.CadenceImportManifestJsonSchema.row(
      capability: OrbitalDynamics.CadenceImport.capability(),
      readiness_capability: OrbitalDynamics.OperationalReadiness.capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema: &cadence_import_manifest_row_json_schema_dependency/1,
      properties: &cadence_import_manifest_row_json_schema_properties/1
    )
  end

  defp cadence_import_manifest_row_json_schema_dependency(name) do
    case name do
      :activity_context_json_schema ->
        activity_context_json_schema()

      :branch_comparison_source_row_json_schema ->
        branch_comparison_source_row_json_schema()

      :branch_event_trust_boundary_status_counts_json_schema ->
        branch_event_trust_boundary_status_counts_json_schema()

      :cadence_import_status_json_schema ->
        cadence_import_status_json_schema()

      :cadence_source_review_row_json_schema ->
        cadence_source_review_row_json_schema()

      :candidate_activity_source_window_json_schema ->
        candidate_activity_source_window_json_schema()

      :candidate_rejection_source_json_schema ->
        candidate_rejection_source_json_schema()

      :contact_allocation_capacity_requirement_row_json_schema ->
        contact_allocation_capacity_requirement_row_json_schema()

      :contact_contention_deferred_priority_json_schema ->
        contact_contention_deferred_priority_json_schema()

      :non_negative_number_map_json_schema ->
        non_negative_number_map_json_schema()

      :number_array_schema ->
        number_array_schema()

      :number_or_number_array_schema ->
        number_or_number_array_schema()

      :number_or_string_json_schema ->
        number_or_string_json_schema()

      :operational_readiness_evidence_json_schema ->
        operational_readiness_evidence_json_schema()

      :operational_readiness_gate_json_schema ->
        operational_readiness_gate_json_schema()

      :operational_readiness_source_report_evidence_json_schema ->
        operational_readiness_source_report_evidence_json_schema()

      :operational_timeline_row_json_schema ->
        operational_timeline_row_json_schema()

      :policy_decision_evidence_json_schema ->
        policy_decision_evidence_json_schema()

      :policy_escalation_json_schema ->
        policy_escalation_json_schema()

      :priority_field_evidence_counts_json_schema ->
        priority_field_evidence_counts_json_schema()

      :probability_json_schema ->
        probability_json_schema()

      :quality_gate_report_row_json_schema ->
        quality_gate_report_row_json_schema()

      :quality_gate_source_report_evidence_json_schema ->
        quality_gate_source_report_evidence_json_schema()

      :semantic_change_details_json_schema ->
        semantic_change_details_json_schema()

      :source_evidence_json_schema ->
        source_evidence_json_schema()

      :source_execution_report_evidence_json_schema ->
        source_execution_report_evidence_json_schema()

      :source_freshness_report_evidence_json_schema ->
        source_freshness_report_evidence_json_schema()

      :source_schema_validation_report_evidence_json_schema ->
        source_schema_validation_report_evidence_json_schema()

      :source_window_lineage_json_schema ->
        source_window_lineage_json_schema()

      :stable_id_array_map_schema ->
        stable_id_array_map_schema()

      :stable_id_array_schema ->
        stable_id_array_schema()

      :string_array_schema ->
        string_array_schema()

      :timeline_activity_precondition_summary_source_json_schema ->
        timeline_activity_precondition_summary_source_json_schema()

      :timeline_activity_state_source_json_schema ->
        timeline_activity_state_source_json_schema()

      :timeline_diff_summary_source_json_schema ->
        timeline_diff_summary_source_json_schema()

      :timeline_identity_json_schema ->
        timeline_identity_json_schema()

      :timeline_lifecycle_state_source_json_schema ->
        timeline_lifecycle_state_source_json_schema()

      :timeline_link_json_schema ->
        timeline_link_json_schema()

      :timeline_preservation_source_json_schema ->
        timeline_preservation_source_json_schema()

      :timeline_protection_summary_json_schema ->
        timeline_protection_summary_json_schema()

      :timeline_transition_application_row_json_schema ->
        timeline_transition_application_row_json_schema()

      :timeline_transition_application_summary_source_json_schema ->
        timeline_transition_application_summary_source_json_schema()
    end
  end

  defp cadence_import_manifest_row_json_schema_properties(name) do
    case name do
      :branch_scoped_downlink_context_json_schema_properties ->
        branch_scoped_downlink_context_json_schema_properties()

      :cadence_import_operational_readiness_evidence_json_schema_properties ->
        cadence_import_operational_readiness_evidence_json_schema_properties()

      :cadence_import_resource_projection_evidence_json_schema_properties ->
        cadence_import_resource_projection_evidence_json_schema_properties()

      :command_authority_handoff_json_schema_properties ->
        command_authority_handoff_json_schema_properties()

      :feedback_maneuver_handoff_json_schema_properties ->
        feedback_maneuver_handoff_json_schema_properties()

      :link_handoff_json_schema_properties ->
        link_handoff_json_schema_properties()

      :resource_availability_variance_json_schema_properties ->
        resource_availability_variance_json_schema_properties()

      :resource_projection_battery_handoff_json_schema_properties ->
        resource_projection_battery_handoff_json_schema_properties()

      :scoped_downlink_context_json_schema_properties ->
        scoped_downlink_context_json_schema_properties()

      :thermal_handoff_json_schema_properties ->
        thermal_handoff_json_schema_properties()

      :timeline_activity_precondition_handoff_json_schema_properties ->
        timeline_activity_precondition_handoff_json_schema_properties()

      :timeline_dependency_impact_handoff_json_schema_properties ->
        timeline_dependency_impact_handoff_json_schema_properties()

      :timeline_publication_handoff_json_schema_properties ->
        timeline_publication_handoff_json_schema_properties()
    end
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
      count_map_schema: non_negative_integer_count_map_json_schema(),
      timeline_publication_summary_source_schema:
        timeline_publication_summary_source_json_schema()
    )
  end

  defp command_authority_handoff_json_schema_properties do
    OrbitalDynamics.Schema.CommandAuthorityHandoffJsonSchema.properties()
  end

  defp resource_availability_variance_json_schema_properties do
    OrbitalDynamics.Schema.ResourceAvailabilityVarianceJsonSchema.properties()
  end

  defp timeline_activity_precondition_handoff_json_schema_properties do
    OrbitalDynamics.Schema.TimelineHandoffJsonSchema.activity_precondition_properties(
      timeline_capability: timeline_capabilities(),
      stable_id_array_schema: stable_id_array_schema(),
      string_array_schema: string_array_schema(),
      timeline_precondition_schema: timeline_precondition_json_schema(),
      timeline_activity_precondition_summary_source_schema:
        timeline_activity_precondition_summary_source_json_schema()
    )
  end

  defp link_handoff_json_schema_properties do
    OrbitalDynamics.Schema.LinkHandoffJsonSchema.properties(
      probability_schema: probability_json_schema()
    )
  end

  defp feedback_maneuver_handoff_json_schema_properties do
    OrbitalDynamics.Schema.FeedbackManeuverHandoffJsonSchema.properties(
      probability_schema: probability_json_schema()
    )
  end

  defp thermal_handoff_json_schema_properties do
    OrbitalDynamics.Schema.ThermalHandoffJsonSchema.properties(
      stable_id_pattern: @stable_id_pattern,
      probability_schema: probability_json_schema()
    )
  end

  defp cadence_import_status_json_schema do
    OrbitalDynamics.Schema.CadenceImportOperationalReadinessJsonSchema.status()
  end

  defp cadence_source_review_row_json_schema do
    OrbitalDynamics.Schema.CadenceSourceReviewRowJsonSchema.row(
      cadence_capability: OrbitalDynamics.CadenceImport.capability(),
      readiness_capability: OrbitalDynamics.OperationalReadiness.capabilities(),
      timeline_capability: timeline_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema: &cadence_source_review_row_json_schema_dependency/1,
      properties: &cadence_source_review_row_json_schema_properties/1
    )
  end

  defp cadence_source_review_row_json_schema_dependency(name) do
    case name do
      :activity_context_json_schema ->
        activity_context_json_schema()

      :branch_comparison_source_row_json_schema ->
        branch_comparison_source_row_json_schema()

      :branch_event_trust_boundary_status_counts_json_schema ->
        branch_event_trust_boundary_status_counts_json_schema()

      :candidate_activity_source_window_json_schema ->
        candidate_activity_source_window_json_schema()

      :candidate_rejection_source_json_schema ->
        candidate_rejection_source_json_schema()

      :contact_allocation_capacity_requirement_row_json_schema ->
        contact_allocation_capacity_requirement_row_json_schema()

      :contact_contention_deferred_priority_json_schema ->
        contact_contention_deferred_priority_json_schema()

      :non_negative_number_map_json_schema ->
        non_negative_number_map_json_schema()

      :number_or_string_json_schema ->
        number_or_string_json_schema()

      :operational_readiness_source_report_evidence_json_schema ->
        operational_readiness_source_report_evidence_json_schema()

      :operational_timeline_row_json_schema ->
        operational_timeline_row_json_schema()

      :policy_decision_evidence_json_schema ->
        policy_decision_evidence_json_schema()

      :policy_escalation_json_schema ->
        policy_escalation_json_schema()

      :priority_field_evidence_counts_json_schema ->
        priority_field_evidence_counts_json_schema()

      :probability_json_schema ->
        probability_json_schema()

      :quality_gate_source_report_evidence_json_schema ->
        quality_gate_source_report_evidence_json_schema()

      :semantic_change_details_json_schema ->
        semantic_change_details_json_schema()

      :source_evidence_json_schema ->
        source_evidence_json_schema()

      :source_execution_report_evidence_json_schema ->
        source_execution_report_evidence_json_schema()

      :source_freshness_report_evidence_json_schema ->
        source_freshness_report_evidence_json_schema()

      :source_schema_validation_report_evidence_json_schema ->
        source_schema_validation_report_evidence_json_schema()

      :source_window_lineage_json_schema ->
        source_window_lineage_json_schema()

      :stable_id_array_map_schema ->
        stable_id_array_map_schema()

      :stable_id_array_schema ->
        stable_id_array_schema()

      :string_array_schema ->
        string_array_schema()

      :timeline_activity_precondition_summary_source_json_schema ->
        timeline_activity_precondition_summary_source_json_schema()

      :timeline_activity_state_source_json_schema ->
        timeline_activity_state_source_json_schema()

      :timeline_diff_summary_source_json_schema ->
        timeline_diff_summary_source_json_schema()

      :timeline_identity_json_schema ->
        timeline_identity_json_schema()

      :timeline_lifecycle_state_source_json_schema ->
        timeline_lifecycle_state_source_json_schema()

      :timeline_link_json_schema ->
        timeline_link_json_schema()

      :timeline_preservation_source_json_schema ->
        timeline_preservation_source_json_schema()

      :timeline_protection_summary_json_schema ->
        timeline_protection_summary_json_schema()

      :timeline_transition_application_row_json_schema ->
        timeline_transition_application_row_json_schema()

      :timeline_transition_application_summary_source_json_schema ->
        timeline_transition_application_summary_source_json_schema()
    end
  end

  defp cadence_source_review_row_json_schema_properties(name) do
    case name do
      :branch_scoped_downlink_context_json_schema_properties ->
        branch_scoped_downlink_context_json_schema_properties()

      :cadence_import_operational_readiness_evidence_json_schema_properties ->
        cadence_import_operational_readiness_evidence_json_schema_properties()

      :cadence_import_resource_projection_evidence_json_schema_properties ->
        cadence_import_resource_projection_evidence_json_schema_properties()

      :command_authority_handoff_json_schema_properties ->
        command_authority_handoff_json_schema_properties()

      :feedback_maneuver_handoff_json_schema_properties ->
        feedback_maneuver_handoff_json_schema_properties()

      :link_handoff_json_schema_properties ->
        link_handoff_json_schema_properties()

      :resource_availability_variance_json_schema_properties ->
        resource_availability_variance_json_schema_properties()

      :resource_projection_battery_handoff_json_schema_properties ->
        resource_projection_battery_handoff_json_schema_properties()

      :scoped_downlink_context_json_schema_properties ->
        scoped_downlink_context_json_schema_properties()

      :thermal_handoff_json_schema_properties ->
        thermal_handoff_json_schema_properties()

      :timeline_activity_precondition_handoff_json_schema_properties ->
        timeline_activity_precondition_handoff_json_schema_properties()

      :timeline_dependency_impact_handoff_json_schema_properties ->
        timeline_dependency_impact_handoff_json_schema_properties()

      :timeline_publication_handoff_json_schema_properties ->
        timeline_publication_handoff_json_schema_properties()
    end
  end

  defp operator_review_row_json_schema do
    OrbitalDynamics.Schema.OperatorReviewRowJsonSchema.row(
      operator_review_capability: OrbitalDynamics.OperatorReview.capabilities(),
      readiness_capability: OrbitalDynamics.OperationalReadiness.capabilities(),
      timeline_capability: timeline_capabilities(),
      stable_id_pattern: @stable_id_pattern,
      schema: &operator_review_row_json_schema_dependency/1,
      properties: &operator_review_row_json_schema_properties/1
    )
  end

  defp operator_review_row_json_schema_dependency(name) do
    case name do
      :activity_context_json_schema ->
        activity_context_json_schema()

      :actual_data_rate_throughput_derivation_json_schema ->
        actual_data_rate_throughput_derivation_json_schema()

      :approval_requirement_json_schema ->
        approval_requirement_json_schema()

      :branch_comparison_source_row_json_schema ->
        branch_comparison_source_row_json_schema()

      :branch_event_trust_boundary_status_counts_json_schema ->
        branch_event_trust_boundary_status_counts_json_schema()

      :candidate_activity_source_window_json_schema ->
        candidate_activity_source_window_json_schema()

      :contact_allocation_capacity_requirement_row_json_schema ->
        contact_allocation_capacity_requirement_row_json_schema()

      :contact_contention_deferred_priority_json_schema ->
        contact_contention_deferred_priority_json_schema()

      :lifecycle_transition_json_schema ->
        lifecycle_transition_json_schema()

      :non_negative_number_map_json_schema ->
        non_negative_number_map_json_schema()

      :number_array_schema ->
        number_array_schema()

      :number_or_number_array_schema ->
        number_or_number_array_schema()

      :number_or_string_json_schema ->
        number_or_string_json_schema()

      :numeric_triplet_schema ->
        numeric_triplet_schema()

      :operational_readiness_evidence_json_schema ->
        operational_readiness_evidence_json_schema()

      :operational_readiness_gate_json_schema ->
        operational_readiness_gate_json_schema()

      :operational_readiness_source_report_evidence_json_schema ->
        operational_readiness_source_report_evidence_json_schema()

      :operational_timeline_row_json_schema ->
        operational_timeline_row_json_schema()

      :policy_decision_evidence_json_schema ->
        policy_decision_evidence_json_schema()

      :policy_decision_rule_match_json_schema ->
        policy_decision_rule_match_json_schema()

      :policy_escalation_json_schema ->
        policy_escalation_json_schema()

      :priority_field_evidence_counts_json_schema ->
        priority_field_evidence_counts_json_schema()

      :probability_json_schema ->
        probability_json_schema()

      :protection_decision_json_schema ->
        protection_decision_json_schema()

      :quality_gate_report_row_json_schema ->
        quality_gate_report_row_json_schema()

      :quality_gate_source_report_evidence_json_schema ->
        quality_gate_source_report_evidence_json_schema()

      :semantic_change_details_json_schema ->
        semantic_change_details_json_schema()

      :source_evidence_json_schema ->
        source_evidence_json_schema()

      :source_window_lineage_json_schema ->
        source_window_lineage_json_schema()

      :stable_id_array_map_schema ->
        stable_id_array_map_schema()

      :stable_id_array_schema ->
        stable_id_array_schema()

      :string_array_schema ->
        string_array_schema()

      :timeline_activity_precondition_summary_source_json_schema ->
        timeline_activity_precondition_summary_source_json_schema()

      :timeline_activity_state_source_json_schema ->
        timeline_activity_state_source_json_schema()

      :timeline_diff_summary_source_json_schema ->
        timeline_diff_summary_source_json_schema()

      :timeline_identity_json_schema ->
        timeline_identity_json_schema()

      :timeline_lifecycle_state_source_json_schema ->
        timeline_lifecycle_state_source_json_schema()

      :timeline_link_json_schema ->
        timeline_link_json_schema()

      :timeline_preservation_source_json_schema ->
        timeline_preservation_source_json_schema()

      :timeline_protection_summary_json_schema ->
        timeline_protection_summary_json_schema()

      :timeline_transition_application_row_json_schema ->
        timeline_transition_application_row_json_schema()

      :timeline_transition_application_summary_source_json_schema ->
        timeline_transition_application_summary_source_json_schema()
    end
  end

  defp operator_review_row_json_schema_properties(name) do
    case name do
      :branch_scoped_downlink_context_json_schema_properties ->
        branch_scoped_downlink_context_json_schema_properties()

      :command_authority_handoff_json_schema_properties ->
        command_authority_handoff_json_schema_properties()

      :feedback_maneuver_handoff_json_schema_properties ->
        feedback_maneuver_handoff_json_schema_properties()

      :link_handoff_json_schema_properties ->
        link_handoff_json_schema_properties()

      :resource_availability_variance_json_schema_properties ->
        resource_availability_variance_json_schema_properties()

      :resource_projection_battery_handoff_json_schema_properties ->
        resource_projection_battery_handoff_json_schema_properties()

      :scoped_downlink_context_json_schema_properties ->
        scoped_downlink_context_json_schema_properties()

      :thermal_handoff_json_schema_properties ->
        thermal_handoff_json_schema_properties()

      :timeline_activity_precondition_handoff_json_schema_properties ->
        timeline_activity_precondition_handoff_json_schema_properties()

      :timeline_dependency_impact_handoff_json_schema_properties ->
        timeline_dependency_impact_handoff_json_schema_properties()

      :timeline_publication_handoff_json_schema_properties ->
        timeline_publication_handoff_json_schema_properties()
    end
  end

  defp maybe_add_const(property, "schema_contract", name, _contract) do
    property
    |> Map.put("const", name)
    |> Map.put("description", "Stable executable contract identifier")
  end

  defp maybe_add_const(property, "schema_version", _name, contract) do
    property
    |> Map.put("const", contract["schema_version"])
    |> Map.put("description", "Artifact schema version")
  end

  defp maybe_add_const(property, "artifact_type", _name, contract) do
    Map.put(property, "const", contract["artifact_family"])
  end

  defp maybe_add_const(property, _field, _name, _contract), do: property

  defp maybe_add_stable_id_pattern(%{"type" => "string"} = property, field) do
    if stable_id_field?(field) do
      Map.put(property, "pattern", @stable_id_pattern)
    else
      property
    end
  end

  defp maybe_add_stable_id_pattern(property, _field), do: property

  defp stable_id_field?(field), do: field == "id" or String.ends_with?(field, "_id")

  defp validate_candidate_refresh_source_report_provenance(
         issues,
         artifact
       ) do
    OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_source_report_provenance(
      issues,
      artifact,
      candidate_refresh_report_contract_callbacks()
    )
  end

  defp validate_contact_intent_direction_routing(issues, path, value, summary) do
    OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_contact_intent_direction_routing(
      issues,
      path,
      value,
      summary,
      candidate_refresh_report_contract_callbacks()
    )
  end

  defp validate_timeline_publication_context(issues, path, summary) do
    OrbitalDynamics.Schema.CandidateRefreshReportContracts.validate_timeline_publication_context(
      issues,
      path,
      summary,
      candidate_refresh_report_contract_callbacks()
    )
  end

  defp validate_contract(@activity_template, contract, artifact) do
    OrbitalDynamics.Schema.ActivityTemplateContracts.validate(
      [],
      "$",
      artifact,
      contract,
      activity_template_contract_callbacks()
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
    |> validate_proposed_contact("$", artifact)
  end

  defp validate_contract(@contact_intent, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_intent("$", artifact)
  end

  defp validate_contract(@contact_intent_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_intent_summary("$", artifact)
  end

  defp validate_contract(@candidate_activity, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_candidate_activity("$", artifact)
  end

  defp validate_contract(@candidate_diff_report, _contract, artifact) do
    validate_optional_candidate_diff_report([], "$", artifact)
  end

  defp validate_contract(@link_capacity_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_link_capacity_report("$", artifact)
  end

  defp validate_contract(@link_capacity_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_link_capacity_summary("$", artifact)
  end

  defp validate_contract(@relay_data_path_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_relay_data_path_summary("$", artifact)
  end

  defp validate_contract(@contact_contention_report, _contract, artifact) do
    []
    |> validate_contact_contention_report("$", artifact)
  end

  defp validate_contract(@contact_contention_resolution_report, _contract, artifact) do
    []
    |> validate_contact_contention_resolution_report("$", artifact)
  end

  defp validate_contract(@contact_contention_resolution_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ContactContentionResolutionSummaryContracts.validate(
      "$",
      artifact,
      contact_contention_resolution_summary_contract_callbacks()
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
    |> validate_station_calendar_provider("$", artifact)
  end

  defp validate_contract(@station_calendar_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_optional_station_calendar_report("$", artifact)
  end

  defp validate_contract(@station_calendar_precedence_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryContracts.validate(
      "$",
      artifact,
      station_calendar_precedence_summary_contract_callbacks()
    )
  end

  defp validate_contract(@station_reservation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.StationReservationReportContracts.validate(
      "$",
      artifact,
      station_reservation_report_contract_callbacks()
    )
  end

  defp validate_contract(@station_reservation_review_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_station_reservation_review_summary("$", artifact)
  end

  defp validate_contract(@station_reservation_hold_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_station_reservation_hold_summary("$", artifact)
  end

  defp validate_contract(@station_reservation_hold_import_readiness_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_station_reservation_hold_import_readiness_summary("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_provider_counteroffer_report("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_review_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_provider_counteroffer_review_summary("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_import_readiness_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_provider_counteroffer_import_readiness_summary("$", artifact)
  end

  defp validate_contract(@provider_counteroffer_plan_impact_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_provider_counteroffer_plan_impact_summary("$", artifact)
  end

  defp validate_contract(@resource_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_resource_summary("$", artifact)
  end

  defp validate_contract(@resource_projection_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_resource_projection_report("$", artifact)
  end

  defp validate_contract(@resource_projection_flow_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_resource_projection_flow_summary("$", artifact)
  end

  defp validate_contract(@contact_filter_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_contact_filter_report("$", artifact)
  end

  defp validate_contract(@resource_filter_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_resource_filter_report("$", artifact)
  end

  defp validate_contract(@resource_filter_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ResourceFilterSummaryContracts.validate(
      "$",
      artifact,
      resource_filter_summary_contract_callbacks()
    )
  end

  defp validate_contract(@realized_activity, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_realized_activity("$", artifact)
  end

  defp validate_contract(@realized_state_snapshot, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_realized_state_snapshot("$", artifact)
  end

  defp validate_contract(@timeline_feedback_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineFeedbackReportContracts.validate(
      "$",
      artifact,
      timeline_feedback_report_contract_callbacks()
    )
  end

  defp validate_contract(@candidate_rejection_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_candidate_rejection_report("$", artifact)
  end

  defp validate_contract(@plan_delta, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_plan_delta("$", artifact)
  end

  defp validate_contract(@approval_requirement, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_approval_requirement("$", artifact)
  end

  defp validate_contract(@policy_decision, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_policy_decision("$", artifact)
  end

  defp validate_contract(@policy_bundle, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_policy_bundle("$", artifact)
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
    |> validate_operational_readiness_report("$", artifact)
  end

  defp validate_contract(@operational_import_eligibility_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_import_eligibility_summary("$", artifact)
  end

  defp validate_contract(@operational_readiness_gate_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_readiness_gate_summary("$", artifact)
  end

  defp validate_contract(@operational_execution_boundary_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_execution_boundary_summary("$", artifact)
  end

  defp validate_contract(@operational_quality_gate_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_quality_gate_summary("$", artifact)
  end

  defp validate_contract(
         @operational_quality_gate_unavailable_resource_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_quality_gate_unavailable_resource_summary("$", artifact)
  end

  defp validate_contract(
         @operational_quality_gate_operator_training_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_quality_gate_operator_training_summary("$", artifact)
  end

  defp validate_contract(
         @operational_quality_gate_schema_validation_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_quality_gate_schema_validation_summary("$", artifact)
  end

  defp validate_contract(
         @operational_quality_gate_import_readiness_summary,
         contract,
         artifact
       ) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_operational_quality_gate_import_readiness_summary("$", artifact)
  end

  defp validate_contract(@quality_gate_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.QualityGateReportContracts.validate_report(
      "$",
      artifact,
      quality_gate_report_contract_callbacks()
    )
  end

  defp validate_contract(@environment_model_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_environment_model_capability("$", artifact)
  end

  defp validate_contract(@environment_provider_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_environment_provider_capability("$", artifact)
  end

  defp validate_contract(@subsystem_model_capability, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_subsystem_model_capability("$", artifact)
  end

  defp validate_contract(@schema_validation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReportContracts.validate_report(
      "$",
      artifact,
      validation_report_contract_callbacks()
    )
  end

  defp validate_contract(@schema_validation_batch_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ValidationReportContracts.validate_batch(
      "$",
      artifact,
      validation_report_contract_callbacks()
    )
  end

  defp validate_contract(@schema_migration_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.SchemaMigrationContracts.validate(
      "$",
      artifact,
      schema_migration_contract_callbacks()
    )
  end

  defp validate_contract(@campaign_request_lint, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LintContracts.validate_campaign_request(
      "$",
      artifact,
      lint_contract_callbacks()
    )
  end

  defp validate_contract(@study_manifest_lint, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.LintContracts.validate_study_manifest(
      "$",
      artifact,
      lint_contract_callbacks()
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
      artifact,
      study_benchmark_contract_callbacks()
    )
  end

  defp validate_contract(@manifest_field_reference, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ManifestFieldReferenceContracts.validate(
      "$",
      artifact,
      manifest_field_reference_contract_callbacks()
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
      result_artifact_contract_callbacks()
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
    |> validate_maneuver_recommendation("$", artifact)
  end

  defp validate_contract(@maneuver_review_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_maneuver_review_report("$", artifact)
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
      artifact,
      optimizer_objective_contract_callbacks()
    )
  end

  defp validate_contract(@objective_satisfaction_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_objective_satisfaction_report(
      "$",
      artifact,
      optimizer_objective_contract_callbacks()
    )
  end

  defp validate_contract(@ranking_comparison_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_ranking_comparison_report(
      "$",
      artifact,
      optimizer_objective_contract_callbacks()
    )
  end

  defp validate_contract(@pareto_frontier_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.ParetoFrontierContracts.validate(
      "$",
      artifact,
      pareto_frontier_contract_callbacks()
    )
  end

  defp validate_contract(@operational_timeline_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.OperationalTimelineReportContracts.validate(
      "$",
      artifact,
      operational_timeline_report_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_diff_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDiffReportContracts.validate(
      "$",
      artifact,
      timeline_diff_report_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_diff_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDiffSummaryContracts.validate(
      "$",
      artifact,
      timeline_diff_summary_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_integrity_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate(
      "$",
      artifact,
      timeline_integrity_report_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_dependency_impact_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate(
      "$",
      artifact,
      timeline_dependency_impact_summary_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_publication_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePublicationSummaryContracts.validate(
      "$",
      artifact,
      timeline_publication_summary_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_activity_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityStateContracts.validate(
      "$",
      artifact,
      timeline_activity_state_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_activity_precondition_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
      "$",
      artifact,
      timeline_activity_precondition_summary_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_activity_status_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_status_state(
      "$",
      artifact,
      timeline_activity_lifecycle_state_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_activity_approval_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_approval_state(
      "$",
      artifact,
      timeline_activity_lifecycle_state_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_activity_lifecycle_state, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts.validate_lifecycle_state(
      "$",
      artifact,
      timeline_activity_lifecycle_state_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_preservation_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePreservationContracts.validate_report(
      "$",
      artifact,
      timeline_preservation_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_preservation_status, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelinePreservationContracts.validate_status(
      "$",
      artifact,
      timeline_preservation_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_lifecycle_state_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.TimelineLifecycleStateSummaryContracts.validate(
      "$",
      artifact,
      timeline_lifecycle_state_summary_contract_callbacks()
    )
  end

  defp validate_contract(@timeline_transition_application_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_timeline_transition_application_report("$", artifact)
  end

  defp validate_contract(@timeline_transition_application_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_timeline_transition_application_summary("$", artifact)
  end

  defp validate_contract(@command_window_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.CommandWindowReportContracts.validate(
      "$",
      artifact,
      command_window_report_contract_callbacks()
    )
  end

  defp validate_contract(@branch_comparison_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> OrbitalDynamics.Schema.BranchComparisonReportContracts.validate(
      "$",
      artifact,
      branch_comparison_report_contract_callbacks()
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
      artifact,
      optimizer_objective_contract_callbacks()
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
    |> validate_spacecraft_state_estimate("$", artifact)
  end

  defp validate_contract(@maneuver_execution_delta, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_maneuver_execution_delta("$", artifact)
  end

  defp validate_contract(@candidate_refresh, contract, artifact) do
    OrbitalDynamics.Schema.CandidateRefreshContracts.validate(
      [],
      artifact,
      contract["required_fields"],
      candidate_refresh_contract_callbacks()
    )
  end

  defp validate_contract(@candidate_diff_row, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "candidate_diff_row.v1")
    |> validate_candidate_diff_row("$", artifact)
  end

  defp validate_contract(@freshness_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_optional_freshness_report("$", artifact)
  end

  defp validate_contract(@invalidated_candidate, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "invalidated_candidate.v1")
    |> validate_invalidated_candidate("$", artifact)
  end

  defp validate_contract(@refresh_budget_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_refresh_budget_report("$", artifact)
  end

  defp validate_contract(@refreshed_window, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "refreshed_window.v1")
    |> validate_refreshed_window("$", artifact)
  end

  defp validate_contract(@remaining_horizon, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_remaining_horizon("$", artifact)
  end

  defp validate_contract(@source_window_lineage, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> expect_equal("$", artifact, "schema_contract", "source_window_lineage.v1")
    |> validate_source_window_lineage("$", artifact)
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
    |> validate_validation_reference_report("$", artifact)
  end

  defp validate_contract(@validation_check, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_validation_check("$", artifact)
  end

  defp validate_contract(@validation_record, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_validation_record("$", artifact)
  end

  defp validate_contract(@model_acceptance_report, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_model_acceptance_report("$", artifact)
  end

  defp validate_contract(@validation_safety_case_summary, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
    |> validate_validation_safety_case_summary("$", artifact)
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
      campaign_strategy_contract_callbacks()
    )
  end

  defp validate_contract(_name, contract, artifact) do
    []
    |> require_fields("$", artifact, contract["required_fields"])
  end

  defp candidate_refresh_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_number: &expect_number/4,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_candidate_refresh_publication_lineage_fields:
        &validate_candidate_refresh_publication_lineage_fields/2,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_candidate_refresh_source_report_provenance:
        &validate_candidate_refresh_source_report_provenance/2,
      validate_operational_feedback: &validate_operational_feedback/3,
      require_nested: &require_nested/4,
      validate_refreshed_windows: &validate_refreshed_windows/2,
      validate_rows: &validate_rows/4,
      validate_candidate_activity: &validate_candidate_activity/3,
      validate_contact_intent: &validate_contact_intent/3,
      validate_optional_contact_allocation_report: &validate_optional_contact_allocation_report/2,
      validate_optional_contact_filter_report: &validate_optional_contact_filter_report/2,
      validate_resource_summary: &validate_resource_summary/3,
      validate_optional_resource_filter_report: &validate_optional_resource_filter_report/2,
      validate_optional_candidate_diff_report: &validate_optional_candidate_diff_report/3,
      validate_optional_candidate_rejection_report:
        &validate_optional_candidate_rejection_report/3,
      validate_optional_freshness_report: &validate_optional_freshness_report/3,
      validate_optional_refresh_budget_report: &validate_optional_refresh_budget_report/3,
      validate_invalidated_candidate: &validate_invalidated_candidate/3,
      validate_embedded_validation_record: &validate_embedded_validation_record/3,
      validate_source_window_lineage: &validate_source_window_lineage/3
    ]
  end

  defp candidate_refresh_report_contract_callbacks do
    [
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_nested_non_negative_number_map: &validate_nested_non_negative_number_map/3,
      validate_non_negative_number_list: &validate_non_negative_number_list/3,
      validate_number_array_map: &validate_number_array_map/3,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_string_list_map: &validate_string_list_map/4,
      validate_operational_readiness_resource_context:
        &validate_operational_readiness_resource_context/3,
      validate_operational_readiness_adapter_boundary_context:
        &validate_operational_readiness_adapter_boundary_context/3,
      validate_operational_readiness_cadence_import_context:
        &validate_operational_readiness_cadence_import_context/3,
      safety_case_count_fields: &safety_case_count_fields/0,
      error: &error/2
    ]
  end

  defp candidate_diff_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_rows: &validate_rows/4,
      validate_optional_rows: &validate_optional_rows/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      list_count: &list_count/2,
      row_count_sum: &row_count_sum/2,
      expect_one_of: &expect_one_of/5,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_list: &expect_optional_list/4,
      validate_candidate_refresh_scoped_context_fields:
        &validate_candidate_refresh_scoped_context_fields/3,
      validate_interval: &validate_interval/3,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      error: &error/2
    ]
  end

  defp contact_intent_summary_contract_callbacks do
    [
      error: &error/2,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_nested_non_negative_number_map: &validate_nested_non_negative_number_map/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_contact_intent_direction_routing: &validate_contact_intent_direction_routing/4,
      contact_intent_model_limits: &contact_intent_model_limits/0,
      station_capacity_value_path_assumptions:
        &contact_intent_station_capacity_value_path_assumptions/0,
      required_capacity_value_path_assumptions:
        &contact_intent_required_capacity_value_path_assumptions/0,
      required_capacity_fraction_source_values:
        &contact_intent_required_capacity_fraction_source_values/0
    ]
  end

  defp link_capacity_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_number: &expect_number/4,
      expect_field_equals: &expect_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_link_capacity_assumptions: &validate_link_capacity_assumptions/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_numeric_map: &validate_numeric_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_number_list_items: &validate_number_list_items/4,
      link_capacity_model_limits: &link_capacity_model_limits/0
    ]
  end

  defp relay_data_path_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      require_fields: &require_fields/4,
      validate_rows: &validate_rows/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      relay_data_path_model_limits: &relay_data_path_model_limits/0
    ]
  end

  defp contact_allocation_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_number_field_equals: &expect_number_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_number_list_items: &validate_number_list_items/4,
      contact_allocation_model_limits: &contact_allocation_model_limits/0,
      contact_allocation_capacity_pack_statuses: &contact_allocation_capacity_pack_statuses/0,
      contact_allocation_reduced_capacity_pack_statuses:
        &contact_allocation_reduced_capacity_pack_statuses/0,
      contact_allocation_station_reservation_match_statuses:
        &contact_allocation_station_reservation_match_statuses/0,
      contact_allocation_station_reservation_expiration_statuses:
        &contact_allocation_station_reservation_expiration_statuses/0,
      contact_allocation_row_statuses: &contact_allocation_row_statuses/0,
      contact_allocation_effective_row_statuses: &contact_allocation_effective_row_statuses/0,
      contact_allocation_station_unavailable_aliases:
        &contact_allocation_station_unavailable_aliases/0,
      contact_allocation_station_blocking_availability:
        &contact_allocation_station_blocking_availability/0,
      contact_allocation_station_availability_precedence:
        &contact_allocation_station_availability_precedence/0,
      contact_allocation_provider_direction_aliases:
        &contact_allocation_provider_direction_aliases/0,
      contact_allocation_required_capacity_fraction_source_values:
        &contact_allocation_required_capacity_fraction_source_values/0,
      contact_allocation_required_capacity_value_path_assumptions:
        &contact_allocation_required_capacity_value_path_assumptions/0,
      contact_allocation_default_required_capacity_value_path_assumptions:
        &contact_allocation_default_required_capacity_value_path_assumptions/0,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      contact_allocation_review_row?: &contact_allocation_review_row?/1,
      contact_allocation_station_pressure_rows: &contact_allocation_station_pressure_rows/1,
      contact_allocation_resource_blocked_rows: &contact_allocation_resource_blocked_rows/1,
      contact_allocation_capacity_pack_rows: &contact_allocation_capacity_pack_rows/1,
      contact_allocation_selected_capacity_pack_rows:
        &contact_allocation_selected_capacity_pack_rows/1,
      contact_allocation_deferred_capacity_pack_rows:
        &contact_allocation_deferred_capacity_pack_rows/1,
      contact_allocation_reservation_expiration_rows:
        &contact_allocation_reservation_expiration_rows/2,
      contact_allocation_invalid_contact_input_ids:
        &contact_allocation_invalid_contact_input_ids/1,
      contact_allocation_status_blocked_contact_ids:
        &contact_allocation_status_blocked_contact_ids/1,
      contact_allocation_row_contact_ids: &contact_allocation_row_contact_ids/1,
      contact_allocation_capacity_pack_required_fraction:
        &contact_allocation_capacity_pack_required_fraction/1,
      contact_allocation_capacity_pack_required_fraction_by_field:
        &contact_allocation_capacity_pack_required_fraction_by_field/2,
      contact_allocation_reservation_expires_at_values:
        &contact_allocation_reservation_expires_at_values/1,
      contact_allocation_reservation_expiration_count:
        &contact_allocation_reservation_expiration_count/2,
      contact_allocation_earliest_reservation_expires_at_s:
        &contact_allocation_earliest_reservation_expires_at_s/1,
      contact_allocation_station_pressure_ids_by_availability:
        &contact_allocation_station_pressure_ids_by_availability/1,
      contact_allocation_reservation_ids_by_expiration_status:
        &contact_allocation_reservation_ids_by_expiration_status/1
    ]
  end

  defp contact_allocation_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_number: &expect_number/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_number_field_equals: &expect_number_field_equals/6,
      expect_probability_range: &expect_probability_range/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_number_list_items: &validate_number_list_items/4,
      validate_rows: &validate_rows/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_optional_station_calendar_report: &validate_optional_station_calendar_report/2,
      validate_optional_contact_filter_report: &validate_optional_contact_filter_report/2,
      validate_optional_contact_contention_report: &validate_optional_contact_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &validate_optional_contact_contention_resolution_report/2,
      validate_contact_allocation_report_counts: &validate_contact_allocation_report_counts/3,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      frequency_map: &frequency_map/2,
      id_array_count_map: &id_array_count_map/1,
      list_count: &list_count/2,
      row_ids_by_direction_and_ground_station: &row_ids_by_direction_and_ground_station/2,
      row_ids_by_field: &row_ids_by_field/3,
      row_ids_by_field_value: &row_ids_by_field_value/4,
      row_ids_by_string_field: &row_ids_by_string_field/3,
      row_unique_values: &row_unique_values/2,
      validate_optional_actual_data_rate_throughput_derivation:
        &validate_optional_actual_data_rate_throughput_derivation/4,
      validate_contact_contention_deferred_priority:
        &validate_contact_contention_deferred_priority/3,
      validate_priority_field_evidence_counts: &validate_priority_field_evidence_counts/3,
      validate_override_count_matches_ids: &validate_override_count_matches_ids/5,
      validate_station_calendar_contact_counts: &validate_station_calendar_contact_counts/3
    ]
  end

  defp contact_allocation_handoff_contract_callbacks do
    [
      expect_optional_type: &expect_optional_type/5,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_contact_allocation_duplicate_evidence:
        &validate_contact_allocation_duplicate_evidence/3,
      validate_override_count_matches_ids: &validate_override_count_matches_ids/5,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3
    ]
  end

  defp contact_allocation_station_pressure_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      contact_allocation_model_limits: &contact_allocation_model_limits/0,
      contact_allocation_station_unavailable_aliases:
        &contact_allocation_station_unavailable_aliases/0,
      contact_allocation_station_blocking_availability:
        &contact_allocation_station_blocking_availability/0,
      contact_allocation_station_availability_precedence:
        &contact_allocation_station_availability_precedence/0,
      contact_allocation_provider_direction_aliases:
        &contact_allocation_provider_direction_aliases/0,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      contact_allocation_station_pressure_rows: &contact_allocation_station_pressure_rows/1,
      contact_allocation_review_row?: &contact_allocation_review_row?/1,
      contact_allocation_row_contact_ids: &contact_allocation_row_contact_ids/1,
      contact_allocation_station_pressure_ids_by_availability:
        &contact_allocation_station_pressure_ids_by_availability/1
    ]
  end

  defp contact_allocation_capacity_pack_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_number_field_equals: &expect_number_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      contact_allocation_model_limits: &contact_allocation_model_limits/0,
      contact_allocation_capacity_pack_statuses: &contact_allocation_capacity_pack_statuses/0,
      contact_allocation_reduced_capacity_pack_statuses:
        &contact_allocation_reduced_capacity_pack_statuses/0,
      contact_allocation_required_capacity_fraction_source_values:
        &contact_allocation_required_capacity_fraction_source_values/0,
      contact_allocation_required_capacity_value_path_assumptions:
        &contact_allocation_required_capacity_value_path_assumptions/0,
      contact_allocation_default_required_capacity_value_path_assumptions:
        &contact_allocation_default_required_capacity_value_path_assumptions/0,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      contact_allocation_capacity_pack_rows: &contact_allocation_capacity_pack_rows/1,
      contact_allocation_selected_capacity_pack_rows:
        &contact_allocation_selected_capacity_pack_rows/1,
      contact_allocation_deferred_capacity_pack_rows:
        &contact_allocation_deferred_capacity_pack_rows/1,
      contact_allocation_capacity_pack_required_fraction:
        &contact_allocation_capacity_pack_required_fraction/1,
      contact_allocation_capacity_pack_required_fraction_by_field:
        &contact_allocation_capacity_pack_required_fraction_by_field/2
    ]
  end

  defp contact_allocation_provider_reservation_request_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      contact_allocation_model_limits: &contact_allocation_model_limits/0,
      contact_allocation_provider_reservation_request_statuses:
        &contact_allocation_provider_reservation_request_statuses/0,
      contact_allocation_station_reservation_match_statuses:
        &contact_allocation_station_reservation_match_statuses/0,
      contact_allocation_provider_direction_aliases:
        &contact_allocation_provider_direction_aliases/0,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      contact_allocation_row_contact_ids: &contact_allocation_row_contact_ids/1,
      contact_allocation_reservation_expiration_row?:
        &contact_allocation_reservation_expiration_row?/1,
      contact_allocation_reservation_ids: &contact_allocation_reservation_ids/1
    ]
  end

  defp contact_allocation_reservation_conflict_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_number_field_equals: &expect_number_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_number_list_items: &validate_number_list_items/4,
      contact_allocation_model_limits: &contact_allocation_model_limits/0,
      contact_allocation_station_reservation_match_statuses:
        &contact_allocation_station_reservation_match_statuses/0,
      contact_allocation_reservation_conflict_match_statuses:
        &contact_allocation_reservation_conflict_match_statuses/0,
      contact_allocation_station_reservation_expiration_statuses:
        &contact_allocation_station_reservation_expiration_statuses/0,
      contact_allocation_provider_direction_aliases:
        &contact_allocation_provider_direction_aliases/0,
      validate_contact_allocation_row: &validate_contact_allocation_row/3,
      contact_allocation_reservation_expiration_row?:
        &contact_allocation_reservation_expiration_row?/1,
      contact_allocation_review_row?: &contact_allocation_review_row?/1,
      contact_allocation_reservation_expiration_rows:
        &contact_allocation_reservation_expiration_rows/2,
      contact_allocation_reservation_row_ids: &contact_allocation_reservation_row_ids/1,
      contact_allocation_reservation_expires_at_values:
        &contact_allocation_reservation_expires_at_values/1,
      contact_allocation_earliest_reservation_expires_at_s:
        &contact_allocation_earliest_reservation_expires_at_s/1,
      contact_allocation_row_contact_ids: &contact_allocation_row_contact_ids/1,
      contact_allocation_reservation_ids_by_expiration_status:
        &contact_allocation_reservation_ids_by_expiration_status/1,
      contact_allocation_pressure_value?: &contact_allocation_pressure_value?/1
    ]
  end

  defp operational_import_eligibility_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_operational_readiness_gate: &validate_operational_readiness_gate/3,
      operational_import_eligibility_summary_model_limits:
        &operational_import_eligibility_summary_model_limits/0,
      operational_readiness_import_classification: &operational_readiness_import_classification/1,
      operational_readiness_level: &operational_readiness_level/1,
      operational_readiness_report_status: &operational_readiness_report_status/1,
      non_negative_integer_sum: &non_negative_integer_sum/1,
      gate_status_count: &gate_status_count/2
    ]
  end

  defp operational_readiness_gate_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_operational_readiness_gate: &validate_operational_readiness_gate/3,
      operational_readiness_gate_summary_model_limits:
        &operational_readiness_gate_summary_model_limits/0,
      operational_readiness_import_classification: &operational_readiness_import_classification/1,
      operational_readiness_level: &operational_readiness_level/1,
      operational_readiness_report_status: &operational_readiness_report_status/1,
      gate_status_count: &gate_status_count/2
    ]
  end

  defp operational_execution_boundary_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_operational_readiness_gate: &validate_operational_readiness_gate/3,
      operational_execution_boundary_summary_model_limits:
        &operational_execution_boundary_summary_model_limits/0,
      operational_readiness_level: &operational_readiness_level/1,
      operational_readiness_report_status: &operational_readiness_report_status/1,
      quality_gate_execution_boundary: &quality_gate_execution_boundary/1,
      non_negative_integer_sum: &non_negative_integer_sum/1,
      error: &error/2
    ]
  end

  defp operational_quality_gate_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_quality_gate_row: &validate_quality_gate_row/3,
      quality_gate_summary_model_limits: &quality_gate_summary_model_limits/0,
      operational_readiness_import_classification: &operational_readiness_import_classification/1,
      operational_readiness_level: &operational_readiness_level/1,
      operational_readiness_report_status: &operational_readiness_report_status/1,
      quality_gate_execution_boundary: &quality_gate_execution_boundary/1,
      quality_gate_status_count: &quality_gate_status_count/2,
      quality_gate_ids_by: &quality_gate_ids_by/2,
      quality_gate_row_ids_by: &quality_gate_row_ids_by/2,
      quality_gate_ids: &quality_gate_ids/2,
      stable_sorted_ids: &stable_sorted_ids/1
    ]
  end

  defp quality_gate_report_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_quality_gate_row: &validate_quality_gate_row/3,
      quality_gate_report_model_limits: &quality_gate_report_model_limits/0,
      operational_readiness_import_classification: &operational_readiness_import_classification/1,
      operational_readiness_level: &operational_readiness_level/1,
      operational_readiness_report_status: &operational_readiness_report_status/1,
      quality_gate_execution_boundary: &quality_gate_execution_boundary/1,
      quality_gate_status_count: &quality_gate_status_count/2,
      quality_gate_ids_by: &quality_gate_ids_by/2,
      quality_gate_row_ids_by: &quality_gate_row_ids_by/2,
      quality_gate_ids: &quality_gate_ids/2,
      error: &error/2
    ]
  end

  defp operational_quality_gate_unavailable_resource_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      quality_gate_unavailable_resource_summary_model_limits:
        &quality_gate_unavailable_resource_summary_model_limits/0,
      stable_id_array_map_value_count: &stable_id_array_map_value_count/1,
      stable_id_array_map_ids: &stable_id_array_map_ids/1,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      unavailable_resource_reason_ids: &unavailable_resource_reason_ids/1,
      resource_availability_reason_ids: &resource_availability_reason_ids/1
    ]
  end

  defp operational_quality_gate_operator_training_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      quality_gate_operator_training_summary_model_limits:
        &quality_gate_operator_training_summary_model_limits/0,
      stable_id_array_map_value_count: &stable_id_array_map_value_count/1,
      stable_id_array_map_ids: &stable_id_array_map_ids/1,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      positive_count_map_keys: &positive_count_map_keys/1,
      list_or_empty: &list_or_empty/1
    ]
  end

  defp operational_quality_gate_schema_validation_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      quality_gate_schema_validation_summary_model_limits:
        &quality_gate_schema_validation_summary_model_limits/0,
      stable_id_array_map_value_count: &stable_id_array_map_value_count/1,
      stable_id_array_map_ids: &stable_id_array_map_ids/1,
      positive_count_map_keys: &positive_count_map_keys/1,
      non_negative_integer_map_value: &non_negative_integer_map_value/2,
      error: &error/2
    ]
  end

  defp operational_quality_gate_import_readiness_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_timeline_publication_context: &validate_timeline_publication_context/3,
      quality_gate_import_readiness_summary_model_limits:
        &quality_gate_import_readiness_summary_model_limits/0,
      stable_id_array_map_value_count: &stable_id_array_map_value_count/1,
      stable_id_array_map_ids: &stable_id_array_map_ids/1,
      positive_count_map_keys: &positive_count_map_keys/1,
      non_negative_integer_map_value: &non_negative_integer_map_value/2,
      error: &error/2
    ]
  end

  defp timeline_activity_precondition_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_optional_timeline_preconditions: &validate_optional_timeline_preconditions/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      timeline_report_model_limits: &timeline_report_model_limits/0
    ]
  end

  defp timeline_activity_lifecycle_state_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_lifecycle_state_protection_consistency:
        &validate_lifecycle_state_protection_consistency/4,
      timeline_report_model_limits: &timeline_report_model_limits/0
    ]
  end

  defp timeline_preservation_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      validate_rows: &validate_rows/4,
      timeline_report_model_limits: &timeline_report_model_limits/0,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      error: &error/2
    ]
  end

  defp timeline_lifecycle_state_summary_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_number: &expect_number/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_rows: &validate_rows/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_lifecycle_state_source_protection_decision:
        &validate_optional_lifecycle_state_source_protection_decision/4,
      timeline_report_model_limits: &timeline_report_model_limits/0
    ]
  end

  defp activity_template_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_id: &validate_stable_id/3,
      validate_string_list_items: &validate_string_list_items/4,
      list_count: &list_count/2,
      activity_template_activity_types: &activity_template_activity_types/0,
      activity_template_activity_statuses: &activity_template_activity_statuses/0,
      activity_template_approval_statuses: &activity_template_approval_statuses/0,
      activity_template_precondition_types: &activity_template_precondition_types/0,
      activity_template_precondition_statuses: &activity_template_precondition_statuses/0,
      error: &error/2
    ]
  end

  defp validation_acceptance_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      validate_stable_ids: &validate_stable_ids/4,
      expect_one_of: &expect_one_of/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_type: &expect_type/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_validation_record: &validate_validation_record/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_optional_rows: &validate_optional_rows/4,
      error: &error/2
    ]
  end

  defp provider_counteroffer_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_rows: &validate_rows/4,
      provider_counteroffer_report_models: &provider_counteroffer_report_models/0,
      provider_counteroffer_numeric_value_count: &provider_counteroffer_numeric_value_count/2,
      provider_counteroffer_numeric_value_sum: &provider_counteroffer_numeric_value_sum/2,
      provider_counteroffer_numeric_value_min: &provider_counteroffer_numeric_value_min/2,
      provider_counteroffer_numeric_rows: &provider_counteroffer_numeric_rows/2,
      provider_counteroffer_timing_shift_rows: &provider_counteroffer_timing_shift_rows/1,
      provider_counteroffer_stable_ids: &provider_counteroffer_stable_ids/2,
      provider_counteroffer_ids: &provider_counteroffer_ids/1,
      provider_counteroffer_ids_by: &provider_counteroffer_ids_by/2,
      provider_counteroffer_status_count: &provider_counteroffer_status_count/3,
      validate_provider_counteroffer_row: &validate_provider_counteroffer_row/3,
      frequency_map: &frequency_map/2
    ]
  end

  defp command_window_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_number: &expect_number/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_rows: &validate_rows/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_interval: &validate_interval/3,
      row_ids_by_field: &row_ids_by_field/3,
      command_window_report_model_limits: &command_window_report_model_limits/0,
      error: &error/2
    ]
  end

  defp station_reservation_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_nested_stable_id_array_map: &validate_nested_stable_id_array_map/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_number_list_items: &validate_number_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      frequency_map: &frequency_map/2,
      id_array_count_map: &id_array_count_map/1,
      error: &error/2,
      station_calendar_report_model_limits: &station_calendar_report_model_limits/0
    ]
  end

  defp station_reservation_report_contract_callbacks do
    [
      station_reservation_report_models: &station_reservation_report_models/0,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_number_list_items: &validate_number_list_items/4,
      frequency_map: &frequency_map/2
    ]
  end

  defp station_calendar_precedence_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      station_calendar_report_model_limits: &station_calendar_report_model_limits/0,
      stable_id_array_map_value_count: &stable_id_array_map_value_count/1,
      id_array_count_map: &id_array_count_map/1
    ]
  end

  defp station_calendar_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_number: &expect_number/4,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_string_lists: &validate_optional_string_lists/4,
      validate_number_list_items: &validate_number_list_items/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_rows: &validate_rows/4,
      validate_optional_rows: &validate_optional_rows/4,
      station_calendar_report_model: &station_calendar_report_model/0,
      station_calendar_report_model_limits: &station_calendar_report_model_limits/0,
      validate_branch_event_trust_boundary_status_count_map:
        &validate_branch_event_trust_boundary_status_count_map/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      frequency_map: &frequency_map/2,
      row_ids_by_field: &row_ids_by_field/3,
      list_count: &list_count/2,
      error: &error/2
    ]
  end

  defp station_calendar_provider_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_number: &expect_optional_number/4,
      validate_rows: &validate_rows/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      error: &error/2
    ]
  end

  defp resource_filter_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_rows: &validate_rows/4,
      validate_suppressed_candidate: &validate_suppressed_candidate/3,
      validate_invalid_resource_summary_input: &validate_invalid_resource_summary_input/3,
      resource_filter_report_model_limits: &resource_filter_report_model_limits/0,
      row_count_difference: &row_count_difference/3,
      frequency_map: &frequency_map/2,
      row_ids_by_field: &row_ids_by_field/3
    ]
  end

  defp resource_projection_flow_row_contract_callbacks do
    [
      validate_stable_ids: &validate_stable_ids/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_source_window: &validate_optional_source_window/4,
      validate_nested_id_match: &validate_nested_id_match/7,
      validate_string_list_items: &validate_string_list_items/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_one_of: &expect_optional_one_of/5
    ]
  end

  defp resource_projection_flow_summary_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_type: &expect_type/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      expect_one_of: &expect_one_of/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_string_list_map: &validate_string_list_map/4,
      validate_number_array_map: &validate_number_array_map/3,
      expect_number: &expect_number/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_resource_projection_subsystem_model_assumptions:
        &validate_resource_projection_subsystem_model_assumptions/3,
      validate_rows: &validate_rows/4,
      validate_resource_projection_flow_summary_projected_resource:
        &validate_resource_projection_flow_summary_projected_resource/3,
      validate_resource_projection_flow_row: &validate_resource_projection_flow_row/3,
      validate_resource_projection_flow_summary_counts:
        &validate_resource_projection_flow_summary_counts/3
    ]
  end

  defp resource_projection_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      resource_projection_report_models: &resource_projection_report_models/0,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      resource_projection_report_model_limits: &resource_projection_report_model_limits/0,
      expect_type: &expect_type/5,
      validate_resource_projection_subsystem_model_assumptions:
        &validate_resource_projection_subsystem_model_assumptions/3,
      validate_optional_rows: &validate_optional_rows/4,
      validate_invalid_resource_summary_input: &validate_invalid_resource_summary_input/3,
      validate_invalid_activity_input: &validate_invalid_activity_input/3,
      validate_rows: &validate_rows/4,
      validate_resource_projection_row: &validate_resource_projection_row/3,
      validate_resource_projection_report_counts: &validate_resource_projection_report_counts/3
    ]
  end

  defp resource_projection_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_items: &validate_string_list_items/4,
      expect_optional_probability: &expect_optional_probability/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_approval_requirement: &validate_approval_requirement/3,
      validate_policy_rule_match: &validate_policy_rule_match/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_source_window: &validate_optional_source_window/4,
      validate_nested_id_match: &validate_nested_id_match/7,
      validate_rows: &validate_rows/4,
      validate_resource_projection_flow_row: &validate_resource_projection_flow_row/3,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6
    ]
  end

  defp timeline_transition_application_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_rows: &validate_rows/4,
      validate_timeline_transition_application_row:
        &validate_timeline_transition_application_row/3,
      timeline_report_model_limits: &timeline_report_model_limits/0
    ]
  end

  defp link_capacity_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_field_matches_list_count: &expect_field_matches_list_count/6,
      expect_optional_list_field_equals: &expect_optional_list_field_equals/6,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_rows: &validate_rows/4,
      validate_optional_actual_data_rate_throughput_derivations:
        &validate_optional_actual_data_rate_throughput_derivations/4
    ]
  end

  defp contact_contention_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_field_at_least: &expect_field_at_least/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_number_list_items: &validate_number_list_items/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_rows: &validate_rows/4,
      validate_optional_actual_data_rate_throughput_derivations:
        &validate_optional_actual_data_rate_throughput_derivations/4,
      validate_invalid_contact_input: &validate_invalid_contact_input/3,
      validate_priority_field_evidence_counts: &validate_priority_field_evidence_counts/3,
      validate_priority_override_map: &validate_priority_override_map/3,
      validate_priority_override_ids_match_map: &validate_priority_override_ids_match_map/3,
      validate_override_count_matches_ids: &validate_override_count_matches_ids/5,
      validate_ids_match_row_multiset: &validate_ids_match_row_multiset/6,
      error: &error/2
    ]
  end

  defp contact_contention_resolution_summary_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_contact_contention_resolution_policy:
        &validate_contact_contention_resolution_policy/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      contact_contention_report_model_limits: &contact_contention_report_model_limits/0,
      sorted_stable_id_array_map_values: &sorted_stable_id_array_map_values/1,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      numeric_map_sum: &numeric_map_sum/1,
      list_count: &list_count/2
    ]
  end

  defp validation_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_list: &expect_optional_list/4,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_rows: &validate_rows/4,
      validate_validation_issue: &validate_validation_issue/3,
      validate_validation_remediation: &validate_validation_remediation/3,
      schema_validation_statuses: &schema_validation_statuses/0,
      schema_validation_model_limits: &schema_validation_model_limits/0,
      error: &error/2
    ]
  end

  defp schema_migration_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_rows: &validate_rows/4,
      schema_migration_report_model_limits: &schema_migration_report_model_limits/0,
      error: &error/2
    ]
  end

  defp lint_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_validation_issue: &validate_validation_issue/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_ids: &validate_stable_ids/4,
      list_value: &list_value/2,
      error: &error/2
    ]
  end

  defp study_benchmark_contract_callbacks do
    [
      validate_optional_schema_contract: &validate_optional_schema_contract/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_non_negative_integer_list_items: &validate_non_negative_integer_list_items/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3
    ]
  end

  defp result_artifact_contract_callbacks do
    [
      validate_execution_report: &validate_nested_execution_report/1,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_number: &expect_number/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_stable_ids: &validate_stable_ids/4,
      error: &error/2
    ]
  end

  defp validate_nested_execution_report(execution_report),
    do:
      validate_contract(
        @execution_report,
        registry_contract!(@execution_report),
        execution_report
      )

  defp optimizer_objective_contract_callbacks do
    [
      objective_tradeoff_report_models: &objective_tradeoff_report_models/0,
      score_term_report_models: &score_term_report_models/0,
      score_report_model_limits: &OrbitalDynamics.CampaignPlanner.score_report_model_limits/0,
      objective_satisfaction_model_limits:
        &OrbitalDynamics.CampaignPlanner.objective_satisfaction_model_limits/0,
      ranking_comparison_model_limits:
        &OrbitalDynamics.Optimizer.ranking_comparison_model_limits/0,
      numeric_delta: &numeric_delta/2,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_stable_ids: &validate_optional_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_numeric_map: &validate_numeric_map/3
    ]
  end

  defp pareto_frontier_contract_callbacks do
    [
      pareto_frontier_model_limits: &OrbitalDynamics.Optimizer.pareto_frontier_model_limits/0,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_numeric_map: &validate_numeric_map/3
    ]
  end

  defp timeline_feedback_report_contract_callbacks do
    [
      timeline_feedback_report_model_limits: &timeline_feedback_report_model_limits/0,
      frequency_map: &frequency_map/2,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_operational_feedback: &validate_operational_feedback/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_timeline_feedback_row: &validate_timeline_feedback_row/3
    ]
  end

  defp timeline_feedback_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_number_list_items: &validate_number_list_items/4,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_execution_uncertainty: &validate_optional_execution_uncertainty/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_actual_data_rate_throughput_derivation:
        &validate_optional_actual_data_rate_throughput_derivation/4,
      validate_resource_availability_variance_fields:
        &validate_resource_availability_variance_fields/3,
      validate_eclipse_lighting_handoff_fields: &validate_eclipse_lighting_handoff_fields/3,
      validate_link_handoff_fields: &validate_link_handoff_fields/3,
      validate_image_quality_score_fields: &validate_image_quality_score_fields/3
    ]
  end

  defp realized_activity_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_list: &expect_optional_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_number_vector: &expect_optional_number_vector/4,
      validate_optional_execution_uncertainty: &validate_optional_execution_uncertainty/4,
      expect_optional_number_or_string: &expect_optional_number_or_string/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      error: &error/2
    ]
  end

  defp operational_feedback_contract_callbacks do
    [
      validate_optional_rows: &validate_optional_rows/4,
      validate_realized_activity: &validate_realized_activity/3,
      error: &error/2
    ]
  end

  defp realized_state_snapshot_contract_callbacks do
    [
      realized_state_snapshot_model_limits:
        &OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits/0,
      frequency_map: &frequency_map/2,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_list: &expect_optional_list/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_realized_activity: &validate_realized_activity/3,
      error: &error/2
    ]
  end

  defp plan_delta_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_schema_contract: &validate_optional_schema_contract/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_timeline_link: &validate_optional_timeline_link/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_execution_uncertainty: &validate_optional_execution_uncertainty/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_number_vector: &expect_optional_number_vector/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_number: &expect_number/4,
      validate_interval: &validate_interval/3,
      validate_realized_activity: &validate_realized_activity/3
    ]
  end

  defp candidate_rejection_report_contract_callbacks do
    [
      candidate_rejection_report_model_limits: &candidate_rejection_report_model_limits/0,
      frequency_map: &frequency_map/2,
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_rows: &validate_rows/4,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      error: &error/2
    ]
  end

  defp contact_filter_report_contract_callbacks do
    [
      contact_filter_report_model_limits: &contact_filter_report_model_limits/0,
      contact_filter_suppressed_directions: &contact_filter_suppressed_directions/0,
      contact_filter_suppression_reasons: &contact_filter_suppression_reasons/0,
      contact_filter_station_unavailable_aliases: &contact_filter_station_unavailable_aliases/0,
      contact_filter_station_availability_precedence:
        &contact_filter_station_availability_precedence/0,
      contact_filter_station_capacity_value_path_assumptions:
        &contact_filter_station_capacity_value_path_assumptions/0,
      contact_filter_contact_capacity_value_path_assumptions:
        &contact_filter_contact_capacity_value_path_assumptions/0,
      contact_filter_provider_direction_aliases: &contact_filter_provider_direction_aliases/0,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_rows: &validate_rows/4,
      validate_suppressed_candidate: &validate_suppressed_candidate/3,
      validate_filter_report_counts: &validate_filter_report_counts/4,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      error: &error/2
    ]
  end

  defp resource_filter_report_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_rows: &validate_optional_rows/4,
      validate_rows: &validate_rows/4,
      validate_invalid_resource_summary_input: &validate_invalid_resource_summary_input/3,
      validate_suppressed_candidate: &validate_suppressed_candidate/3,
      validate_filter_report_counts: &validate_filter_report_counts/4,
      expect_optional_field_equals: &expect_optional_field_equals/6
    ]
  end

  defp maneuver_review_report_contract_callbacks do
    [
      maneuver_review_report_model_limits: &maneuver_review_report_model_limits/0,
      frequency_map: &frequency_map/2,
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_number: &expect_number/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_rows: &validate_rows/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_number_vector: &expect_number_vector/3,
      expect_optional_number: &expect_optional_number/4,
      expect_one_of: &expect_one_of/5
    ]
  end

  defp operational_timeline_report_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      frequency_map: &frequency_map/2,
      sum_row_numbers: &sum_row_numbers/2,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_operational_timeline_row: &validate_operational_timeline_row/3
    ]
  end

  defp timeline_diff_report_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      frequency_map: &frequency_map/2,
      nested_frequency_map: &nested_frequency_map/3,
      changed_field_frequency_map: &changed_field_frequency_map/1,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_timeline_diff_row: &validate_timeline_diff_row/3
    ]
  end

  defp timeline_diff_summary_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      expect_equal: &expect_equal/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_timeline_diff_row: &validate_timeline_diff_row/3
    ]
  end

  defp timeline_integrity_report_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_rows: &validate_rows/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_string_list_items: &validate_string_list_items/4
    ]
  end

  defp timeline_dependency_impact_summary_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_rows: &validate_rows/4,
      validate_string_list_items: &validate_string_list_items/4
    ]
  end

  defp timeline_publication_summary_contract_callbacks do
    [
      timeline_report_model_limits: &timeline_report_model_limits/0,
      error: &error/2,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_field_equals: &expect_optional_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_timeline_diff_summary_source:
        &validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_dependency_impact_summary_source:
        &validate_optional_timeline_dependency_impact_summary_source/3
    ]
  end

  defp timeline_publication_handoff_contract_callbacks do
    [
      expect_field_equals: &expect_field_equals/6,
      expect_optional_type: &expect_optional_type/5,
      timeline_publication_summary_contract_callbacks:
        &timeline_publication_summary_contract_callbacks/0
    ]
  end

  defp timeline_activity_state_contract_callbacks do
    [
      timeline_feedback_report_model_limits: &timeline_feedback_report_model_limits/0,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_stable_ids: &validate_stable_ids/4,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_timeline_activity_state_assumptions:
        &validate_timeline_activity_state_assumptions/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_rows: &validate_rows/4,
      validate_timeline_feedback_row: &validate_timeline_feedback_row/3
    ]
  end

  defp branch_comparison_report_contract_callbacks do
    [
      branch_comparison_model_limits:
        &OrbitalDynamics.CampaignPlanner.branch_comparison_model_limits/0,
      branch_comparison_row_count_fields: &branch_comparison_row_count_fields/0,
      strategy_recommendation_pressure_handoff_string_list_fields:
        &strategy_recommendation_pressure_handoff_string_list_fields/0,
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_probability_range: &expect_probability_range/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_list_count_equals: &expect_list_count_equals/5,
      validate_branch_event_summary_fields: &validate_branch_event_summary_fields/3,
      validate_numeric_map: &validate_numeric_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_string_lists: &validate_optional_string_lists/4,
      validate_rows: &validate_rows/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_items: &validate_string_list_items/4,
      error: &error/2
    ]
  end

  defp strategy_recommendation_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_stable_id_list: &validate_stable_id_list/3,
      validate_optional_schema_contract: &validate_optional_schema_contract/4,
      expect_optional_type: &expect_optional_type/5,
      expect_type: &expect_type/5,
      validate_optional_rows: &validate_optional_rows/4,
      expect_number: &expect_number/4,
      validate_branch_event_summary_fields: &validate_branch_event_summary_fields/3,
      validate_scoped_downlink_context_fields: &validate_scoped_downlink_context_fields/3,
      error: &error/2
    ]
  end

  defp branch_event_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_field_at_least: &expect_field_at_least/5,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_type: &expect_optional_type/5,
      expect_type: &expect_type/5,
      expect_probability_range: &expect_probability_range/4,
      validate_candidate_diff_changed_fields: &validate_candidate_diff_changed_fields/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_numeric_map: &validate_numeric_map/3,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_semantic_change_details: &validate_semantic_change_details/3,
      validate_stable_ids: &validate_stable_ids/4,
      validate_string_list_map: &validate_string_list_map/4,
      validate_string_list_items: &validate_string_list_items/4,
      error: &error/2
    ]
  end

  defp branch_comparison_row_count_fields, do: @branch_comparison_row_count_fields

  defp strategy_recommendation_pressure_handoff_string_list_fields,
    do: @strategy_recommendation_pressure_handoff_string_list_fields

  defp manifest_field_reference_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_field_equals: &expect_field_equals/5,
      validate_string_list_items: &validate_string_list_items/4,
      error: &error/2
    ]
  end

  defp campaign_plan_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_contact_contention_report: &validate_optional_contact_contention_report/2,
      validate_optional_contact_contention_resolution_report:
        &validate_optional_contact_contention_resolution_report/2,
      validate_optional_station_calendar_report: &validate_optional_station_calendar_report/2,
      validate_optional_objective_tradeoff_report: &validate_optional_objective_tradeoff_report/2,
      validate_optional_objective_satisfaction_report:
        &validate_optional_objective_satisfaction_report/2,
      validate_optional_operational_timeline_report:
        &validate_optional_operational_timeline_report/2,
      validate_optional_timeline_transition_application_report:
        &validate_optional_timeline_transition_application_report/3,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      validate_optional_operational_readiness_report:
        &validate_optional_operational_readiness_report/3,
      validate_optional_quality_gate_report: &validate_optional_quality_gate_report/3,
      validate_optional_optimizer_contract: &validate_optional_optimizer_contract/2,
      validate_optional_link_capacity_report: &validate_optional_link_capacity_report/2,
      validate_optional_resource_projection_report:
        &validate_optional_resource_projection_report/3,
      validate_optional_resource_projection_flow_summary:
        &validate_optional_resource_projection_flow_summary/3,
      validate_optional_timeline_activity_precondition_summaries:
        &validate_optional_timeline_activity_precondition_summaries/3,
      validate_optional_timeline_integrity_report: &validate_optional_timeline_integrity_report/3,
      validate_optional_resource_filter_report: &validate_optional_resource_filter_report/3,
      validate_optional_score_term_report: &validate_optional_score_term_report/2,
      validate_rows: &validate_rows/4,
      validate_activity: &validate_activity/3,
      validate_proposed_contact: &validate_proposed_contact/3,
      validate_contact_intent: &validate_contact_intent/3,
      validate_optional_contact_filter_report: &validate_optional_contact_filter_report/2
    ]
  end

  defp campaign_repair_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_one_of: &expect_one_of/5,
      validate_realized_state_snapshot: &validate_realized_state_snapshot/3,
      validate_rows: &validate_rows/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_activity: &validate_activity/3,
      validate_contact_intent: &validate_contact_intent/3,
      validate_resource_summary: &validate_resource_summary/3,
      validate_optional_contact_filter_report: &validate_optional_contact_filter_report/3,
      validate_optional_resource_filter_report: &validate_optional_resource_filter_report/3,
      validate_optional_resource_projection_report:
        &validate_optional_resource_projection_report/3,
      validate_optional_operational_timeline_report:
        &validate_optional_operational_timeline_report/2,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      validate_optional_objective_tradeoff_report: &validate_optional_objective_tradeoff_report/2,
      validate_optional_score_term_report: &validate_optional_score_term_report/2,
      validate_optional_link_capacity_report: &validate_optional_link_capacity_report/2,
      validate_optional_candidate_diff_report: &validate_optional_candidate_diff_report/3,
      validate_optional_candidate_rejection_report:
        &validate_optional_candidate_rejection_report/3,
      validate_optional_freshness_report: &validate_optional_freshness_report/3,
      validate_optional_station_calendar_report: &validate_optional_station_calendar_report/3,
      validate_plan_delta: &validate_plan_delta/3,
      validate_approval_requirement: &validate_approval_requirement/3,
      validate_policy_decision: &validate_policy_decision/3,
      require_nested: &require_nested/4,
      validate_optional_timeline_protection_summary:
        &validate_optional_timeline_protection_summary/4,
      expect_field_equals_with_message: &expect_field_equals/6
    ]
  end

  defp campaign_strategy_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      validate_operational_feedback: &validate_operational_feedback/3,
      validate_rows: &validate_rows/4,
      validate_branch: &validate_branch/3,
      validate_recommendation: &validate_recommendation/3,
      validate_optional_branch_comparison_report: &validate_optional_branch_comparison_report/2,
      validate_optional_ranking_comparison_report: &validate_optional_ranking_comparison_report/2,
      validate_optional_operator_review_package: &validate_optional_operator_review_package/2,
      require_nested: &require_nested/4
    ]
  end

  defp validate_candidate_refresh_publication_lineage_fields(issues, artifact) do
    issues =
      Enum.reduce(
        OrbitalDynamics.Schema.CandidateRefreshRegistryContracts.publication_lineage_id_array_fields(),
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type("$", artifact, field, :list)
          |> validate_optional_stable_id_list("$", artifact, field)
        end
      )

    issues =
      Enum.reduce(
        OrbitalDynamics.Schema.CandidateRefreshRegistryContracts.publication_lineage_count_map_fields(),
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type("$", artifact, field, :map)
          |> validate_non_negative_integer_count_map("$.#{field}", Map.get(artifact, field))
        end
      )

    Enum.reduce(
      OrbitalDynamics.Schema.CandidateRefreshRegistryContracts.publication_lineage_stable_id_array_map_fields(),
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type("$", artifact, field, :map)
        |> validate_stable_id_array_map("$.#{field}", Map.get(artifact, field))
      end
    )
  end

  defp validation_level_json_schema do
    %{
      "type" => "string",
      "enum" => OrbitalDynamics.Schema.ValidationPolicyContracts.level_names()
    }
  end

  defp validate_activity(issues, path, activity) do
    OrbitalDynamics.Schema.ActivityContracts.validate(
      issues,
      path,
      activity
    )
  end

  defp validate_candidate_activity(issues, path, activity) do
    OrbitalDynamics.Schema.CandidateActivityContracts.validate(
      issues,
      path,
      activity
    )
  end

  defp validate_spacecraft_state_estimate(issues, path, state) do
    OrbitalDynamics.Schema.AcceptedStateContracts.validate_spacecraft_state_estimate(
      issues,
      path,
      state
    )
  end

  defp validate_maneuver_execution_delta(issues, path, delta) do
    OrbitalDynamics.Schema.AcceptedStateContracts.validate_maneuver_execution_delta(
      issues,
      path,
      delta
    )
  end

  defp validate_proposed_contact(issues, path, contact) do
    OrbitalDynamics.Schema.ProposedContactContracts.validate(
      issues,
      path,
      contact
    )
  end

  defp validate_refreshed_windows(issues, refreshed_windows) when is_map(refreshed_windows) do
    OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_refreshed_windows(
      issues,
      refreshed_windows
    )
  end

  defp validate_refreshed_windows(issues, _refreshed_windows), do: issues

  defp validate_refreshed_window(issues, path, window) do
    OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_refreshed_window(
      issues,
      path,
      window
    )
  end

  defp validate_contact_intent(issues, path, intent) do
    OrbitalDynamics.Schema.ContactIntentContracts.validate(
      issues,
      path,
      intent,
      contact_intent_contract_callbacks()
    )
  end

  defp contact_intent_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      expect_number: &expect_number/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_string_list_items: &validate_string_list_items/4,
      expect_type: &expect_type/5,
      require_nested: &require_nested/4,
      expect_field_equals: &expect_field_equals/6,
      validate_rows: &validate_rows/4,
      validate_approval_requirement: &validate_approval_requirement/3,
      validate_policy_decision: &validate_policy_decision/3,
      validate_station_calendar_contact_counts: &validate_station_calendar_contact_counts/3,
      validate_interval: &validate_interval/3,
      contact_intent_model_limits: &contact_intent_model_limits/0,
      error: &error/2
    ]
  end

  defp validate_contact_intent_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactIntentSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_intent_summary_contract_callbacks()
    )
  end

  defp validate_station_calendar_provider(issues, path, provider) do
    OrbitalDynamics.Schema.StationCalendarProviderContracts.validate(
      issues,
      path,
      provider,
      station_calendar_provider_contract_callbacks()
    )
  end

  defp validate_optional_contact_filter_report(issues, report) do
    validate_optional_contact_filter_report(issues, "$.contact_filter_report", report)
  end

  defp validate_optional_contact_filter_report(issues, _path, nil), do: issues

  defp validate_optional_contact_filter_report(issues, path, %{} = report) do
    validate_contact_filter_report(issues, path, report)
  end

  defp validate_optional_contact_filter_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_contact_filter_report(issues, path, report) do
    OrbitalDynamics.Schema.ContactFilterReportContracts.validate(
      issues,
      path,
      report,
      contact_filter_report_contract_callbacks()
    )
  end

  defp validate_optional_contact_contention_report(issues, nil), do: issues

  defp validate_optional_contact_contention_report(issues, %{} = report) do
    issues
    |> validate_contact_contention_report("$.contact_contention_report", report)
  end

  defp validate_optional_contact_contention_report(issues, _report),
    do: [error("$.contact_contention_report", "must be an object") | issues]

  defp validate_contact_contention_report(issues, path, report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_report(
      issues,
      path,
      report,
      contact_contention_report_contract_callbacks()
    )
  end

  defp validate_optional_link_capacity_report(issues, nil), do: issues

  defp validate_optional_link_capacity_report(issues, %{} = report) do
    validate_contract(@link_capacity_report, registry_contract!(@link_capacity_report), report) ++
      issues
  end

  defp validate_optional_link_capacity_report(issues, _report),
    do: [error("$.link_capacity_report", "must be an object") | issues]

  defp validate_link_capacity_report(issues, path, report) do
    OrbitalDynamics.Schema.LinkCapacityReportContracts.validate(
      issues,
      path,
      report,
      link_capacity_report_contract_callbacks()
    )
  end

  defp validate_optional_contact_allocation_report(issues, nil), do: issues

  defp validate_optional_contact_allocation_report(issues, %{} = report) do
    validate_contact_allocation_report(issues, "$.contact_allocation_report", report)
  end

  defp validate_optional_contact_allocation_report(issues, _report),
    do: [error("$.contact_allocation_report", "must be an object") | issues]

  defp validate_contact_allocation_report(issues, path, report) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_report(
      issues,
      path,
      report,
      contact_allocation_model_limits(),
      contact_allocation_report_contract_callbacks()
    )
  end

  defp validate_contact_allocation_row(issues, path, row) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_row(
      issues,
      path,
      row,
      contact_allocation_report_contract_callbacks()
    )
  end

  defp validate_contact_allocation_capacity_pack_group(issues, path, group) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_capacity_pack_group(
      issues,
      path,
      group,
      contact_allocation_report_contract_callbacks()
    )
  end

  defp validate_optional_contact_contention_resolution_report(issues, nil), do: issues

  defp validate_optional_contact_contention_resolution_report(issues, %{} = report) do
    issues
    |> validate_contact_contention_resolution_report(
      "$.contact_contention_resolution_report",
      report
    )
  end

  defp validate_optional_contact_contention_resolution_report(issues, _report),
    do: [error("$.contact_contention_resolution_report", "must be an object") | issues]

  defp validate_contact_contention_resolution_report(issues, path, report) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_report(
      issues,
      path,
      report,
      contact_contention_report_contract_callbacks()
    )
  end

  defp validate_contact_contention_resolution_policy(issues, path, policy) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_resolution_policy(
      issues,
      path,
      policy,
      contact_contention_report_contract_callbacks()
    )
  end

  defp validate_contact_contention_deferred_priority(issues, path, row) do
    OrbitalDynamics.Schema.ContactContentionReportContracts.validate_deferred_priority(
      issues,
      path,
      row,
      contact_contention_report_contract_callbacks()
    )
  end

  defp validate_priority_field_evidence_counts(issues, path, counts) when is_map(counts) do
    Enum.reduce(counts, issues, fn {field, count}, acc ->
      cond do
        not is_binary(field) or field == "" ->
          [error("#{path}.#{inspect(field)}", "field name must be a non-empty string") | acc]

        not is_integer(count) or count < 0 ->
          [error("#{path}.#{field}", "must be a non-negative integer") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_priority_field_evidence_counts(issues, _path, _counts), do: issues

  defp validate_branch_event_summary_fields(issues, path, row) do
    OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields(
      issues,
      path,
      row,
      branch_event_contract_callbacks()
    )
  end

  defp validate_scoped_downlink_context_fields(issues, path, row) do
    OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate(
      issues,
      path,
      row
    )
  end

  defp validate_image_quality_score_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_image_quality_score_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_observation_quality_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_observation_quality_handoff_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_feedback_maneuver_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_feedback_maneuver_handoff_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_link_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_link_handoff_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_completion_fraction_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_completion_fraction_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_station_capacity_fraction_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_station_capacity_fraction_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_eclipse_lighting_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_eclipse_lighting_handoff_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_thermal_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_thermal_handoff_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_candidate_refresh_scoped_context_fields(issues, path, row) do
    OrbitalDynamics.Schema.CandidateRefreshScopedContextContracts.validate(
      issues,
      path,
      row
    )
  end

  defp validate_branch_event_trust_boundary_status_count_map(issues, path, counts) do
    OrbitalDynamics.Schema.BranchEventContracts.validate_trust_boundary_status_count_map(
      issues,
      path,
      counts,
      branch_event_contract_callbacks()
    )
  end

  defp validate_invalid_contact_input(issues, path, row) do
    issues
    |> expect_optional_one_of(path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end

  defp validate_optional_station_calendar_report(issues, report),
    do: validate_optional_station_calendar_report(issues, "$.station_calendar_report", report)

  defp validate_optional_station_calendar_report(issues, path, report) do
    OrbitalDynamics.Schema.StationCalendarReportContracts.validate_optional_report(
      issues,
      path,
      report,
      station_calendar_report_contract_callbacks()
    )
  end

  defp stable_id_array_map_ids(values) when is_map(values) do
    OrbitalDynamics.Schema.CollectionAggregation.stable_id_array_map_ids(values)
  end

  defp stable_id_array_map_ids(values),
    do: OrbitalDynamics.Schema.CollectionAggregation.stable_id_array_map_ids(values)

  defp validate_station_reservation_review_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_review(
      issues,
      path,
      summary,
      station_reservation_summary_contract_callbacks()
    )
  end

  defp validate_station_reservation_hold_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold(
      issues,
      path,
      summary,
      station_reservation_summary_contract_callbacks()
    )
  end

  defp validate_station_reservation_hold_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.StationReservationSummaryContracts.validate_hold_import_readiness(
      issues,
      path,
      summary,
      station_reservation_summary_contract_callbacks()
    )
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp validate_station_calendar_contact_counts(issues, path, contact) do
    OrbitalDynamics.Schema.StationCalendarContactCountContracts.validate(
      issues,
      path,
      contact
    )
  end

  defp validate_resource_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ResourceSummaryContracts.validate(
      issues,
      path,
      summary
    )
  end

  defp validate_optional_resource_projection_report(issues, _path, nil), do: issues

  defp validate_optional_resource_projection_report(issues, path, %{} = report) do
    validate_resource_projection_report(issues, path, report)
  end

  defp validate_optional_resource_projection_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_resource_projection_flow_summary(issues, _path, nil), do: issues

  defp validate_optional_resource_projection_flow_summary(issues, path, %{} = summary) do
    validate_resource_projection_flow_summary(issues, path, summary)
  end

  defp validate_optional_resource_projection_flow_summary(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_operational_readiness_report(issues, _path, nil), do: issues

  defp validate_optional_operational_readiness_report(issues, path, %{} = report) do
    validate_operational_readiness_report(issues, path, report)
  end

  defp validate_optional_operational_readiness_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_quality_gate_report(issues, _path, nil), do: issues

  defp validate_optional_quality_gate_report(issues, path, %{} = report) do
    validate_quality_gate_report(issues, path, report)
  end

  defp validate_optional_quality_gate_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_resource_projection_report(issues, path, report) do
    OrbitalDynamics.Schema.ResourceProjectionReportContracts.validate(
      issues,
      path,
      report,
      resource_projection_report_contract_callbacks()
    )
  end

  defp validate_resource_projection_flow_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryContracts.validate(
      issues,
      path,
      summary,
      resource_projection_report_model_limits(),
      resource_projection_flow_summary_contract_callbacks()
    )
  end

  defp validate_resource_projection_flow_summary_projected_resource(issues, path, row) do
    OrbitalDynamics.Schema.ResourceProjectionFlowProjectedResourceContracts.validate(
      issues,
      path,
      row
    )
  end

  defp validate_resource_projection_row(issues, path, row) do
    OrbitalDynamics.Schema.ResourceProjectionRowContracts.validate(
      issues,
      path,
      row,
      resource_projection_row_contract_callbacks()
    )
  end

  defp validate_resource_projection_flow_row(issues, path, row) do
    OrbitalDynamics.Schema.ResourceProjectionFlowRowContracts.validate(
      issues,
      path,
      row,
      resource_projection_flow_row_contract_callbacks()
    )
  end

  defp validate_invalid_activity_input(issues, path, row) do
    issues
    |> expect_optional_one_of(path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end

  defp validate_realized_state_snapshot(issues, path, snapshot) do
    OrbitalDynamics.Schema.RealizedStateSnapshotContracts.validate(
      issues,
      path,
      snapshot,
      realized_state_snapshot_contract_callbacks()
    )
  end

  defp validate_realized_activity(issues, path, activity) do
    OrbitalDynamics.Schema.RealizedActivityContracts.validate(
      issues,
      path,
      activity,
      realized_activity_contract_callbacks()
    )
  end

  defp validate_operational_feedback(issues, path, feedback) do
    OrbitalDynamics.Schema.OperationalFeedbackContracts.validate(
      issues,
      path,
      feedback,
      operational_feedback_contract_callbacks()
    )
  end

  defp validate_timeline_feedback_row(issues, path, row) do
    OrbitalDynamics.Schema.TimelineFeedbackRowContracts.validate(
      issues,
      path,
      row,
      timeline_feedback_row_contract_callbacks()
    )
  end

  defp validate_resource_availability_variance_fields(issues, path, row) do
    OrbitalDynamics.Schema.HandoffFieldContracts.validate_resource_availability_variance_fields(
      issues,
      path,
      row,
      handoff_field_contract_callbacks()
    )
  end

  defp validate_maneuver_recommendation(issues, path, maneuver) do
    OrbitalDynamics.Schema.ManeuverRecommendationContracts.validate(
      issues,
      path,
      maneuver,
      maneuver_recommendation_model_limits()
    )
  end

  defp validate_maneuver_review_report(issues, path, report) do
    OrbitalDynamics.Schema.ManeuverReviewReportContracts.validate(
      issues,
      path,
      report,
      maneuver_review_report_contract_callbacks()
    )
  end

  defp validate_optional_objective_tradeoff_report(issues, nil), do: issues

  defp validate_optional_objective_tradeoff_report(issues, %{} = report) do
    validate_contract(
      @objective_tradeoff_report,
      registry_contract!(@objective_tradeoff_report),
      report
    ) ++
      issues
  end

  defp validate_optional_objective_tradeoff_report(issues, _report),
    do: [error("$.objective_tradeoff_report", "must be an object") | issues]

  defp objective_tradeoff_report_models do
    [
      "ranked_timeline_score_term_tradeoffs",
      "repair_score_term_tradeoffs",
      "strategy_branch_score_term_tradeoffs"
    ]
  end

  defp validate_optional_objective_satisfaction_report(issues, nil), do: issues

  defp validate_optional_objective_satisfaction_report(issues, %{} = report) do
    validate_contract(
      @objective_satisfaction_report,
      registry_contract!(@objective_satisfaction_report),
      report
    ) ++
      issues
  end

  defp validate_optional_objective_satisfaction_report(issues, _report),
    do: [error("$.objective_satisfaction_report", "must be an object") | issues]

  defp validate_optional_operational_timeline_report(issues, nil), do: issues

  defp validate_optional_operational_timeline_report(issues, %{} = report) do
    validate_contract(
      @operational_timeline_report,
      registry_contract!(@operational_timeline_report),
      report
    ) ++
      issues
  end

  defp validate_optional_operational_timeline_report(issues, _report),
    do: [error("$.operational_timeline_report", "must be an object") | issues]

  defp validate_optional_operator_review_package(issues, nil), do: issues

  defp validate_optional_operator_review_package(issues, %{} = package) do
    validate_contract(
      @operator_review_package,
      registry_contract!(@operator_review_package),
      package
    ) ++
      issues
  end

  defp validate_optional_operator_review_package(issues, _package),
    do: [error("$.operator_review_package", "must be an object") | issues]

  defp validate_operational_timeline_row(issues, path, row) do
    OrbitalDynamics.Schema.OperationalTimelineRowContracts.validate(
      issues,
      path,
      row,
      operational_timeline_row_contract_callbacks()
    )
  end

  defp operational_timeline_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_type: &expect_type/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_probability: &expect_optional_probability/4,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_optional_timeline_preconditions: &validate_optional_timeline_preconditions/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_number_list_items: &validate_number_list_items/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_timeline_integrity_evidence: &validate_timeline_integrity_evidence/3,
      validate_timeline_identity: &validate_timeline_identity/3
    ]
  end

  defp validate_timeline_diff_row(issues, path, row) do
    OrbitalDynamics.Schema.TimelineDiffRowContracts.validate(
      issues,
      path,
      row,
      timeline_diff_row_contract_callbacks()
    )
  end

  defp timeline_diff_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_type: &expect_type/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      expect_number: &expect_number/4,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_timeline_identity_collision_fields: &validate_timeline_identity_collision_fields/3
    ]
  end

  defp validate_optional_timeline_diff_summary_source(issues, _path, nil), do: issues

  defp validate_optional_timeline_diff_summary_source(issues, path, %{} = summary),
    do:
      OrbitalDynamics.Schema.TimelineDiffSummaryContracts.validate(
        issues,
        path,
        summary,
        timeline_diff_summary_contract_callbacks()
      )

  defp validate_optional_timeline_diff_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_dependency_impact_summary_source(issues, _path, nil),
    do: issues

  defp validate_optional_timeline_dependency_impact_summary_source(issues, path, %{} = summary),
    do:
      OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate(
        issues,
        path,
        summary,
        timeline_dependency_impact_summary_contract_callbacks()
      )

  defp validate_optional_timeline_dependency_impact_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_publication_summary_source(issues, path, summary) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_optional_timeline_publication_summary_source(
      issues,
      path,
      summary,
      timeline_publication_summary_contract_callbacks()
    )
  end

  defp validate_timeline_publication_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_publication_matches_source_summary(
      issues,
      path,
      row,
      timeline_publication_handoff_contract_callbacks()
    )
  end

  defp validate_optional_timeline_dependency_impact_source_row(issues, _path, nil), do: issues

  defp validate_optional_timeline_dependency_impact_source_row(issues, path, %{} = row),
    do:
      OrbitalDynamics.Schema.TimelineDependencyImpactSummaryContracts.validate_row(
        issues,
        path,
        row,
        timeline_dependency_impact_summary_contract_callbacks()
      )

  defp validate_optional_timeline_dependency_impact_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_activity_precondition_summary_source(issues, _path, nil),
    do: issues

  defp validate_optional_timeline_activity_precondition_summary_source(
         issues,
         path,
         %{} = summary
       ) do
    OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
      issues,
      path,
      summary,
      timeline_activity_precondition_summary_contract_callbacks()
    )
  end

  defp validate_optional_timeline_activity_precondition_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_activity_precondition_summaries(issues, _path, nil),
    do: issues

  defp validate_optional_timeline_activity_precondition_summaries(issues, path, summaries)
       when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = summary, index}, acc ->
        OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts.validate(
          acc,
          "#{path}[#{index}]",
          summary,
          timeline_activity_precondition_summary_contract_callbacks()
        )

      {_summary, index}, acc ->
        [error("#{path}[#{index}]", "must be an object") | acc]
    end)
  end

  defp validate_optional_timeline_activity_precondition_summaries(issues, path, _summaries),
    do: [error(path, "must be a list") | issues]

  defp validate_optional_timeline_integrity_report(issues, _path, nil), do: issues

  defp validate_optional_timeline_integrity_report(issues, path, %{} = report) do
    OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate(
      issues,
      path,
      report,
      timeline_integrity_report_contract_callbacks()
    )
  end

  defp validate_optional_timeline_integrity_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_timeline_activity_state_assumptions(issues, path, state, fields) do
    case Map.get(state, "assumptions") do
      assumptions when is_map(assumptions) ->
        Enum.reduce(fields, issues, fn field, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, true)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_optional_timeline_preservation_source_row(issues, _path, nil), do: issues

  defp validate_optional_timeline_preservation_source_row(issues, path, %{} = row) do
    OrbitalDynamics.Schema.TimelinePreservationContracts.validate_optional_source_row(
      issues,
      path,
      row,
      timeline_preservation_contract_callbacks()
    )
  end

  defp validate_optional_timeline_preservation_source_row(issues, path, row),
    do:
      OrbitalDynamics.Schema.TimelinePreservationContracts.validate_optional_source_row(
        issues,
        path,
        row,
        timeline_preservation_contract_callbacks()
      )

  defp validate_optional_timeline_lifecycle_state_source_row(issues, path, row) do
    OrbitalDynamics.Schema.TimelineLifecycleStateSourceContracts.validate_optional(
      issues,
      path,
      row,
      timeline_lifecycle_state_source_contract_callbacks()
    )
  end

  defp timeline_lifecycle_state_source_contract_callbacks do
    [
      validate_stable_ids: &validate_stable_ids/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_string_list: &validate_optional_string_list/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_lifecycle_state_source_protection_decision:
        &validate_optional_lifecycle_state_source_protection_decision/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      error: &error/2
    ]
  end

  defp validate_optional_timeline_activity_state_source(issues, _path, nil), do: issues

  defp validate_optional_timeline_activity_state_source(issues, path, %{} = state) do
    OrbitalDynamics.Schema.TimelineActivityStateContracts.validate(
      issues,
      path,
      state,
      timeline_activity_state_contract_callbacks()
    )
  end

  defp validate_optional_timeline_activity_state_source(issues, path, _state),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_lifecycle_state_source_protection_decision(issues, path, row, field) do
    case Map.get(row, field) do
      nil -> issues
      %{} -> validate_optional_protection_decision(issues, path, row, field)
      value when is_binary(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a map or string") | issues]
    end
  end

  defp validate_timeline_transition_application_report(issues, path, report) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationReportContracts.validate(
      issues,
      path,
      report,
      timeline_report_model_limits(),
      timeline_transition_application_report_contract_callbacks()
    )
  end

  defp timeline_transition_application_report_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_type: &expect_type/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      validate_timeline_transition_application_report_counts:
        &validate_timeline_transition_application_report_counts/3,
      validate_optional_rows: &validate_optional_rows/4,
      validate_rows: &validate_rows/4,
      validate_timeline_transition_selected_activity:
        &validate_timeline_transition_selected_activity/3,
      validate_timeline_transition_application_row:
        &validate_timeline_transition_application_row/3
    ]
  end

  defp validate_timeline_transition_application_report_counts(issues, path, report) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationReportCountContracts.validate(
      issues,
      path,
      report,
      timeline_transition_application_report_count_contract_callbacks()
    )
  end

  defp timeline_transition_application_report_count_contract_callbacks do
    [
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      frequency_map: &frequency_map/2,
      nested_frequency_map: &nested_frequency_map/3,
      sum_row_numbers: &sum_row_numbers/2,
      list_value: &list_value/2,
      sorted_unique_binary_values: &sorted_unique_binary_values/1
    ]
  end

  defp validate_timeline_transition_application_summary(issues, path, summary) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationSummaryContracts.validate(
      issues,
      path,
      summary,
      timeline_transition_application_summary_contract_callbacks()
    )
  end

  defp validate_optional_timeline_transition_application_report(issues, _path, nil), do: issues

  defp validate_optional_timeline_transition_application_report(issues, path, %{} = report),
    do: validate_timeline_transition_application_report(issues, path, report)

  defp validate_optional_timeline_transition_application_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_transition_application_summary_source(issues, _path, nil),
    do: issues

  defp validate_optional_timeline_transition_application_summary_source(
         issues,
         path,
         %{} = summary
       ),
       do: validate_timeline_transition_application_summary(issues, path, summary)

  defp validate_optional_timeline_transition_application_summary_source(issues, path, _summary),
    do: [error(path, "must be an object") | issues]

  defp validate_timeline_transition_selected_activity(issues, path, activity) do
    OrbitalDynamics.Schema.TimelineTransitionSelectedActivityContracts.validate(
      issues,
      path,
      activity,
      timeline_transition_selected_activity_contract_callbacks()
    )
  end

  defp timeline_transition_selected_activity_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_type: &expect_type/5,
      expect_one_of: &expect_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_timeline_integrity_evidence: &validate_timeline_integrity_evidence/3,
      validate_interval: &validate_interval/3
    ]
  end

  defp validate_timeline_transition_application_row(issues, path, row) do
    OrbitalDynamics.Schema.TimelineTransitionApplicationRowContracts.validate(
      issues,
      path,
      row,
      timeline_transition_application_row_contract_callbacks()
    )
  end

  defp timeline_transition_application_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_number: &expect_number/4,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_timeline_identity_collision_fields: &validate_timeline_identity_collision_fields/3,
      validate_selected_timeline_integrity_fields: &validate_selected_timeline_integrity_fields/3,
      validate_timeline_diff_row: &validate_timeline_diff_row/3
    ]
  end

  defp validate_timeline_identity_collision_fields(issues, path, row) do
    OrbitalDynamics.Schema.TimelineIdentityCollisionContracts.validate_fields(
      issues,
      path,
      row
    )
  end

  defp validate_selected_timeline_integrity_fields(issues, path, row) do
    OrbitalDynamics.Schema.TimelineSelectedIntegrityContracts.validate(
      issues,
      path,
      row,
      timeline_selected_integrity_contract_callbacks()
    )
  end

  defp timeline_selected_integrity_contract_callbacks do
    [
      expect_optional_type: &expect_optional_type/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      expect_field_equals: &expect_field_equals/6
    ]
  end

  defp validate_optional_timeline_transition_application_row(issues, _path, nil), do: issues

  defp validate_optional_timeline_transition_application_row(issues, path, %{} = row),
    do: validate_timeline_transition_application_row(issues, path, row)

  defp validate_optional_timeline_transition_application_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_timeline_integrity_source_row(issues, _path, nil), do: issues

  defp validate_optional_timeline_integrity_source_row(issues, path, %{} = row),
    do:
      OrbitalDynamics.Schema.TimelineIntegrityReportContracts.validate_row(
        issues,
        path,
        row,
        timeline_integrity_report_contract_callbacks()
      )

  defp validate_optional_timeline_integrity_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_branch_comparison_report(issues, nil), do: issues

  defp validate_optional_branch_comparison_report(issues, %{} = report) do
    validate_contract(
      @branch_comparison_report,
      registry_contract!(@branch_comparison_report),
      report
    ) ++
      issues
  end

  defp validate_optional_branch_comparison_report(issues, _report),
    do: [error("$.branch_comparison_report", "must be an object") | issues]

  defp validate_optional_ranking_comparison_report(issues, nil), do: issues

  defp validate_optional_ranking_comparison_report(issues, %{} = report) do
    validate_contract(
      @ranking_comparison_report,
      registry_contract!(@ranking_comparison_report),
      report
    ) ++
      issues
  end

  defp validate_optional_ranking_comparison_report(issues, _report),
    do: [error("$.ranking_comparison_report", "must be an object") | issues]

  defp validate_optional_branch_comparison_source_row(issues, _path, nil), do: issues

  defp validate_optional_branch_comparison_source_row(issues, path, %{} = row) do
    issues
    |> expect_optional_non_negative_integer(path, row, "downlink_completion_required_contacts")
    |> expect_optional_non_negative_integer(path, row, "downlink_completion_planned_contacts")
    |> expect_optional_probability(path, row, "downlink_completion_ratio")
    |> expect_optional_probability(path, row, "observation_success_factor")
    |> OrbitalDynamics.Schema.BranchComparisonReportContracts.validate_row_counts(
      path,
      row,
      branch_comparison_report_contract_callbacks()
    )
  end

  defp validate_optional_branch_comparison_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_optimizer_contract(issues, nil), do: issues

  defp validate_optional_optimizer_contract(issues, %{} = contract) do
    validate_contract(@optimizer_contract, registry_contract!(@optimizer_contract), contract) ++
      issues
  end

  defp validate_optional_optimizer_contract(issues, _contract),
    do: [error("$.optimizer_contract", "must be an object") | issues]

  defp validate_optional_score_term_report(issues, nil), do: issues

  defp validate_optional_score_term_report(issues, %{} = report) do
    validate_contract(@score_term_report, registry_contract!(@score_term_report), report) ++
      issues
  end

  defp validate_optional_score_term_report(issues, _report),
    do: [error("$.score_term_report", "must be an object") | issues]

  defp score_term_report_models do
    [
      "ranked_timeline_score_terms",
      "repair_score_terms",
      "strategy_branch_score_terms"
    ]
  end

  defp validate_optional_resource_filter_report(issues, report) do
    validate_optional_resource_filter_report(issues, "$.resource_filter_report", report)
  end

  defp validate_optional_resource_filter_report(issues, _path, nil), do: issues

  defp validate_optional_resource_filter_report(issues, path, %{} = report) do
    validate_resource_filter_report(issues, path, report)
  end

  defp validate_optional_resource_filter_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_resource_filter_report(issues, path, report) do
    OrbitalDynamics.Schema.ResourceFilterReportContracts.validate(
      issues,
      path,
      report,
      resource_filter_report_contract_callbacks()
    )
  end

  defp validate_suppressed_candidate(issues, path, candidate) do
    OrbitalDynamics.Schema.SuppressedCandidateContracts.validate(
      issues,
      path,
      candidate
    )
  end

  defp validate_invalid_resource_summary_input(issues, path, row) do
    issues
    |> expect_optional_one_of(path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end

  defp validate_optional_candidate_diff_report(issues, path, report) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report(
      issues,
      path,
      report,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_candidate_diff_row(issues, path, candidate) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_row(
      issues,
      path,
      candidate,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_optional_freshness_report(issues, path, report) do
    OrbitalDynamics.Schema.FreshnessReportContracts.validate_optional(
      issues,
      path,
      report
    )
  end

  defp validate_optional_refresh_budget_report(issues, path, report) do
    OrbitalDynamics.Schema.RefreshBudgetReportContracts.validate_optional(
      issues,
      path,
      report
    )
  end

  defp validate_refresh_budget_report(issues, path, report) do
    OrbitalDynamics.Schema.RefreshBudgetReportContracts.validate(
      issues,
      path,
      report
    )
  end

  defp validate_remaining_horizon(issues, path, horizon) do
    OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_remaining_horizon(
      issues,
      path,
      horizon
    )
  end

  defp validate_invalidated_candidate(issues, path, candidate) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_invalidated_candidate(
      issues,
      path,
      candidate,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_semantic_change_details(issues, path, row) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_semantic_change_details(
      issues,
      path,
      row,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_candidate_diff_changed_fields(issues, path, row) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_changed_fields(
      issues,
      path,
      row,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_source_window_lineage(issues, path, lineage) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_source_window_lineage(
      issues,
      path,
      lineage,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_optional_source_window(issues, path, row, field) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window(
      issues,
      path,
      row,
      field,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_optional_source_window_lineage(issues, path, row, field) do
    OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window_lineage(
      issues,
      path,
      row,
      field,
      candidate_diff_contract_callbacks()
    )
  end

  defp validate_filter_report_counts(issues, path, report, kind) do
    OrbitalDynamics.Schema.FilterReportCountContracts.validate_counts(
      issues,
      path,
      report,
      kind,
      filter_report_count_contract_callbacks()
    )
  end

  defp filter_report_count_contract_callbacks do
    [
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      error: &error/2
    ]
  end

  defp validate_non_negative_number_map(issues, path, values) when is_map(values) do
    Enum.reduce(values, issues, fn {field, value}, acc ->
      cond do
        is_number(value) and value >= 0.0 ->
          acc

        is_number(value) ->
          [error("#{path}.#{field}", "must be non-negative") | acc]

        true ->
          [error("#{path}.#{field}", "must be a number") | acc]
      end
    end)
  end

  defp validate_non_negative_number_map(issues, _path, _values), do: issues

  defp validate_nested_non_negative_number_map(issues, _path, value)
       when value in [nil, :null],
       do: issues

  defp validate_nested_non_negative_number_map(issues, path, %{} = values) do
    Enum.reduce(values, issues, fn {key, nested_values}, acc ->
      validate_non_negative_number_map(acc, "#{path}.#{key}", nested_values)
    end)
  end

  defp validate_nested_non_negative_number_map(issues, _path, _value), do: issues

  defp validate_non_negative_number_list(issues, _path, value) when value in [nil, :null],
    do: issues

  defp validate_non_negative_number_list(issues, path, values) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {value, index}, acc ->
      cond do
        is_number(value) and value >= 0.0 ->
          acc

        is_number(value) ->
          [error("#{path}[#{index}]", "must be non-negative") | acc]

        true ->
          [error("#{path}[#{index}]", "must be a number") | acc]
      end
    end)
  end

  defp validate_non_negative_number_list(issues, path, _value),
    do: [error(path, "must be an array") | issues]

  defp validate_number_array_map(issues, _path, value) when value in [nil, :null], do: issues

  defp validate_number_array_map(issues, path, %{} = values) do
    Enum.reduce(values, issues, fn {key, refs}, acc ->
      validate_non_negative_number_list(acc, "#{path}.#{key}", refs)
    end)
  end

  defp validate_number_array_map(issues, path, _value),
    do: [error(path, "must be an object") | issues]

  defp validate_string_list_map(issues, path, summary, field) do
    case Map.get(summary, field) do
      %{} = grouped_values ->
        Enum.reduce(grouped_values, issues, fn {key, values}, acc ->
          entry_path = "#{path}.#{field}.#{key}"

          cond do
            not is_list(values) ->
              [error(entry_path, "must be an array") | acc]

            Enum.all?(values, &is_binary/1) ->
              acc

            true ->
              [error(entry_path, "must contain only strings") | acc]
          end
        end)

      _grouped_values ->
        issues
    end
  end

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp non_negative_integer_map_sum(_counts), do: nil

  defp numeric_map_sum(values) when is_map(values) do
    values = Map.values(values)

    if Enum.all?(values, &is_number/1),
      do: Enum.sum(values),
      else: nil
  end

  defp numeric_map_sum(_values), do: nil

  defp stable_id_array_map_value_count(values) when is_map(values) do
    OrbitalDynamics.Schema.CollectionAggregation.stable_id_array_map_value_count(values)
  end

  defp stable_id_array_map_value_count(values),
    do: OrbitalDynamics.Schema.CollectionAggregation.stable_id_array_map_value_count(values)

  defp validate_duplicate_suppressed_candidate_evidence(issues, path, candidate) do
    OrbitalDynamics.Schema.SuppressedCandidateContracts.validate_duplicate_evidence(
      issues,
      path,
      candidate
    )
  end

  defp validate_link_capacity_summary(issues, path, summary) do
    OrbitalDynamics.Schema.LinkCapacitySummaryContracts.validate_summary(
      issues,
      path,
      summary,
      link_capacity_summary_contract_callbacks()
    )
  end

  defp validate_link_capacity_assumptions(issues, path, artifact) do
    OrbitalDynamics.Schema.LinkCapacityReportContracts.validate_assumptions(
      issues,
      path,
      artifact,
      link_capacity_report_contract_callbacks()
    )
  end

  defp validate_relay_data_path_summary(issues, path, summary) do
    OrbitalDynamics.Schema.RelayDataPathSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      relay_data_path_summary_contract_callbacks()
    )
  end

  defp relay_custody_statuses, do: ~w(confirmed pending missing_ack failed unknown)
  defp relay_latency_statuses, do: ~w(within_limit exceeds_limit not_evaluated unknown)
  defp relay_risk_statuses, do: ~w(nominal review high unknown)

  defp sorted_stable_id_array_map_values(values) when is_map(values) do
    values
    |> Map.values()
    |> List.flatten()
    |> sorted_unique_binary_values()
  end

  defp sorted_stable_id_array_map_values(_values), do: nil

  defp validate_operator_review_row_links(issues, path, row) do
    OrbitalDynamics.Schema.ReviewRowLinkContracts.validate(
      issues,
      path,
      row
    )
  end

  defp validate_contact_allocation_report_counts(issues, path, report) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_counts(
      issues,
      path,
      report,
      contact_allocation_report_contract_callbacks()
    )
  end

  defp validate_contact_allocation_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactAllocationSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_allocation_summary_contract_callbacks()
    )
  end

  defp validate_contact_allocation_reservation_conflict_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_allocation_reservation_conflict_summary_contract_callbacks()
    )
  end

  defp validate_contact_allocation_station_pressure_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_allocation_station_pressure_summary_contract_callbacks()
    )
  end

  defp contact_allocation_review_row?(row) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.review_row?(row)
  end

  defp validate_contact_allocation_capacity_pack_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_allocation_capacity_pack_summary_contract_callbacks()
    )
  end

  defp validate_contact_allocation_provider_reservation_request_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      contact_allocation_provider_reservation_request_summary_contract_callbacks()
    )
  end

  defp contact_allocation_row_contact_ids(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.row_contact_ids(rows)
  end

  defp validate_contact_allocation_duplicate_evidence(issues, path, row) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.validate_duplicate_evidence(
      issues,
      path,
      row,
      contact_allocation_report_contract_callbacks()
    )
  end

  defp contact_allocation_invalid_contact_input_ids(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.invalid_contact_input_ids(rows)
  end

  defp contact_allocation_status_blocked_contact_ids(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.status_blocked_contact_ids(rows)
  end

  defp contact_allocation_resource_blocked_rows(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.resource_blocked_rows(rows)
  end

  defp contact_allocation_capacity_pack_rows(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.capacity_pack_rows(rows)
  end

  defp contact_allocation_selected_capacity_pack_rows(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.selected_capacity_pack_rows(rows)
  end

  defp contact_allocation_deferred_capacity_pack_rows(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.deferred_capacity_pack_rows(rows)
  end

  defp contact_allocation_capacity_pack_required_fraction(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.capacity_pack_required_fraction(rows)
  end

  defp contact_allocation_capacity_pack_required_fraction_by_field(rows, field) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.capacity_pack_required_fraction_by_field(
      rows,
      field
    )
  end

  defp validate_ids_match_row_multiset(issues, path, report, field, expected_ids, message) do
    ids = Map.get(report, field)

    if is_list(ids) and Enum.sort(ids) != Enum.sort(expected_ids) do
      [error("#{path}.#{field}", message) | issues]
    else
      issues
    end
  end

  defp validate_optional_stable_id_array_map(issues, path, report, field) do
    issues
    |> expect_optional_type(path, report, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(report, field))
  end

  defp validate_contact_allocation_expiration_handoff_summary(issues, path, artifact) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_expiration_summary(
      issues,
      path,
      artifact,
      contact_allocation_handoff_contract_callbacks()
    )
  end

  defp validate_quality_gate_handoff_summary(issues, path, artifact) do
    OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_summary(
      issues,
      path,
      artifact,
      quality_gate_handoff_contract_callbacks()
    )
  end

  defp quality_gate_handoff_contract_callbacks do
    [
      validate_optional_stable_ids: &validate_optional_stable_ids/4,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4
    ]
  end

  defp contact_allocation_reservation_expiration_rows(rows, now_s) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_expiration_rows(
      rows,
      now_s
    )
  end

  defp contact_allocation_reservation_expiration_count(rows, status) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_expiration_count(
      rows,
      status
    )
  end

  defp contact_allocation_earliest_reservation_expires_at_s(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.earliest_reservation_expires_at_s(
      rows
    )
  end

  defp contact_allocation_reservation_ids_by_expiration_status(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_ids_by_expiration_status(
      rows
    )
  end

  defp contact_allocation_reservation_row_ids(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_row_ids(rows)
  end

  defp contact_allocation_reservation_expires_at_values(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_expires_at_values(rows)
  end

  defp contact_allocation_reservation_expiration_row?(row) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_expiration_row?(row)
  end

  defp contact_allocation_reservation_ids(row) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.reservation_ids(row)
  end

  defp contact_allocation_station_pressure_rows(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.station_pressure_rows(rows)
  end

  defp contact_allocation_station_pressure_ids_by_availability(rows) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.station_pressure_ids_by_availability(
      rows
    )
  end

  defp contact_allocation_pressure_value?(value) do
    OrbitalDynamics.Schema.ContactAllocationReportContracts.pressure_value?(value)
  end

  defp validate_resource_projection_report_counts(issues, path, report) do
    OrbitalDynamics.Schema.ResourceProjectionReportCountContracts.validate(
      issues,
      path,
      report
    )
  end

  defp validate_resource_projection_flow_summary_counts(issues, path, summary) do
    OrbitalDynamics.Schema.ResourceProjectionFlowSummaryCountContracts.validate(
      issues,
      path,
      summary
    )
  end

  defp resource_projection_handoff_contract_callbacks do
    [
      expect_field_equals: &expect_field_equals/6,
      expect_optional_number: &expect_optional_number/4,
      resource_projection_downlink_flow_row?: &resource_projection_downlink_flow_row?/1
    ]
  end

  defp source_evidence_contract_callbacks do
    [
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_probability: &expect_optional_probability/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_resource_projection_battery_handoff_fields:
        &validate_resource_projection_battery_handoff_fields/3,
      validate_resource_projection_battery_handoff_matches_own_flow:
        &validate_resource_projection_battery_handoff_matches_own_flow/3,
      validate_stable_ids: &validate_stable_ids/4
    ]
  end

  defp handoff_field_contract_callbacks do
    [
      expect_field_at_least: &expect_field_at_least/5,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_number_or_string: &expect_optional_number_or_string/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_type: &expect_optional_type/5,
      validate_stable_ids: &validate_stable_ids/4
    ]
  end

  defp resource_projection_report_model_limits do
    OrbitalDynamics.ResourceProjection.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp resource_projection_assumptions_json_schema do
    OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema.assumptions()
  end

  defp validate_resource_projection_subsystem_model_assumptions(issues, path, artifact) do
    OrbitalDynamics.Schema.ResourceProjectionAssumptionsContracts.validate_subsystem_model_assumptions(
      issues,
      path,
      artifact
    )
  end

  defp resource_projection_report_models do
    [
      "thin_battery_handoff_resource_projection_fixture",
      "thin_campaign_selected_activity_resource_projection",
      "thin_repaired_activity_resource_projection",
      "thin_selected_activity_resource_projection",
      "thin_stale_derived_margin_resource_projection_fixture",
      "thin_strategy_branch_activity_resource_projection"
    ]
  end

  defp resource_projection_downlink_flow_row?(%{"activity_type" => "downlink"}), do: true

  defp resource_projection_downlink_flow_row?(%{
         "activity_type" => "planned_contact",
         "direction" => "downlink"
       }),
       do: true

  defp resource_projection_downlink_flow_row?(%{
         "direction" => "downlink",
         "ground_station_id" => station_id
       })
       when not is_nil(station_id),
       do: true

  defp resource_projection_downlink_flow_row?(_row), do: false

  defp validate_candidate_rejection_report(issues, path, report) do
    OrbitalDynamics.Schema.CandidateRejectionReportContracts.validate(
      issues,
      path,
      report,
      candidate_rejection_report_contract_callbacks()
    )
  end

  defp validate_optional_candidate_rejection_source_row(issues, _path, nil), do: issues

  defp validate_optional_candidate_rejection_source_row(issues, path, %{} = row) do
    OrbitalDynamics.Schema.CandidateRejectionReportContracts.validate_optional_source_row(
      issues,
      path,
      row,
      candidate_rejection_report_contract_callbacks()
    )
  end

  defp validate_optional_candidate_rejection_source_row(issues, path, row),
    do:
      OrbitalDynamics.Schema.CandidateRejectionReportContracts.validate_optional_source_row(
        issues,
        path,
        row,
        candidate_rejection_report_contract_callbacks()
      )

  defp validate_provider_counteroffer_report(issues, path, report) do
    OrbitalDynamics.Schema.ProviderCounterofferReportContracts.validate(
      issues,
      path,
      report,
      provider_counteroffer_report_contract_callbacks()
    )
  end

  defp validate_provider_counteroffer_row(issues, path, row) do
    OrbitalDynamics.Schema.ProviderCounterofferReportContracts.validate_row(
      issues,
      path,
      row,
      provider_counteroffer_report_contract_callbacks()
    )
  end

  defp validate_provider_counteroffer_review_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_review(
      issues,
      path,
      summary,
      provider_counteroffer_report_contract_callbacks()
    )
  end

  defp validate_provider_counteroffer_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_import_readiness(
      issues,
      path,
      summary,
      provider_counteroffer_report_contract_callbacks()
    )
  end

  defp validate_provider_counteroffer_plan_impact_summary(issues, path, summary) do
    OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts.validate_plan_impact(
      issues,
      path,
      summary,
      provider_counteroffer_report_contract_callbacks()
    )
  end

  defp provider_counteroffer_numeric_rows(rows, field) do
    Enum.filter(rows, fn row -> is_number(Map.get(row, field)) end)
  end

  defp provider_counteroffer_timing_shift_rows(rows) do
    Enum.filter(rows, fn row ->
      Enum.any?(
        [
          row["provider_counteroffer_start_delta_s"],
          row["provider_counteroffer_end_delta_s"],
          row["provider_counteroffer_duration_delta_s"]
        ],
        fn value -> is_number(value) and value != 0.0 end
      )
    end)
  end

  defp provider_counteroffer_ids(rows),
    do: provider_counteroffer_stable_ids(rows, "provider_counteroffer_id")

  defp provider_counteroffer_stable_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp provider_counteroffer_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "provider_counteroffer_id"))
    |> Enum.reject(fn {key, _ids} -> is_nil(key) end)
    |> Map.new(fn {key, ids} ->
      {key, ids |> Enum.filter(&is_binary/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp provider_counteroffer_status_count(rows, field, status) do
    Enum.count(rows, &(Map.get(&1, field) == status))
  end

  defp provider_counteroffer_numeric_value_count(rows, field) do
    rows
    |> provider_counteroffer_numeric_values(field)
    |> length()
  end

  defp provider_counteroffer_numeric_value_sum(rows, field) do
    rows
    |> provider_counteroffer_numeric_values(field)
    |> Enum.sum()
  end

  defp provider_counteroffer_numeric_value_min(rows, field) do
    rows
    |> provider_counteroffer_numeric_values(field)
    |> Enum.min(fn -> nil end)
  end

  defp provider_counteroffer_numeric_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
  end

  defp validate_optional_candidate_rejection_report(issues, _path, nil), do: issues

  defp validate_optional_candidate_rejection_report(issues, path, %{} = report) do
    issues
    |> require_fields(
      path,
      report,
      registry_contract!(@candidate_rejection_report)["required_fields"]
    )
    |> validate_candidate_rejection_report(path, report)
  end

  defp validate_optional_candidate_rejection_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []

  defp validate_timeline_integrity_evidence(issues, path, row) do
    OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts.validate(
      issues,
      path,
      row,
      timeline_integrity_evidence_contract_callbacks()
    )
  end

  defp timeline_integrity_evidence_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_field_equals: &expect_field_equals/6,
      validate_stable_id: &validate_stable_id/3,
      validate_string_list_allowed: &validate_string_list_allowed/5,
      error: &error/2
    ]
  end

  defp validate_cadence_import_manifest(issues, path, manifest) do
    OrbitalDynamics.Schema.CadenceImportManifestContracts.validate(
      issues,
      path,
      manifest,
      OrbitalDynamics.CadenceImport.capability().supported_sources,
      cadence_import_manifest_model_limits(),
      @cadence_import_manifest_scalar_count_fields,
      cadence_import_manifest_contract_callbacks()
    )
  end

  defp cadence_import_manifest_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      validate_stable_ids: &validate_stable_ids/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_contact_allocation_expiration_handoff_summary:
        &validate_contact_allocation_expiration_handoff_summary/3,
      validate_quality_gate_handoff_summary: &validate_quality_gate_handoff_summary/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      expect_type: &expect_type/5,
      validate_rows: &validate_rows/4,
      validate_cadence_import_row: &validate_cadence_import_row/3,
      validate_suppression_duplicate_handoff_groups:
        &validate_suppression_duplicate_handoff_groups/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      expect_optional_one_of: &expect_optional_one_of/5,
      error: &error/2
    ]
  end

  defp cadence_source_review_row_contract_callbacks do
    [
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_source_operational_readiness_gate_handoff_matches:
        &validate_source_operational_readiness_gate_handoff_matches/3,
      validate_source_quality_gate_row_handoff_matches:
        &validate_source_quality_gate_row_handoff_matches/3,
      validate_source_operational_readiness_report_handoff_matches:
        &validate_source_operational_readiness_report_handoff_matches/3,
      validate_source_quality_gate_report_handoff_matches:
        &validate_source_quality_gate_report_handoff_matches/3,
      validate_branch_event_summary_fields: &validate_branch_event_summary_fields/3,
      validate_observation_quality_handoff_fields: &validate_observation_quality_handoff_fields/3,
      validate_feedback_maneuver_handoff_fields: &validate_feedback_maneuver_handoff_fields/3,
      validate_link_handoff_fields: &validate_link_handoff_fields/3,
      validate_resource_availability_variance_fields:
        &validate_resource_availability_variance_fields/3,
      validate_completion_fraction_fields: &validate_completion_fraction_fields/3,
      validate_eclipse_lighting_handoff_fields: &validate_eclipse_lighting_handoff_fields/3,
      validate_thermal_handoff_fields: &validate_thermal_handoff_fields/3,
      expect_optional_probability: &expect_optional_probability/4,
      validate_selected_timeline_integrity_fields: &validate_selected_timeline_integrity_fields/3,
      validate_stable_ids: &validate_stable_ids/4,
      expect_optional_number: &expect_optional_number/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_semantic_change_details: &validate_semantic_change_details/3,
      validate_candidate_diff_changed_fields: &validate_candidate_diff_changed_fields/3,
      validate_optional_policy_decision_evidence: &validate_optional_policy_decision_evidence/3,
      validate_optional_policy_escalation: &validate_optional_policy_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &validate_optional_candidate_rejection_source_row/3,
      validate_optional_timeline_dependency_impact_source_row:
        &validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_timeline_publication_summary_source:
        &validate_optional_timeline_publication_summary_source/3,
      validate_timeline_publication_handoff_matches_source:
        &validate_timeline_publication_handoff_matches_source/3,
      validate_optional_branch_comparison_source_row:
        &validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &validate_source_evidence_fields/3,
      validate_freshness_source_status_matches: &validate_freshness_source_status_matches/3,
      validate_refresh_budget_handoff_matches_source:
        &validate_refresh_budget_handoff_matches_source/3,
      validate_schema_validation_source_status_matches:
        &validate_schema_validation_source_status_matches/3,
      validate_execution_source_status_matches: &validate_execution_source_status_matches/3,
      validate_operational_readiness_resource_context:
        &validate_operational_readiness_resource_context/3,
      validate_resource_projection_battery_handoff_fields:
        &validate_resource_projection_battery_handoff_fields/3,
      validate_resource_projection_remaining_handoff_fields:
        &validate_resource_projection_remaining_handoff_fields/3,
      validate_resource_projection_battery_handoff_matches_source:
        &validate_resource_projection_battery_handoff_matches_source/3,
      validate_resource_projection_count_handoff_matches_source:
        &validate_resource_projection_count_handoff_matches_source/3,
      validate_resource_projection_flow_summary_context_matches_source:
        &validate_resource_projection_flow_summary_context_matches_source/3,
      validate_link_capacity_handoff_count_lists: &validate_link_capacity_handoff_count_lists/3,
      validate_link_capacity_handoff_matches_source:
        &validate_link_capacity_handoff_matches_source/3,
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_contact_allocation_handoff_matches_source:
        &validate_contact_allocation_handoff_matches_source/3,
      validate_command_window_handoff_matches_source:
        &validate_command_window_handoff_matches_source/3,
      validate_maneuver_review_handoff_matches_source:
        &validate_maneuver_review_handoff_matches_source/3,
      validate_timeline_diff_handoff_matches_source:
        &validate_timeline_diff_handoff_matches_source/3,
      validate_timeline_transition_application_handoff_matches_source:
        &validate_timeline_transition_application_handoff_matches_source/3,
      validate_candidate_rejection_handoff_matches_source:
        &validate_candidate_rejection_handoff_matches_source/3,
      validate_candidate_diff_handoff_matches_source:
        &validate_candidate_diff_handoff_matches_source/3,
      validate_constraint_handoff_matches_source: &validate_constraint_handoff_matches_source/3,
      validate_objective_satisfaction_handoff_matches_source:
        &validate_objective_satisfaction_handoff_matches_source/3,
      validate_score_term_handoff_matches_source: &validate_score_term_handoff_matches_source/3,
      validate_objective_tradeoff_handoff_matches_source:
        &validate_objective_tradeoff_handoff_matches_source/3,
      validate_approval_requirement_handoff_matches_source:
        &validate_approval_requirement_handoff_matches_source/3,
      validate_plan_delta_handoff_matches_source: &validate_plan_delta_handoff_matches_source/3,
      validate_risk_explanation_handoff_matches_source:
        &validate_risk_explanation_handoff_matches_source/3,
      validate_operational_timeline_handoff_matches_source:
        &validate_operational_timeline_handoff_matches_source/3,
      validate_strategy_recommendation_handoff_matches_source:
        &validate_strategy_recommendation_handoff_matches_source/3,
      validate_strategy_tradeoff_handoff_matches_source:
        &validate_strategy_tradeoff_handoff_matches_source/3,
      validate_ranking_comparison_handoff_matches_source:
        &validate_ranking_comparison_handoff_matches_source/3,
      validate_pareto_frontier_handoff_matches_source:
        &validate_pareto_frontier_handoff_matches_source/3,
      validate_realized_feedback_handoff_matches_source:
        &validate_realized_feedback_handoff_matches_source/3,
      validate_provider_counteroffer_handoff_matches_source:
        &validate_provider_counteroffer_handoff_matches_source/3,
      validate_contact_intent_handoff_matches_source:
        &validate_contact_intent_handoff_matches_source/3,
      validate_station_calendar_handoff_matches_source:
        &validate_station_calendar_handoff_matches_source/3,
      validate_provider_calendar_contention_handoff_matches_source:
        &validate_provider_calendar_contention_handoff_matches_source/3,
      validate_station_calendar_handoff_count_lists:
        &validate_station_calendar_handoff_count_lists/3,
      validate_suppression_duplicate_handoff_row_fields:
        &validate_suppression_duplicate_handoff_row_fields/3,
      validate_suppression_handoff_matches_source: &validate_suppression_handoff_matches_source/3,
      validate_contact_contention_handoff_matches_source:
        &validate_contact_contention_handoff_matches_source/3,
      validate_optional_source_window: &validate_optional_source_window/4,
      validate_optional_source_window_lineage: &validate_optional_source_window_lineage/4,
      validate_operator_review_row_links: &validate_operator_review_row_links/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_contact_allocation_capacity_pack_handoff_matches_source:
        &validate_contact_allocation_capacity_pack_handoff_matches_source/3,
      validate_station_capacity_fraction_fields: &validate_station_capacity_fraction_fields/3,
      validate_optional_timeline_link: &validate_optional_timeline_link/4,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      validate_optional_timeline_protection_summary:
        &validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_activity_state_source:
        &validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &validate_optional_timeline_preservation_source_row/3,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_timeline_diff_summary_source:
        &validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &validate_optional_timeline_integrity_source_row/3,
      error: &error/2
    ]
  end

  defp validate_operational_readiness_report(issues, path, report) do
    OrbitalDynamics.Schema.OperationalReadinessReportContracts.validate(
      issues,
      path,
      report,
      operational_readiness_report_contract_callbacks()
    )
  end

  defp operational_readiness_report_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      validate_stable_ids: &validate_stable_ids/4,
      expect_one_of: &expect_one_of/5,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_type: &expect_type/5,
      validate_rows: &validate_rows/4,
      validate_gate: &validate_operational_readiness_gate/3,
      validate_evidence: &validate_operational_readiness_evidence/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      operational_readiness_model_limits: &operational_readiness_model_limits/0,
      validate_assumptions: &validate_operational_readiness_assumptions/3,
      validate_classification: &validate_operational_readiness_classification/4,
      validate_evidence_gate_counts: &validate_operational_readiness_evidence_gate_counts/4,
      expect_field_equals: &expect_field_equals/5
    ]
  end

  defp validate_operational_readiness_assumptions(issues, path, report) do
    OrbitalDynamics.Schema.OperationalReadinessClassificationContracts.validate_assumptions(
      issues,
      path,
      report
    )
  end

  defp validate_operational_readiness_classification(issues, path, report, gates) do
    OrbitalDynamics.Schema.OperationalReadinessClassificationContracts.validate_classification(
      issues,
      path,
      report,
      gates
    )
  end

  defp operational_readiness_import_classification(gates) do
    OrbitalDynamics.Schema.OperationalReadinessClassificationContracts.import_classification(
      gates
    )
  end

  defp operational_readiness_level(import_classification) do
    OrbitalDynamics.Schema.OperationalReadinessClassificationContracts.readiness_level(
      import_classification
    )
  end

  defp operational_readiness_report_status(import_classification) do
    OrbitalDynamics.Schema.OperationalReadinessClassificationContracts.report_status(
      import_classification
    )
  end

  defp validate_operational_import_eligibility_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalImportEligibilitySummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_import_eligibility_summary_contract_callbacks()
    )
  end

  defp validate_operational_readiness_gate_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalReadinessGateSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_readiness_gate_summary_contract_callbacks()
    )
  end

  defp validate_operational_execution_boundary_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_execution_boundary_summary_contract_callbacks()
    )
  end

  defp non_negative_integer_sum(values) do
    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)), do: Enum.sum(values)
  end

  defp validate_operational_readiness_evidence_gate_counts(issues, path, evidence, gates)
       when is_map(evidence) and is_list(gates) do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceContracts.validate_gate_counts(
      issues,
      path,
      evidence,
      gates,
      operational_readiness_evidence_contract_callbacks()
    )
  end

  defp validate_operational_readiness_evidence_gate_counts(issues, _path, _evidence, _gates),
    do: issues

  defp operational_readiness_evidence_contract_callbacks do
    [
      expect_field_equals: &expect_field_equals/6,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_items: &validate_string_list_items/4,
      stable_sorted_ids: &stable_sorted_ids/1,
      validate_resource_context: &validate_operational_readiness_resource_context/3,
      validate_timeline_publication_context: &validate_timeline_publication_context/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      error: &error/2
    ]
  end

  defp operational_readiness_context_contract_callbacks do
    [
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_field_equals: &expect_field_equals/6,
      non_negative_integer_map_sum: &non_negative_integer_map_sum/1,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_array_map: &validate_optional_stable_id_array_map/4
    ]
  end

  defp operational_readiness_gate_contract_callbacks do
    [
      require_fields: &require_fields/4,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_resource_context: &validate_operational_readiness_resource_context/3,
      validate_operator_training_context:
        &validate_operational_readiness_operator_training_context/3,
      validate_adapter_boundary_context:
        &validate_operational_readiness_adapter_boundary_context/3,
      validate_cadence_import_context: &validate_operational_readiness_cadence_import_context/3,
      validate_timeline_publication_context: &validate_timeline_publication_context/3
    ]
  end

  defp validate_operational_readiness_gate(issues, path, gate) do
    OrbitalDynamics.Schema.OperationalReadinessGateContracts.validate(
      issues,
      path,
      gate,
      operational_readiness_gate_contract_callbacks()
    )
  end

  defp validate_operational_readiness_evidence(issues, path, evidence) do
    OrbitalDynamics.Schema.OperationalReadinessEvidenceContracts.validate(
      issues,
      path,
      evidence,
      operational_readiness_evidence_contract_callbacks()
    )
  end

  defp gate_status_count(gates, status) when is_list(gates) do
    OrbitalDynamics.Schema.OperationalReadinessReportContracts.gate_status_count(gates, status)
  end

  defp gate_status_count(_gates, _status), do: nil

  defp validate_operational_quality_gate_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_quality_gate_summary_contract_callbacks()
    )
  end

  defp validate_operational_quality_gate_unavailable_resource_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateUnavailableResourceSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_quality_gate_unavailable_resource_summary_contract_callbacks()
    )
  end

  defp validate_operational_quality_gate_operator_training_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateOperatorTrainingSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_quality_gate_operator_training_summary_contract_callbacks()
    )
  end

  defp validate_operational_quality_gate_schema_validation_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateSchemaValidationSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_quality_gate_schema_validation_summary_contract_callbacks()
    )
  end

  defp non_negative_integer_map_value(counts, key) when is_map(counts) do
    OrbitalDynamics.Schema.CollectionAggregation.non_negative_integer_map_value(counts, key)
  end

  defp non_negative_integer_map_value(counts, key),
    do: OrbitalDynamics.Schema.CollectionAggregation.non_negative_integer_map_value(counts, key)

  defp validate_operational_quality_gate_import_readiness_summary(issues, path, summary) do
    OrbitalDynamics.Schema.OperationalQualityGateImportReadinessSummaryContracts.validate_summary(
      issues,
      path,
      summary,
      operational_quality_gate_import_readiness_summary_contract_callbacks()
    )
  end

  defp positive_count_map_keys(counts) when is_map(counts) do
    OrbitalDynamics.Schema.CollectionAggregation.positive_count_map_keys(counts)
  end

  defp positive_count_map_keys(counts),
    do: OrbitalDynamics.Schema.CollectionAggregation.positive_count_map_keys(counts)

  defp validate_quality_gate_report(issues, path, report) do
    OrbitalDynamics.Schema.QualityGateReportContracts.validate_report(
      issues,
      path,
      report,
      quality_gate_report_contract_callbacks()
    )
  end

  defp quality_gate_execution_boundary("importable"), do: "adapter_handoff_only"

  defp quality_gate_execution_boundary("review_only"),
    do: "operator_review_required_before_import"

  defp quality_gate_execution_boundary("analysis_only"), do: "analysis_only_not_for_execution"

  defp quality_gate_execution_boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp quality_gate_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_source_gate_handoff_matches:
        &validate_source_operational_readiness_gate_handoff_matches/3,
      validate_source_report_handoff_matches:
        &validate_source_operational_readiness_report_handoff_matches/3,
      validate_resource_context: &validate_operational_readiness_resource_context/3,
      validate_operator_training_context:
        &validate_operational_readiness_operator_training_context/3,
      validate_adapter_boundary_context:
        &validate_operational_readiness_adapter_boundary_context/3,
      validate_cadence_import_context: &validate_operational_readiness_cadence_import_context/3,
      validate_timeline_publication_context: &validate_timeline_publication_context/3,
      stable_sorted_ids: &stable_sorted_ids/1
    ]
  end

  defp validate_quality_gate_row(issues, path, row) do
    OrbitalDynamics.Schema.QualityGateRowContracts.validate(
      issues,
      path,
      row,
      quality_gate_row_contract_callbacks()
    )
  end

  defp validate_operational_readiness_operator_training_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_operator_training_context(
      issues,
      path,
      row,
      operational_readiness_context_contract_callbacks()
    )
  end

  defp validate_operational_readiness_resource_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_resource_context(
      issues,
      path,
      row,
      operational_readiness_context_contract_callbacks()
    )
  end

  defp resource_availability_reason_ids(counts) when is_map(counts) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.resource_availability_reason_ids(
      counts
    )
  end

  defp resource_availability_reason_ids(_counts), do: nil

  defp unavailable_resource_reason_ids(counts) when is_map(counts) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.unavailable_resource_reason_ids(
      counts
    )
  end

  defp unavailable_resource_reason_ids(_counts), do: nil

  defp validate_operational_readiness_adapter_boundary_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_adapter_boundary_context(
      issues,
      path,
      row,
      operational_readiness_context_contract_callbacks()
    )
  end

  defp validate_operational_readiness_cadence_import_context(issues, path, row) do
    OrbitalDynamics.Schema.OperationalReadinessContextContracts.validate_cadence_import_context(
      issues,
      path,
      row,
      operational_readiness_context_contract_callbacks()
    )
  end

  defp quality_gate_status_count(rows, status) when is_list(rows) do
    OrbitalDynamics.Schema.QualityGateRowContracts.status_count(rows, status)
  end

  defp quality_gate_status_count(_rows, _status), do: nil

  defp quality_gate_ids_by(rows, field) when is_list(rows) do
    OrbitalDynamics.Schema.QualityGateRowContracts.ids_by(
      rows,
      field,
      quality_gate_row_contract_callbacks()
    )
  end

  defp quality_gate_ids_by(_rows, _field), do: nil

  defp quality_gate_row_ids_by(rows, field) when is_list(rows) do
    OrbitalDynamics.Schema.QualityGateRowContracts.row_ids_by(
      rows,
      field,
      quality_gate_row_contract_callbacks()
    )
  end

  defp quality_gate_row_ids_by(_rows, _field), do: nil

  defp quality_gate_ids(rows, status) when is_list(rows) do
    OrbitalDynamics.Schema.QualityGateRowContracts.ids(
      rows,
      status,
      quality_gate_row_contract_callbacks()
    )
  end

  defp quality_gate_ids(_rows, _status), do: nil

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp validate_cadence_import_row(issues, path, row) do
    capability = OrbitalDynamics.CadenceImport.capability()

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
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_one_of: &expect_one_of/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_number_list_items: &validate_number_list_items/4,
      validate_station_calendar_handoff_count_lists:
        &validate_station_calendar_handoff_count_lists/3,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_contact_allocation_capacity_pack_handoff_matches_source:
        &validate_contact_allocation_capacity_pack_handoff_matches_source/3,
      validate_station_capacity_fraction_fields: &validate_station_capacity_fraction_fields/3,
      validate_suppression_duplicate_handoff_row_fields:
        &validate_suppression_duplicate_handoff_row_fields/3,
      validate_scoped_downlink_context_fields: &validate_scoped_downlink_context_fields/3,
      validate_observation_quality_handoff_fields: &validate_observation_quality_handoff_fields/3,
      validate_feedback_maneuver_handoff_fields: &validate_feedback_maneuver_handoff_fields/3,
      validate_link_handoff_fields: &validate_link_handoff_fields/3,
      validate_resource_availability_variance_fields:
        &validate_resource_availability_variance_fields/3,
      validate_eclipse_lighting_handoff_fields: &validate_eclipse_lighting_handoff_fields/3,
      validate_thermal_handoff_fields: &validate_thermal_handoff_fields/3,
      validate_branch_event_summary_fields: &validate_branch_event_summary_fields/3,
      expect_optional_number: &expect_optional_number/4,
      validate_semantic_change_details: &validate_semantic_change_details/3,
      validate_candidate_diff_changed_fields: &validate_candidate_diff_changed_fields/3,
      validate_optional_policy_decision_evidence: &validate_optional_policy_decision_evidence/3,
      validate_optional_policy_escalation: &validate_optional_policy_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &validate_optional_candidate_rejection_source_row/3,
      validate_optional_branch_comparison_source_row:
        &validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &validate_source_evidence_fields/3,
      validate_source_operational_readiness_report_handoff_matches:
        &validate_source_operational_readiness_report_handoff_matches/3,
      validate_source_quality_gate_report_handoff_matches:
        &validate_source_quality_gate_report_handoff_matches/3,
      validate_freshness_source_status_matches: &validate_freshness_source_status_matches/3,
      validate_refresh_budget_handoff_matches_source:
        &validate_refresh_budget_handoff_matches_source/3,
      validate_schema_validation_source_status_matches:
        &validate_schema_validation_source_status_matches/3,
      validate_execution_source_status_matches: &validate_execution_source_status_matches/3,
      validate_optional_source_window: &validate_optional_source_window/4,
      validate_nested_id_match: &validate_nested_id_match/7,
      validate_optional_source_window_lineage: &validate_optional_source_window_lineage/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_timeline_link: &validate_optional_timeline_link/4,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      validate_cadence_source_review_row: &validate_cadence_source_review_row/3,
      validate_operational_readiness_resource_context:
        &validate_operational_readiness_resource_context/3,
      validate_operational_readiness_cadence_import_context:
        &validate_operational_readiness_cadence_import_context/3
    ]
    |> Keyword.merge(cadence_import_row_handoff_contract_callbacks())
  end

  defp cadence_import_row_handoff_contract_callbacks do
    [
      validate_approval_requirement_handoff_matches_source:
        &validate_approval_requirement_handoff_matches_source/3,
      validate_cadence_source_review_approval_requirement_handoff_matches:
        &validate_cadence_source_review_approval_requirement_handoff_matches/3,
      validate_cadence_source_review_battery_handoff_matches:
        &validate_cadence_source_review_battery_handoff_matches/3,
      validate_cadence_source_review_candidate_diff_handoff_matches:
        &validate_cadence_source_review_candidate_diff_handoff_matches/3,
      validate_cadence_source_review_candidate_rejection_handoff_matches:
        &validate_cadence_source_review_candidate_rejection_handoff_matches/3,
      validate_cadence_source_review_command_window_handoff_matches:
        &validate_cadence_source_review_command_window_handoff_matches/3,
      validate_cadence_source_review_constraint_handoff_matches:
        &validate_cadence_source_review_constraint_handoff_matches/3,
      validate_cadence_source_review_contact_allocation_capacity_pack_handoff_matches:
        &validate_cadence_source_review_contact_allocation_capacity_pack_handoff_matches/3,
      validate_cadence_source_review_contact_allocation_handoff_matches:
        &validate_cadence_source_review_contact_allocation_handoff_matches/3,
      validate_cadence_source_review_contact_contention_handoff_matches:
        &validate_cadence_source_review_contact_contention_handoff_matches/3,
      validate_cadence_source_review_contact_intent_handoff_matches:
        &validate_cadence_source_review_contact_intent_handoff_matches/3,
      validate_cadence_source_review_execution_handoff_matches:
        &validate_cadence_source_review_execution_handoff_matches/3,
      validate_cadence_source_review_freshness_handoff_matches:
        &validate_cadence_source_review_freshness_handoff_matches/3,
      validate_cadence_source_review_link_capacity_handoff_matches:
        &validate_cadence_source_review_link_capacity_handoff_matches/3,
      validate_cadence_source_review_maneuver_review_handoff_matches:
        &validate_cadence_source_review_maneuver_review_handoff_matches/3,
      validate_cadence_source_review_objective_satisfaction_handoff_matches:
        &validate_cadence_source_review_objective_satisfaction_handoff_matches/3,
      validate_cadence_source_review_objective_tradeoff_handoff_matches:
        &validate_cadence_source_review_objective_tradeoff_handoff_matches/3,
      validate_cadence_source_review_operational_readiness_handoff_matches:
        &validate_cadence_source_review_operational_readiness_handoff_matches/3,
      validate_cadence_source_review_operational_timeline_handoff_matches:
        &validate_cadence_source_review_operational_timeline_handoff_matches/3,
      validate_cadence_source_review_pareto_frontier_handoff_matches:
        &validate_cadence_source_review_pareto_frontier_handoff_matches/3,
      validate_cadence_source_review_plan_delta_handoff_matches:
        &validate_cadence_source_review_plan_delta_handoff_matches/3,
      validate_cadence_source_review_policy_escalation_handoff_matches:
        &validate_cadence_source_review_policy_escalation_handoff_matches/3,
      validate_cadence_source_review_provider_calendar_contention_handoff_matches:
        &validate_cadence_source_review_provider_calendar_contention_handoff_matches/3,
      validate_cadence_source_review_provider_counteroffer_handoff_matches:
        &validate_cadence_source_review_provider_counteroffer_handoff_matches/3,
      validate_cadence_source_review_quality_gate_handoff_matches:
        &validate_cadence_source_review_quality_gate_handoff_matches/3,
      validate_cadence_source_review_ranking_comparison_handoff_matches:
        &validate_cadence_source_review_ranking_comparison_handoff_matches/3,
      validate_cadence_source_review_realized_feedback_handoff_matches:
        &validate_cadence_source_review_realized_feedback_handoff_matches/3,
      validate_cadence_source_review_refresh_budget_handoff_matches:
        &validate_cadence_source_review_refresh_budget_handoff_matches/3,
      validate_cadence_source_review_resource_projection_context_handoff_matches:
        &validate_cadence_source_review_resource_projection_context_handoff_matches/3,
      validate_cadence_source_review_resource_projection_count_handoff_matches:
        &validate_cadence_source_review_resource_projection_count_handoff_matches/3,
      validate_cadence_source_review_risk_explanation_handoff_matches:
        &validate_cadence_source_review_risk_explanation_handoff_matches/3,
      validate_cadence_source_review_schema_validation_handoff_matches:
        &validate_cadence_source_review_schema_validation_handoff_matches/3,
      validate_cadence_source_review_score_term_handoff_matches:
        &validate_cadence_source_review_score_term_handoff_matches/3,
      validate_cadence_source_review_station_calendar_handoff_matches:
        &validate_cadence_source_review_station_calendar_handoff_matches/3,
      validate_cadence_source_review_strategy_recommendation_handoff_matches:
        &validate_cadence_source_review_strategy_recommendation_handoff_matches/3,
      validate_cadence_source_review_strategy_tradeoff_handoff_matches:
        &validate_cadence_source_review_strategy_tradeoff_handoff_matches/3,
      validate_cadence_source_review_suppression_duplicate_matches:
        &validate_cadence_source_review_suppression_duplicate_matches/3,
      validate_cadence_source_review_timeline_activity_precondition_handoff_matches:
        &validate_cadence_source_review_timeline_activity_precondition_handoff_matches/3,
      validate_cadence_source_review_timeline_dependency_impact_handoff_matches:
        &validate_cadence_source_review_timeline_dependency_impact_handoff_matches/3,
      validate_cadence_source_review_timeline_diff_handoff_matches:
        &validate_cadence_source_review_timeline_diff_handoff_matches/3,
      validate_cadence_source_review_timeline_lifecycle_state_handoff_matches:
        &validate_cadence_source_review_timeline_lifecycle_state_handoff_matches/3,
      validate_cadence_source_review_timeline_preservation_handoff_matches:
        &validate_cadence_source_review_timeline_preservation_handoff_matches/3,
      validate_cadence_source_review_timeline_protection_handoff_matches:
        &validate_cadence_source_review_timeline_protection_handoff_matches/3,
      validate_cadence_source_review_timeline_publication_handoff_matches:
        &validate_cadence_source_review_timeline_publication_handoff_matches/3,
      validate_cadence_source_review_timeline_transition_application_handoff_matches:
        &validate_cadence_source_review_timeline_transition_application_handoff_matches/3,
      validate_cadence_source_review_warning_handoff_matches:
        &validate_cadence_source_review_warning_handoff_matches/3,
      validate_candidate_diff_handoff_matches_source:
        &validate_candidate_diff_handoff_matches_source/3,
      validate_candidate_rejection_handoff_matches_source:
        &validate_candidate_rejection_handoff_matches_source/3,
      validate_command_window_handoff_matches_source:
        &validate_command_window_handoff_matches_source/3,
      validate_constraint_handoff_matches_source: &validate_constraint_handoff_matches_source/3,
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_contact_allocation_handoff_matches_source:
        &validate_contact_allocation_handoff_matches_source/3,
      validate_contact_contention_handoff_matches_source:
        &validate_contact_contention_handoff_matches_source/3,
      validate_contact_intent_handoff_matches_source:
        &validate_contact_intent_handoff_matches_source/3,
      validate_link_capacity_handoff_count_lists: &validate_link_capacity_handoff_count_lists/3,
      validate_link_capacity_handoff_matches_source:
        &validate_link_capacity_handoff_matches_source/3,
      validate_maneuver_review_handoff_matches_source:
        &validate_maneuver_review_handoff_matches_source/3,
      validate_objective_satisfaction_handoff_matches_source:
        &validate_objective_satisfaction_handoff_matches_source/3,
      validate_objective_tradeoff_handoff_matches_source:
        &validate_objective_tradeoff_handoff_matches_source/3,
      validate_operational_timeline_handoff_matches_source:
        &validate_operational_timeline_handoff_matches_source/3,
      validate_operator_review_row_links: &validate_operator_review_row_links/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_activity_state_source:
        &validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_dependency_impact_source_row:
        &validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_timeline_diff_summary_source:
        &validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_integrity_source_row:
        &validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_preservation_source_row:
        &validate_optional_timeline_preservation_source_row/3,
      validate_optional_timeline_protection_summary:
        &validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_publication_summary_source:
        &validate_optional_timeline_publication_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_transition_application_summary_source:
        &validate_optional_timeline_transition_application_summary_source/3,
      validate_pareto_frontier_handoff_matches_source:
        &validate_pareto_frontier_handoff_matches_source/3,
      validate_plan_delta_handoff_matches_source: &validate_plan_delta_handoff_matches_source/3,
      validate_provider_calendar_contention_handoff_matches_source:
        &validate_provider_calendar_contention_handoff_matches_source/3,
      validate_provider_counteroffer_handoff_matches_source:
        &validate_provider_counteroffer_handoff_matches_source/3,
      validate_ranking_comparison_handoff_matches_source:
        &validate_ranking_comparison_handoff_matches_source/3,
      validate_realized_feedback_handoff_matches_source:
        &validate_realized_feedback_handoff_matches_source/3,
      validate_resource_projection_battery_handoff_fields:
        &validate_resource_projection_battery_handoff_fields/3,
      validate_resource_projection_battery_handoff_matches_source:
        &validate_resource_projection_battery_handoff_matches_source/3,
      validate_resource_projection_count_handoff_matches_source:
        &validate_resource_projection_count_handoff_matches_source/3,
      validate_resource_projection_flow_summary_context_matches_source:
        &validate_resource_projection_flow_summary_context_matches_source/3,
      validate_resource_projection_remaining_handoff_fields:
        &validate_resource_projection_remaining_handoff_fields/3,
      validate_risk_explanation_handoff_matches_source:
        &validate_risk_explanation_handoff_matches_source/3,
      validate_score_term_handoff_matches_source: &validate_score_term_handoff_matches_source/3,
      validate_selected_timeline_integrity_fields: &validate_selected_timeline_integrity_fields/3,
      validate_source_operational_readiness_gate_handoff_matches:
        &validate_source_operational_readiness_gate_handoff_matches/3,
      validate_source_quality_gate_row_handoff_matches:
        &validate_source_quality_gate_row_handoff_matches/3,
      validate_station_calendar_handoff_matches_source:
        &validate_station_calendar_handoff_matches_source/3,
      validate_strategy_branch_comparison_handoff_matches_source:
        &validate_strategy_branch_comparison_handoff_matches_source/3,
      validate_strategy_recommendation_handoff_matches_source:
        &validate_strategy_recommendation_handoff_matches_source/3,
      validate_strategy_tradeoff_handoff_matches_source:
        &validate_strategy_tradeoff_handoff_matches_source/3,
      validate_suppression_handoff_matches_source: &validate_suppression_handoff_matches_source/3,
      validate_timeline_diff_handoff_matches_source:
        &validate_timeline_diff_handoff_matches_source/3,
      validate_timeline_publication_handoff_matches_source:
        &validate_timeline_publication_handoff_matches_source/3,
      validate_timeline_transition_application_handoff_matches_source:
        &validate_timeline_transition_application_handoff_matches_source/3
    ]
  end

  defp validate_cadence_source_review_row(issues, path, row) do
    OrbitalDynamics.Schema.CadenceSourceReviewRowContracts.validate(
      issues,
      path,
      row,
      cadence_source_review_row_contract_callbacks()
    )
  end

  defp row_count_difference(report, field, subtract) do
    OrbitalDynamics.Schema.CollectionAggregation.row_count_difference(report, field, subtract)
  end

  defp row_count_sum(report, fields) do
    OrbitalDynamics.Schema.CollectionAggregation.row_count_sum(report, fields)
  end

  defp list_count(map, field) do
    OrbitalDynamics.Schema.CollectionAggregation.list_count(map, field)
  end

  defp sum_row_numbers(rows, field) do
    OrbitalDynamics.Schema.CollectionAggregation.sum_row_numbers(rows, field)
  end

  defp sorted_unique_binary_values(values) do
    OrbitalDynamics.Schema.CollectionAggregation.sorted_unique_binary_values(values)
  end

  defp row_unique_values(rows, field) do
    OrbitalDynamics.Schema.CollectionAggregation.row_unique_values(rows, field)
  end

  defp row_ids_by_field(rows, group_field, id_field) do
    OrbitalDynamics.Schema.CollectionAggregation.row_ids_by_field(rows, group_field, id_field)
  end

  defp row_ids_by_field_value(rows, field, value, id_field) do
    OrbitalDynamics.Schema.CollectionAggregation.row_ids_by_field_value(
      rows,
      field,
      value,
      id_field
    )
  end

  defp row_ids_by_string_field(rows, group_field, id_field) do
    OrbitalDynamics.Schema.CollectionAggregation.row_ids_by_string_field(
      rows,
      group_field,
      id_field
    )
  end

  defp row_ids_by_direction_and_ground_station(rows, id_field) do
    OrbitalDynamics.Schema.CollectionAggregation.row_ids_by_direction_and_ground_station(
      rows,
      id_field
    )
  end

  defp id_array_count_map(id_arrays) when is_map(id_arrays) do
    OrbitalDynamics.Schema.CollectionAggregation.id_array_count_map(id_arrays)
  end

  defp frequency_map(rows, field) do
    OrbitalDynamics.Schema.CollectionAggregation.frequency_map(rows, field)
  end

  defp nested_frequency_map(rows, field, nested_field) do
    OrbitalDynamics.Schema.CollectionAggregation.nested_frequency_map(rows, field, nested_field)
  end

  defp changed_field_frequency_map(rows) do
    OrbitalDynamics.Schema.CollectionAggregation.changed_field_frequency_map(rows)
  end

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp expect_optional_list_field_equals(issues, path, map, field, expected, message) do
    value = Map.get(map, field)

    cond do
      (is_nil(value) or not Map.has_key?(map, field)) and expected == [] ->
        issues

      Map.has_key?(map, field) and value != expected ->
        [error("#{path}.#{field}", message) | issues]

      true ->
        issues
    end
  end

  defp expect_number_field_equals(issues, _path, _map, _field, nil, _message), do: issues

  defp expect_number_field_equals(issues, path, map, field, expected, message)
       when is_number(expected) do
    value = Map.get(map, field)

    cond do
      not Map.has_key?(map, field) ->
        issues

      is_number(value) and abs(value - expected) <= 1.0e-9 ->
        issues

      true ->
        [error("#{path}.#{field}", message) | issues]
    end
  end

  defp validate_plan_delta(issues, path, delta) do
    OrbitalDynamics.Schema.PlanDeltaContracts.validate(
      issues,
      path,
      delta,
      plan_delta_contract_callbacks()
    )
  end

  defp validate_approval_requirement(issues, path, requirement) do
    OrbitalDynamics.Schema.ApprovalRequirementContracts.validate(
      issues,
      path,
      requirement,
      policy_model_limits(),
      approval_requirement_contract_callbacks()
    )
  end

  defp approval_requirement_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_schema_contract: &validate_optional_schema_contract/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_rows: &validate_optional_rows/4,
      validate_policy_rule_match: &validate_policy_rule_match/3,
      expect_optional_one_of: &expect_optional_one_of/5,
      validate_policy_escalation: &validate_policy_escalation/3,
      validate_string_list_items: &validate_string_list_items/4,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      expect_field_equals: &expect_field_equals/5,
      error: &error/2
    ]
  end

  defp validate_optional_policy_decision_evidence(issues, path, decision) do
    OrbitalDynamics.Schema.ApprovalRequirementContracts.validate_policy_decision_evidence(
      issues,
      path,
      decision,
      policy_model_limits(),
      approval_requirement_contract_callbacks()
    )
  end

  defp validate_source_evidence_fields(issues, path, row) do
    OrbitalDynamics.Schema.SourceEvidenceContracts.validate_fields(
      issues,
      path,
      row,
      source_evidence_contract_callbacks()
    )
  end

  defp validate_freshness_source_status_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_freshness_matches(
      issues,
      path,
      row,
      freshness_statuses()
    )
  end

  defp validate_refresh_budget_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_refresh_budget_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_schema_validation_source_status_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_schema_validation_matches(
      issues,
      path,
      row,
      schema_validation_statuses()
    )
  end

  defp validate_execution_source_status_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_execution_matches(
      issues,
      path,
      row,
      OrbitalDynamics.Schema.ExecutionReportContracts.statuses()
    )
  end

  defp validate_resource_projection_battery_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_fields(
      issues,
      path,
      row,
      resource_projection_handoff_contract_callbacks()
    )
  end

  defp validate_resource_projection_remaining_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_remaining_handoff_fields(
      issues,
      path,
      row,
      resource_projection_handoff_contract_callbacks()
    )
  end

  defp validate_resource_projection_battery_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_resource_projection_count_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_count_handoff_matches_source(
      issues,
      path,
      row,
      resource_projection_handoff_contract_callbacks()
    )
  end

  defp validate_resource_projection_flow_summary_context_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_flow_summary_context_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_resource_projection_battery_handoff_matches_own_flow(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_matches_own_flow(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_battery_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_cadence_source_review_battery_handoff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_resource_projection_count_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_cadence_source_review_count_handoff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_resource_projection_context_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_cadence_source_review_context_handoff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_suppression_duplicate_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_cadence_source_review_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_suppression_duplicate_matches(issues, _path, _row),
    do: issues

  defp validate_link_capacity_handoff_count_lists(issues, path, row) do
    OrbitalDynamics.Schema.LinkCapacityHandoffContracts.validate_count_lists(
      issues,
      path,
      row
    )
  end

  defp validate_link_capacity_handoff_matches_source(
         issues,
         path,
         %{"source_link_capacity" => %{}} = row
       ) do
    OrbitalDynamics.Schema.LinkCapacityHandoffContracts.validate_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_link_capacity_handoff_matches_source(issues, _path, _row), do: issues

  defp validate_cadence_source_review_link_capacity_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.LinkCapacityHandoffContracts.validate_cadence_source_review_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_link_capacity_handoff_matches(issues, _path, _row),
    do: issues

  defp validate_contact_allocation_handoff_fields(issues, path, row) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_fields(
      issues,
      path,
      row,
      contact_allocation_handoff_contract_callbacks()
    )
  end

  defp validate_contact_allocation_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_contact_allocation_capacity_pack_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_capacity_pack_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_contact_allocation_capacity_pack_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_cadence_source_review_capacity_pack_matches(
      issues,
      path,
      row
    )
  end

  defp validate_contact_contention_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.ContactContentionHandoffContracts.validate_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_contact_contention_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactContentionHandoffContracts.validate_cadence_source_review_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_contact_contention_handoff_matches(issues, _path, _row),
    do: issues

  defp validate_source_operational_readiness_gate_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_gate_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_source_operational_readiness_report_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_report_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_source_quality_gate_row_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_row_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_source_quality_gate_report_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_report_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_contact_allocation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_cadence_source_review_allocation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_command_window_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_command_window_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_command_window_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_cadence_source_review_command_window_matches(
      issues,
      path,
      row
    )
  end

  defp validate_maneuver_review_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_maneuver_review_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_maneuver_review_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CommandWindowManeuverHandoffContracts.validate_cadence_source_review_maneuver_review_matches(
      issues,
      path,
      row
    )
  end

  defp validate_timeline_diff_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_diff_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_diff_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_diff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_timeline_transition_application_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_timeline_transition_application_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_transition_application_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_transition_application_matches(
      issues,
      path,
      row
    )
  end

  defp validate_candidate_rejection_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CandidateHandoffContracts.validate_candidate_rejection_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_candidate_rejection_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CandidateHandoffContracts.validate_cadence_source_review_candidate_rejection_matches(
      issues,
      path,
      row
    )
  end

  defp validate_candidate_diff_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CandidateHandoffContracts.validate_candidate_diff_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_candidate_diff_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.CandidateHandoffContracts.validate_cadence_source_review_candidate_diff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_constraint_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_constraint_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_constraint_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_cadence_source_review_constraint_matches(
      issues,
      path,
      row
    )
  end

  defp validate_objective_satisfaction_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_objective_satisfaction_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_objective_satisfaction_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_cadence_source_review_objective_satisfaction_matches(
      issues,
      path,
      row
    )
  end

  defp validate_score_term_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_score_term_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_score_term_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_cadence_source_review_score_term_matches(
      issues,
      path,
      row
    )
  end

  defp validate_objective_tradeoff_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_objective_tradeoff_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_objective_tradeoff_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.OptimizationHandoffContracts.validate_cadence_source_review_objective_tradeoff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_approval_requirement_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_approval_requirement_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_approval_requirement_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_cadence_source_review_approval_requirement_matches(
      issues,
      path,
      row
    )
  end

  defp validate_plan_delta_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_plan_delta_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_plan_delta_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.PolicyPlanHandoffContracts.validate_cadence_source_review_plan_delta_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_warning_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_warning_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_protection_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_timeline_protection_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_publication_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_publication_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_dependency_impact_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_dependency_impact_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_activity_precondition_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_activity_precondition_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_lifecycle_state_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_lifecycle_state_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_timeline_preservation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_timeline_preservation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_policy_escalation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_policy_escalation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_freshness_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_freshness_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_refresh_budget_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_refresh_budget_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_schema_validation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_schema_validation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_execution_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_execution_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_quality_gate_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_quality_gate_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_operational_readiness_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_operational_readiness_matches(
      issues,
      path,
      row
    )
  end

  defp validate_risk_explanation_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_risk_explanation_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_risk_explanation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_cadence_source_review_risk_explanation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_operational_timeline_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_operational_timeline_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_operational_timeline_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.TimelineHandoffContracts.validate_cadence_source_review_operational_timeline_matches(
      issues,
      path,
      row
    )
  end

  defp validate_strategy_recommendation_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_strategy_recommendation_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_strategy_recommendation_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_cadence_source_review_strategy_recommendation_matches(
      issues,
      path,
      row
    )
  end

  defp validate_strategy_tradeoff_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_strategy_tradeoff_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_strategy_tradeoff_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_cadence_source_review_strategy_tradeoff_matches(
      issues,
      path,
      row
    )
  end

  defp validate_strategy_branch_comparison_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_branch_comparison_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_ranking_comparison_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_ranking_comparison_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_ranking_comparison_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_cadence_source_review_ranking_comparison_matches(
      issues,
      path,
      row
    )
  end

  defp validate_pareto_frontier_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_pareto_frontier_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_pareto_frontier_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.StrategyHandoffContracts.validate_cadence_source_review_pareto_frontier_matches(
      issues,
      path,
      row
    )
  end

  defp validate_realized_feedback_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_realized_feedback_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_realized_feedback_handoff_matches(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.RiskFeedbackHandoffContracts.validate_cadence_source_review_realized_feedback_matches(
      issues,
      path,
      row
    )
  end

  defp validate_provider_counteroffer_handoff_matches_source(
         issues,
         path,
         %{"source_provider_counteroffer" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_provider_counteroffer_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_provider_counteroffer_handoff_matches_source(issues, _path, _row), do: issues

  defp validate_cadence_source_review_provider_counteroffer_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_cadence_source_review_provider_counteroffer_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_provider_counteroffer_handoff_matches(
         issues,
         _path,
         _row
       ),
       do: issues

  defp validate_contact_intent_handoff_matches_source(
         issues,
         path,
         %{"source_contact_intent" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_contact_intent_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_contact_intent_handoff_matches_source(issues, _path, _row), do: issues

  defp validate_cadence_source_review_contact_intent_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactReviewHandoffContracts.validate_cadence_source_review_contact_intent_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_contact_intent_handoff_matches(issues, _path, _row),
    do: issues

  defp validate_station_calendar_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_station_calendar_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_cadence_source_review_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_station_calendar_handoff_matches(issues, _path, _row),
    do: issues

  defp validate_provider_calendar_contention_handoff_matches_source(
         issues,
         path,
         row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_provider_calendar_contention_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_provider_calendar_contention_handoff_matches(
         issues,
         path,
         %{"source_review_row" => %{}} = row
       ) do
    OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_cadence_source_review_provider_calendar_contention_matches(
      issues,
      path,
      row
    )
  end

  defp validate_cadence_source_review_provider_calendar_contention_handoff_matches(
         issues,
         _path,
         _row
       ),
       do: issues

  defp validate_station_calendar_handoff_count_lists(issues, path, row) do
    OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_count_lists(
      issues,
      path,
      row
    )
  end

  defp validate_suppression_duplicate_handoff_row_fields(issues, path, row) do
    OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_row_fields(
      issues,
      path,
      row,
      suppression_handoff_contract_callbacks()
    )
  end

  defp validate_suppression_handoff_matches_source(issues, path, row) do
    OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_matches_source(
      issues,
      path,
      row
    )
  end

  defp validate_suppression_duplicate_handoff_groups(issues, path, rows) when is_list(rows) do
    OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups(
      issues,
      path,
      rows,
      suppression_handoff_contract_callbacks()
    )
  end

  defp validate_suppression_duplicate_handoff_groups(issues, path, rows) do
    OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups(
      issues,
      path,
      rows,
      suppression_handoff_contract_callbacks()
    )
  end

  defp suppression_handoff_contract_callbacks do
    [
      expect_optional_type: &expect_optional_type/5,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_duplicate_suppressed_candidate_evidence:
        &validate_duplicate_suppressed_candidate_evidence/3,
      expect_field_equals: &expect_field_equals/5,
      error: &error/2
    ]
  end

  defp validate_optional_policy_escalation(issues, path, row, field) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = escalation ->
        validate_policy_escalation(issues, "#{path}.#{field}", escalation)

      _value ->
        [error("#{path}.#{field}", "must be an object") | issues]
    end
  end

  defp validate_branch(issues, path, branch) do
    OrbitalDynamics.Schema.StrategyBranchContracts.validate(
      issues,
      path,
      branch,
      strategy_branch_contract_callbacks()
    )
  end

  defp strategy_branch_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_number: &expect_number/4,
      expect_probability_range: &expect_probability_range/4,
      expect_type: &expect_type/5,
      validate_numeric_map: &validate_numeric_map/3,
      validate_rows: &validate_rows/4,
      validate_branch_event: &validate_branch_event/3,
      validate_optional_resource_projection_report:
        &validate_optional_resource_projection_report/3,
      validate_policy_decision: &validate_policy_decision/3,
      validate_approval_requirement: &validate_approval_requirement/3,
      expect_field_equals_with_message: &expect_field_equals/6,
      error: &error/2
    ]
  end

  defp validate_branch_event(issues, path, event) do
    OrbitalDynamics.Schema.BranchEventContracts.validate_event(
      issues,
      path,
      event,
      branch_event_contract_callbacks()
    )
  end

  defp validate_recommendation(issues, path, recommendation) do
    OrbitalDynamics.Schema.StrategyRecommendationContracts.validate(
      issues,
      path,
      recommendation,
      strategy_recommendation_contract_callbacks()
    )
  end

  defp validate_policy_decision(issues, path, decision) do
    OrbitalDynamics.Schema.PolicyDecisionContracts.validate(
      issues,
      path,
      decision,
      policy_model_limits(),
      policy_rule_match_field_groups()
    )
  end

  defp validate_policy_rule_match(issues, path, match) do
    OrbitalDynamics.Schema.PolicyRuleMatchContracts.validate(
      issues,
      path,
      match,
      policy_rule_match_field_groups()
    )
  end

  defp policy_rule_match_field_groups do
    [
      string_fields: @policy_context_string_fields,
      string_array_fields: @policy_context_string_array_fields,
      string_or_array_fields: @policy_context_string_or_array_fields,
      number_fields: @policy_context_number_fields,
      integer_fields: @policy_context_integer_fields,
      boolean_fields: @policy_context_boolean_fields
    ]
  end

  defp validate_policy_escalation(issues, path, escalation) do
    OrbitalDynamics.Schema.PolicyEscalationContracts.validate(
      issues,
      path,
      escalation
    )
  end

  defp validate_policy_bundle(issues, path, bundle) do
    OrbitalDynamics.Schema.PolicyBundleContracts.validate(
      issues,
      path,
      bundle,
      policy_model_limits(),
      policy_action_rule_field_groups()
    )
  end

  defp validate_operator_review_package(issues, path, package) do
    OrbitalDynamics.Schema.OperatorReviewPackageContracts.validate(
      issues,
      path,
      package,
      OrbitalDynamics.OperatorReview.capabilities().source_artifact_types,
      operator_review_package_model_limits(),
      operator_review_package_contract_field_groups(),
      operator_review_package_contract_callbacks()
    )
  end

  defp operator_review_package_contract_field_groups do
    [
      required_scalar_count_fields: @operator_review_package_required_scalar_count_fields,
      optional_scalar_count_fields: @operator_review_package_optional_scalar_count_fields
    ]
  end

  defp operator_review_package_contract_callbacks do
    [
      expect_equal: &expect_equal/5,
      expect_one_of: &expect_one_of/5,
      validate_stable_ids: &validate_stable_ids/4,
      expect_non_negative_integer: &expect_non_negative_integer/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_type: &expect_optional_type/5,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_string_list_items: &validate_string_list_items/4,
      validate_contact_allocation_expiration_handoff_summary:
        &validate_contact_allocation_expiration_handoff_summary/3,
      validate_quality_gate_handoff_summary: &validate_quality_gate_handoff_summary/3,
      validate_optional_exact_model_limits: &validate_optional_exact_model_limits/5,
      expect_type: &expect_type/5,
      validate_rows: &validate_rows/4,
      validate_operator_review_row: &validate_operator_review_row/3,
      validate_suppression_duplicate_handoff_groups:
        &validate_suppression_duplicate_handoff_groups/3,
      validate_non_negative_integer_count_map: &validate_non_negative_integer_count_map/3,
      expect_field_equals: &expect_field_equals/5,
      expect_field_equals_with_message: &expect_field_equals/6,
      error: &error/2
    ]
  end

  defp validate_operator_review_row(issues, path, row) do
    OrbitalDynamics.Schema.OperatorReviewRowContracts.validate(
      issues,
      path,
      row,
      OrbitalDynamics.OperatorReview.capabilities().review_types,
      OrbitalDynamics.Communications.StationCalendar.capabilities().provider_counteroffer_negotiation_states,
      operator_review_row_contract_callbacks()
    )
  end

  defp operator_review_row_contract_callbacks do
    [
      require_fields: &require_fields/4,
      validate_stable_ids: &validate_stable_ids/4,
      expect_number: &expect_number/4,
      expect_one_of: &expect_one_of/5,
      expect_type: &expect_type/5,
      expect_optional_type: &expect_optional_type/5,
      expect_optional_one_of: &expect_optional_one_of/5,
      validate_string_list_items: &validate_string_list_items/4,
      expect_optional_non_negative_integer: &expect_optional_non_negative_integer/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_optional_number: &expect_optional_number/4,
      expect_field_at_least: &expect_field_at_least/5,
      validate_number_list_items: &validate_number_list_items/4,
      validate_optional_activity_context: &validate_optional_activity_context/4,
      validate_optional_protection_decision: &validate_optional_protection_decision/4,
      validate_scoped_downlink_context_fields: &validate_scoped_downlink_context_fields/3,
      validate_observation_quality_handoff_fields: &validate_observation_quality_handoff_fields/3,
      validate_feedback_maneuver_handoff_fields: &validate_feedback_maneuver_handoff_fields/3,
      validate_link_handoff_fields: &validate_link_handoff_fields/3,
      validate_completion_fraction_fields: &validate_completion_fraction_fields/3,
      validate_eclipse_lighting_handoff_fields: &validate_eclipse_lighting_handoff_fields/3,
      validate_thermal_handoff_fields: &validate_thermal_handoff_fields/3,
      expect_optional_probability: &expect_optional_probability/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      validate_semantic_change_details: &validate_semantic_change_details/3,
      validate_candidate_diff_changed_fields: &validate_candidate_diff_changed_fields/3,
      validate_optional_source_window: &validate_optional_source_window/4,
      validate_nested_id_match: &validate_nested_id_match/7,
      validate_optional_source_window_lineage: &validate_optional_source_window_lineage/4,
      validate_contact_allocation_capacity_pack_group:
        &validate_contact_allocation_capacity_pack_group/3,
      validate_contact_allocation_capacity_pack_handoff_matches_source:
        &validate_contact_allocation_capacity_pack_handoff_matches_source/3,
      validate_station_capacity_fraction_fields: &validate_station_capacity_fraction_fields/3,
      validate_resource_availability_variance_fields:
        &validate_resource_availability_variance_fields/3,
      expect_optional_number_or_number_list: &expect_optional_number_or_number_list/4,
      validate_optional_actual_data_rate_throughput_derivation:
        &validate_optional_actual_data_rate_throughput_derivation/4,
      validate_optional_lifecycle_transition: &validate_optional_lifecycle_transition/4,
      validate_stable_id_array_map: &validate_stable_id_array_map/3,
      validate_non_negative_number_map: &validate_non_negative_number_map/3,
      validate_optional_rows: &validate_optional_rows/4,
      validate_contact_contention_deferred_priority:
        &validate_contact_contention_deferred_priority/3,
      validate_priority_field_evidence_counts: &validate_priority_field_evidence_counts/3,
      validate_optional_branch_comparison_source_row:
        &validate_optional_branch_comparison_source_row/3,
      validate_optional_policy_decision_evidence: &validate_optional_policy_decision_evidence/3,
      validate_optional_policy_escalation: &validate_optional_policy_escalation/4,
      validate_optional_timeline_dependency_impact_source_row:
        &validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_timeline_publication_summary_source:
        &validate_optional_timeline_publication_summary_source/3,
      validate_timeline_publication_handoff_matches_source:
        &validate_timeline_publication_handoff_matches_source/3,
      validate_source_evidence_fields: &validate_source_evidence_fields/3,
      validate_source_operational_readiness_report_handoff_matches:
        &validate_source_operational_readiness_report_handoff_matches/3,
      validate_source_quality_gate_report_handoff_matches:
        &validate_source_quality_gate_report_handoff_matches/3,
      validate_freshness_source_status_matches: &validate_freshness_source_status_matches/3,
      validate_refresh_budget_handoff_matches_source:
        &validate_refresh_budget_handoff_matches_source/3,
      validate_schema_validation_source_status_matches:
        &validate_schema_validation_source_status_matches/3,
      validate_execution_source_status_matches: &validate_execution_source_status_matches/3,
      validate_selected_timeline_integrity_fields: &validate_selected_timeline_integrity_fields/3,
      validate_optional_timeline_diff_summary_source:
        &validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_activity_state_source:
        &validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &validate_optional_timeline_preservation_source_row/3,
      validate_branch_event_summary_fields: &validate_branch_event_summary_fields/3,
      validate_optional_timeline_identity: &validate_optional_timeline_identity/4,
      validate_optional_timeline_link: &validate_optional_timeline_link/4,
      validate_optional_timeline_protection_summary:
        &validate_optional_timeline_protection_summary/4,
      validate_operational_readiness_resource_context:
        &validate_operational_readiness_resource_context/3,
      validate_source_operational_readiness_gate_handoff_matches:
        &validate_source_operational_readiness_gate_handoff_matches/3,
      validate_source_quality_gate_row_handoff_matches:
        &validate_source_quality_gate_row_handoff_matches/3,
      validate_resource_projection_battery_handoff_fields:
        &validate_resource_projection_battery_handoff_fields/3,
      validate_resource_projection_battery_handoff_matches_source:
        &validate_resource_projection_battery_handoff_matches_source/3,
      validate_resource_projection_count_handoff_matches_source:
        &validate_resource_projection_count_handoff_matches_source/3,
      validate_resource_projection_flow_summary_context_matches_source:
        &validate_resource_projection_flow_summary_context_matches_source/3,
      validate_link_capacity_handoff_count_lists: &validate_link_capacity_handoff_count_lists/3,
      validate_link_capacity_handoff_matches_source:
        &validate_link_capacity_handoff_matches_source/3,
      validate_contact_allocation_handoff_fields: &validate_contact_allocation_handoff_fields/3,
      validate_contact_allocation_handoff_matches_source:
        &validate_contact_allocation_handoff_matches_source/3,
      validate_command_window_handoff_matches_source:
        &validate_command_window_handoff_matches_source/3,
      validate_maneuver_review_handoff_matches_source:
        &validate_maneuver_review_handoff_matches_source/3,
      validate_timeline_diff_handoff_matches_source:
        &validate_timeline_diff_handoff_matches_source/3,
      validate_timeline_transition_application_handoff_matches_source:
        &validate_timeline_transition_application_handoff_matches_source/3,
      validate_candidate_rejection_handoff_matches_source:
        &validate_candidate_rejection_handoff_matches_source/3,
      validate_candidate_diff_handoff_matches_source:
        &validate_candidate_diff_handoff_matches_source/3,
      validate_constraint_handoff_matches_source: &validate_constraint_handoff_matches_source/3,
      validate_objective_satisfaction_handoff_matches_source:
        &validate_objective_satisfaction_handoff_matches_source/3,
      validate_score_term_handoff_matches_source: &validate_score_term_handoff_matches_source/3,
      validate_objective_tradeoff_handoff_matches_source:
        &validate_objective_tradeoff_handoff_matches_source/3,
      validate_approval_requirement_handoff_matches_source:
        &validate_approval_requirement_handoff_matches_source/3,
      validate_plan_delta_handoff_matches_source: &validate_plan_delta_handoff_matches_source/3,
      validate_risk_explanation_handoff_matches_source:
        &validate_risk_explanation_handoff_matches_source/3,
      validate_operational_timeline_handoff_matches_source:
        &validate_operational_timeline_handoff_matches_source/3,
      validate_strategy_recommendation_handoff_matches_source:
        &validate_strategy_recommendation_handoff_matches_source/3,
      validate_strategy_tradeoff_handoff_matches_source:
        &validate_strategy_tradeoff_handoff_matches_source/3,
      validate_ranking_comparison_handoff_matches_source:
        &validate_ranking_comparison_handoff_matches_source/3,
      validate_pareto_frontier_handoff_matches_source:
        &validate_pareto_frontier_handoff_matches_source/3,
      validate_realized_feedback_handoff_matches_source:
        &validate_realized_feedback_handoff_matches_source/3,
      validate_provider_counteroffer_handoff_matches_source:
        &validate_provider_counteroffer_handoff_matches_source/3,
      validate_contact_intent_handoff_matches_source:
        &validate_contact_intent_handoff_matches_source/3,
      validate_station_calendar_handoff_matches_source:
        &validate_station_calendar_handoff_matches_source/3,
      validate_provider_calendar_contention_handoff_matches_source:
        &validate_provider_calendar_contention_handoff_matches_source/3,
      validate_station_calendar_handoff_count_lists:
        &validate_station_calendar_handoff_count_lists/3,
      validate_suppression_duplicate_handoff_row_fields:
        &validate_suppression_duplicate_handoff_row_fields/3,
      validate_suppression_handoff_matches_source: &validate_suppression_handoff_matches_source/3,
      validate_contact_contention_handoff_matches_source:
        &validate_contact_contention_handoff_matches_source/3,
      validate_operator_review_row_links: &validate_operator_review_row_links/3
    ]
  end

  defp policy_action_rule_field_groups do
    [
      string_fields: @policy_context_string_fields,
      string_array_fields: @policy_context_string_array_fields,
      string_or_array_fields: @policy_context_string_or_array_fields,
      number_fields: @policy_action_rule_number_fields,
      integer_fields: @policy_action_rule_integer_fields,
      boolean_fields: @policy_context_boolean_fields
    ]
  end

  defp validate_environment_model_capability(issues, path, record) do
    OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_model(
      issues,
      path,
      record
    )
  end

  defp validate_environment_provider_capability(issues, path, record) do
    OrbitalDynamics.Schema.ModelCapabilityContracts.validate_environment_provider(
      issues,
      path,
      record
    )
  end

  defp validate_subsystem_model_capability(issues, path, record) do
    OrbitalDynamics.Schema.ModelCapabilityContracts.validate_subsystem_model(
      issues,
      path,
      record
    )
  end

  defp numeric_delta(left, right) do
    OrbitalDynamics.Schema.CollectionAggregation.numeric_delta(left, right)
  end

  defp validate_validation_issue(issues, path, issue) do
    OrbitalDynamics.Schema.ValidationDiagnosticContracts.validate_issue(
      issues,
      path,
      issue
    )
  end

  defp validate_validation_remediation(issues, path, remediation) do
    OrbitalDynamics.Schema.ValidationDiagnosticContracts.validate_remediation(
      issues,
      path,
      remediation
    )
  end

  defp validate_validation_record(issues, path, record) do
    OrbitalDynamics.Schema.ValidationRecordContracts.validate(
      issues,
      path,
      record
    )
  end

  defp validate_embedded_validation_record(issues, path, record) do
    OrbitalDynamics.Schema.ValidationRecordContracts.validate_embedded(
      issues,
      path,
      record
    )
  end

  defp validate_model_acceptance_report(issues, path, report) do
    OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.validate_model_acceptance_report(
      issues,
      path,
      report,
      model_acceptance_report_model_limits(),
      validation_acceptance_report_contract_callbacks()
    )
  end

  defp validate_validation_safety_case_summary(issues, path, report) do
    OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.validate_validation_safety_case_summary(
      issues,
      path,
      report,
      model_acceptance_report_model_limits(),
      validation_acceptance_report_contract_callbacks()
    )
  end

  defp safety_case_count_fields,
    do: OrbitalDynamics.Schema.ValidationAcceptanceReportContracts.safety_case_count_fields()

  defp validate_optional_schema_contract(issues, path, row, expected) do
    OrbitalDynamics.Schema.SchemaContractField.validate_optional(
      issues,
      path,
      row,
      expected
    )
  end

  defp validate_validation_reference_report(issues, path, report) do
    OrbitalDynamics.Schema.ValidationReferenceContracts.validate_report(
      issues,
      path,
      report
    )
  end

  defp validate_validation_check(issues, path, check) do
    OrbitalDynamics.Schema.ValidationReferenceContracts.validate_check(
      issues,
      path,
      check
    )
  end

  defp validate_optional_timeline_preconditions(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.TimelinePreconditionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_activity_context(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.ActivityContextContracts.validate_optional(
      issues,
      path,
      map,
      field,
      activity_context_contract_callbacks()
    )
  end

  defp activity_context_contract_callbacks do
    [
      validate_stable_ids: &validate_stable_ids/4,
      validate_optional_stable_id_list: &validate_optional_stable_id_list/4,
      expect_optional_probability: &expect_optional_probability/4,
      expect_optional_integer: &expect_optional_integer/4,
      expect_field_at_least: &expect_field_at_least/5,
      expect_optional_type: &expect_optional_type/5,
      validate_string_list_items: &validate_string_list_items/4,
      expect_optional_number: &expect_optional_number/4,
      expect_optional_non_negative_number: &expect_optional_non_negative_number/4,
      validate_numeric_map: &validate_numeric_map/3,
      validate_optional_actual_data_rate_throughput_derivation:
        &validate_optional_actual_data_rate_throughput_derivation/4,
      validate_optional_execution_uncertainty: &validate_optional_execution_uncertainty/4,
      validate_candidate_refresh_scoped_context_fields:
        &validate_candidate_refresh_scoped_context_fields/3,
      expect_optional_number_or_string: &expect_optional_number_or_string/4,
      validate_candidate_diff_changed_fields: &validate_candidate_diff_changed_fields/3,
      validate_number_list_items: &validate_number_list_items/4,
      validate_timeline_integrity_evidence: &validate_timeline_integrity_evidence/3
    ]
  end

  defp validate_optional_actual_data_rate_throughput_derivation(issues, path, map, field)
       when is_map(map) do
    OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_actual_data_rate_throughput_derivations(issues, path, map, field)
       when is_map(map) do
    OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivations(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_execution_uncertainty(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_execution_uncertainty(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_protection_decision(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.ProtectionDecisionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_lifecycle_state_protection_consistency(issues, path, state, prefix)
       when is_map(state) do
    OrbitalDynamics.Schema.ProtectionDecisionContracts.validate_lifecycle_state_consistency(
      issues,
      path,
      state,
      prefix
    )
  end

  defp validate_optional_lifecycle_transition(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.LifecycleTransitionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_timeline_identity(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_optional_identity(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_timeline_identity(issues, path, identity) when is_map(identity) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_identity(
      issues,
      path,
      identity
    )
  end

  defp validate_timeline_identity(issues, _path, _identity), do: issues

  defp validate_optional_timeline_link(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_optional_link(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_timeline_protection_summary(issues, path, map, field) when is_map(map) do
    OrbitalDynamics.Schema.TimelineProtectionSummaryContracts.validate_optional_summary(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_priority_override_map(issues, path, overrides) when is_map(overrides) do
    OrbitalDynamics.Schema.PriorityOverrideContracts.validate_map(
      issues,
      path,
      overrides
    )
  end

  defp validate_priority_override_map(issues, _path, _overrides), do: issues

  defp validate_override_count_matches_ids(issues, path, map, count_field, ids_field)
       when is_map(map) do
    OrbitalDynamics.Schema.PriorityOverrideContracts.validate_count_matches_ids(
      issues,
      path,
      map,
      count_field,
      ids_field
    )
  end

  defp validate_priority_override_ids_match_map(issues, path, policy) when is_map(policy) do
    OrbitalDynamics.Schema.PriorityOverrideContracts.validate_ids_match_map(
      issues,
      path,
      policy
    )
  end
end
