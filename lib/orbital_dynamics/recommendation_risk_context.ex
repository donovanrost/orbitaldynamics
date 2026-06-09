defmodule OrbitalDynamics.RecommendationRiskContext do
  @moduledoc false

  @validation_refresh_context_keys [
    "model_acceptance_report_ids",
    "model_acceptance_intended_uses",
    "model_acceptance_statuses",
    "model_acceptance_model_ids",
    "model_acceptance_model_statuses",
    "model_acceptance_validation_levels",
    "model_acceptance_model_reasons",
    "model_acceptance_status_count_maps",
    "model_acceptance_validation_level_count_maps",
    "model_acceptance_model_ids_by_status",
    "model_acceptance_model_ids_by_validation_level",
    "model_acceptance_model_ids_by_intended_use",
    "model_acceptance_required_operator_actions",
    "model_acceptance_feedback_sources",
    "model_acceptance_feedback_scopes",
    "model_acceptance_feedback_keys",
    "model_acceptance_trust_boundaries",
    "schema_validation_statuses",
    "schema_validation_modes",
    "schema_validation_validated_contracts",
    "schema_validation_artifact_families",
    "schema_validation_artifact_paths",
    "schema_validation_issue_severities",
    "schema_validation_issue_paths",
    "schema_validation_error_count_values",
    "schema_validation_warning_count_values",
    "schema_validation_remediation_count_values",
    "schema_validation_remediation_categories",
    "schema_validation_remediation_actions",
    "schema_validation_required_operator_actions",
    "schema_validation_feedback_sources",
    "schema_validation_feedback_scopes",
    "schema_validation_feedback_keys",
    "schema_validation_trust_boundaries",
    "validation_safety_case_report_ids",
    "validation_safety_case_statuses",
    "validation_safety_case_evidence_statuses",
    "validation_safety_case_input_contracts",
    "validation_safety_case_evidence_refs",
    "validation_safety_case_evidence_count_values",
    "validation_safety_case_accepted_evidence_count_values",
    "validation_safety_case_review_required_evidence_count_values",
    "validation_safety_case_blocked_evidence_count_values",
    "validation_safety_case_model_blocked_count_values",
    "validation_safety_case_quality_gate_review_count_values",
    "validation_safety_case_quality_gate_blocked_count_values",
    "validation_safety_case_schema_error_count_values",
    "validation_safety_case_schema_warning_count_values",
    "validation_safety_case_evidence_status_count_maps",
    "validation_safety_case_evidence_refs_by_status",
    "validation_safety_case_evidence_refs_by_contract",
    "validation_safety_case_required_operator_actions",
    "validation_safety_case_feedback_sources",
    "validation_safety_case_feedback_scopes",
    "validation_safety_case_feedback_keys",
    "validation_safety_case_trust_boundaries",
    "refresh_budget_statuses",
    "refresh_budget_candidate_limit_statuses",
    "refresh_budget_input_candidate_count_values",
    "refresh_budget_kept_candidate_count_values",
    "refresh_budget_dropped_candidate_count_values",
    "refresh_budget_invalid_limit_count_values",
    "refresh_budget_current_max_candidate_activity_values",
    "refresh_budget_relaxed_max_candidate_activity_values",
    "refresh_budget_required_operator_actions",
    "refresh_budget_feedback_sources",
    "refresh_budget_feedback_scopes",
    "refresh_budget_feedback_keys",
    "refresh_budget_trust_boundaries",
    "refresh_freshness_statuses",
    "refresh_freshness_state_quality_statuses",
    "refresh_freshness_accepted_snapshot_age_values_s",
    "refresh_freshness_horizon_start_offset_values_s",
    "refresh_freshness_max_snapshot_age_values_s",
    "refresh_freshness_max_horizon_start_offset_values_s",
    "refresh_freshness_stale_reason_ids",
    "refresh_freshness_unknown_reason_ids",
    "refresh_freshness_required_operator_actions",
    "refresh_freshness_feedback_sources",
    "refresh_freshness_feedback_scopes",
    "refresh_freshness_feedback_keys",
    "refresh_freshness_trust_boundaries"
  ]

  @approval_boundary_context_keys [
    "approval_boundary_ids",
    "approval_boundary_statuses",
    "approval_boundary_reasons",
    "automation_boundaries",
    "execution_boundaries",
    "approval_boundary_import_classifications",
    "approval_boundary_required_operator_actions",
    "approval_boundary_required_authorities",
    "approval_boundary_policy_bundle_ids",
    "approval_boundary_rule_ids",
    "approval_boundary_feedback_sources",
    "approval_boundary_feedback_scopes",
    "approval_boundary_feedback_keys",
    "approval_boundary_trust_boundaries"
  ]

  @provider_reservation_request_context_keys [
    "provider_reservation_request_contact_ids",
    "provider_reservation_request_source_activity_ids",
    "provider_reservation_request_ground_station_ids",
    "provider_reservation_request_directions",
    "provider_reservation_request_station_reservation_ids",
    "provider_reservation_request_station_reserved_by",
    "provider_reservation_request_station_reservation_statuses",
    "provider_reservation_request_station_reservation_match_statuses",
    "provider_reservation_request_statuses",
    "provider_reservation_request_row_scopes",
    "provider_reservation_request_required_operator_actions",
    "provider_reservation_request_assumption_maps",
    "provider_reservation_request_feedback_sources",
    "provider_reservation_request_feedback_scopes",
    "provider_reservation_request_trust_boundaries"
  ]

  @capacity_pack_context_keys [
    "capacity_pack_risk_contact_ids",
    "capacity_pack_risk_source_activity_ids",
    "capacity_pack_risk_ground_station_ids",
    "capacity_pack_risk_group_ids",
    "capacity_pack_risk_statuses",
    "capacity_pack_risk_capacity_fraction_values",
    "capacity_pack_risk_used_fraction_values",
    "capacity_pack_risk_unused_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_sources",
    "capacity_pack_risk_derivation_reasons",
    "capacity_pack_risk_feedback_sources",
    "capacity_pack_risk_feedback_scopes",
    "capacity_pack_risk_trust_boundaries"
  ]

  @station_reservation_conflict_context_keys [
    "station_reservation_conflict_contact_ids",
    "station_reservation_conflict_source_activity_ids",
    "station_reservation_conflict_ground_station_ids",
    "station_reservation_conflict_reservation_ids",
    "station_reservation_conflict_reserved_by",
    "station_reservation_conflict_statuses",
    "station_reservation_conflict_match_statuses",
    "station_reservation_conflict_expires_at_values_s",
    "station_reservation_conflict_derivation_reasons",
    "station_reservation_conflict_feedback_sources",
    "station_reservation_conflict_feedback_scopes",
    "station_reservation_conflict_trust_boundaries"
  ]

  @station_reservation_hold_import_readiness_context_keys [
    "station_reservation_hold_import_statuses",
    "station_reservation_hold_import_readiness_summary_models",
    "station_reservation_hold_import_readiness_sources",
    "station_reservation_hold_import_readiness_source_artifact_types",
    "station_reservation_hold_import_readiness_statuses",
    "station_reservation_hold_import_classifications",
    "station_reservation_hold_count_values",
    "station_reservation_hold_ids",
    "station_reservation_hold_ids_by_import_status",
    "station_reservation_hold_ids_by_required_import_action",
    "station_reservation_hold_ids_by_direction",
    "station_reservation_hold_ids_by_direction_and_ground_station_id",
    "station_reservation_hold_contact_ids",
    "station_reservation_hold_contact_ids_by_import_status",
    "station_reservation_hold_contact_ids_by_expiration_status",
    "station_reservation_hold_contact_ids_by_direction",
    "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
    "station_reservation_hold_import_status_count_maps",
    "station_reservation_hold_required_import_action_count_maps",
    "station_reservation_hold_import_execution_boundaries",
    "station_reservation_hold_provider_write_values",
    "station_reservation_hold_cadence_write_values",
    "station_reservation_hold_reservation_acceptance_values",
    "station_reservation_hold_feedback_sources",
    "station_reservation_hold_feedback_scopes",
    "station_reservation_hold_trust_boundaries",
    "source_station_reservation_hold_import_readiness_summaries"
  ]

  @timeline_activity_precondition_context_keys [
    "timeline_activity_precondition_activity_ids",
    "timeline_activity_precondition_timeline_ids",
    "timeline_activity_precondition_activity_types",
    "timeline_activity_precondition_statuses",
    "timeline_activity_precondition_blocked_count_values",
    "timeline_activity_precondition_review_count_values",
    "timeline_activity_precondition_blocked_types",
    "timeline_activity_precondition_review_types",
    "timeline_activity_precondition_dependency_activity_ids",
    "timeline_activity_precondition_dependency_timeline_ids",
    "timeline_activity_precondition_exclusive_with_activity_ids",
    "timeline_activity_precondition_exclusive_with_timeline_ids",
    "timeline_activity_precondition_duplicate_dependency_activity_ids",
    "timeline_activity_precondition_duplicate_dependency_timeline_ids",
    "timeline_activity_precondition_duplicate_exclusivity_activity_ids",
    "timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
    "timeline_activity_precondition_allow_overlap_values",
    "timeline_activity_precondition_invalid_activity_input_values",
    "timeline_activity_precondition_invalid_activity_input_reasons",
    "timeline_activity_precondition_required_operator_actions",
    "timeline_activity_precondition_requires_operator_review_values",
    "timeline_activity_precondition_feedback_sources",
    "timeline_activity_precondition_feedback_scopes",
    "timeline_activity_precondition_feedback_keys",
    "timeline_activity_precondition_trust_boundaries",
    "timeline_activity_precondition_derivation_reasons",
    "timeline_activity_precondition_assumption_maps"
  ]

  @timeline_preservation_context_keys [
    "timeline_preservation_activity_ids",
    "timeline_preservation_timeline_ids",
    "timeline_preservation_statuses",
    "timeline_preservation_requires_preservation_values",
    "timeline_preservation_requires_operator_review_values",
    "timeline_preservation_protection_decisions",
    "timeline_preservation_protection_categories",
    "timeline_preservation_protection_reasons",
    "timeline_preservation_preserve_activity_count_values",
    "timeline_preservation_review_change_activity_count_values",
    "timeline_preservation_sensitive_activity_count_values",
    "timeline_preservation_preserve_activity_ids",
    "timeline_preservation_preserve_timeline_ids",
    "timeline_preservation_review_change_activity_ids",
    "timeline_preservation_review_change_timeline_ids",
    "timeline_preservation_sensitive_activity_ids",
    "timeline_preservation_sensitive_timeline_ids",
    "timeline_preservation_invalid_activity_input_values",
    "timeline_preservation_invalid_activity_input_reasons",
    "timeline_preservation_required_operator_actions",
    "timeline_preservation_feedback_sources",
    "timeline_preservation_feedback_scopes",
    "timeline_preservation_feedback_keys",
    "timeline_preservation_trust_boundaries",
    "timeline_preservation_derivation_reasons",
    "timeline_preservation_assumption_maps"
  ]

  @timeline_publication_context_keys [
    "timeline_publication_ids",
    "timeline_publication_sequences",
    "timeline_publication_statuses",
    "timeline_publication_downstream_invalidation_statuses",
    "timeline_publication_dependency_impact_statuses",
    "timeline_publication_source_artifact_ids",
    "timeline_publication_source_artifact_types",
    "timeline_publication_authorities",
    "timeline_publication_supersedes_artifact_ids",
    "timeline_publication_downstream_product_ids",
    "timeline_publication_invalidated_downstream_product_ids",
    "timeline_publication_downstream_invalidation_reason_count_maps",
    "timeline_publication_downstream_invalidation_reasons",
    "timeline_publication_invalidated_downstream_product_ids_by_reason",
    "timeline_publication_dependency_impact_row_count_values",
    "timeline_publication_timeline_diff_row_count_values",
    "timeline_publication_timeline_diff_changed_count_values",
    "timeline_publication_timeline_diff_review_required_count_values",
    "timeline_publication_changed_field_count_maps",
    "timeline_publication_changed_fields",
    "timeline_publication_changed_timeline_ids",
    "timeline_publication_review_timeline_ids",
    "timeline_publication_timeline_ids_by_changed_field",
    "timeline_publication_feedback_sources",
    "timeline_publication_feedback_scopes",
    "timeline_publication_feedback_keys",
    "timeline_publication_trust_boundaries",
    "timeline_publication_derivation_reasons",
    "timeline_publication_assumption_maps"
  ]

  @timeline_lifecycle_state_context_keys [
    "timeline_lifecycle_state_statuses",
    "timeline_lifecycle_state_planned_activity_count_values",
    "timeline_lifecycle_state_realized_activity_count_values",
    "timeline_lifecycle_state_row_count_values",
    "timeline_lifecycle_state_recordable_count_values",
    "timeline_lifecycle_state_preserved_count_values",
    "timeline_lifecycle_state_review_required_count_values",
    "timeline_lifecycle_state_duplicate_identity_count_values",
    "timeline_lifecycle_state_invalid_activity_input_count_values",
    "timeline_lifecycle_state_transition_decision_count_maps",
    "timeline_lifecycle_state_required_operator_action_count_maps",
    "timeline_lifecycle_state_operator_action_reason_count_maps",
    "timeline_lifecycle_state_import_action_count_maps",
    "timeline_lifecycle_state_planned_status_category_count_maps",
    "timeline_lifecycle_state_realized_status_category_count_maps",
    "timeline_lifecycle_state_status_transition_category_count_maps",
    "timeline_lifecycle_state_approval_transition_category_count_maps",
    "timeline_lifecycle_state_recordable_timeline_ids",
    "timeline_lifecycle_state_preserved_timeline_ids",
    "timeline_lifecycle_state_review_timeline_ids",
    "timeline_lifecycle_state_review_activity_ids",
    "timeline_lifecycle_state_invalid_activity_input_ids",
    "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
    "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason",
    "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category",
    "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category",
    "timeline_lifecycle_state_required_operator_actions",
    "timeline_lifecycle_state_requires_operator_review_values",
    "timeline_lifecycle_state_feedback_sources",
    "timeline_lifecycle_state_feedback_scopes",
    "timeline_lifecycle_state_feedback_keys",
    "timeline_lifecycle_state_trust_boundaries",
    "timeline_lifecycle_state_derivation_reasons",
    "timeline_lifecycle_state_assumption_maps"
  ]

  @timeline_activity_lifecycle_state_context_keys [
    "timeline_activity_lifecycle_state_activity_ids",
    "timeline_activity_lifecycle_state_timeline_ids",
    "timeline_activity_lifecycle_state_planned_activity_ids",
    "timeline_activity_lifecycle_state_realized_activity_ids",
    "timeline_activity_lifecycle_state_planned_timeline_ids",
    "timeline_activity_lifecycle_state_realized_timeline_ids",
    "timeline_activity_lifecycle_state_transition_decisions",
    "timeline_activity_lifecycle_state_status_transition_decisions",
    "timeline_activity_lifecycle_state_approval_transition_decisions",
    "timeline_activity_lifecycle_state_review_required_values",
    "timeline_activity_lifecycle_state_requires_operator_review_values",
    "timeline_activity_lifecycle_state_required_operator_actions",
    "timeline_activity_lifecycle_state_operator_action_reasons",
    "timeline_activity_lifecycle_state_import_actions",
    "timeline_activity_lifecycle_state_invalid_activity_input_values",
    "timeline_activity_lifecycle_state_invalid_activity_input_count_values",
    "timeline_activity_lifecycle_state_invalid_activity_input_reasons",
    "timeline_activity_lifecycle_state_planned_statuses",
    "timeline_activity_lifecycle_state_realized_statuses",
    "timeline_activity_lifecycle_state_planned_status_categories",
    "timeline_activity_lifecycle_state_realized_status_categories",
    "timeline_activity_lifecycle_state_planned_approval_statuses",
    "timeline_activity_lifecycle_state_realized_approval_statuses",
    "timeline_activity_lifecycle_state_planned_approval_categories",
    "timeline_activity_lifecycle_state_realized_approval_categories",
    "timeline_activity_lifecycle_state_planned_locked_values",
    "timeline_activity_lifecycle_state_realized_locked_values",
    "timeline_activity_lifecycle_state_planned_executed_values",
    "timeline_activity_lifecycle_state_realized_executed_values",
    "timeline_activity_lifecycle_state_status_transitions",
    "timeline_activity_lifecycle_state_approval_transitions",
    "timeline_activity_lifecycle_state_planned_protection_decisions",
    "timeline_activity_lifecycle_state_realized_protection_decisions",
    "timeline_activity_lifecycle_state_feedback_sources",
    "timeline_activity_lifecycle_state_feedback_scopes",
    "timeline_activity_lifecycle_state_feedback_keys",
    "timeline_activity_lifecycle_state_trust_boundaries",
    "timeline_activity_lifecycle_state_derivation_reasons",
    "timeline_activity_lifecycle_state_assumption_maps"
  ]

  @timeline_dependency_impact_context_keys [
    "timeline_dependency_impact_activity_ids",
    "timeline_dependency_impact_timeline_ids",
    "timeline_dependency_impact_scopes",
    "timeline_dependency_impact_statuses",
    "timeline_dependency_impact_required_operator_actions",
    "timeline_dependency_impact_operator_action_reasons",
    "timeline_dependency_impact_dependency_activity_ids",
    "timeline_dependency_impact_dependency_timeline_ids",
    "timeline_dependency_impact_exclusive_with_activity_ids",
    "timeline_dependency_impact_exclusive_with_timeline_ids",
    "timeline_dependency_impact_impacted_dependency_activity_ids",
    "timeline_dependency_impact_impacted_dependency_timeline_ids",
    "timeline_dependency_impact_impacted_exclusive_with_activity_ids",
    "timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
    "timeline_dependency_impact_feedback_sources",
    "timeline_dependency_impact_feedback_scopes",
    "timeline_dependency_impact_feedback_keys",
    "timeline_dependency_impact_trust_boundaries",
    "timeline_dependency_impact_derivation_reasons"
  ]

  @relay_data_path_context_keys [
    "relay_data_path_risk_types",
    "relay_data_path_ground_station_ids",
    "relay_data_path_route_ids",
    "relay_data_path_source_spacecraft_ids",
    "relay_data_path_relay_spacecraft_ids",
    "relay_data_path_relay_chain_spacecraft_ids",
    "relay_data_path_relay_hop_count_values",
    "relay_data_path_ground_downlink_contact_ids",
    "relay_data_path_custody_statuses",
    "relay_data_path_latency_values_s",
    "relay_data_path_latency_limit_values_s",
    "relay_data_path_latency_statuses",
    "relay_data_path_risk_statuses",
    "relay_data_path_risk_reasons",
    "relay_data_path_product_ids",
    "relay_data_path_collection_ids",
    "relay_data_path_route_count_values",
    "relay_data_path_relay_route_count_values",
    "relay_data_path_direct_downlink_route_count_values",
    "relay_data_path_custody_status_count_maps",
    "relay_data_path_latency_status_count_maps",
    "relay_data_path_risk_status_count_maps",
    "relay_data_path_route_ids_by_custody_status",
    "relay_data_path_route_ids_by_latency_status",
    "relay_data_path_route_ids_by_risk_status",
    "relay_data_path_route_ids_by_ground_station_id",
    "relay_data_path_feedback_sources",
    "relay_data_path_feedback_scopes",
    "relay_data_path_feedback_keys",
    "relay_data_path_trust_boundaries",
    "relay_data_path_derivation_reasons",
    "relay_data_path_assumption_maps"
  ]

  @link_capacity_context_keys [
    "link_capacity_pressure_risk_types",
    "link_capacity_pressure_ground_station_ids",
    "link_capacity_pressure_required_contact_values",
    "link_capacity_pressure_planned_contact_values",
    "link_capacity_pressure_required_downlink_values_mb",
    "link_capacity_pressure_planned_downlink_values_mb",
    "link_capacity_pressure_start_values_s",
    "link_capacity_pressure_end_values_s",
    "link_capacity_pressure_source_activity_ids",
    "link_capacity_pressure_source_window_ids",
    "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
    "link_capacity_pressure_selected_downlink_shortfall_values_mb",
    "link_capacity_pressure_actual_throughput_values_mb",
    "link_capacity_pressure_actual_downlink_completion_ratio_values",
    "link_capacity_pressure_actual_downlink_shortfall_values_mb",
    "link_capacity_pressure_downlink_requirement_statuses",
    "link_capacity_pressure_actual_downlink_requirement_statuses",
    "link_capacity_pressure_downlink_demand_sources",
    "link_capacity_pressure_downlink_completion_sources",
    "link_capacity_pressure_feedback_sources",
    "link_capacity_pressure_feedback_scopes",
    "link_capacity_pressure_trust_boundaries",
    "link_capacity_pressure_derivation_reasons"
  ]

  @contact_intent_context_keys [
    "contact_intent_pressure_risk_types",
    "contact_intent_pressure_contact_ids",
    "contact_intent_pressure_source_activity_ids",
    "contact_intent_pressure_ground_station_ids",
    "contact_intent_pressure_required_contact_values",
    "contact_intent_pressure_planned_contact_values",
    "contact_intent_pressure_required_downlink_values_mb",
    "contact_intent_pressure_planned_downlink_values_mb",
    "contact_intent_pressure_start_values_s",
    "contact_intent_pressure_end_values_s",
    "contact_intent_pressure_source_window_ids",
    "contact_intent_pressure_timeline_ids",
    "contact_intent_pressure_approval_statuses",
    "contact_intent_pressure_required_operator_actions",
    "contact_intent_pressure_cadence_import_statuses",
    "contact_intent_pressure_invalid_cadence_import_values",
    "contact_intent_pressure_invalid_cadence_import_reasons",
    "contact_intent_pressure_invalid_activity_input_values",
    "contact_intent_pressure_invalid_activity_input_reasons",
    "contact_intent_pressure_gate_statuses",
    "contact_intent_pressure_policy_classifications",
    "contact_intent_pressure_policy_bundle_ids",
    "contact_intent_pressure_station_availabilities",
    "contact_intent_pressure_station_contention_statuses",
    "contact_intent_pressure_station_calendar_entry_ids",
    "contact_intent_pressure_station_calendar_provider_ids",
    "contact_intent_pressure_station_calendar_provider_entry_ids",
    "contact_intent_pressure_station_calendar_directions",
    "contact_intent_pressure_station_calendar_statuses",
    "contact_intent_pressure_station_calendar_trust_boundary_statuses",
    "contact_intent_pressure_station_reservation_ids",
    "contact_intent_pressure_station_reserved_by",
    "contact_intent_pressure_station_reservation_statuses",
    "contact_intent_pressure_station_reservation_match_statuses",
    "contact_intent_pressure_feedback_sources",
    "contact_intent_pressure_feedback_scopes",
    "contact_intent_pressure_trust_boundaries",
    "contact_intent_pressure_derivation_reasons"
  ]

  @station_calendar_context_keys [
    "station_calendar_pressure_risk_types",
    "station_calendar_pressure_ground_station_ids",
    "station_calendar_pressure_start_values_s",
    "station_calendar_pressure_end_values_s",
    "station_calendar_pressure_capacity_fraction_values",
    "station_calendar_pressure_station_availabilities",
    "station_calendar_pressure_station_contention_statuses",
    "station_calendar_pressure_station_calendar_entry_ids",
    "station_calendar_pressure_station_calendar_provider_ids",
    "station_calendar_pressure_station_calendar_provider_entry_ids",
    "station_calendar_pressure_station_calendar_directions",
    "station_calendar_pressure_station_calendar_statuses",
    "station_calendar_pressure_station_calendar_overlap_count_values",
    "station_calendar_pressure_station_calendar_overlap_entry_ids",
    "station_calendar_pressure_station_calendar_overlap_availabilities",
    "station_calendar_pressure_station_calendar_entry_ambiguous_values",
    "station_calendar_pressure_station_calendar_ambiguous_entry_count_values",
    "station_calendar_pressure_station_calendar_ambiguous_entry_ids",
    "station_calendar_pressure_station_calendar_reservation_overlap_count_values",
    "station_calendar_pressure_station_calendar_reservation_ids",
    "station_calendar_pressure_station_calendar_reserved_by",
    "station_calendar_pressure_station_calendar_reservation_statuses",
    "station_calendar_pressure_station_calendar_trust_boundary_statuses",
    "station_calendar_pressure_station_reservation_ids",
    "station_calendar_pressure_station_reserved_by",
    "station_calendar_pressure_station_reservation_statuses",
    "station_calendar_pressure_station_reservation_match_statuses",
    "station_calendar_pressure_station_reservation_expires_at_values_s",
    "station_calendar_pressure_station_reservation_expiration_statuses",
    "station_calendar_pressure_provider_calendar_contention_group_ids",
    "station_calendar_pressure_provider_calendar_contention_statuses",
    "station_calendar_pressure_provider_calendar_contention_entry_ids",
    "station_calendar_pressure_provider_calendar_contention_provider_ids",
    "station_calendar_pressure_provider_calendar_contention_provider_entry_ids",
    "station_calendar_pressure_provider_calendar_contention_availabilities",
    "station_calendar_pressure_provider_calendar_contention_directions",
    "station_calendar_pressure_provider_calendar_contention_reservation_ids",
    "station_calendar_pressure_provider_calendar_contention_reserved_by",
    "station_calendar_pressure_provider_calendar_contention_reservation_statuses",
    "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses",
    "station_calendar_pressure_provider_calendar_contention_overlap_pairs",
    "station_calendar_pressure_required_operator_actions",
    "station_calendar_pressure_feedback_sources",
    "station_calendar_pressure_feedback_scopes",
    "station_calendar_pressure_trust_boundaries",
    "station_calendar_pressure_derivation_reasons"
  ]

  @resource_margin_context_keys [
    "resource_margin_risk_types",
    "resource_margin_spacecraft_ids",
    "resource_margin_scenario_ids",
    "resource_margin_timeline_ids",
    "resource_margin_source_activity_ids",
    "resource_margin_replacement_activity_ids",
    "resource_margin_fields",
    "resource_margin_values",
    "resource_margin_threshold_values",
    "resource_margin_field_value_maps",
    "resource_margin_source_quality_values",
    "resource_margin_start_values_s",
    "resource_margin_end_values_s",
    "resource_margin_diff_statuses",
    "resource_margin_changed_fields",
    "resource_margin_required_operator_actions",
    "resource_margin_requires_operator_review_values",
    "resource_margin_feedback_sources",
    "resource_margin_feedback_scopes",
    "resource_margin_feedback_keys",
    "resource_margin_trust_boundaries",
    "resource_margin_derivation_reasons"
  ]

  @maneuver_execution_uncertainty_context_keys [
    "maneuver_execution_uncertainty_risk_types",
    "maneuver_execution_uncertainty_activity_ids",
    "maneuver_execution_uncertainty_timeline_ids",
    "maneuver_execution_uncertainty_maneuver_ids",
    "maneuver_execution_uncertainty_scenario_ids",
    "maneuver_execution_uncertainty_source_activity_ids",
    "maneuver_execution_uncertainty_replacement_activity_ids",
    "maneuver_execution_uncertainty_statuses",
    "maneuver_execution_uncertainty_sources",
    "maneuver_execution_uncertainty_maps",
    "maneuver_execution_uncertainty_timing_3sigma_values_s",
    "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s",
    "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s",
    "maneuver_execution_uncertainty_start_values_s",
    "maneuver_execution_uncertainty_end_values_s",
    "maneuver_execution_uncertainty_changed_fields",
    "maneuver_execution_uncertainty_required_operator_actions",
    "maneuver_execution_uncertainty_requires_operator_review_values",
    "maneuver_execution_uncertainty_feedback_sources",
    "maneuver_execution_uncertainty_feedback_scopes",
    "maneuver_execution_uncertainty_feedback_keys",
    "maneuver_execution_uncertainty_trust_boundaries",
    "maneuver_execution_uncertainty_derivation_reasons"
  ]

  @timeline_integrity_context_keys [
    "timeline_integrity_risk_types",
    "timeline_integrity_activity_ids",
    "timeline_integrity_timeline_ids",
    "timeline_integrity_statuses",
    "timeline_integrity_issue_count_values",
    "timeline_integrity_issue_types",
    "timeline_integrity_issue_maps",
    "timeline_integrity_missing_dependency_activity_ids",
    "timeline_integrity_missing_dependency_timeline_ids",
    "timeline_integrity_dependency_cycle_activity_ids",
    "timeline_integrity_dependency_cycle_timeline_ids",
    "timeline_integrity_dependency_order_violation_activity_ids",
    "timeline_integrity_dependency_order_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_activity_ids",
    "timeline_integrity_exclusivity_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_groups",
    "timeline_integrity_required_operator_actions",
    "timeline_integrity_feedback_sources",
    "timeline_integrity_feedback_scopes",
    "timeline_integrity_feedback_keys",
    "timeline_integrity_trust_boundaries",
    "timeline_integrity_derivation_reasons"
  ]

  @execution_success_feedback_context_keys [
    "execution_success_feedback_risk_types",
    "execution_success_feedback_activity_ids",
    "execution_success_feedback_scenario_ids",
    "execution_success_feedback_timeline_ids",
    "execution_success_feedback_source_activity_ids",
    "execution_success_feedback_replacement_activity_ids",
    "execution_success_feedback_command_success_factor_values",
    "execution_success_feedback_maneuver_success_factor_values",
    "execution_success_feedback_command_results",
    "execution_success_feedback_maneuver_results",
    "execution_success_feedback_realized_statuses",
    "execution_success_feedback_ground_station_ids",
    "execution_success_feedback_planned_ground_station_ids",
    "execution_success_feedback_realized_ground_station_ids",
    "execution_success_feedback_ground_station_match_statuses",
    "execution_success_feedback_directions",
    "execution_success_feedback_planned_directions",
    "execution_success_feedback_realized_directions",
    "execution_success_feedback_direction_match_statuses",
    "execution_success_feedback_source_window_ids",
    "execution_success_feedback_planned_source_window_ids",
    "execution_success_feedback_realized_source_window_ids",
    "execution_success_feedback_source_window_match_statuses",
    "execution_success_feedback_command_identity_mismatch_fields",
    "execution_success_feedback_start_values_s",
    "execution_success_feedback_end_values_s",
    "execution_success_feedback_changed_fields",
    "execution_success_feedback_status_transition_maps",
    "execution_success_feedback_transition_types",
    "execution_success_feedback_transition_categories",
    "execution_success_feedback_transition_reasons",
    "execution_success_feedback_required_operator_actions",
    "execution_success_feedback_requires_operator_review_values",
    "execution_success_feedback_feedback_sources",
    "execution_success_feedback_feedback_scopes",
    "execution_success_feedback_feedback_keys",
    "execution_success_feedback_trust_boundaries",
    "execution_success_feedback_derivation_reasons"
  ]

  @operational_feedback_context_keys [
    "strategy_operational_feedback_risk_types",
    "strategy_operational_feedback_activity_ids",
    "strategy_operational_feedback_scenario_ids",
    "strategy_operational_feedback_timeline_ids",
    "strategy_operational_feedback_source_activity_ids",
    "strategy_operational_feedback_replacement_activity_ids",
    "strategy_operational_feedback_contact_success_factor_values",
    "strategy_operational_feedback_observation_success_factor_values",
    "strategy_operational_feedback_station_throughput_factor_values",
    "strategy_operational_feedback_contact_results",
    "strategy_operational_feedback_observation_results",
    "strategy_operational_feedback_realized_statuses",
    "strategy_operational_feedback_ground_station_ids",
    "strategy_operational_feedback_planned_ground_station_ids",
    "strategy_operational_feedback_realized_ground_station_ids",
    "strategy_operational_feedback_ground_station_match_statuses",
    "strategy_operational_feedback_directions",
    "strategy_operational_feedback_planned_directions",
    "strategy_operational_feedback_realized_directions",
    "strategy_operational_feedback_direction_match_statuses",
    "strategy_operational_feedback_source_window_ids",
    "strategy_operational_feedback_planned_source_window_ids",
    "strategy_operational_feedback_realized_source_window_ids",
    "strategy_operational_feedback_source_window_match_statuses",
    "strategy_operational_feedback_contact_identity_mismatch_fields",
    "strategy_operational_feedback_target_ids",
    "strategy_operational_feedback_planned_target_ids",
    "strategy_operational_feedback_realized_target_ids",
    "strategy_operational_feedback_target_match_statuses",
    "strategy_operational_feedback_collection_ids",
    "strategy_operational_feedback_planned_collection_ids",
    "strategy_operational_feedback_realized_collection_ids",
    "strategy_operational_feedback_collection_match_statuses",
    "strategy_operational_feedback_product_ids",
    "strategy_operational_feedback_planned_product_ids",
    "strategy_operational_feedback_realized_product_ids",
    "strategy_operational_feedback_product_match_statuses",
    "strategy_operational_feedback_payload_ids",
    "strategy_operational_feedback_planned_payload_ids",
    "strategy_operational_feedback_realized_payload_ids",
    "strategy_operational_feedback_payload_match_statuses",
    "strategy_operational_feedback_instrument_ids",
    "strategy_operational_feedback_planned_instrument_ids",
    "strategy_operational_feedback_realized_instrument_ids",
    "strategy_operational_feedback_instrument_match_statuses",
    "strategy_operational_feedback_observation_identity_mismatch_fields",
    "strategy_operational_feedback_pointing_statuses",
    "strategy_operational_feedback_pointing_error_values_deg",
    "strategy_operational_feedback_attitude_statuses",
    "strategy_operational_feedback_attitude_error_values_deg",
    "strategy_operational_feedback_lighting_condition_match_statuses",
    "strategy_operational_feedback_planned_lighting_conditions",
    "strategy_operational_feedback_realized_lighting_conditions",
    "strategy_operational_feedback_lighting_condition_details",
    "strategy_operational_feedback_lighting_confidence_values",
    "strategy_operational_feedback_eclipse_overlap_fraction_values",
    "strategy_operational_feedback_image_quality_score_values",
    "strategy_operational_feedback_image_quality_statuses",
    "strategy_operational_feedback_image_quality_sources",
    "strategy_operational_feedback_cloud_cover_fraction_values",
    "strategy_operational_feedback_blur_score_values",
    "strategy_operational_feedback_actual_throughput_values_mb",
    "strategy_operational_feedback_estimated_throughput_values_mb",
    "strategy_operational_feedback_start_values_s",
    "strategy_operational_feedback_end_values_s",
    "strategy_operational_feedback_changed_fields",
    "strategy_operational_feedback_status_transition_maps",
    "strategy_operational_feedback_transition_types",
    "strategy_operational_feedback_transition_categories",
    "strategy_operational_feedback_transition_reasons",
    "strategy_operational_feedback_required_operator_actions",
    "strategy_operational_feedback_requires_operator_review_values",
    "strategy_operational_feedback_feedback_sources",
    "strategy_operational_feedback_feedback_scopes",
    "strategy_operational_feedback_feedback_keys",
    "strategy_operational_feedback_trust_boundaries",
    "strategy_operational_feedback_derivation_reasons"
  ]

  def validation_refresh_context_keys, do: @validation_refresh_context_keys

  def approval_boundary_context_keys, do: @approval_boundary_context_keys

  def provider_reservation_request_context_keys, do: @provider_reservation_request_context_keys

  def capacity_pack_context_keys, do: @capacity_pack_context_keys

  def station_reservation_conflict_context_keys, do: @station_reservation_conflict_context_keys

  def station_reservation_hold_import_readiness_context_keys,
    do: @station_reservation_hold_import_readiness_context_keys

  def timeline_activity_precondition_context_keys,
    do: @timeline_activity_precondition_context_keys

  def timeline_preservation_context_keys, do: @timeline_preservation_context_keys

  def timeline_publication_context_keys, do: @timeline_publication_context_keys

  def timeline_lifecycle_state_context_keys, do: @timeline_lifecycle_state_context_keys

  def timeline_activity_lifecycle_state_context_keys,
    do: @timeline_activity_lifecycle_state_context_keys

  def timeline_dependency_impact_context_keys, do: @timeline_dependency_impact_context_keys

  def relay_data_path_context_keys, do: @relay_data_path_context_keys

  def link_capacity_context_keys, do: @link_capacity_context_keys

  def contact_intent_context_keys, do: @contact_intent_context_keys

  def station_calendar_context_keys, do: @station_calendar_context_keys

  def resource_margin_context_keys, do: @resource_margin_context_keys

  def maneuver_execution_uncertainty_context_keys,
    do: @maneuver_execution_uncertainty_context_keys

  def timeline_integrity_context_keys, do: @timeline_integrity_context_keys

  def execution_success_feedback_context_keys,
    do: @execution_success_feedback_context_keys

  def operational_feedback_context_keys,
    do: @operational_feedback_context_keys

  def validation_refresh_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    model_acceptance_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "model_acceptance" or
            Map.get(&1, "type") == "model_acceptance_pressure")
      )

    schema_validation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "schema_validation" or
            Map.get(&1, "type") == "schema_validation_pressure")
      )

    validation_safety_case_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "validation_safety_case" or
            Map.get(&1, "type") == "validation_safety_case_pressure")
      )

    refresh_budget_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "refresh_budget" or
            Map.get(&1, "type") == "refresh_budget_pressure")
      )

    refresh_freshness_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "refresh_freshness" or
            Map.get(&1, "type") == "refresh_freshness_pressure")
      )

    %{
      "model_acceptance_report_ids" => risk_context_values(model_acceptance_risks, "report_id"),
      "model_acceptance_intended_uses" =>
        risk_context_values(model_acceptance_risks, "intended_use"),
      "model_acceptance_statuses" =>
        risk_context_values(model_acceptance_risks, "model_acceptance_status"),
      "model_acceptance_model_ids" => risk_context_values(model_acceptance_risks, "model_id"),
      "model_acceptance_model_statuses" =>
        risk_context_values(model_acceptance_risks, "model_status"),
      "model_acceptance_validation_levels" =>
        risk_context_values(model_acceptance_risks, "validation_level"),
      "model_acceptance_model_reasons" =>
        risk_context_values(model_acceptance_risks, "model_reason"),
      "model_acceptance_status_count_maps" =>
        risk_context_values(model_acceptance_risks, "status_counts"),
      "model_acceptance_validation_level_count_maps" =>
        risk_context_values(model_acceptance_risks, "validation_level_counts"),
      "model_acceptance_model_ids_by_status" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_status"),
      "model_acceptance_model_ids_by_validation_level" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_validation_level"),
      "model_acceptance_model_ids_by_intended_use" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_intended_use"),
      "model_acceptance_required_operator_actions" =>
        risk_context_values(model_acceptance_risks, "required_operator_action"),
      "model_acceptance_feedback_sources" =>
        risk_context_values(model_acceptance_risks, "feedback_source"),
      "model_acceptance_feedback_scopes" =>
        risk_context_values(model_acceptance_risks, "feedback_scope"),
      "model_acceptance_feedback_keys" =>
        risk_context_values(model_acceptance_risks, "feedback_key"),
      "model_acceptance_trust_boundaries" =>
        risk_context_values(model_acceptance_risks, "trust_boundary"),
      "schema_validation_statuses" =>
        risk_context_values(schema_validation_risks, "validation_status"),
      "schema_validation_modes" =>
        risk_context_values(schema_validation_risks, "validation_mode"),
      "schema_validation_validated_contracts" =>
        risk_context_values(schema_validation_risks, "validated_contract"),
      "schema_validation_artifact_families" =>
        risk_context_values(schema_validation_risks, "validated_artifact_family"),
      "schema_validation_artifact_paths" =>
        risk_context_values(schema_validation_risks, "artifact_path"),
      "schema_validation_issue_severities" =>
        risk_context_values(schema_validation_risks, "issue_severity"),
      "schema_validation_issue_paths" =>
        risk_context_values(schema_validation_risks, "issue_path"),
      "schema_validation_error_count_values" =>
        risk_context_values(schema_validation_risks, "error_count"),
      "schema_validation_warning_count_values" =>
        risk_context_values(schema_validation_risks, "warning_count"),
      "schema_validation_remediation_count_values" =>
        risk_context_values(schema_validation_risks, "remediation_count"),
      "schema_validation_remediation_categories" =>
        risk_context_values(schema_validation_risks, "remediation_category"),
      "schema_validation_remediation_actions" =>
        risk_context_values(schema_validation_risks, "remediation_action"),
      "schema_validation_required_operator_actions" =>
        risk_context_values(schema_validation_risks, "required_operator_action"),
      "schema_validation_feedback_sources" =>
        risk_context_values(schema_validation_risks, "feedback_source"),
      "schema_validation_feedback_scopes" =>
        risk_context_values(schema_validation_risks, "feedback_scope"),
      "schema_validation_feedback_keys" =>
        risk_context_values(schema_validation_risks, "feedback_key"),
      "schema_validation_trust_boundaries" =>
        risk_context_values(schema_validation_risks, "trust_boundary"),
      "validation_safety_case_report_ids" =>
        risk_context_values(validation_safety_case_risks, "report_id"),
      "validation_safety_case_statuses" =>
        risk_context_values(validation_safety_case_risks, "validation_safety_case_status"),
      "validation_safety_case_evidence_statuses" =>
        risk_context_values(validation_safety_case_risks, "evidence_status"),
      "validation_safety_case_input_contracts" =>
        risk_context_values(validation_safety_case_risks, ["input_contract", "input_contracts"]),
      "validation_safety_case_evidence_refs" =>
        risk_context_values(validation_safety_case_risks, "evidence_ref"),
      "validation_safety_case_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "evidence_count"),
      "validation_safety_case_accepted_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "accepted_evidence_count"),
      "validation_safety_case_review_required_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "review_required_evidence_count"),
      "validation_safety_case_blocked_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "blocked_evidence_count"),
      "validation_safety_case_model_blocked_count_values" =>
        risk_context_values(validation_safety_case_risks, "model_blocked_count"),
      "validation_safety_case_quality_gate_review_count_values" =>
        risk_context_values(validation_safety_case_risks, "quality_gate_review_count"),
      "validation_safety_case_quality_gate_blocked_count_values" =>
        risk_context_values(validation_safety_case_risks, "quality_gate_blocked_count"),
      "validation_safety_case_schema_error_count_values" =>
        risk_context_values(validation_safety_case_risks, "schema_error_count"),
      "validation_safety_case_schema_warning_count_values" =>
        risk_context_values(validation_safety_case_risks, "schema_warning_count"),
      "validation_safety_case_evidence_status_count_maps" =>
        risk_context_values(validation_safety_case_risks, "evidence_status_counts"),
      "validation_safety_case_evidence_refs_by_status" =>
        risk_context_values(validation_safety_case_risks, "evidence_refs_by_status"),
      "validation_safety_case_evidence_refs_by_contract" =>
        risk_context_values(validation_safety_case_risks, "evidence_refs_by_contract"),
      "validation_safety_case_required_operator_actions" =>
        risk_context_values(validation_safety_case_risks, "required_operator_action"),
      "validation_safety_case_feedback_sources" =>
        risk_context_values(validation_safety_case_risks, "feedback_source"),
      "validation_safety_case_feedback_scopes" =>
        risk_context_values(validation_safety_case_risks, "feedback_scope"),
      "validation_safety_case_feedback_keys" =>
        risk_context_values(validation_safety_case_risks, "feedback_key"),
      "validation_safety_case_trust_boundaries" =>
        risk_context_values(validation_safety_case_risks, "trust_boundary"),
      "refresh_budget_statuses" =>
        risk_context_values(refresh_budget_risks, "refresh_budget_status"),
      "refresh_budget_candidate_limit_statuses" =>
        risk_context_values(refresh_budget_risks, "candidate_limit_status"),
      "refresh_budget_input_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "input_candidate_count"),
      "refresh_budget_kept_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "kept_candidate_count"),
      "refresh_budget_dropped_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "dropped_candidate_count"),
      "refresh_budget_invalid_limit_count_values" =>
        risk_context_values(refresh_budget_risks, "invalid_limit_count"),
      "refresh_budget_current_max_candidate_activity_values" =>
        risk_context_values(refresh_budget_risks, "current_max_candidate_activities"),
      "refresh_budget_relaxed_max_candidate_activity_values" =>
        risk_context_values(refresh_budget_risks, "relaxed_max_candidate_activities"),
      "refresh_budget_required_operator_actions" =>
        risk_context_values(refresh_budget_risks, "required_operator_action"),
      "refresh_budget_feedback_sources" =>
        risk_context_values(refresh_budget_risks, "feedback_source"),
      "refresh_budget_feedback_scopes" =>
        risk_context_values(refresh_budget_risks, "feedback_scope"),
      "refresh_budget_feedback_keys" => risk_context_values(refresh_budget_risks, "feedback_key"),
      "refresh_budget_trust_boundaries" =>
        risk_context_values(refresh_budget_risks, "trust_boundary"),
      "refresh_freshness_statuses" =>
        risk_context_values(refresh_freshness_risks, "freshness_status"),
      "refresh_freshness_state_quality_statuses" =>
        risk_context_values(refresh_freshness_risks, "state_quality_status"),
      "refresh_freshness_accepted_snapshot_age_values_s" =>
        risk_context_values(refresh_freshness_risks, "accepted_snapshot_age_s"),
      "refresh_freshness_horizon_start_offset_values_s" =>
        risk_context_values(refresh_freshness_risks, "horizon_start_offset_s"),
      "refresh_freshness_max_snapshot_age_values_s" =>
        risk_context_values(refresh_freshness_risks, "max_snapshot_age_s"),
      "refresh_freshness_max_horizon_start_offset_values_s" =>
        risk_context_values(refresh_freshness_risks, "max_horizon_start_offset_s"),
      "refresh_freshness_stale_reason_ids" =>
        risk_context_values(refresh_freshness_risks, ["stale_reasons"]),
      "refresh_freshness_unknown_reason_ids" =>
        risk_context_values(refresh_freshness_risks, ["unknown_reasons"]),
      "refresh_freshness_required_operator_actions" =>
        risk_context_values(refresh_freshness_risks, "required_operator_action"),
      "refresh_freshness_feedback_sources" =>
        risk_context_values(refresh_freshness_risks, "feedback_source"),
      "refresh_freshness_feedback_scopes" =>
        risk_context_values(refresh_freshness_risks, "feedback_scope"),
      "refresh_freshness_feedback_keys" =>
        risk_context_values(refresh_freshness_risks, "feedback_key"),
      "refresh_freshness_trust_boundaries" =>
        risk_context_values(refresh_freshness_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def validation_refresh_context(_risks), do: %{}

  def approval_boundary_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    approval_boundary_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "approval_boundary" or
            Map.get(&1, "type") == "approval_boundary_pressure")
      )

    %{
      "approval_boundary_ids" =>
        risk_context_values(approval_boundary_risks, "approval_boundary"),
      "approval_boundary_statuses" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_status"),
      "approval_boundary_reasons" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_reason"),
      "automation_boundaries" =>
        risk_context_values(approval_boundary_risks, "automation_boundary"),
      "execution_boundaries" =>
        risk_context_values(approval_boundary_risks, "execution_boundary"),
      "approval_boundary_import_classifications" =>
        risk_context_values(approval_boundary_risks, "import_classification"),
      "approval_boundary_required_operator_actions" =>
        risk_context_values(approval_boundary_risks, "required_operator_action"),
      "approval_boundary_required_authorities" =>
        risk_context_values(approval_boundary_risks, "required_authority"),
      "approval_boundary_policy_bundle_ids" =>
        risk_context_values(approval_boundary_risks, "policy_bundle_id"),
      "approval_boundary_rule_ids" => risk_context_values(approval_boundary_risks, "rule_id"),
      "approval_boundary_feedback_sources" =>
        risk_context_values(approval_boundary_risks, "feedback_source"),
      "approval_boundary_feedback_scopes" =>
        risk_context_values(approval_boundary_risks, "feedback_scope"),
      "approval_boundary_feedback_keys" =>
        risk_context_values(approval_boundary_risks, "feedback_key"),
      "approval_boundary_trust_boundaries" =>
        risk_context_values(approval_boundary_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def approval_boundary_context(_risks), do: %{}

  def provider_reservation_request_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    provider_reservation_request_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation_provider_reservation_request" or
            Map.get(&1, "type") == "provider_reservation_request_review")
      )

    %{
      "provider_reservation_request_contact_ids" =>
        risk_context_values(provider_reservation_request_risks, "contact_id"),
      "provider_reservation_request_source_activity_ids" =>
        risk_context_values(provider_reservation_request_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "provider_reservation_request_ground_station_ids" =>
        risk_context_values(provider_reservation_request_risks, "ground_station_id"),
      "provider_reservation_request_directions" =>
        risk_context_values(provider_reservation_request_risks, "direction"),
      "provider_reservation_request_station_reservation_ids" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_id"),
      "provider_reservation_request_station_reserved_by" =>
        risk_context_values(provider_reservation_request_risks, "station_reserved_by"),
      "provider_reservation_request_station_reservation_statuses" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_status"),
      "provider_reservation_request_station_reservation_match_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "station_reservation_match_status"
        ),
      "provider_reservation_request_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "provider_reservation_request_status"
        ),
      "provider_reservation_request_row_scopes" =>
        risk_context_values(provider_reservation_request_risks, "provider_reservation_row_scope"),
      "provider_reservation_request_required_operator_actions" =>
        risk_context_values(provider_reservation_request_risks, "required_operator_action"),
      "provider_reservation_request_assumption_maps" =>
        risk_context_values(provider_reservation_request_risks, "assumptions"),
      "provider_reservation_request_feedback_sources" =>
        risk_context_values(provider_reservation_request_risks, "feedback_source"),
      "provider_reservation_request_feedback_scopes" =>
        risk_context_values(provider_reservation_request_risks, "feedback_scope"),
      "provider_reservation_request_trust_boundaries" =>
        risk_context_values(provider_reservation_request_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def provider_reservation_request_context(_risks), do: %{}

  def capacity_pack_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    capacity_pack_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_contention_resolution" or
            Map.has_key?(&1, "capacity_pack_group_id"))
      )

    %{
      "capacity_pack_risk_contact_ids" => risk_context_values(capacity_pack_risks, "contact_id"),
      "capacity_pack_risk_source_activity_ids" =>
        risk_context_values(capacity_pack_risks, ["source_activity_id", "source_activity_ids"]),
      "capacity_pack_risk_ground_station_ids" =>
        risk_context_values(capacity_pack_risks, "ground_station_id"),
      "capacity_pack_risk_group_ids" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_group_id"),
      "capacity_pack_risk_statuses" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_status"),
      "capacity_pack_risk_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_capacity_fraction"),
      "capacity_pack_risk_used_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_used_fraction"),
      "capacity_pack_risk_unused_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_unused_fraction"),
      "capacity_pack_risk_required_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction"),
      "capacity_pack_risk_required_capacity_fraction_sources" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction_source"),
      "capacity_pack_risk_derivation_reasons" =>
        risk_context_values(capacity_pack_risks, ["derivation_reasons"]),
      "capacity_pack_risk_feedback_sources" =>
        risk_context_values(capacity_pack_risks, "feedback_source"),
      "capacity_pack_risk_feedback_scopes" =>
        risk_context_values(capacity_pack_risks, "feedback_scope"),
      "capacity_pack_risk_trust_boundaries" =>
        risk_context_values(capacity_pack_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def capacity_pack_context(_risks), do: %{}

  def station_reservation_conflict_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_reservation_conflict_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation" and
            Map.has_key?(&1, "station_reservation_match_status"))
      )

    %{
      "station_reservation_conflict_contact_ids" =>
        risk_context_values(station_reservation_conflict_risks, "contact_id"),
      "station_reservation_conflict_source_activity_ids" =>
        risk_context_values(station_reservation_conflict_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "station_reservation_conflict_ground_station_ids" =>
        risk_context_values(station_reservation_conflict_risks, "ground_station_id"),
      "station_reservation_conflict_reservation_ids" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_id"),
      "station_reservation_conflict_reserved_by" =>
        risk_context_values(station_reservation_conflict_risks, "station_reserved_by"),
      "station_reservation_conflict_statuses" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_status"),
      "station_reservation_conflict_match_statuses" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_match_status"
        ),
      "station_reservation_conflict_expires_at_values_s" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_expires_at_s"
        ),
      "station_reservation_conflict_derivation_reasons" =>
        risk_context_values(station_reservation_conflict_risks, ["derivation_reasons"]),
      "station_reservation_conflict_feedback_sources" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_source"),
      "station_reservation_conflict_feedback_scopes" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_scope"),
      "station_reservation_conflict_trust_boundaries" =>
        risk_context_values(station_reservation_conflict_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def station_reservation_conflict_context(_risks), do: %{}

  def station_reservation_hold_import_readiness_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_reservation_hold_risks =
      Enum.filter(
        risks,
        &(Map.has_key?(&1, "station_reservation_hold_import_status") or
            Map.has_key?(&1, "station_reservation_hold_import_readiness_status") or
            Map.has_key?(&1, "source_station_reservation_hold_import_readiness_summary"))
      )

    %{
      "station_reservation_hold_import_statuses" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_status"
        ),
      "station_reservation_hold_import_readiness_summary_models" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_summary_model"
        ),
      "station_reservation_hold_import_readiness_sources" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_source"
        ),
      "station_reservation_hold_import_readiness_source_artifact_types" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_source_artifact_type"
        ),
      "station_reservation_hold_import_readiness_statuses" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_readiness_status"
        ),
      "station_reservation_hold_import_classifications" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_classification"
        ),
      "station_reservation_hold_count_values" =>
        risk_context_values(station_reservation_hold_risks, "station_reservation_hold_count"),
      "station_reservation_hold_ids" =>
        risk_context_values(station_reservation_hold_risks, [
          "station_reservation_hold_ids"
        ]),
      "station_reservation_hold_ids_by_import_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_import_status"
        ),
      "station_reservation_hold_ids_by_required_import_action" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_required_import_action"
        ),
      "station_reservation_hold_ids_by_direction" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_direction"
        ),
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_ids_by_direction_and_ground_station_id"
        ),
      "station_reservation_hold_contact_ids" =>
        risk_context_values(station_reservation_hold_risks, "contact_id"),
      "station_reservation_hold_contact_ids_by_import_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_import_status"
        ),
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_expiration_status"
        ),
      "station_reservation_hold_contact_ids_by_direction" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_direction"
        ),
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_contact_ids_by_direction_and_ground_station_id"
        ),
      "station_reservation_hold_import_status_count_maps" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_status_counts"
        ),
      "station_reservation_hold_required_import_action_count_maps" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_required_import_action_counts"
        ),
      "station_reservation_hold_import_execution_boundaries" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_import_execution_boundary"
        ),
      "station_reservation_hold_provider_write_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_provider_write"
        ),
      "station_reservation_hold_cadence_write_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_cadence_write"
        ),
      "station_reservation_hold_reservation_acceptance_values" =>
        risk_context_values(
          station_reservation_hold_risks,
          "station_reservation_hold_reservation_acceptance"
        ),
      "station_reservation_hold_feedback_sources" =>
        risk_context_values(station_reservation_hold_risks, "feedback_source"),
      "station_reservation_hold_feedback_scopes" =>
        risk_context_values(station_reservation_hold_risks, "feedback_scope"),
      "station_reservation_hold_trust_boundaries" =>
        risk_context_values(station_reservation_hold_risks, "trust_boundary"),
      "source_station_reservation_hold_import_readiness_summaries" =>
        risk_context_values(
          station_reservation_hold_risks,
          "source_station_reservation_hold_import_readiness_summary"
        )
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def station_reservation_hold_import_readiness_context(_risks), do: %{}

  def timeline_activity_precondition_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_precondition_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_precondition_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_precondition")
      )

    %{
      "timeline_activity_precondition_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, "activity_id"),
      "timeline_activity_precondition_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, "timeline_id"),
      "timeline_activity_precondition_activity_types" =>
        risk_context_values(timeline_activity_precondition_risks, "activity_type"),
      "timeline_activity_precondition_statuses" =>
        risk_context_values(timeline_activity_precondition_risks, "precondition_status"),
      "timeline_activity_precondition_blocked_count_values" =>
        risk_context_values(timeline_activity_precondition_risks, "blocked_precondition_count"),
      "timeline_activity_precondition_review_count_values" =>
        risk_context_values(timeline_activity_precondition_risks, "review_precondition_count"),
      "timeline_activity_precondition_blocked_types" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "blocked_precondition_types"
        ]),
      "timeline_activity_precondition_review_types" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "review_precondition_types"
        ]),
      "timeline_activity_precondition_dependency_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "dependency_activity_ids"
        ]),
      "timeline_activity_precondition_dependency_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "dependency_timeline_ids"
        ]),
      "timeline_activity_precondition_exclusive_with_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "exclusive_with_activity_ids"
        ]),
      "timeline_activity_precondition_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "exclusive_with_timeline_ids"
        ]),
      "timeline_activity_precondition_duplicate_dependency_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_dependency_activity_ids"
        ]),
      "timeline_activity_precondition_duplicate_dependency_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_dependency_timeline_ids"
        ]),
      "timeline_activity_precondition_duplicate_exclusivity_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_exclusivity_activity_ids"
        ]),
      "timeline_activity_precondition_duplicate_exclusivity_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_exclusivity_timeline_ids"
        ]),
      "timeline_activity_precondition_allow_overlap_values" =>
        risk_context_values(timeline_activity_precondition_risks, "allow_overlap"),
      "timeline_activity_precondition_invalid_activity_input_values" =>
        risk_context_values(timeline_activity_precondition_risks, "invalid_activity_input"),
      "timeline_activity_precondition_invalid_activity_input_reasons" =>
        risk_context_values(
          timeline_activity_precondition_risks,
          "invalid_activity_input_reason"
        ),
      "timeline_activity_precondition_required_operator_actions" =>
        risk_context_values(timeline_activity_precondition_risks, "required_operator_action"),
      "timeline_activity_precondition_requires_operator_review_values" =>
        risk_context_values(timeline_activity_precondition_risks, "requires_operator_review"),
      "timeline_activity_precondition_feedback_sources" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_source"),
      "timeline_activity_precondition_feedback_scopes" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_scope"),
      "timeline_activity_precondition_feedback_keys" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_key"),
      "timeline_activity_precondition_trust_boundaries" =>
        risk_context_values(timeline_activity_precondition_risks, "trust_boundary"),
      "timeline_activity_precondition_derivation_reasons" =>
        risk_context_values(timeline_activity_precondition_risks, ["derivation_reasons"]),
      "timeline_activity_precondition_assumption_maps" =>
        risk_context_values(timeline_activity_precondition_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_activity_precondition_context(_risks), do: %{}

  def timeline_preservation_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_preservation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_preservation_review" or
            Map.get(&1, "feedback_scope") == "timeline_preservation")
      )

    %{
      "timeline_preservation_activity_ids" =>
        risk_context_values(timeline_preservation_risks, "activity_id"),
      "timeline_preservation_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, "timeline_id"),
      "timeline_preservation_statuses" =>
        risk_context_values(timeline_preservation_risks, "timeline_preservation_status"),
      "timeline_preservation_requires_preservation_values" =>
        risk_context_values(timeline_preservation_risks, "requires_preservation"),
      "timeline_preservation_requires_operator_review_values" =>
        risk_context_values(timeline_preservation_risks, "requires_operator_review"),
      "timeline_preservation_protection_decisions" =>
        risk_context_values(timeline_preservation_risks, "protection_decision"),
      "timeline_preservation_protection_categories" =>
        risk_context_values(timeline_preservation_risks, "protection_category"),
      "timeline_preservation_protection_reasons" =>
        risk_context_values(timeline_preservation_risks, "protection_reason"),
      "timeline_preservation_preserve_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "preserve_activity_count"),
      "timeline_preservation_review_change_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "review_change_activity_count"),
      "timeline_preservation_sensitive_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "preservation_sensitive_activity_count"),
      "timeline_preservation_preserve_activity_ids" =>
        risk_context_values(timeline_preservation_risks, ["preserve_activity_ids"]),
      "timeline_preservation_preserve_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, ["preserve_timeline_ids"]),
      "timeline_preservation_review_change_activity_ids" =>
        risk_context_values(timeline_preservation_risks, ["review_change_activity_ids"]),
      "timeline_preservation_review_change_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, ["review_change_timeline_ids"]),
      "timeline_preservation_sensitive_activity_ids" =>
        risk_context_values(timeline_preservation_risks, [
          "preservation_sensitive_activity_ids"
        ]),
      "timeline_preservation_sensitive_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, [
          "preservation_sensitive_timeline_ids"
        ]),
      "timeline_preservation_invalid_activity_input_values" =>
        risk_context_values(timeline_preservation_risks, "invalid_activity_input"),
      "timeline_preservation_invalid_activity_input_reasons" =>
        risk_context_values(timeline_preservation_risks, "invalid_activity_input_reason"),
      "timeline_preservation_required_operator_actions" =>
        risk_context_values(timeline_preservation_risks, "required_operator_action"),
      "timeline_preservation_feedback_sources" =>
        risk_context_values(timeline_preservation_risks, "feedback_source"),
      "timeline_preservation_feedback_scopes" =>
        risk_context_values(timeline_preservation_risks, "feedback_scope"),
      "timeline_preservation_feedback_keys" =>
        risk_context_values(timeline_preservation_risks, "feedback_key"),
      "timeline_preservation_trust_boundaries" =>
        risk_context_values(timeline_preservation_risks, "trust_boundary"),
      "timeline_preservation_derivation_reasons" =>
        risk_context_values(timeline_preservation_risks, ["derivation_reasons"]),
      "timeline_preservation_assumption_maps" =>
        risk_context_values(timeline_preservation_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_preservation_context(_risks), do: %{}

  def timeline_publication_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_publication_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_publication_pressure" or
            Map.get(&1, "feedback_scope") == "timeline_publication")
      )

    %{
      "timeline_publication_ids" =>
        risk_context_values(timeline_publication_risks, "publication_id"),
      "timeline_publication_sequences" =>
        risk_context_values(timeline_publication_risks, "publication_sequence"),
      "timeline_publication_statuses" =>
        risk_context_values(timeline_publication_risks, "publication_status"),
      "timeline_publication_downstream_invalidation_statuses" =>
        risk_context_values(timeline_publication_risks, "downstream_invalidation_status"),
      "timeline_publication_dependency_impact_statuses" =>
        risk_context_values(timeline_publication_risks, "dependency_impact_status"),
      "timeline_publication_source_artifact_ids" =>
        risk_context_values(timeline_publication_risks, "source_artifact_id"),
      "timeline_publication_source_artifact_types" =>
        risk_context_values(timeline_publication_risks, "source_artifact_type"),
      "timeline_publication_authorities" =>
        risk_context_values(timeline_publication_risks, "publication_authority"),
      "timeline_publication_supersedes_artifact_ids" =>
        risk_context_values(timeline_publication_risks, ["supersedes_artifact_ids"]),
      "timeline_publication_downstream_product_ids" =>
        risk_context_values(timeline_publication_risks, ["downstream_product_ids"]),
      "timeline_publication_invalidated_downstream_product_ids" =>
        risk_context_values(timeline_publication_risks, [
          "invalidated_downstream_product_ids"
        ]),
      "timeline_publication_downstream_invalidation_reason_count_maps" =>
        risk_context_values(
          timeline_publication_risks,
          "downstream_invalidation_reason_counts"
        ),
      "timeline_publication_downstream_invalidation_reasons" =>
        risk_context_values(timeline_publication_risks, [
          "downstream_invalidation_reasons"
        ]),
      "timeline_publication_invalidated_downstream_product_ids_by_reason" =>
        risk_context_values(
          timeline_publication_risks,
          "invalidated_downstream_product_ids_by_reason"
        ),
      "timeline_publication_dependency_impact_row_count_values" =>
        risk_context_values(timeline_publication_risks, "dependency_impact_row_count"),
      "timeline_publication_timeline_diff_row_count_values" =>
        risk_context_values(timeline_publication_risks, "timeline_diff_row_count"),
      "timeline_publication_timeline_diff_changed_count_values" =>
        risk_context_values(timeline_publication_risks, "timeline_diff_changed_count"),
      "timeline_publication_timeline_diff_review_required_count_values" =>
        risk_context_values(
          timeline_publication_risks,
          "timeline_diff_review_required_count"
        ),
      "timeline_publication_changed_field_count_maps" =>
        risk_context_values(timeline_publication_risks, "changed_field_counts"),
      "timeline_publication_changed_fields" =>
        risk_context_values(timeline_publication_risks, ["changed_fields"]),
      "timeline_publication_changed_timeline_ids" =>
        risk_context_values(timeline_publication_risks, ["changed_timeline_ids"]),
      "timeline_publication_review_timeline_ids" =>
        risk_context_values(timeline_publication_risks, ["review_timeline_ids"]),
      "timeline_publication_timeline_ids_by_changed_field" =>
        risk_context_values(timeline_publication_risks, "timeline_ids_by_changed_field"),
      "timeline_publication_feedback_sources" =>
        risk_context_values(timeline_publication_risks, "feedback_source"),
      "timeline_publication_feedback_scopes" =>
        risk_context_values(timeline_publication_risks, "feedback_scope"),
      "timeline_publication_feedback_keys" =>
        risk_context_values(timeline_publication_risks, "feedback_key"),
      "timeline_publication_trust_boundaries" =>
        risk_context_values(timeline_publication_risks, "trust_boundary"),
      "timeline_publication_derivation_reasons" =>
        risk_context_values(timeline_publication_risks, ["derivation_reasons"]),
      "timeline_publication_assumption_maps" =>
        risk_context_values(timeline_publication_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_publication_context(_risks), do: %{}

  def timeline_lifecycle_state_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_lifecycle_state_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_lifecycle_state_review" or
            Map.get(&1, "feedback_scope") == "timeline_lifecycle_state")
      )

    %{
      "timeline_lifecycle_state_statuses" =>
        risk_context_values(timeline_lifecycle_state_risks, "timeline_lifecycle_state_status"),
      "timeline_lifecycle_state_planned_activity_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "planned_activity_count"),
      "timeline_lifecycle_state_realized_activity_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "realized_activity_count"),
      "timeline_lifecycle_state_row_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "row_count"),
      "timeline_lifecycle_state_recordable_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "recordable_count"),
      "timeline_lifecycle_state_preserved_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "preserved_count"),
      "timeline_lifecycle_state_review_required_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "review_required_count"),
      "timeline_lifecycle_state_duplicate_identity_count_values" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "duplicate_timeline_identity_count"
        ),
      "timeline_lifecycle_state_invalid_activity_input_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "invalid_activity_input_count"),
      "timeline_lifecycle_state_transition_decision_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "transition_decision_counts"),
      "timeline_lifecycle_state_required_operator_action_count_maps" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "required_operator_action_counts"
        ),
      "timeline_lifecycle_state_operator_action_reason_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "operator_action_reason_counts"),
      "timeline_lifecycle_state_import_action_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "import_action_counts"),
      "timeline_lifecycle_state_planned_status_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "planned_status_category_counts"),
      "timeline_lifecycle_state_realized_status_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "realized_status_category_counts"),
      "timeline_lifecycle_state_status_transition_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "status_transition_category_counts"),
      "timeline_lifecycle_state_approval_transition_category_count_maps" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "approval_transition_category_counts"
        ),
      "timeline_lifecycle_state_recordable_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["recordable_timeline_ids"]),
      "timeline_lifecycle_state_preserved_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["preserved_timeline_ids"]),
      "timeline_lifecycle_state_review_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["review_timeline_ids"]),
      "timeline_lifecycle_state_review_activity_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["review_activity_ids"]),
      "timeline_lifecycle_state_invalid_activity_input_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["invalid_activity_input_ids"]),
      "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_required_operator_action"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_operator_action_reason"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_status_transition_category"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_approval_transition_category"
        ),
      "timeline_lifecycle_state_required_operator_actions" =>
        risk_context_values(timeline_lifecycle_state_risks, "required_operator_action"),
      "timeline_lifecycle_state_requires_operator_review_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "requires_operator_review"),
      "timeline_lifecycle_state_feedback_sources" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_source"),
      "timeline_lifecycle_state_feedback_scopes" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_scope"),
      "timeline_lifecycle_state_feedback_keys" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_key"),
      "timeline_lifecycle_state_trust_boundaries" =>
        risk_context_values(timeline_lifecycle_state_risks, "trust_boundary"),
      "timeline_lifecycle_state_derivation_reasons" =>
        risk_context_values(timeline_lifecycle_state_risks, ["derivation_reasons"]),
      "timeline_lifecycle_state_assumption_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_lifecycle_state_context(_risks), do: %{}

  def timeline_activity_lifecycle_state_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_lifecycle_state_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_lifecycle_state_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_lifecycle_state")
      )

    %{
      "timeline_activity_lifecycle_state_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "activity_id"),
      "timeline_activity_lifecycle_state_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "timeline_id"),
      "timeline_activity_lifecycle_state_planned_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_activity_id"),
      "timeline_activity_lifecycle_state_realized_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_activity_id"),
      "timeline_activity_lifecycle_state_planned_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_timeline_id"),
      "timeline_activity_lifecycle_state_realized_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_timeline_id"),
      "timeline_activity_lifecycle_state_transition_decisions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "transition_decision"),
      "timeline_activity_lifecycle_state_status_transition_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "status_transition_decision"
        ),
      "timeline_activity_lifecycle_state_approval_transition_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "approval_transition_decision"
        ),
      "timeline_activity_lifecycle_state_review_required_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "review_required"),
      "timeline_activity_lifecycle_state_requires_operator_review_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "requires_operator_review"
        ),
      "timeline_activity_lifecycle_state_required_operator_actions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "required_operator_action",
          "required_operator_actions"
        ]),
      "timeline_activity_lifecycle_state_operator_action_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "operator_action_reasons"
        ]),
      "timeline_activity_lifecycle_state_import_actions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "import_action"),
      "timeline_activity_lifecycle_state_invalid_activity_input_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "invalid_activity_input"
        ),
      "timeline_activity_lifecycle_state_invalid_activity_input_count_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "invalid_activity_input_count"
        ),
      "timeline_activity_lifecycle_state_invalid_activity_input_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "invalid_activity_input_reasons"
        ]),
      "timeline_activity_lifecycle_state_planned_statuses" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_status"),
      "timeline_activity_lifecycle_state_realized_statuses" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_status"),
      "timeline_activity_lifecycle_state_planned_status_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_status_category"
        ),
      "timeline_activity_lifecycle_state_realized_status_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_status_category"
        ),
      "timeline_activity_lifecycle_state_planned_approval_statuses" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_approval_status"
        ),
      "timeline_activity_lifecycle_state_realized_approval_statuses" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_approval_status"
        ),
      "timeline_activity_lifecycle_state_planned_approval_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_approval_category"
        ),
      "timeline_activity_lifecycle_state_realized_approval_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_approval_category"
        ),
      "timeline_activity_lifecycle_state_planned_locked_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_locked"),
      "timeline_activity_lifecycle_state_realized_locked_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_locked"),
      "timeline_activity_lifecycle_state_planned_executed_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_executed"),
      "timeline_activity_lifecycle_state_realized_executed_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_executed"),
      "timeline_activity_lifecycle_state_status_transitions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "status_transition"),
      "timeline_activity_lifecycle_state_approval_transitions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "approval_transition"),
      "timeline_activity_lifecycle_state_planned_protection_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_protection_decision"
        ),
      "timeline_activity_lifecycle_state_realized_protection_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_protection_decision"
        ),
      "timeline_activity_lifecycle_state_feedback_sources" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_source"),
      "timeline_activity_lifecycle_state_feedback_scopes" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_scope"),
      "timeline_activity_lifecycle_state_feedback_keys" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_key"),
      "timeline_activity_lifecycle_state_trust_boundaries" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "trust_boundary"),
      "timeline_activity_lifecycle_state_derivation_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "derivation_reasons"
        ]),
      "timeline_activity_lifecycle_state_assumption_maps" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_activity_lifecycle_state_context(_risks), do: %{}

  def timeline_dependency_impact_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_dependency_impact_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_dependency_impact" or
            Map.get(&1, "feedback_scope") == "timeline_dependency_impact")
      )

    %{
      "timeline_dependency_impact_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "activity_id"),
      "timeline_dependency_impact_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "timeline_id"),
      "timeline_dependency_impact_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_scope"),
      "timeline_dependency_impact_statuses" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_status"),
      "timeline_dependency_impact_required_operator_actions" =>
        risk_context_values(timeline_dependency_impact_risks, "required_operator_action"),
      "timeline_dependency_impact_operator_action_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, "operator_action_reason"),
      "timeline_dependency_impact_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_activity_ids"]),
      "timeline_dependency_impact_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_timeline_ids"]),
      "timeline_dependency_impact_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_feedback_sources" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_source"),
      "timeline_dependency_impact_feedback_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_scope"),
      "timeline_dependency_impact_feedback_keys" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_key"),
      "timeline_dependency_impact_trust_boundaries" =>
        risk_context_values(timeline_dependency_impact_risks, "trust_boundary"),
      "timeline_dependency_impact_derivation_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_dependency_impact_context(_risks), do: %{}

  def relay_data_path_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    relay_data_path_risks =
      Enum.filter(risks, &relay_data_path_risk?/1)

    %{
      "relay_data_path_risk_types" =>
        risk_context_values(relay_data_path_risks, ["type", "risk_type"]),
      "relay_data_path_ground_station_ids" =>
        risk_context_values(relay_data_path_risks, "ground_station_id"),
      "relay_data_path_route_ids" =>
        risk_context_values(relay_data_path_risks, ["route_id", "route_ids"]),
      "relay_data_path_source_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, [
          "source_spacecraft_id",
          "source_spacecraft_ids"
        ]),
      "relay_data_path_relay_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, ["relay_spacecraft_ids"]),
      "relay_data_path_relay_chain_spacecraft_ids" =>
        risk_context_values(relay_data_path_risks, ["relay_chain_spacecraft_ids"]),
      "relay_data_path_relay_hop_count_values" =>
        risk_context_values(relay_data_path_risks, "relay_hop_count"),
      "relay_data_path_ground_downlink_contact_ids" =>
        risk_context_values(relay_data_path_risks, [
          "ground_downlink_contact_id",
          "ground_downlink_contact_ids"
        ]),
      "relay_data_path_custody_statuses" =>
        risk_context_values(relay_data_path_risks, "custody_status"),
      "relay_data_path_latency_values_s" =>
        risk_context_values(relay_data_path_risks, "latency_s"),
      "relay_data_path_latency_limit_values_s" =>
        risk_context_values(relay_data_path_risks, "latency_limit_s"),
      "relay_data_path_latency_statuses" =>
        risk_context_values(relay_data_path_risks, "latency_status"),
      "relay_data_path_risk_statuses" =>
        risk_context_values(relay_data_path_risks, "risk_status"),
      "relay_data_path_risk_reasons" =>
        risk_context_values(relay_data_path_risks, ["risk_reasons"]),
      "relay_data_path_product_ids" =>
        risk_context_values(relay_data_path_risks, ["product_ids"]),
      "relay_data_path_collection_ids" =>
        risk_context_values(relay_data_path_risks, ["collection_ids"]),
      "relay_data_path_route_count_values" =>
        risk_context_values(relay_data_path_risks, "route_count"),
      "relay_data_path_relay_route_count_values" =>
        risk_context_values(relay_data_path_risks, "relay_route_count"),
      "relay_data_path_direct_downlink_route_count_values" =>
        risk_context_values(relay_data_path_risks, "direct_downlink_route_count"),
      "relay_data_path_custody_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "custody_status_counts"),
      "relay_data_path_latency_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "latency_status_counts"),
      "relay_data_path_risk_status_count_maps" =>
        risk_context_values(relay_data_path_risks, "risk_status_counts"),
      "relay_data_path_route_ids_by_custody_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_custody_status"),
      "relay_data_path_route_ids_by_latency_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_latency_status"),
      "relay_data_path_route_ids_by_risk_status" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_risk_status"),
      "relay_data_path_route_ids_by_ground_station_id" =>
        risk_context_values(relay_data_path_risks, "route_ids_by_ground_station_id"),
      "relay_data_path_feedback_sources" =>
        risk_context_values(relay_data_path_risks, "feedback_source"),
      "relay_data_path_feedback_scopes" =>
        risk_context_values(relay_data_path_risks, "feedback_scope"),
      "relay_data_path_feedback_keys" =>
        risk_context_values(relay_data_path_risks, "feedback_key"),
      "relay_data_path_trust_boundaries" =>
        risk_context_values(relay_data_path_risks, "trust_boundary"),
      "relay_data_path_derivation_reasons" =>
        risk_context_values(relay_data_path_risks, ["derivation_reasons"]),
      "relay_data_path_assumption_maps" =>
        risk_context_values(relay_data_path_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def relay_data_path_context(_risks), do: %{}

  def link_capacity_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    link_capacity_risks =
      Enum.filter(risks, &link_capacity_risk?/1)

    %{
      "link_capacity_pressure_risk_types" =>
        risk_context_values(link_capacity_risks, ["type", "risk_type"]),
      "link_capacity_pressure_ground_station_ids" =>
        risk_context_values(link_capacity_risks, "ground_station_id"),
      "link_capacity_pressure_required_contact_values" =>
        risk_context_values(link_capacity_risks, "required_contacts"),
      "link_capacity_pressure_planned_contact_values" =>
        risk_context_values(link_capacity_risks, "planned_contacts"),
      "link_capacity_pressure_required_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "required_downlink_mb"),
      "link_capacity_pressure_planned_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "planned_downlink_mb"),
      "link_capacity_pressure_start_values_s" =>
        risk_context_values(link_capacity_risks, "starts_at_s"),
      "link_capacity_pressure_end_values_s" =>
        risk_context_values(link_capacity_risks, "ends_at_s"),
      "link_capacity_pressure_source_activity_ids" =>
        risk_context_values(link_capacity_risks, ["source_activity_ids"]),
      "link_capacity_pressure_source_window_ids" =>
        risk_context_values(link_capacity_risks, ["source_window_id", "source_window_ids"]),
      "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_capacity_adjusted_throughput_mb"),
      "link_capacity_pressure_selected_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_downlink_shortfall_mb"),
      "link_capacity_pressure_actual_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_throughput_mb"),
      "link_capacity_pressure_actual_downlink_completion_ratio_values" =>
        risk_context_values(link_capacity_risks, "actual_downlink_completion_ratio"),
      "link_capacity_pressure_actual_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_downlink_shortfall_mb"),
      "link_capacity_pressure_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "downlink_requirement_status"),
      "link_capacity_pressure_actual_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "actual_downlink_requirement_status"),
      "link_capacity_pressure_downlink_demand_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_demand_sources"]),
      "link_capacity_pressure_downlink_completion_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_completion_sources"]),
      "link_capacity_pressure_feedback_sources" =>
        risk_context_values(link_capacity_risks, "feedback_source"),
      "link_capacity_pressure_feedback_scopes" =>
        risk_context_values(link_capacity_risks, "feedback_scope"),
      "link_capacity_pressure_trust_boundaries" =>
        risk_context_values(link_capacity_risks, "trust_boundary"),
      "link_capacity_pressure_derivation_reasons" =>
        risk_context_values(link_capacity_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def link_capacity_context(_risks), do: %{}

  def contact_intent_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    contact_intent_risks =
      Enum.filter(risks, &contact_intent_risk?/1)

    %{
      "contact_intent_pressure_risk_types" =>
        risk_context_values(contact_intent_risks, ["type", "risk_type"]),
      "contact_intent_pressure_contact_ids" =>
        risk_context_values(contact_intent_risks, "contact_id"),
      "contact_intent_pressure_source_activity_ids" =>
        risk_context_values(contact_intent_risks, ["source_activity_id", "source_activity_ids"]),
      "contact_intent_pressure_ground_station_ids" =>
        risk_context_values(contact_intent_risks, "ground_station_id"),
      "contact_intent_pressure_required_contact_values" =>
        risk_context_values(contact_intent_risks, "required_contacts"),
      "contact_intent_pressure_planned_contact_values" =>
        risk_context_values(contact_intent_risks, "planned_contacts"),
      "contact_intent_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_intent_risks, "required_downlink_mb"),
      "contact_intent_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_intent_risks, "planned_downlink_mb"),
      "contact_intent_pressure_start_values_s" =>
        risk_context_values(contact_intent_risks, "starts_at_s"),
      "contact_intent_pressure_end_values_s" =>
        risk_context_values(contact_intent_risks, "ends_at_s"),
      "contact_intent_pressure_source_window_ids" =>
        risk_context_values(contact_intent_risks, "source_window_id"),
      "contact_intent_pressure_timeline_ids" =>
        risk_context_values(contact_intent_risks, "timeline_id"),
      "contact_intent_pressure_approval_statuses" =>
        risk_context_values(contact_intent_risks, "approval_status"),
      "contact_intent_pressure_required_operator_actions" =>
        risk_context_values(contact_intent_risks, "required_operator_action"),
      "contact_intent_pressure_cadence_import_statuses" =>
        risk_context_values(contact_intent_risks, "cadence_import_status"),
      "contact_intent_pressure_invalid_cadence_import_values" =>
        risk_context_values(contact_intent_risks, "invalid_cadence_import"),
      "contact_intent_pressure_invalid_cadence_import_reasons" =>
        risk_context_values(contact_intent_risks, "invalid_cadence_import_reason"),
      "contact_intent_pressure_invalid_activity_input_values" =>
        risk_context_values(contact_intent_risks, "invalid_activity_input"),
      "contact_intent_pressure_invalid_activity_input_reasons" =>
        risk_context_values(contact_intent_risks, "invalid_activity_input_reason"),
      "contact_intent_pressure_gate_statuses" =>
        risk_context_values(contact_intent_risks, "contact_intent_gate_status"),
      "contact_intent_pressure_policy_classifications" =>
        risk_context_values(contact_intent_risks, "policy_classification"),
      "contact_intent_pressure_policy_bundle_ids" =>
        risk_context_values(contact_intent_risks, "policy_bundle_id"),
      "contact_intent_pressure_station_availabilities" =>
        risk_context_values(contact_intent_risks, "station_availability"),
      "contact_intent_pressure_station_contention_statuses" =>
        risk_context_values(contact_intent_risks, "station_contention_status"),
      "contact_intent_pressure_station_calendar_entry_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_entry_id"),
      "contact_intent_pressure_station_calendar_provider_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_provider_id"),
      "contact_intent_pressure_station_calendar_provider_entry_ids" =>
        risk_context_values(contact_intent_risks, "station_calendar_provider_entry_id"),
      "contact_intent_pressure_station_calendar_directions" =>
        risk_context_values(contact_intent_risks, ["station_calendar_directions"]),
      "contact_intent_pressure_station_calendar_statuses" =>
        risk_context_values(contact_intent_risks, "station_calendar_status"),
      "contact_intent_pressure_station_calendar_trust_boundary_statuses" =>
        risk_context_values(contact_intent_risks, "station_calendar_trust_boundary_status"),
      "contact_intent_pressure_station_reservation_ids" =>
        risk_context_values(contact_intent_risks, "station_reservation_id"),
      "contact_intent_pressure_station_reserved_by" =>
        risk_context_values(contact_intent_risks, "station_reserved_by"),
      "contact_intent_pressure_station_reservation_statuses" =>
        risk_context_values(contact_intent_risks, "station_reservation_status"),
      "contact_intent_pressure_station_reservation_match_statuses" =>
        risk_context_values(contact_intent_risks, "station_reservation_match_status"),
      "contact_intent_pressure_feedback_sources" =>
        risk_context_values(contact_intent_risks, "feedback_source"),
      "contact_intent_pressure_feedback_scopes" =>
        risk_context_values(contact_intent_risks, "feedback_scope"),
      "contact_intent_pressure_trust_boundaries" =>
        risk_context_values(contact_intent_risks, "trust_boundary"),
      "contact_intent_pressure_derivation_reasons" =>
        risk_context_values(contact_intent_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def contact_intent_context(_risks), do: %{}

  def station_calendar_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_calendar_risks =
      Enum.filter(risks, &station_calendar_risk?/1)

    %{
      "station_calendar_pressure_risk_types" =>
        risk_context_values(station_calendar_risks, ["type", "risk_type"]),
      "station_calendar_pressure_ground_station_ids" =>
        risk_context_values(station_calendar_risks, "ground_station_id"),
      "station_calendar_pressure_start_values_s" =>
        risk_context_values(station_calendar_risks, "starts_at_s"),
      "station_calendar_pressure_end_values_s" =>
        risk_context_values(station_calendar_risks, "ends_at_s"),
      "station_calendar_pressure_capacity_fraction_values" =>
        risk_context_values(station_calendar_risks, "capacity_fraction"),
      "station_calendar_pressure_station_availabilities" =>
        risk_context_values(station_calendar_risks, "station_availability"),
      "station_calendar_pressure_station_contention_statuses" =>
        risk_context_values(station_calendar_risks, "station_contention_status"),
      "station_calendar_pressure_station_calendar_entry_ids" =>
        risk_context_values(station_calendar_risks, "station_calendar_entry_id"),
      "station_calendar_pressure_station_calendar_provider_ids" =>
        risk_context_values(station_calendar_risks, "station_calendar_provider_id"),
      "station_calendar_pressure_station_calendar_provider_entry_ids" =>
        risk_context_values(station_calendar_risks, "station_calendar_provider_entry_id"),
      "station_calendar_pressure_station_calendar_directions" =>
        risk_context_values(station_calendar_risks, ["station_calendar_directions"]),
      "station_calendar_pressure_station_calendar_statuses" =>
        risk_context_values(station_calendar_risks, "station_calendar_status"),
      "station_calendar_pressure_station_calendar_overlap_count_values" =>
        risk_context_values(station_calendar_risks, "station_calendar_overlap_count"),
      "station_calendar_pressure_station_calendar_overlap_entry_ids" =>
        risk_context_values(station_calendar_risks, ["station_calendar_overlap_entry_ids"]),
      "station_calendar_pressure_station_calendar_overlap_availabilities" =>
        risk_context_values(station_calendar_risks, [
          "station_calendar_overlap_availabilities"
        ]),
      "station_calendar_pressure_station_calendar_entry_ambiguous_values" =>
        risk_context_values(station_calendar_risks, "station_calendar_entry_ambiguous"),
      "station_calendar_pressure_station_calendar_ambiguous_entry_count_values" =>
        risk_context_values(station_calendar_risks, "station_calendar_ambiguous_entry_count"),
      "station_calendar_pressure_station_calendar_ambiguous_entry_ids" =>
        risk_context_values(station_calendar_risks, ["station_calendar_ambiguous_entry_ids"]),
      "station_calendar_pressure_station_calendar_reservation_overlap_count_values" =>
        risk_context_values(
          station_calendar_risks,
          "station_calendar_reservation_overlap_count"
        ),
      "station_calendar_pressure_station_calendar_reservation_ids" =>
        risk_context_values(station_calendar_risks, ["station_calendar_reservation_ids"]),
      "station_calendar_pressure_station_calendar_reserved_by" =>
        risk_context_values(station_calendar_risks, ["station_calendar_reserved_by"]),
      "station_calendar_pressure_station_calendar_reservation_statuses" =>
        risk_context_values(station_calendar_risks, [
          "station_calendar_reservation_statuses"
        ]),
      "station_calendar_pressure_station_calendar_trust_boundary_statuses" =>
        risk_context_values(station_calendar_risks, "station_calendar_trust_boundary_status"),
      "station_calendar_pressure_station_reservation_ids" =>
        risk_context_values(station_calendar_risks, ["station_reservation_id", "reservation_id"]),
      "station_calendar_pressure_station_reserved_by" =>
        risk_context_values(station_calendar_risks, ["station_reserved_by", "reserved_by"]),
      "station_calendar_pressure_station_reservation_statuses" =>
        risk_context_values(station_calendar_risks, [
          "station_reservation_status",
          "reservation_status"
        ]),
      "station_calendar_pressure_station_reservation_match_statuses" =>
        risk_context_values(station_calendar_risks, "station_reservation_match_status"),
      "station_calendar_pressure_station_reservation_expires_at_values_s" =>
        risk_context_values(station_calendar_risks, "station_reservation_expires_at_s"),
      "station_calendar_pressure_station_reservation_expiration_statuses" =>
        risk_context_values(station_calendar_risks, "station_reservation_expiration_status"),
      "station_calendar_pressure_provider_calendar_contention_group_ids" =>
        risk_context_values(station_calendar_risks, "provider_calendar_contention_group_id"),
      "station_calendar_pressure_provider_calendar_contention_statuses" =>
        risk_context_values(station_calendar_risks, "provider_calendar_contention_status"),
      "station_calendar_pressure_provider_calendar_contention_entry_ids" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_entry_ids"
        ]),
      "station_calendar_pressure_provider_calendar_contention_provider_ids" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_provider_ids"
        ]),
      "station_calendar_pressure_provider_calendar_contention_provider_entry_ids" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_provider_entry_ids"
        ]),
      "station_calendar_pressure_provider_calendar_contention_availabilities" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_availabilities"
        ]),
      "station_calendar_pressure_provider_calendar_contention_directions" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_directions"
        ]),
      "station_calendar_pressure_provider_calendar_contention_reservation_ids" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_reservation_ids"
        ]),
      "station_calendar_pressure_provider_calendar_contention_reserved_by" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_reserved_by"
        ]),
      "station_calendar_pressure_provider_calendar_contention_reservation_statuses" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_reservation_statuses"
        ]),
      "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_trust_boundary_statuses"
        ]),
      "station_calendar_pressure_provider_calendar_contention_overlap_pairs" =>
        risk_context_values(station_calendar_risks, [
          "provider_calendar_contention_overlap_pairs"
        ]),
      "station_calendar_pressure_required_operator_actions" =>
        risk_context_values(station_calendar_risks, "required_operator_action"),
      "station_calendar_pressure_feedback_sources" =>
        risk_context_values(station_calendar_risks, "feedback_source"),
      "station_calendar_pressure_feedback_scopes" =>
        risk_context_values(station_calendar_risks, "feedback_scope"),
      "station_calendar_pressure_trust_boundaries" =>
        risk_context_values(station_calendar_risks, "trust_boundary"),
      "station_calendar_pressure_derivation_reasons" =>
        risk_context_values(station_calendar_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def station_calendar_context(_risks), do: %{}

  def resource_margin_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    resource_margin_risks =
      Enum.filter(risks, &resource_margin_risk?/1)

    %{
      "resource_margin_risk_types" =>
        risk_context_values(resource_margin_risks, "resource_margin_risk_type"),
      "resource_margin_spacecraft_ids" =>
        risk_context_values(resource_margin_risks, "spacecraft_id"),
      "resource_margin_scenario_ids" => risk_context_values(resource_margin_risks, "scenario_id"),
      "resource_margin_timeline_ids" => risk_context_values(resource_margin_risks, "timeline_id"),
      "resource_margin_source_activity_ids" =>
        risk_context_values(resource_margin_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "resource_margin_replacement_activity_ids" =>
        risk_context_values(resource_margin_risks, "replacement_activity_id"),
      "resource_margin_fields" => risk_context_values(resource_margin_risks, "resource_field"),
      "resource_margin_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_value"),
      "resource_margin_threshold_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_threshold"),
      "resource_margin_field_value_maps" =>
        risk_context_values(resource_margin_risks, "resource_margin_field_value"),
      "resource_margin_source_quality_values" =>
        risk_context_values(resource_margin_risks, "source_quality"),
      "resource_margin_start_values_s" =>
        risk_context_values(resource_margin_risks, "starts_at_s"),
      "resource_margin_end_values_s" => risk_context_values(resource_margin_risks, "ends_at_s"),
      "resource_margin_diff_statuses" =>
        risk_context_values(resource_margin_risks, "diff_status"),
      "resource_margin_changed_fields" =>
        risk_context_values(resource_margin_risks, ["changed_fields"]),
      "resource_margin_required_operator_actions" =>
        risk_context_values(resource_margin_risks, "required_operator_action"),
      "resource_margin_requires_operator_review_values" =>
        risk_context_values(resource_margin_risks, "requires_operator_review"),
      "resource_margin_feedback_sources" =>
        risk_context_values(resource_margin_risks, "feedback_source"),
      "resource_margin_feedback_scopes" =>
        risk_context_values(resource_margin_risks, "feedback_scope"),
      "resource_margin_feedback_keys" =>
        risk_context_values(resource_margin_risks, "feedback_key"),
      "resource_margin_trust_boundaries" =>
        risk_context_values(resource_margin_risks, "trust_boundary"),
      "resource_margin_derivation_reasons" =>
        risk_context_values(resource_margin_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def resource_margin_context(_risks), do: %{}

  def maneuver_execution_uncertainty_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    maneuver_execution_uncertainty_risks =
      Enum.filter(risks, &maneuver_execution_uncertainty_risk?/1)

    %{
      "maneuver_execution_uncertainty_risk_types" =>
        risk_context_values(maneuver_execution_uncertainty_risks, [
          "type",
          "risk_type"
        ]),
      "maneuver_execution_uncertainty_activity_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "activity_id"),
      "maneuver_execution_uncertainty_timeline_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "timeline_id"),
      "maneuver_execution_uncertainty_maneuver_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "maneuver_id"),
      "maneuver_execution_uncertainty_scenario_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "scenario_id"),
      "maneuver_execution_uncertainty_source_activity_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "maneuver_execution_uncertainty_replacement_activity_ids" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "replacement_activity_id"),
      "maneuver_execution_uncertainty_statuses" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "execution_uncertainty_status"),
      "maneuver_execution_uncertainty_sources" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "execution_uncertainty_source"),
      "maneuver_execution_uncertainty_maps" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "execution_uncertainty"),
      "maneuver_execution_uncertainty_timing_3sigma_values_s" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "timing_3sigma_s"),
      "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s" =>
        risk_context_values(
          maneuver_execution_uncertainty_risks,
          "timing_3sigma_threshold_s"
        ),
      "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "delta_v_3sigma_km_s"),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s" =>
        risk_context_values(
          maneuver_execution_uncertainty_risks,
          "delta_v_3sigma_magnitude_km_s"
        ),
      "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s" =>
        risk_context_values(
          maneuver_execution_uncertainty_risks,
          "delta_v_3sigma_magnitude_threshold_km_s"
        ),
      "maneuver_execution_uncertainty_start_values_s" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "starts_at_s"),
      "maneuver_execution_uncertainty_end_values_s" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "ends_at_s"),
      "maneuver_execution_uncertainty_changed_fields" =>
        risk_context_values(maneuver_execution_uncertainty_risks, ["changed_fields"]),
      "maneuver_execution_uncertainty_required_operator_actions" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "required_operator_action"),
      "maneuver_execution_uncertainty_requires_operator_review_values" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "requires_operator_review"),
      "maneuver_execution_uncertainty_feedback_sources" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "feedback_source"),
      "maneuver_execution_uncertainty_feedback_scopes" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "feedback_scope"),
      "maneuver_execution_uncertainty_feedback_keys" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "feedback_key"),
      "maneuver_execution_uncertainty_trust_boundaries" =>
        risk_context_values(maneuver_execution_uncertainty_risks, "trust_boundary"),
      "maneuver_execution_uncertainty_derivation_reasons" =>
        risk_context_values(maneuver_execution_uncertainty_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def maneuver_execution_uncertainty_context(_risks), do: %{}

  def timeline_integrity_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_integrity_risks =
      Enum.filter(risks, &timeline_integrity_risk?/1)

    %{
      "timeline_integrity_risk_types" =>
        risk_context_values(timeline_integrity_risks, ["type", "risk_type"]),
      "timeline_integrity_activity_ids" =>
        risk_context_values(timeline_integrity_risks, "activity_id"),
      "timeline_integrity_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, "timeline_id"),
      "timeline_integrity_statuses" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_status"),
      "timeline_integrity_issue_count_values" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" =>
        risk_context_values(timeline_integrity_risks, ["timeline_integrity_issue_types"]),
      "timeline_integrity_issue_maps" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issues"),
      "timeline_integrity_missing_dependency_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_activity_ids"]),
      "timeline_integrity_missing_dependency_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_timeline_ids"]),
      "timeline_integrity_dependency_cycle_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_activity_ids"]),
      "timeline_integrity_dependency_cycle_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_timeline_ids"]),
      "timeline_integrity_dependency_order_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_activity_ids"
        ]),
      "timeline_integrity_dependency_order_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_timeline_ids"
        ]),
      "timeline_integrity_exclusivity_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_activity_ids"]),
      "timeline_integrity_exclusivity_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_timeline_ids"]),
      "timeline_integrity_exclusivity_violation_groups" =>
        risk_context_values(timeline_integrity_risks, "exclusivity_violation_group"),
      "timeline_integrity_required_operator_actions" =>
        risk_context_values(timeline_integrity_risks, "required_operator_action"),
      "timeline_integrity_feedback_sources" =>
        risk_context_values(timeline_integrity_risks, "feedback_source"),
      "timeline_integrity_feedback_scopes" =>
        risk_context_values(timeline_integrity_risks, "feedback_scope"),
      "timeline_integrity_feedback_keys" =>
        risk_context_values(timeline_integrity_risks, "feedback_key"),
      "timeline_integrity_trust_boundaries" =>
        risk_context_values(timeline_integrity_risks, "trust_boundary"),
      "timeline_integrity_derivation_reasons" =>
        risk_context_values(timeline_integrity_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_integrity_context(_risks), do: %{}

  def execution_success_feedback_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    execution_success_feedback_risks =
      Enum.filter(risks, &execution_success_feedback_risk?/1)

    %{
      "execution_success_feedback_risk_types" =>
        risk_context_values(execution_success_feedback_risks, ["type", "risk_type"]),
      "execution_success_feedback_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, "activity_id"),
      "execution_success_feedback_scenario_ids" =>
        risk_context_values(execution_success_feedback_risks, "scenario_id"),
      "execution_success_feedback_timeline_ids" =>
        risk_context_values(execution_success_feedback_risks, "timeline_id"),
      "execution_success_feedback_source_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "execution_success_feedback_replacement_activity_ids" =>
        risk_context_values(execution_success_feedback_risks, "replacement_activity_id"),
      "execution_success_feedback_command_success_factor_values" =>
        risk_context_values(execution_success_feedback_risks, "command_success_factor"),
      "execution_success_feedback_maneuver_success_factor_values" =>
        risk_context_values(execution_success_feedback_risks, "maneuver_success_factor"),
      "execution_success_feedback_command_results" =>
        risk_context_values(execution_success_feedback_risks, "command_result"),
      "execution_success_feedback_maneuver_results" =>
        risk_context_values(execution_success_feedback_risks, "maneuver_result"),
      "execution_success_feedback_realized_statuses" =>
        risk_context_values(execution_success_feedback_risks, "realized_status"),
      "execution_success_feedback_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "ground_station_id"),
      "execution_success_feedback_planned_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "planned_ground_station_id"),
      "execution_success_feedback_realized_ground_station_ids" =>
        risk_context_values(execution_success_feedback_risks, "realized_ground_station_id"),
      "execution_success_feedback_ground_station_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "ground_station_match_status"),
      "execution_success_feedback_directions" =>
        risk_context_values(execution_success_feedback_risks, "direction"),
      "execution_success_feedback_planned_directions" =>
        risk_context_values(execution_success_feedback_risks, "planned_direction"),
      "execution_success_feedback_realized_directions" =>
        risk_context_values(execution_success_feedback_risks, "realized_direction"),
      "execution_success_feedback_direction_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "direction_match_status"),
      "execution_success_feedback_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "source_window_id"),
      "execution_success_feedback_planned_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "planned_source_window_id"),
      "execution_success_feedback_realized_source_window_ids" =>
        risk_context_values(execution_success_feedback_risks, "realized_source_window_id"),
      "execution_success_feedback_source_window_match_statuses" =>
        risk_context_values(execution_success_feedback_risks, "source_window_match_status"),
      "execution_success_feedback_command_identity_mismatch_fields" =>
        risk_context_values(execution_success_feedback_risks, [
          "command_identity_mismatch_fields"
        ]),
      "execution_success_feedback_start_values_s" =>
        risk_context_values(execution_success_feedback_risks, "starts_at_s"),
      "execution_success_feedback_end_values_s" =>
        risk_context_values(execution_success_feedback_risks, "ends_at_s"),
      "execution_success_feedback_changed_fields" =>
        risk_context_values(execution_success_feedback_risks, ["changed_fields"]),
      "execution_success_feedback_status_transition_maps" =>
        risk_context_values(execution_success_feedback_risks, "status_transition"),
      "execution_success_feedback_transition_types" =>
        risk_context_values(execution_success_feedback_risks, "transition_type"),
      "execution_success_feedback_transition_categories" =>
        risk_context_values(execution_success_feedback_risks, "transition_category"),
      "execution_success_feedback_transition_reasons" =>
        risk_context_values(execution_success_feedback_risks, "transition_reason"),
      "execution_success_feedback_required_operator_actions" =>
        risk_context_values(execution_success_feedback_risks, "required_operator_action"),
      "execution_success_feedback_requires_operator_review_values" =>
        risk_context_values(execution_success_feedback_risks, "requires_operator_review"),
      "execution_success_feedback_feedback_sources" =>
        risk_context_values(execution_success_feedback_risks, "feedback_source"),
      "execution_success_feedback_feedback_scopes" =>
        risk_context_values(execution_success_feedback_risks, "feedback_scope"),
      "execution_success_feedback_feedback_keys" =>
        risk_context_values(execution_success_feedback_risks, "feedback_key"),
      "execution_success_feedback_trust_boundaries" =>
        risk_context_values(execution_success_feedback_risks, "trust_boundary"),
      "execution_success_feedback_derivation_reasons" =>
        risk_context_values(execution_success_feedback_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def execution_success_feedback_context(_risks), do: %{}

  def operational_feedback_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    operational_feedback_risks =
      Enum.filter(risks, &operational_feedback_risk?/1)

    %{
      "strategy_operational_feedback_risk_types" =>
        risk_context_values(operational_feedback_risks, ["type", "risk_type"]),
      "strategy_operational_feedback_activity_ids" =>
        risk_context_values(operational_feedback_risks, "activity_id"),
      "strategy_operational_feedback_scenario_ids" =>
        risk_context_values(operational_feedback_risks, "scenario_id"),
      "strategy_operational_feedback_timeline_ids" =>
        risk_context_values(operational_feedback_risks, "timeline_id"),
      "strategy_operational_feedback_source_activity_ids" =>
        risk_context_values(operational_feedback_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "strategy_operational_feedback_replacement_activity_ids" =>
        risk_context_values(operational_feedback_risks, "replacement_activity_id"),
      "strategy_operational_feedback_contact_success_factor_values" =>
        risk_context_values(operational_feedback_risks, "contact_success_factor"),
      "strategy_operational_feedback_observation_success_factor_values" =>
        risk_context_values(operational_feedback_risks, "observation_success_factor"),
      "strategy_operational_feedback_station_throughput_factor_values" =>
        risk_context_values(operational_feedback_risks, "station_throughput_factor"),
      "strategy_operational_feedback_contact_results" =>
        risk_context_values(operational_feedback_risks, "contact_result"),
      "strategy_operational_feedback_observation_results" =>
        risk_context_values(operational_feedback_risks, "observation_result"),
      "strategy_operational_feedback_realized_statuses" =>
        risk_context_values(operational_feedback_risks, "realized_status"),
      "strategy_operational_feedback_ground_station_ids" =>
        risk_context_values(operational_feedback_risks, "ground_station_id"),
      "strategy_operational_feedback_planned_ground_station_ids" =>
        risk_context_values(operational_feedback_risks, "planned_ground_station_id"),
      "strategy_operational_feedback_realized_ground_station_ids" =>
        risk_context_values(operational_feedback_risks, "realized_ground_station_id"),
      "strategy_operational_feedback_ground_station_match_statuses" =>
        risk_context_values(operational_feedback_risks, "ground_station_match_status"),
      "strategy_operational_feedback_directions" =>
        risk_context_values(operational_feedback_risks, "direction"),
      "strategy_operational_feedback_planned_directions" =>
        risk_context_values(operational_feedback_risks, "planned_direction"),
      "strategy_operational_feedback_realized_directions" =>
        risk_context_values(operational_feedback_risks, "realized_direction"),
      "strategy_operational_feedback_direction_match_statuses" =>
        risk_context_values(operational_feedback_risks, "direction_match_status"),
      "strategy_operational_feedback_source_window_ids" =>
        risk_context_values(operational_feedback_risks, "source_window_id"),
      "strategy_operational_feedback_planned_source_window_ids" =>
        risk_context_values(operational_feedback_risks, "planned_source_window_id"),
      "strategy_operational_feedback_realized_source_window_ids" =>
        risk_context_values(operational_feedback_risks, "realized_source_window_id"),
      "strategy_operational_feedback_source_window_match_statuses" =>
        risk_context_values(operational_feedback_risks, "source_window_match_status"),
      "strategy_operational_feedback_contact_identity_mismatch_fields" =>
        risk_context_values(operational_feedback_risks, ["contact_identity_mismatch_fields"]),
      "strategy_operational_feedback_target_ids" =>
        risk_context_values(operational_feedback_risks, "target_id"),
      "strategy_operational_feedback_planned_target_ids" =>
        risk_context_values(operational_feedback_risks, "planned_target_id"),
      "strategy_operational_feedback_realized_target_ids" =>
        risk_context_values(operational_feedback_risks, "realized_target_id"),
      "strategy_operational_feedback_target_match_statuses" =>
        risk_context_values(operational_feedback_risks, "target_match_status"),
      "strategy_operational_feedback_collection_ids" =>
        risk_context_values(operational_feedback_risks, [
          "collection_id",
          "collection_ids"
        ]),
      "strategy_operational_feedback_planned_collection_ids" =>
        risk_context_values(operational_feedback_risks, "planned_collection_id"),
      "strategy_operational_feedback_realized_collection_ids" =>
        risk_context_values(operational_feedback_risks, "realized_collection_id"),
      "strategy_operational_feedback_collection_match_statuses" =>
        risk_context_values(operational_feedback_risks, "collection_match_status"),
      "strategy_operational_feedback_product_ids" =>
        risk_context_values(operational_feedback_risks, ["product_id", "product_ids"]),
      "strategy_operational_feedback_planned_product_ids" =>
        risk_context_values(operational_feedback_risks, [
          "planned_product_id",
          "planned_product_ids"
        ]),
      "strategy_operational_feedback_realized_product_ids" =>
        risk_context_values(operational_feedback_risks, [
          "realized_product_id",
          "realized_product_ids"
        ]),
      "strategy_operational_feedback_product_match_statuses" =>
        risk_context_values(operational_feedback_risks, [
          "product_match_status",
          "product_ids_match_status"
        ]),
      "strategy_operational_feedback_payload_ids" =>
        risk_context_values(operational_feedback_risks, ["payload_id", "payload_ids"]),
      "strategy_operational_feedback_planned_payload_ids" =>
        risk_context_values(operational_feedback_risks, "planned_payload_id"),
      "strategy_operational_feedback_realized_payload_ids" =>
        risk_context_values(operational_feedback_risks, "realized_payload_id"),
      "strategy_operational_feedback_payload_match_statuses" =>
        risk_context_values(operational_feedback_risks, "payload_match_status"),
      "strategy_operational_feedback_instrument_ids" =>
        risk_context_values(operational_feedback_risks, ["instrument_id", "instrument_ids"]),
      "strategy_operational_feedback_planned_instrument_ids" =>
        risk_context_values(operational_feedback_risks, "planned_instrument_id"),
      "strategy_operational_feedback_realized_instrument_ids" =>
        risk_context_values(operational_feedback_risks, "realized_instrument_id"),
      "strategy_operational_feedback_instrument_match_statuses" =>
        risk_context_values(operational_feedback_risks, "instrument_match_status"),
      "strategy_operational_feedback_observation_identity_mismatch_fields" =>
        risk_context_values(operational_feedback_risks, [
          "observation_identity_mismatch_fields"
        ]),
      "strategy_operational_feedback_pointing_statuses" =>
        risk_context_values(operational_feedback_risks, "pointing_status"),
      "strategy_operational_feedback_pointing_error_values_deg" =>
        risk_context_values(operational_feedback_risks, "pointing_error_deg"),
      "strategy_operational_feedback_attitude_statuses" =>
        risk_context_values(operational_feedback_risks, "attitude_status"),
      "strategy_operational_feedback_attitude_error_values_deg" =>
        risk_context_values(operational_feedback_risks, "attitude_error_deg"),
      "strategy_operational_feedback_lighting_condition_match_statuses" =>
        risk_context_values(operational_feedback_risks, "lighting_condition_match_status"),
      "strategy_operational_feedback_planned_lighting_conditions" =>
        risk_context_values(operational_feedback_risks, "planned_lighting_condition"),
      "strategy_operational_feedback_realized_lighting_conditions" =>
        risk_context_values(operational_feedback_risks, "realized_lighting_condition"),
      "strategy_operational_feedback_lighting_condition_details" =>
        risk_context_values(operational_feedback_risks, "lighting_condition_detail"),
      "strategy_operational_feedback_lighting_confidence_values" =>
        risk_context_values(operational_feedback_risks, "lighting_confidence"),
      "strategy_operational_feedback_eclipse_overlap_fraction_values" =>
        risk_context_values(operational_feedback_risks, "eclipse_overlap_fraction"),
      "strategy_operational_feedback_image_quality_score_values" =>
        risk_context_values(operational_feedback_risks, "image_quality_score"),
      "strategy_operational_feedback_image_quality_statuses" =>
        risk_context_values(operational_feedback_risks, "image_quality_status"),
      "strategy_operational_feedback_image_quality_sources" =>
        risk_context_values(operational_feedback_risks, "image_quality_source"),
      "strategy_operational_feedback_cloud_cover_fraction_values" =>
        risk_context_values(operational_feedback_risks, "cloud_cover_fraction"),
      "strategy_operational_feedback_blur_score_values" =>
        risk_context_values(operational_feedback_risks, "blur_score"),
      "strategy_operational_feedback_actual_throughput_values_mb" =>
        risk_context_values(operational_feedback_risks, "actual_throughput_mb"),
      "strategy_operational_feedback_estimated_throughput_values_mb" =>
        risk_context_values(operational_feedback_risks, "estimated_throughput_mb"),
      "strategy_operational_feedback_start_values_s" =>
        risk_context_values(operational_feedback_risks, "starts_at_s"),
      "strategy_operational_feedback_end_values_s" =>
        risk_context_values(operational_feedback_risks, "ends_at_s"),
      "strategy_operational_feedback_changed_fields" =>
        risk_context_values(operational_feedback_risks, ["changed_fields"]),
      "strategy_operational_feedback_status_transition_maps" =>
        risk_context_values(operational_feedback_risks, "status_transition"),
      "strategy_operational_feedback_transition_types" =>
        risk_context_values(operational_feedback_risks, "transition_type"),
      "strategy_operational_feedback_transition_categories" =>
        risk_context_values(operational_feedback_risks, "transition_category"),
      "strategy_operational_feedback_transition_reasons" =>
        risk_context_values(operational_feedback_risks, "transition_reason"),
      "strategy_operational_feedback_required_operator_actions" =>
        risk_context_values(operational_feedback_risks, "required_operator_action"),
      "strategy_operational_feedback_requires_operator_review_values" =>
        risk_context_values(operational_feedback_risks, "requires_operator_review"),
      "strategy_operational_feedback_feedback_sources" =>
        risk_context_values(operational_feedback_risks, "feedback_source"),
      "strategy_operational_feedback_feedback_scopes" =>
        risk_context_values(operational_feedback_risks, "feedback_scope"),
      "strategy_operational_feedback_feedback_keys" =>
        risk_context_values(operational_feedback_risks, "feedback_key"),
      "strategy_operational_feedback_trust_boundaries" =>
        risk_context_values(operational_feedback_risks, "trust_boundary"),
      "strategy_operational_feedback_derivation_reasons" =>
        risk_context_values(operational_feedback_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def operational_feedback_context(_risks), do: %{}

  defp resource_margin_risk?(%{"resource_field" => field}) when is_binary(field) do
    field in [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c"
    ]
  end

  defp resource_margin_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "fuel_margin_low",
      "power_margin_low",
      "storage_margin_low",
      "downlink_margin_low",
      "thermal_margin_c_low"
    ]
  end

  defp resource_margin_risk?(_risk), do: false

  defp maneuver_execution_uncertainty_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "maneuver_execution_uncertainty_high",
      "maneuver_execution_uncertainty_missing"
    ]
  end

  defp maneuver_execution_uncertainty_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "maneuver_execution_uncertainty_high",
      "maneuver_execution_uncertainty_missing"
    ]
  end

  defp maneuver_execution_uncertainty_risk?(%{"feedback_scope" => scope})
       when scope == "maneuver_execution_uncertainty",
       do: true

  defp maneuver_execution_uncertainty_risk?(_risk), do: false

  defp timeline_integrity_risk?(%{"type" => "timeline_integrity_issue"}), do: true

  defp timeline_integrity_risk?(%{"risk_type" => "timeline_integrity_issue"}), do: true

  defp timeline_integrity_risk?(%{"feedback_scope" => "timeline_integrity"}), do: true

  defp timeline_integrity_risk?(_risk), do: false

  defp relay_data_path_risk?(%{"type" => "relay_data_path_pressure"}), do: true

  defp relay_data_path_risk?(%{"risk_type" => "relay_data_path_pressure"}), do: true

  defp relay_data_path_risk?(_risk), do: false

  defp link_capacity_risk?(%{"type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "link_capacity",
       do: true

  defp link_capacity_risk?(%{
         "risk_type" => "downlink_completion_gap",
         "feedback_scope" => scope
       })
       when scope == "link_capacity",
       do: true

  defp link_capacity_risk?(_risk), do: false

  defp contact_intent_risk?(%{"type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "contact_intent",
       do: true

  defp contact_intent_risk?(%{
         "risk_type" => "downlink_completion_gap",
         "feedback_scope" => scope
       })
       when scope == "contact_intent",
       do: true

  defp contact_intent_risk?(_risk), do: false

  defp station_calendar_risk?(%{"feedback_scope" => "station_calendar"}), do: true

  defp station_calendar_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "ground_station_reserved",
      "ground_station_outage",
      "reduced_downlink_capacity"
    ]
  end

  defp station_calendar_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "ground_station_reserved",
      "ground_station_outage",
      "reduced_downlink_capacity"
    ]
  end

  defp station_calendar_risk?(_risk), do: false

  defp execution_success_feedback_risk?(%{"type" => type}) when is_binary(type) do
    type in ["command_success_rate_low", "maneuver_success_rate_low"]
  end

  defp execution_success_feedback_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in ["command_success_rate_low", "maneuver_success_rate_low"]
  end

  defp execution_success_feedback_risk?(_risk), do: false

  defp operational_feedback_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "contact_success_rate_low",
      "observation_success_rate_low",
      "station_throughput_factor_low"
    ]
  end

  defp operational_feedback_risk?(%{"risk_type" => type}) when is_binary(type) do
    type in [
      "contact_success_rate_low",
      "observation_success_rate_low",
      "station_throughput_factor_low"
    ]
  end

  defp operational_feedback_risk?(_risk), do: false

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
