defmodule OrbitalDynamics.Schema.StrategyHandoffContracts do
  @moduledoc false

  @strategy_recommendation_source_field_pairs [
    {"subject_id", "recommended_branch_id"},
    {"branch_id", "recommended_branch_id"},
    {"recommended_branch_id", "recommended_branch_id"},
    {"ranked_branch_ids", "ranked_branch_ids"},
    {"approval_status", "approval_status"},
    {"reason", "reason"}
  ]
  @strategy_recommendation_source_count_fields [
    {"tradeoff_count", "tradeoffs"},
    {"risk_count", "risks_remaining"},
    {"approval_requirement_count", "requires_approval"}
  ]
  @branch_window_context_field_pairs [
    {"branch_source_window_ids", "branch_source_window_ids"},
    {"branch_source_window_count", "branch_source_window_count"},
    {"branch_source_window_bounds", "branch_source_window_bounds"},
    {"branch_source_window_bound_count", "branch_source_window_bound_count"},
    {"branch_untimed_source_window_ids", "branch_untimed_source_window_ids"},
    {"branch_untimed_source_window_count", "branch_untimed_source_window_count"},
    {"branch_partially_timed_source_window_ids", "branch_partially_timed_source_window_ids"},
    {"branch_partially_timed_source_window_count", "branch_partially_timed_source_window_count"},
    {"branch_source_window_timing_coverage_status",
     "branch_source_window_timing_coverage_status"},
    {"branch_earliest_starts_at_s", "branch_earliest_starts_at_s"},
    {"branch_latest_ends_at_s", "branch_latest_ends_at_s"}
  ]
  @branch_reservation_expiration_context_field_pairs [
    {"branch_station_reservation_expiration_statuses",
     "branch_station_reservation_expiration_statuses"}
  ]
  @approval_boundary_context_field_pairs [
    {"approval_boundary_ids", "approval_boundary_ids"},
    {"approval_boundary_statuses", "approval_boundary_statuses"},
    {"approval_boundary_reasons", "approval_boundary_reasons"},
    {"automation_boundaries", "automation_boundaries"},
    {"execution_boundaries", "execution_boundaries"},
    {"approval_boundary_import_classifications", "approval_boundary_import_classifications"},
    {"approval_boundary_required_operator_actions",
     "approval_boundary_required_operator_actions"},
    {"approval_boundary_required_authorities", "approval_boundary_required_authorities"},
    {"approval_boundary_policy_bundle_ids", "approval_boundary_policy_bundle_ids"},
    {"approval_boundary_rule_ids", "approval_boundary_rule_ids"},
    {"approval_boundary_feedback_sources", "approval_boundary_feedback_sources"},
    {"approval_boundary_feedback_scopes", "approval_boundary_feedback_scopes"},
    {"approval_boundary_feedback_keys", "approval_boundary_feedback_keys"},
    {"approval_boundary_trust_boundaries", "approval_boundary_trust_boundaries"}
  ]
  @provider_reservation_request_context_field_pairs [
    {"provider_reservation_request_contact_ids", "provider_reservation_request_contact_ids"},
    {"provider_reservation_request_source_activity_ids",
     "provider_reservation_request_source_activity_ids"},
    {"provider_reservation_request_ground_station_ids",
     "provider_reservation_request_ground_station_ids"},
    {"provider_reservation_request_directions", "provider_reservation_request_directions"},
    {"provider_reservation_request_station_reservation_ids",
     "provider_reservation_request_station_reservation_ids"},
    {"provider_reservation_request_station_reserved_by",
     "provider_reservation_request_station_reserved_by"},
    {"provider_reservation_request_station_reservation_statuses",
     "provider_reservation_request_station_reservation_statuses"},
    {"provider_reservation_request_station_reservation_match_statuses",
     "provider_reservation_request_station_reservation_match_statuses"},
    {"provider_reservation_request_statuses", "provider_reservation_request_statuses"},
    {"provider_reservation_request_row_scopes", "provider_reservation_request_row_scopes"},
    {"provider_reservation_request_required_operator_actions",
     "provider_reservation_request_required_operator_actions"},
    {"provider_reservation_request_assumption_maps",
     "provider_reservation_request_assumption_maps"},
    {"provider_reservation_request_feedback_sources",
     "provider_reservation_request_feedback_sources"},
    {"provider_reservation_request_feedback_scopes",
     "provider_reservation_request_feedback_scopes"},
    {"provider_reservation_request_trust_boundaries",
     "provider_reservation_request_trust_boundaries"},
    {"provider_reservation_request_station_reservation_expiration_statuses",
     "provider_reservation_request_station_reservation_expiration_statuses"}
  ]
  @capacity_pack_context_field_pairs [
    {"capacity_pack_risk_contact_ids", "capacity_pack_risk_contact_ids"},
    {"capacity_pack_risk_source_activity_ids", "capacity_pack_risk_source_activity_ids"},
    {"capacity_pack_risk_ground_station_ids", "capacity_pack_risk_ground_station_ids"},
    {"capacity_pack_risk_group_ids", "capacity_pack_risk_group_ids"},
    {"capacity_pack_risk_statuses", "capacity_pack_risk_statuses"},
    {"capacity_pack_risk_capacity_fraction_values",
     "capacity_pack_risk_capacity_fraction_values"},
    {"capacity_pack_risk_used_fraction_values", "capacity_pack_risk_used_fraction_values"},
    {"capacity_pack_risk_unused_fraction_values", "capacity_pack_risk_unused_fraction_values"},
    {"capacity_pack_risk_required_capacity_fraction_values",
     "capacity_pack_risk_required_capacity_fraction_values"},
    {"capacity_pack_risk_required_capacity_fraction_sources",
     "capacity_pack_risk_required_capacity_fraction_sources"},
    {"capacity_pack_risk_derivation_reasons", "capacity_pack_risk_derivation_reasons"},
    {"capacity_pack_risk_feedback_sources", "capacity_pack_risk_feedback_sources"},
    {"capacity_pack_risk_feedback_scopes", "capacity_pack_risk_feedback_scopes"},
    {"capacity_pack_risk_trust_boundaries", "capacity_pack_risk_trust_boundaries"}
  ]
  @contact_contention_resolution_context_field_pairs [
    {"contact_contention_resolution_pressure_risk_types",
     "contact_contention_resolution_pressure_risk_types"},
    {"contact_contention_resolution_pressure_contact_ids",
     "contact_contention_resolution_pressure_contact_ids"},
    {"contact_contention_resolution_pressure_selected_contact_ids",
     "contact_contention_resolution_pressure_selected_contact_ids"},
    {"contact_contention_resolution_pressure_scenario_ids",
     "contact_contention_resolution_pressure_scenario_ids"},
    {"contact_contention_resolution_pressure_spacecraft_ids",
     "contact_contention_resolution_pressure_spacecraft_ids"},
    {"contact_contention_resolution_pressure_ground_station_ids",
     "contact_contention_resolution_pressure_ground_station_ids"},
    {"contact_contention_resolution_pressure_source_activity_ids",
     "contact_contention_resolution_pressure_source_activity_ids"},
    {"contact_contention_resolution_pressure_source_window_ids",
     "contact_contention_resolution_pressure_source_window_ids"},
    {"contact_contention_resolution_pressure_required_contact_values",
     "contact_contention_resolution_pressure_required_contact_values"},
    {"contact_contention_resolution_pressure_planned_contact_values",
     "contact_contention_resolution_pressure_planned_contact_values"},
    {"contact_contention_resolution_pressure_required_downlink_values_mb",
     "contact_contention_resolution_pressure_required_downlink_values_mb"},
    {"contact_contention_resolution_pressure_planned_downlink_values_mb",
     "contact_contention_resolution_pressure_planned_downlink_values_mb"},
    {"contact_contention_resolution_pressure_start_values_s",
     "contact_contention_resolution_pressure_start_values_s"},
    {"contact_contention_resolution_pressure_end_values_s",
     "contact_contention_resolution_pressure_end_values_s"},
    {"contact_contention_resolution_pressure_selected_priority_sources",
     "contact_contention_resolution_pressure_selected_priority_sources"},
    {"contact_contention_resolution_pressure_selection_reasons",
     "contact_contention_resolution_pressure_selection_reasons"},
    {"contact_contention_resolution_pressure_resolution_selection_rules",
     "contact_contention_resolution_pressure_resolution_selection_rules"},
    {"contact_contention_resolution_pressure_priority_override_count_values",
     "contact_contention_resolution_pressure_priority_override_count_values"},
    {"contact_contention_resolution_pressure_priority_override_contact_ids",
     "contact_contention_resolution_pressure_priority_override_contact_ids"},
    {"contact_contention_resolution_pressure_review_statuses",
     "contact_contention_resolution_pressure_review_statuses"},
    {"contact_contention_resolution_pressure_downlink_demand_sources",
     "contact_contention_resolution_pressure_downlink_demand_sources"},
    {"contact_contention_resolution_pressure_downlink_completion_sources",
     "contact_contention_resolution_pressure_downlink_completion_sources"},
    {"contact_contention_resolution_pressure_feedback_sources",
     "contact_contention_resolution_pressure_feedback_sources"},
    {"contact_contention_resolution_pressure_feedback_scopes",
     "contact_contention_resolution_pressure_feedback_scopes"},
    {"contact_contention_resolution_pressure_trust_boundaries",
     "contact_contention_resolution_pressure_trust_boundaries"},
    {"contact_contention_resolution_pressure_derivation_reasons",
     "contact_contention_resolution_pressure_derivation_reasons"}
  ]
  @contact_contention_context_field_pairs [
    {"contact_contention_pressure_risk_types", "contact_contention_pressure_risk_types"},
    {"contact_contention_pressure_contact_ids", "contact_contention_pressure_contact_ids"},
    {"contact_contention_pressure_scenario_ids", "contact_contention_pressure_scenario_ids"},
    {"contact_contention_pressure_spacecraft_ids", "contact_contention_pressure_spacecraft_ids"},
    {"contact_contention_pressure_ground_station_ids",
     "contact_contention_pressure_ground_station_ids"},
    {"contact_contention_pressure_source_activity_ids",
     "contact_contention_pressure_source_activity_ids"},
    {"contact_contention_pressure_source_window_ids",
     "contact_contention_pressure_source_window_ids"},
    {"contact_contention_pressure_required_contact_values",
     "contact_contention_pressure_required_contact_values"},
    {"contact_contention_pressure_planned_contact_values",
     "contact_contention_pressure_planned_contact_values"},
    {"contact_contention_pressure_required_downlink_values_mb",
     "contact_contention_pressure_required_downlink_values_mb"},
    {"contact_contention_pressure_planned_downlink_values_mb",
     "contact_contention_pressure_planned_downlink_values_mb"},
    {"contact_contention_pressure_start_values_s", "contact_contention_pressure_start_values_s"},
    {"contact_contention_pressure_end_values_s", "contact_contention_pressure_end_values_s"},
    {"contact_contention_pressure_group_ids", "contact_contention_pressure_group_ids"},
    {"contact_contention_pressure_resource_scopes",
     "contact_contention_pressure_resource_scopes"},
    {"contact_contention_pressure_contention_contact_ids",
     "contact_contention_pressure_contention_contact_ids"},
    {"contact_contention_pressure_required_operator_actions",
     "contact_contention_pressure_required_operator_actions"},
    {"contact_contention_pressure_approval_statuses",
     "contact_contention_pressure_approval_statuses"},
    {"contact_contention_pressure_operator_action_reasons",
     "contact_contention_pressure_operator_action_reasons"},
    {"contact_contention_pressure_downlink_demand_sources",
     "contact_contention_pressure_downlink_demand_sources"},
    {"contact_contention_pressure_downlink_completion_sources",
     "contact_contention_pressure_downlink_completion_sources"},
    {"contact_contention_pressure_feedback_sources",
     "contact_contention_pressure_feedback_sources"},
    {"contact_contention_pressure_feedback_scopes",
     "contact_contention_pressure_feedback_scopes"},
    {"contact_contention_pressure_trust_boundaries",
     "contact_contention_pressure_trust_boundaries"},
    {"contact_contention_pressure_derivation_reasons",
     "contact_contention_pressure_derivation_reasons"}
  ]
  @contact_filter_context_field_pairs [
    {"contact_filter_pressure_risk_types", "contact_filter_pressure_risk_types"},
    {"contact_filter_pressure_contact_ids", "contact_filter_pressure_contact_ids"},
    {"contact_filter_pressure_scenario_ids", "contact_filter_pressure_scenario_ids"},
    {"contact_filter_pressure_spacecraft_ids", "contact_filter_pressure_spacecraft_ids"},
    {"contact_filter_pressure_ground_station_ids", "contact_filter_pressure_ground_station_ids"},
    {"contact_filter_pressure_source_activity_ids",
     "contact_filter_pressure_source_activity_ids"},
    {"contact_filter_pressure_source_window_ids", "contact_filter_pressure_source_window_ids"},
    {"contact_filter_pressure_required_contact_values",
     "contact_filter_pressure_required_contact_values"},
    {"contact_filter_pressure_planned_contact_values",
     "contact_filter_pressure_planned_contact_values"},
    {"contact_filter_pressure_required_downlink_values_mb",
     "contact_filter_pressure_required_downlink_values_mb"},
    {"contact_filter_pressure_planned_downlink_values_mb",
     "contact_filter_pressure_planned_downlink_values_mb"},
    {"contact_filter_pressure_start_values_s", "contact_filter_pressure_start_values_s"},
    {"contact_filter_pressure_end_values_s", "contact_filter_pressure_end_values_s"},
    {"contact_filter_pressure_suppressed_reasons", "contact_filter_pressure_suppressed_reasons"},
    {"contact_filter_pressure_review_statuses", "contact_filter_pressure_review_statuses"},
    {"contact_filter_pressure_station_reservation_ids",
     "contact_filter_pressure_station_reservation_ids"},
    {"contact_filter_pressure_station_reserved_by",
     "contact_filter_pressure_station_reserved_by"},
    {"contact_filter_pressure_station_reservation_statuses",
     "contact_filter_pressure_station_reservation_statuses"},
    {"contact_filter_pressure_station_reservation_match_statuses",
     "contact_filter_pressure_station_reservation_match_statuses"},
    {"contact_filter_pressure_station_calendar_entry_ids",
     "contact_filter_pressure_station_calendar_entry_ids"},
    {"contact_filter_pressure_station_calendar_entry_statuses",
     "contact_filter_pressure_station_calendar_entry_statuses"},
    {"contact_filter_pressure_downlink_demand_sources",
     "contact_filter_pressure_downlink_demand_sources"},
    {"contact_filter_pressure_downlink_completion_sources",
     "contact_filter_pressure_downlink_completion_sources"},
    {"contact_filter_pressure_feedback_sources", "contact_filter_pressure_feedback_sources"},
    {"contact_filter_pressure_feedback_scopes", "contact_filter_pressure_feedback_scopes"},
    {"contact_filter_pressure_trust_boundaries", "contact_filter_pressure_trust_boundaries"},
    {"contact_filter_pressure_derivation_reasons", "contact_filter_pressure_derivation_reasons"}
  ]
  @resource_filter_context_field_pairs [
    {"resource_filter_pressure_risk_types", "resource_filter_pressure_risk_types"},
    {"resource_filter_pressure_scenario_ids", "resource_filter_pressure_scenario_ids"},
    {"resource_filter_pressure_spacecraft_ids", "resource_filter_pressure_spacecraft_ids"},
    {"resource_filter_pressure_resource_fields", "resource_filter_pressure_resource_fields"},
    {"resource_filter_pressure_available_values", "resource_filter_pressure_available_values"},
    {"resource_filter_pressure_source_activity_ids",
     "resource_filter_pressure_source_activity_ids"},
    {"resource_filter_pressure_start_values_s", "resource_filter_pressure_start_values_s"},
    {"resource_filter_pressure_end_values_s", "resource_filter_pressure_end_values_s"},
    {"resource_filter_pressure_suppressed_reasons",
     "resource_filter_pressure_suppressed_reasons"},
    {"resource_filter_pressure_source_quality_values",
     "resource_filter_pressure_source_quality_values"},
    {"resource_filter_pressure_resource_trust_boundary_statuses",
     "resource_filter_pressure_resource_trust_boundary_statuses"},
    {"resource_filter_pressure_fuel_margin_values",
     "resource_filter_pressure_fuel_margin_values"},
    {"resource_filter_pressure_fuel_margin_threshold_values",
     "resource_filter_pressure_fuel_margin_threshold_values"},
    {"resource_filter_pressure_power_margin_values",
     "resource_filter_pressure_power_margin_values"},
    {"resource_filter_pressure_power_margin_threshold_values",
     "resource_filter_pressure_power_margin_threshold_values"},
    {"resource_filter_pressure_storage_margin_values",
     "resource_filter_pressure_storage_margin_values"},
    {"resource_filter_pressure_storage_margin_threshold_values",
     "resource_filter_pressure_storage_margin_threshold_values"},
    {"resource_filter_pressure_downlink_margin_values",
     "resource_filter_pressure_downlink_margin_values"},
    {"resource_filter_pressure_downlink_margin_threshold_values",
     "resource_filter_pressure_downlink_margin_threshold_values"},
    {"resource_filter_pressure_thermal_margin_values_c",
     "resource_filter_pressure_thermal_margin_values_c"},
    {"resource_filter_pressure_thermal_margin_threshold_values_c",
     "resource_filter_pressure_thermal_margin_threshold_values_c"},
    {"resource_filter_pressure_operator_training_requirement_count_values",
     "resource_filter_pressure_operator_training_requirement_count_values"},
    {"resource_filter_pressure_required_operator_roles",
     "resource_filter_pressure_required_operator_roles"},
    {"resource_filter_pressure_feedback_sources", "resource_filter_pressure_feedback_sources"},
    {"resource_filter_pressure_feedback_scopes", "resource_filter_pressure_feedback_scopes"},
    {"resource_filter_pressure_trust_boundaries", "resource_filter_pressure_trust_boundaries"},
    {"resource_filter_pressure_derivation_reasons", "resource_filter_pressure_derivation_reasons"}
  ]
  @resource_margin_context_field_pairs [
    {"resource_margin_risk_types", "resource_margin_risk_types"},
    {"resource_margin_spacecraft_ids", "resource_margin_spacecraft_ids"},
    {"resource_margin_scenario_ids", "resource_margin_scenario_ids"},
    {"resource_margin_timeline_ids", "resource_margin_timeline_ids"},
    {"resource_margin_source_activity_ids", "resource_margin_source_activity_ids"},
    {"resource_margin_replacement_activity_ids", "resource_margin_replacement_activity_ids"},
    {"resource_margin_fields", "resource_margin_fields"},
    {"resource_margin_values", "resource_margin_values"},
    {"resource_margin_threshold_values", "resource_margin_threshold_values"},
    {"resource_margin_field_value_maps", "resource_margin_field_value_maps"},
    {"resource_margin_source_quality_values", "resource_margin_source_quality_values"},
    {"resource_margin_start_values_s", "resource_margin_start_values_s"},
    {"resource_margin_end_values_s", "resource_margin_end_values_s"},
    {"resource_margin_diff_statuses", "resource_margin_diff_statuses"},
    {"resource_margin_changed_fields", "resource_margin_changed_fields"},
    {"resource_margin_required_operator_actions", "resource_margin_required_operator_actions"},
    {"resource_margin_requires_operator_review_values",
     "resource_margin_requires_operator_review_values"},
    {"resource_margin_feedback_sources", "resource_margin_feedback_sources"},
    {"resource_margin_feedback_scopes", "resource_margin_feedback_scopes"},
    {"resource_margin_feedback_keys", "resource_margin_feedback_keys"},
    {"resource_margin_trust_boundaries", "resource_margin_trust_boundaries"},
    {"resource_margin_derivation_reasons", "resource_margin_derivation_reasons"}
  ]
  @resource_projection_context_field_pairs [
    {"resource_projection_pressure_risk_types", "resource_projection_pressure_risk_types"},
    {"resource_projection_pressure_scenario_ids", "resource_projection_pressure_scenario_ids"},
    {"resource_projection_pressure_spacecraft_ids",
     "resource_projection_pressure_spacecraft_ids"},
    {"resource_projection_pressure_ground_station_ids",
     "resource_projection_pressure_ground_station_ids"},
    {"resource_projection_pressure_resource_fields",
     "resource_projection_pressure_resource_fields"},
    {"resource_projection_pressure_source_activity_ids",
     "resource_projection_pressure_source_activity_ids"},
    {"resource_projection_pressure_required_contact_values",
     "resource_projection_pressure_required_contact_values"},
    {"resource_projection_pressure_planned_contact_values",
     "resource_projection_pressure_planned_contact_values"},
    {"resource_projection_pressure_required_downlink_values_mb",
     "resource_projection_pressure_required_downlink_values_mb"},
    {"resource_projection_pressure_planned_downlink_values_mb",
     "resource_projection_pressure_planned_downlink_values_mb"},
    {"resource_projection_pressure_start_values_s",
     "resource_projection_pressure_start_values_s"},
    {"resource_projection_pressure_end_values_s", "resource_projection_pressure_end_values_s"},
    {"resource_projection_pressure_downlink_demand_sources",
     "resource_projection_pressure_downlink_demand_sources"},
    {"resource_projection_pressure_downlink_completion_sources",
     "resource_projection_pressure_downlink_completion_sources"},
    {"resource_projection_pressure_available_values",
     "resource_projection_pressure_available_values"},
    {"resource_projection_pressure_degraded_values",
     "resource_projection_pressure_degraded_values"},
    {"resource_projection_pressure_payload_available_values",
     "resource_projection_pressure_payload_available_values"},
    {"resource_projection_pressure_spacecraft_available_values",
     "resource_projection_pressure_spacecraft_available_values"},
    {"resource_projection_pressure_antenna_available_values",
     "resource_projection_pressure_antenna_available_values"},
    {"resource_projection_pressure_modes", "resource_projection_pressure_modes"},
    {"resource_projection_pressure_incompatible_activity_types",
     "resource_projection_pressure_incompatible_activity_types"},
    {"resource_projection_pressure_storage_margin_values",
     "resource_projection_pressure_storage_margin_values"},
    {"resource_projection_pressure_storage_margin_threshold_values",
     "resource_projection_pressure_storage_margin_threshold_values"},
    {"resource_projection_pressure_projected_storage_overflow_values_mb",
     "resource_projection_pressure_projected_storage_overflow_values_mb"},
    {"resource_projection_pressure_downlink_margin_values",
     "resource_projection_pressure_downlink_margin_values"},
    {"resource_projection_pressure_downlink_margin_threshold_values",
     "resource_projection_pressure_downlink_margin_threshold_values"},
    {"resource_projection_pressure_projected_downlink_shortfall_values_mb",
     "resource_projection_pressure_projected_downlink_shortfall_values_mb"},
    {"resource_projection_pressure_power_margin_values",
     "resource_projection_pressure_power_margin_values"},
    {"resource_projection_pressure_power_margin_threshold_values",
     "resource_projection_pressure_power_margin_threshold_values"},
    {"resource_projection_pressure_projected_battery_overuse_values_wh",
     "resource_projection_pressure_projected_battery_overuse_values_wh"},
    {"resource_projection_pressure_thermal_margin_values_c",
     "resource_projection_pressure_thermal_margin_values_c"},
    {"resource_projection_pressure_thermal_margin_threshold_values_c",
     "resource_projection_pressure_thermal_margin_threshold_values_c"},
    {"resource_projection_pressure_source_quality_values",
     "resource_projection_pressure_source_quality_values"},
    {"resource_projection_pressure_feedback_sources",
     "resource_projection_pressure_feedback_sources"},
    {"resource_projection_pressure_feedback_scopes",
     "resource_projection_pressure_feedback_scopes"},
    {"resource_projection_pressure_trust_boundaries",
     "resource_projection_pressure_trust_boundaries"},
    {"resource_projection_pressure_derivation_reasons",
     "resource_projection_pressure_derivation_reasons"}
  ]
  @execution_success_feedback_context_field_pairs [
    {"execution_success_feedback_risk_types", "execution_success_feedback_risk_types"},
    {"execution_success_feedback_activity_ids", "execution_success_feedback_activity_ids"},
    {"execution_success_feedback_scenario_ids", "execution_success_feedback_scenario_ids"},
    {"execution_success_feedback_timeline_ids", "execution_success_feedback_timeline_ids"},
    {"execution_success_feedback_source_activity_ids",
     "execution_success_feedback_source_activity_ids"},
    {"execution_success_feedback_replacement_activity_ids",
     "execution_success_feedback_replacement_activity_ids"},
    {"execution_success_feedback_command_success_factor_values",
     "execution_success_feedback_command_success_factor_values"},
    {"execution_success_feedback_maneuver_success_factor_values",
     "execution_success_feedback_maneuver_success_factor_values"},
    {"execution_success_feedback_command_results", "execution_success_feedback_command_results"},
    {"execution_success_feedback_maneuver_results",
     "execution_success_feedback_maneuver_results"},
    {"execution_success_feedback_realized_statuses",
     "execution_success_feedback_realized_statuses"},
    {"execution_success_feedback_ground_station_ids",
     "execution_success_feedback_ground_station_ids"},
    {"execution_success_feedback_planned_ground_station_ids",
     "execution_success_feedback_planned_ground_station_ids"},
    {"execution_success_feedback_realized_ground_station_ids",
     "execution_success_feedback_realized_ground_station_ids"},
    {"execution_success_feedback_ground_station_match_statuses",
     "execution_success_feedback_ground_station_match_statuses"},
    {"execution_success_feedback_directions", "execution_success_feedback_directions"},
    {"execution_success_feedback_planned_directions",
     "execution_success_feedback_planned_directions"},
    {"execution_success_feedback_realized_directions",
     "execution_success_feedback_realized_directions"},
    {"execution_success_feedback_direction_match_statuses",
     "execution_success_feedback_direction_match_statuses"},
    {"execution_success_feedback_source_window_ids",
     "execution_success_feedback_source_window_ids"},
    {"execution_success_feedback_planned_source_window_ids",
     "execution_success_feedback_planned_source_window_ids"},
    {"execution_success_feedback_realized_source_window_ids",
     "execution_success_feedback_realized_source_window_ids"},
    {"execution_success_feedback_source_window_match_statuses",
     "execution_success_feedback_source_window_match_statuses"},
    {"execution_success_feedback_command_identity_mismatch_fields",
     "execution_success_feedback_command_identity_mismatch_fields"},
    {"execution_success_feedback_start_values_s", "execution_success_feedback_start_values_s"},
    {"execution_success_feedback_end_values_s", "execution_success_feedback_end_values_s"},
    {"execution_success_feedback_changed_fields", "execution_success_feedback_changed_fields"},
    {"execution_success_feedback_status_transition_maps",
     "execution_success_feedback_status_transition_maps"},
    {"execution_success_feedback_transition_types",
     "execution_success_feedback_transition_types"},
    {"execution_success_feedback_transition_categories",
     "execution_success_feedback_transition_categories"},
    {"execution_success_feedback_transition_reasons",
     "execution_success_feedback_transition_reasons"},
    {"execution_success_feedback_required_operator_actions",
     "execution_success_feedback_required_operator_actions"},
    {"execution_success_feedback_requires_operator_review_values",
     "execution_success_feedback_requires_operator_review_values"},
    {"execution_success_feedback_feedback_sources",
     "execution_success_feedback_feedback_sources"},
    {"execution_success_feedback_feedback_scopes", "execution_success_feedback_feedback_scopes"},
    {"execution_success_feedback_feedback_keys", "execution_success_feedback_feedback_keys"},
    {"execution_success_feedback_trust_boundaries",
     "execution_success_feedback_trust_boundaries"},
    {"execution_success_feedback_derivation_reasons",
     "execution_success_feedback_derivation_reasons"}
  ]
  @timeline_dependency_impact_context_field_pairs [
    {"timeline_dependency_impact_activity_ids", "timeline_dependency_impact_activity_ids"},
    {"timeline_dependency_impact_timeline_ids", "timeline_dependency_impact_timeline_ids"},
    {"timeline_dependency_impact_scopes", "timeline_dependency_impact_scopes"},
    {"timeline_dependency_impact_statuses", "timeline_dependency_impact_statuses"},
    {"timeline_dependency_impact_required_operator_actions",
     "timeline_dependency_impact_required_operator_actions"},
    {"timeline_dependency_impact_operator_action_reasons",
     "timeline_dependency_impact_operator_action_reasons"},
    {"timeline_dependency_impact_dependency_activity_ids",
     "timeline_dependency_impact_dependency_activity_ids"},
    {"timeline_dependency_impact_dependency_timeline_ids",
     "timeline_dependency_impact_dependency_timeline_ids"},
    {"timeline_dependency_impact_exclusive_with_activity_ids",
     "timeline_dependency_impact_exclusive_with_activity_ids"},
    {"timeline_dependency_impact_exclusive_with_timeline_ids",
     "timeline_dependency_impact_exclusive_with_timeline_ids"},
    {"timeline_dependency_impact_impacted_dependency_activity_ids",
     "timeline_dependency_impact_impacted_dependency_activity_ids"},
    {"timeline_dependency_impact_impacted_dependency_timeline_ids",
     "timeline_dependency_impact_impacted_dependency_timeline_ids"},
    {"timeline_dependency_impact_impacted_exclusive_with_activity_ids",
     "timeline_dependency_impact_impacted_exclusive_with_activity_ids"},
    {"timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
     "timeline_dependency_impact_impacted_exclusive_with_timeline_ids"},
    {"timeline_dependency_impact_feedback_sources",
     "timeline_dependency_impact_feedback_sources"},
    {"timeline_dependency_impact_feedback_scopes", "timeline_dependency_impact_feedback_scopes"},
    {"timeline_dependency_impact_feedback_keys", "timeline_dependency_impact_feedback_keys"},
    {"timeline_dependency_impact_trust_boundaries",
     "timeline_dependency_impact_trust_boundaries"},
    {"timeline_dependency_impact_derivation_reasons",
     "timeline_dependency_impact_derivation_reasons"}
  ]
  @timeline_publication_context_field_pairs [
    {"timeline_publication_ids", "timeline_publication_ids"},
    {"timeline_publication_sequences", "timeline_publication_sequences"},
    {"timeline_publication_statuses", "timeline_publication_statuses"},
    {"timeline_publication_downstream_invalidation_statuses",
     "timeline_publication_downstream_invalidation_statuses"},
    {"timeline_publication_dependency_impact_statuses",
     "timeline_publication_dependency_impact_statuses"},
    {"timeline_publication_source_artifact_ids", "timeline_publication_source_artifact_ids"},
    {"timeline_publication_source_artifact_types", "timeline_publication_source_artifact_types"},
    {"timeline_publication_authorities", "timeline_publication_authorities"},
    {"timeline_publication_supersedes_artifact_ids",
     "timeline_publication_supersedes_artifact_ids"},
    {"timeline_publication_downstream_product_ids",
     "timeline_publication_downstream_product_ids"},
    {"timeline_publication_invalidated_downstream_product_ids",
     "timeline_publication_invalidated_downstream_product_ids"},
    {"timeline_publication_downstream_invalidation_reason_count_maps",
     "timeline_publication_downstream_invalidation_reason_count_maps"},
    {"timeline_publication_downstream_invalidation_reasons",
     "timeline_publication_downstream_invalidation_reasons"},
    {"timeline_publication_invalidated_downstream_product_ids_by_reason",
     "timeline_publication_invalidated_downstream_product_ids_by_reason"},
    {"timeline_publication_dependency_impact_row_count_values",
     "timeline_publication_dependency_impact_row_count_values"},
    {"timeline_publication_timeline_diff_row_count_values",
     "timeline_publication_timeline_diff_row_count_values"},
    {"timeline_publication_timeline_diff_changed_count_values",
     "timeline_publication_timeline_diff_changed_count_values"},
    {"timeline_publication_timeline_diff_review_required_count_values",
     "timeline_publication_timeline_diff_review_required_count_values"},
    {"timeline_publication_changed_field_count_maps",
     "timeline_publication_changed_field_count_maps"},
    {"timeline_publication_changed_fields", "timeline_publication_changed_fields"},
    {"timeline_publication_changed_timeline_ids", "timeline_publication_changed_timeline_ids"},
    {"timeline_publication_review_timeline_ids", "timeline_publication_review_timeline_ids"},
    {"timeline_publication_timeline_ids_by_changed_field",
     "timeline_publication_timeline_ids_by_changed_field"},
    {"timeline_publication_feedback_sources", "timeline_publication_feedback_sources"},
    {"timeline_publication_feedback_scopes", "timeline_publication_feedback_scopes"},
    {"timeline_publication_feedback_keys", "timeline_publication_feedback_keys"},
    {"timeline_publication_trust_boundaries", "timeline_publication_trust_boundaries"},
    {"timeline_publication_derivation_reasons", "timeline_publication_derivation_reasons"},
    {"timeline_publication_assumption_maps", "timeline_publication_assumption_maps"}
  ]
  @maneuver_execution_uncertainty_context_field_pairs [
    {"maneuver_execution_uncertainty_risk_types", "maneuver_execution_uncertainty_risk_types"},
    {"maneuver_execution_uncertainty_activity_ids",
     "maneuver_execution_uncertainty_activity_ids"},
    {"maneuver_execution_uncertainty_timeline_ids",
     "maneuver_execution_uncertainty_timeline_ids"},
    {"maneuver_execution_uncertainty_maneuver_ids",
     "maneuver_execution_uncertainty_maneuver_ids"},
    {"maneuver_execution_uncertainty_scenario_ids",
     "maneuver_execution_uncertainty_scenario_ids"},
    {"maneuver_execution_uncertainty_source_activity_ids",
     "maneuver_execution_uncertainty_source_activity_ids"},
    {"maneuver_execution_uncertainty_replacement_activity_ids",
     "maneuver_execution_uncertainty_replacement_activity_ids"},
    {"maneuver_execution_uncertainty_statuses", "maneuver_execution_uncertainty_statuses"},
    {"maneuver_execution_uncertainty_sources", "maneuver_execution_uncertainty_sources"},
    {"maneuver_execution_uncertainty_maps", "maneuver_execution_uncertainty_maps"},
    {"maneuver_execution_uncertainty_timing_3sigma_values_s",
     "maneuver_execution_uncertainty_timing_3sigma_values_s"},
    {"maneuver_execution_uncertainty_timing_3sigma_threshold_values_s",
     "maneuver_execution_uncertainty_timing_3sigma_threshold_values_s"},
    {"maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s",
     "maneuver_execution_uncertainty_delta_v_3sigma_vectors_km_s"},
    {"maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_values_km_s"},
    {"maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s",
     "maneuver_execution_uncertainty_delta_v_3sigma_magnitude_threshold_values_km_s"},
    {"maneuver_execution_uncertainty_start_values_s",
     "maneuver_execution_uncertainty_start_values_s"},
    {"maneuver_execution_uncertainty_end_values_s",
     "maneuver_execution_uncertainty_end_values_s"},
    {"maneuver_execution_uncertainty_changed_fields",
     "maneuver_execution_uncertainty_changed_fields"},
    {"maneuver_execution_uncertainty_required_operator_actions",
     "maneuver_execution_uncertainty_required_operator_actions"},
    {"maneuver_execution_uncertainty_requires_operator_review_values",
     "maneuver_execution_uncertainty_requires_operator_review_values"},
    {"maneuver_execution_uncertainty_feedback_sources",
     "maneuver_execution_uncertainty_feedback_sources"},
    {"maneuver_execution_uncertainty_feedback_scopes",
     "maneuver_execution_uncertainty_feedback_scopes"},
    {"maneuver_execution_uncertainty_feedback_keys",
     "maneuver_execution_uncertainty_feedback_keys"},
    {"maneuver_execution_uncertainty_trust_boundaries",
     "maneuver_execution_uncertainty_trust_boundaries"},
    {"maneuver_execution_uncertainty_derivation_reasons",
     "maneuver_execution_uncertainty_derivation_reasons"}
  ]
  @relay_data_path_context_field_pairs [
    {"relay_data_path_risk_types", "relay_data_path_risk_types"},
    {"relay_data_path_ground_station_ids", "relay_data_path_ground_station_ids"},
    {"relay_data_path_route_ids", "relay_data_path_route_ids"},
    {"relay_data_path_source_spacecraft_ids", "relay_data_path_source_spacecraft_ids"},
    {"relay_data_path_relay_spacecraft_ids", "relay_data_path_relay_spacecraft_ids"},
    {"relay_data_path_relay_chain_spacecraft_ids", "relay_data_path_relay_chain_spacecraft_ids"},
    {"relay_data_path_relay_hop_count_values", "relay_data_path_relay_hop_count_values"},
    {"relay_data_path_ground_downlink_contact_ids",
     "relay_data_path_ground_downlink_contact_ids"},
    {"relay_data_path_custody_statuses", "relay_data_path_custody_statuses"},
    {"relay_data_path_latency_values_s", "relay_data_path_latency_values_s"},
    {"relay_data_path_latency_limit_values_s", "relay_data_path_latency_limit_values_s"},
    {"relay_data_path_latency_statuses", "relay_data_path_latency_statuses"},
    {"relay_data_path_risk_statuses", "relay_data_path_risk_statuses"},
    {"relay_data_path_risk_reasons", "relay_data_path_risk_reasons"},
    {"relay_data_path_product_ids", "relay_data_path_product_ids"},
    {"relay_data_path_collection_ids", "relay_data_path_collection_ids"},
    {"relay_data_path_route_count_values", "relay_data_path_route_count_values"},
    {"relay_data_path_relay_route_count_values", "relay_data_path_relay_route_count_values"},
    {"relay_data_path_direct_downlink_route_count_values",
     "relay_data_path_direct_downlink_route_count_values"},
    {"relay_data_path_custody_status_count_maps", "relay_data_path_custody_status_count_maps"},
    {"relay_data_path_latency_status_count_maps", "relay_data_path_latency_status_count_maps"},
    {"relay_data_path_risk_status_count_maps", "relay_data_path_risk_status_count_maps"},
    {"relay_data_path_route_ids_by_custody_status",
     "relay_data_path_route_ids_by_custody_status"},
    {"relay_data_path_route_ids_by_latency_status",
     "relay_data_path_route_ids_by_latency_status"},
    {"relay_data_path_route_ids_by_risk_status", "relay_data_path_route_ids_by_risk_status"},
    {"relay_data_path_route_ids_by_ground_station_id",
     "relay_data_path_route_ids_by_ground_station_id"},
    {"relay_data_path_feedback_sources", "relay_data_path_feedback_sources"},
    {"relay_data_path_feedback_scopes", "relay_data_path_feedback_scopes"},
    {"relay_data_path_feedback_keys", "relay_data_path_feedback_keys"},
    {"relay_data_path_trust_boundaries", "relay_data_path_trust_boundaries"},
    {"relay_data_path_derivation_reasons", "relay_data_path_derivation_reasons"},
    {"relay_data_path_assumption_maps", "relay_data_path_assumption_maps"}
  ]
  @link_capacity_context_field_pairs [
    {"link_capacity_pressure_risk_types", "link_capacity_pressure_risk_types"},
    {"link_capacity_pressure_ground_station_ids", "link_capacity_pressure_ground_station_ids"},
    {"link_capacity_pressure_required_contact_values",
     "link_capacity_pressure_required_contact_values"},
    {"link_capacity_pressure_planned_contact_values",
     "link_capacity_pressure_planned_contact_values"},
    {"link_capacity_pressure_required_downlink_values_mb",
     "link_capacity_pressure_required_downlink_values_mb"},
    {"link_capacity_pressure_planned_downlink_values_mb",
     "link_capacity_pressure_planned_downlink_values_mb"},
    {"link_capacity_pressure_start_values_s", "link_capacity_pressure_start_values_s"},
    {"link_capacity_pressure_end_values_s", "link_capacity_pressure_end_values_s"},
    {"link_capacity_pressure_source_activity_ids", "link_capacity_pressure_source_activity_ids"},
    {"link_capacity_pressure_source_window_ids", "link_capacity_pressure_source_window_ids"},
    {"link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
     "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb"},
    {"link_capacity_pressure_selected_downlink_shortfall_values_mb",
     "link_capacity_pressure_selected_downlink_shortfall_values_mb"},
    {"link_capacity_pressure_actual_throughput_values_mb",
     "link_capacity_pressure_actual_throughput_values_mb"},
    {"link_capacity_pressure_actual_downlink_completion_ratio_values",
     "link_capacity_pressure_actual_downlink_completion_ratio_values"},
    {"link_capacity_pressure_actual_downlink_shortfall_values_mb",
     "link_capacity_pressure_actual_downlink_shortfall_values_mb"},
    {"link_capacity_pressure_downlink_requirement_statuses",
     "link_capacity_pressure_downlink_requirement_statuses"},
    {"link_capacity_pressure_actual_downlink_requirement_statuses",
     "link_capacity_pressure_actual_downlink_requirement_statuses"},
    {"link_capacity_pressure_downlink_demand_sources",
     "link_capacity_pressure_downlink_demand_sources"},
    {"link_capacity_pressure_downlink_completion_sources",
     "link_capacity_pressure_downlink_completion_sources"},
    {"link_capacity_pressure_feedback_sources", "link_capacity_pressure_feedback_sources"},
    {"link_capacity_pressure_feedback_scopes", "link_capacity_pressure_feedback_scopes"},
    {"link_capacity_pressure_trust_boundaries", "link_capacity_pressure_trust_boundaries"},
    {"link_capacity_pressure_derivation_reasons", "link_capacity_pressure_derivation_reasons"}
  ]
  @score_term_context_field_pairs [
    {"score_term_pressure_risk_types", "score_term_pressure_risk_types"},
    {"score_term_pressure_objective_ids", "score_term_pressure_objective_ids"},
    {"score_term_pressure_objective_types", "score_term_pressure_objective_types"},
    {"score_term_pressure_latency_objective_values",
     "score_term_pressure_latency_objective_values"},
    {"score_term_pressure_target_ids", "score_term_pressure_target_ids"},
    {"score_term_pressure_scenario_ids", "score_term_pressure_scenario_ids"},
    {"score_term_pressure_branch_ids", "score_term_pressure_branch_ids"},
    {"score_term_pressure_ground_station_ids", "score_term_pressure_ground_station_ids"},
    {"score_term_pressure_collection_ids", "score_term_pressure_collection_ids"},
    {"score_term_pressure_product_ids", "score_term_pressure_product_ids"},
    {"score_term_pressure_payload_ids", "score_term_pressure_payload_ids"},
    {"score_term_pressure_instrument_ids", "score_term_pressure_instrument_ids"},
    {"score_term_pressure_start_values_s", "score_term_pressure_start_values_s"},
    {"score_term_pressure_end_values_s", "score_term_pressure_end_values_s"},
    {"score_term_pressure_required_contact_values",
     "score_term_pressure_required_contact_values"},
    {"score_term_pressure_planned_contact_values", "score_term_pressure_planned_contact_values"},
    {"score_term_pressure_required_downlink_values_mb",
     "score_term_pressure_required_downlink_values_mb"},
    {"score_term_pressure_planned_downlink_values_mb",
     "score_term_pressure_planned_downlink_values_mb"},
    {"score_term_pressure_max_latency_values_s", "score_term_pressure_max_latency_values_s"},
    {"score_term_pressure_planned_latency_values_s",
     "score_term_pressure_planned_latency_values_s"},
    {"score_term_pressure_required_observation_values",
     "score_term_pressure_required_observation_values"},
    {"score_term_pressure_planned_observation_values",
     "score_term_pressure_planned_observation_values"},
    {"score_term_pressure_priorities", "score_term_pressure_priorities"},
    {"score_term_pressure_latitude_values_deg", "score_term_pressure_latitude_values_deg"},
    {"score_term_pressure_longitude_values_deg", "score_term_pressure_longitude_values_deg"},
    {"score_term_pressure_minimum_elevation_values_deg",
     "score_term_pressure_minimum_elevation_values_deg"},
    {"score_term_pressure_source_activity_ids", "score_term_pressure_source_activity_ids"},
    {"score_term_pressure_keys", "score_term_pressure_keys"},
    {"score_term_pressure_values", "score_term_pressure_values"},
    {"score_term_pressure_timeline_score_values", "score_term_pressure_timeline_score_values"},
    {"score_term_pressure_score_term_maps", "score_term_pressure_score_term_maps"},
    {"score_term_pressure_downlink_demand_sources",
     "score_term_pressure_downlink_demand_sources"},
    {"score_term_pressure_downlink_completion_sources",
     "score_term_pressure_downlink_completion_sources"},
    {"score_term_pressure_feedback_sources", "score_term_pressure_feedback_sources"},
    {"score_term_pressure_feedback_scopes", "score_term_pressure_feedback_scopes"},
    {"score_term_pressure_trust_boundaries", "score_term_pressure_trust_boundaries"},
    {"score_term_pressure_derivation_reasons", "score_term_pressure_derivation_reasons"}
  ]
  @objective_satisfaction_context_field_pairs [
    {"objective_satisfaction_pressure_risk_types", "objective_satisfaction_pressure_risk_types"},
    {"objective_satisfaction_pressure_objective_ids",
     "objective_satisfaction_pressure_objective_ids"},
    {"objective_satisfaction_pressure_objective_types",
     "objective_satisfaction_pressure_objective_types"},
    {"objective_satisfaction_pressure_objective_statuses",
     "objective_satisfaction_pressure_objective_statuses"},
    {"objective_satisfaction_pressure_source_objective_statuses",
     "objective_satisfaction_pressure_source_objective_statuses"},
    {"objective_satisfaction_pressure_latency_objective_values",
     "objective_satisfaction_pressure_latency_objective_values"},
    {"objective_satisfaction_pressure_target_ids", "objective_satisfaction_pressure_target_ids"},
    {"objective_satisfaction_pressure_scenario_ids",
     "objective_satisfaction_pressure_scenario_ids"},
    {"objective_satisfaction_pressure_spacecraft_ids",
     "objective_satisfaction_pressure_spacecraft_ids"},
    {"objective_satisfaction_pressure_branch_ids", "objective_satisfaction_pressure_branch_ids"},
    {"objective_satisfaction_pressure_ground_station_ids",
     "objective_satisfaction_pressure_ground_station_ids"},
    {"objective_satisfaction_pressure_collection_ids",
     "objective_satisfaction_pressure_collection_ids"},
    {"objective_satisfaction_pressure_product_ids",
     "objective_satisfaction_pressure_product_ids"},
    {"objective_satisfaction_pressure_payload_ids",
     "objective_satisfaction_pressure_payload_ids"},
    {"objective_satisfaction_pressure_instrument_ids",
     "objective_satisfaction_pressure_instrument_ids"},
    {"objective_satisfaction_pressure_start_values_s",
     "objective_satisfaction_pressure_start_values_s"},
    {"objective_satisfaction_pressure_end_values_s",
     "objective_satisfaction_pressure_end_values_s"},
    {"objective_satisfaction_pressure_required_contact_values",
     "objective_satisfaction_pressure_required_contact_values"},
    {"objective_satisfaction_pressure_planned_contact_values",
     "objective_satisfaction_pressure_planned_contact_values"},
    {"objective_satisfaction_pressure_required_downlink_values_mb",
     "objective_satisfaction_pressure_required_downlink_values_mb"},
    {"objective_satisfaction_pressure_planned_downlink_values_mb",
     "objective_satisfaction_pressure_planned_downlink_values_mb"},
    {"objective_satisfaction_pressure_max_latency_values_s",
     "objective_satisfaction_pressure_max_latency_values_s"},
    {"objective_satisfaction_pressure_planned_latency_values_s",
     "objective_satisfaction_pressure_planned_latency_values_s"},
    {"objective_satisfaction_pressure_required_observation_values",
     "objective_satisfaction_pressure_required_observation_values"},
    {"objective_satisfaction_pressure_planned_observation_values",
     "objective_satisfaction_pressure_planned_observation_values"},
    {"objective_satisfaction_pressure_priorities", "objective_satisfaction_pressure_priorities"},
    {"objective_satisfaction_pressure_latitude_values_deg",
     "objective_satisfaction_pressure_latitude_values_deg"},
    {"objective_satisfaction_pressure_longitude_values_deg",
     "objective_satisfaction_pressure_longitude_values_deg"},
    {"objective_satisfaction_pressure_minimum_elevation_values_deg",
     "objective_satisfaction_pressure_minimum_elevation_values_deg"},
    {"objective_satisfaction_pressure_observation_success_factor_values",
     "objective_satisfaction_pressure_observation_success_factor_values"},
    {"objective_satisfaction_pressure_image_quality_score_values",
     "objective_satisfaction_pressure_image_quality_score_values"},
    {"objective_satisfaction_pressure_image_quality_statuses",
     "objective_satisfaction_pressure_image_quality_statuses"},
    {"objective_satisfaction_pressure_image_quality_sources",
     "objective_satisfaction_pressure_image_quality_sources"},
    {"objective_satisfaction_pressure_cloud_cover_fraction_values",
     "objective_satisfaction_pressure_cloud_cover_fraction_values"},
    {"objective_satisfaction_pressure_blur_score_values",
     "objective_satisfaction_pressure_blur_score_values"},
    {"objective_satisfaction_pressure_quality_feedback_sources",
     "objective_satisfaction_pressure_quality_feedback_sources"},
    {"objective_satisfaction_pressure_source_activity_ids",
     "objective_satisfaction_pressure_source_activity_ids"},
    {"objective_satisfaction_pressure_missed_downlink_activity_ids",
     "objective_satisfaction_pressure_missed_downlink_activity_ids"},
    {"objective_satisfaction_pressure_realized_statuses",
     "objective_satisfaction_pressure_realized_statuses"},
    {"objective_satisfaction_pressure_contact_results",
     "objective_satisfaction_pressure_contact_results"},
    {"objective_satisfaction_pressure_candidate_window_maps",
     "objective_satisfaction_pressure_candidate_window_maps"},
    {"objective_satisfaction_pressure_allowed_scenario_ids",
     "objective_satisfaction_pressure_allowed_scenario_ids"},
    {"objective_satisfaction_pressure_spacecraft_constraint_maps",
     "objective_satisfaction_pressure_spacecraft_constraint_maps"},
    {"objective_satisfaction_pressure_coverage_objective_ids",
     "objective_satisfaction_pressure_coverage_objective_ids"},
    {"objective_satisfaction_pressure_downlink_demand_sources",
     "objective_satisfaction_pressure_downlink_demand_sources"},
    {"objective_satisfaction_pressure_downlink_completion_sources",
     "objective_satisfaction_pressure_downlink_completion_sources"},
    {"objective_satisfaction_pressure_feedback_sources",
     "objective_satisfaction_pressure_feedback_sources"},
    {"objective_satisfaction_pressure_feedback_scopes",
     "objective_satisfaction_pressure_feedback_scopes"},
    {"objective_satisfaction_pressure_trust_boundaries",
     "objective_satisfaction_pressure_trust_boundaries"},
    {"objective_satisfaction_pressure_derivation_reasons",
     "objective_satisfaction_pressure_derivation_reasons"}
  ]
  @objective_tradeoff_context_field_pairs [
    {"objective_tradeoff_pressure_risk_types", "objective_tradeoff_pressure_risk_types"},
    {"objective_tradeoff_pressure_objective_ids", "objective_tradeoff_pressure_objective_ids"},
    {"objective_tradeoff_pressure_objective_types",
     "objective_tradeoff_pressure_objective_types"},
    {"objective_tradeoff_pressure_latency_objective_values",
     "objective_tradeoff_pressure_latency_objective_values"},
    {"objective_tradeoff_pressure_target_ids", "objective_tradeoff_pressure_target_ids"},
    {"objective_tradeoff_pressure_scenario_ids", "objective_tradeoff_pressure_scenario_ids"},
    {"objective_tradeoff_pressure_branch_ids", "objective_tradeoff_pressure_branch_ids"},
    {"objective_tradeoff_pressure_ground_station_ids",
     "objective_tradeoff_pressure_ground_station_ids"},
    {"objective_tradeoff_pressure_collection_ids", "objective_tradeoff_pressure_collection_ids"},
    {"objective_tradeoff_pressure_product_ids", "objective_tradeoff_pressure_product_ids"},
    {"objective_tradeoff_pressure_payload_ids", "objective_tradeoff_pressure_payload_ids"},
    {"objective_tradeoff_pressure_instrument_ids", "objective_tradeoff_pressure_instrument_ids"},
    {"objective_tradeoff_pressure_start_values_s", "objective_tradeoff_pressure_start_values_s"},
    {"objective_tradeoff_pressure_end_values_s", "objective_tradeoff_pressure_end_values_s"},
    {"objective_tradeoff_pressure_required_contact_values",
     "objective_tradeoff_pressure_required_contact_values"},
    {"objective_tradeoff_pressure_planned_contact_values",
     "objective_tradeoff_pressure_planned_contact_values"},
    {"objective_tradeoff_pressure_required_downlink_values_mb",
     "objective_tradeoff_pressure_required_downlink_values_mb"},
    {"objective_tradeoff_pressure_planned_downlink_values_mb",
     "objective_tradeoff_pressure_planned_downlink_values_mb"},
    {"objective_tradeoff_pressure_max_latency_values_s",
     "objective_tradeoff_pressure_max_latency_values_s"},
    {"objective_tradeoff_pressure_planned_latency_values_s",
     "objective_tradeoff_pressure_planned_latency_values_s"},
    {"objective_tradeoff_pressure_source_activity_ids",
     "objective_tradeoff_pressure_source_activity_ids"},
    {"objective_tradeoff_pressure_score_values", "objective_tradeoff_pressure_score_values"},
    {"objective_tradeoff_pressure_score_delta_from_selected_values",
     "objective_tradeoff_pressure_score_delta_from_selected_values"},
    {"objective_tradeoff_pressure_score_term_maps",
     "objective_tradeoff_pressure_score_term_maps"},
    {"objective_tradeoff_pressure_required_observation_values",
     "objective_tradeoff_pressure_required_observation_values"},
    {"objective_tradeoff_pressure_planned_observation_values",
     "objective_tradeoff_pressure_planned_observation_values"},
    {"objective_tradeoff_pressure_priorities", "objective_tradeoff_pressure_priorities"},
    {"objective_tradeoff_pressure_latitude_values_deg",
     "objective_tradeoff_pressure_latitude_values_deg"},
    {"objective_tradeoff_pressure_longitude_values_deg",
     "objective_tradeoff_pressure_longitude_values_deg"},
    {"objective_tradeoff_pressure_minimum_elevation_values_deg",
     "objective_tradeoff_pressure_minimum_elevation_values_deg"},
    {"objective_tradeoff_pressure_feedback_sources",
     "objective_tradeoff_pressure_feedback_sources"},
    {"objective_tradeoff_pressure_feedback_scopes",
     "objective_tradeoff_pressure_feedback_scopes"},
    {"objective_tradeoff_pressure_trust_boundaries",
     "objective_tradeoff_pressure_trust_boundaries"},
    {"objective_tradeoff_pressure_derivation_reasons",
     "objective_tradeoff_pressure_derivation_reasons"}
  ]
  @station_reservation_conflict_context_field_pairs [
    {"station_reservation_conflict_contact_ids", "station_reservation_conflict_contact_ids"},
    {"station_reservation_conflict_source_activity_ids",
     "station_reservation_conflict_source_activity_ids"},
    {"station_reservation_conflict_ground_station_ids",
     "station_reservation_conflict_ground_station_ids"},
    {"station_reservation_conflict_reservation_ids",
     "station_reservation_conflict_reservation_ids"},
    {"station_reservation_conflict_reserved_by", "station_reservation_conflict_reserved_by"},
    {"station_reservation_conflict_statuses", "station_reservation_conflict_statuses"},
    {"station_reservation_conflict_match_statuses",
     "station_reservation_conflict_match_statuses"},
    {"station_reservation_conflict_expires_at_values_s",
     "station_reservation_conflict_expires_at_values_s"},
    {"station_reservation_conflict_expiration_statuses",
     "station_reservation_conflict_expiration_statuses"},
    {"station_reservation_conflict_derivation_reasons",
     "station_reservation_conflict_derivation_reasons"},
    {"station_reservation_conflict_feedback_sources",
     "station_reservation_conflict_feedback_sources"},
    {"station_reservation_conflict_feedback_scopes",
     "station_reservation_conflict_feedback_scopes"},
    {"station_reservation_conflict_trust_boundaries",
     "station_reservation_conflict_trust_boundaries"}
  ]
  @station_reservation_hold_context_field_pairs [
    {"station_reservation_hold_import_statuses", "station_reservation_hold_import_statuses"},
    {"station_reservation_hold_import_readiness_summary_models",
     "station_reservation_hold_import_readiness_summary_models"},
    {"station_reservation_hold_import_readiness_sources",
     "station_reservation_hold_import_readiness_sources"},
    {"station_reservation_hold_import_readiness_source_artifact_types",
     "station_reservation_hold_import_readiness_source_artifact_types"},
    {"station_reservation_hold_import_readiness_statuses",
     "station_reservation_hold_import_readiness_statuses"},
    {"station_reservation_hold_import_classifications",
     "station_reservation_hold_import_classifications"},
    {"station_reservation_hold_count_values", "station_reservation_hold_count_values"},
    {"station_reservation_hold_ids", "station_reservation_hold_ids"},
    {"station_reservation_hold_ids_by_import_status",
     "station_reservation_hold_ids_by_import_status"},
    {"station_reservation_hold_ids_by_required_import_action",
     "station_reservation_hold_ids_by_required_import_action"},
    {"station_reservation_hold_ids_by_direction", "station_reservation_hold_ids_by_direction"},
    {"station_reservation_hold_ids_by_direction_and_ground_station_id",
     "station_reservation_hold_ids_by_direction_and_ground_station_id"},
    {"station_reservation_hold_contact_ids", "station_reservation_hold_contact_ids"},
    {"station_reservation_hold_contact_ids_by_import_status",
     "station_reservation_hold_contact_ids_by_import_status"},
    {"station_reservation_hold_contact_ids_by_expiration_status",
     "station_reservation_hold_contact_ids_by_expiration_status"},
    {"station_reservation_hold_contact_ids_by_direction",
     "station_reservation_hold_contact_ids_by_direction"},
    {"station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
     "station_reservation_hold_contact_ids_by_direction_and_ground_station_id"},
    {"station_reservation_hold_import_status_count_maps",
     "station_reservation_hold_import_status_count_maps"},
    {"station_reservation_hold_required_import_action_count_maps",
     "station_reservation_hold_required_import_action_count_maps"},
    {"station_reservation_hold_import_execution_boundaries",
     "station_reservation_hold_import_execution_boundaries"},
    {"station_reservation_hold_provider_write_values",
     "station_reservation_hold_provider_write_values"},
    {"station_reservation_hold_cadence_write_values",
     "station_reservation_hold_cadence_write_values"},
    {"station_reservation_hold_reservation_acceptance_values",
     "station_reservation_hold_reservation_acceptance_values"},
    {"station_reservation_hold_feedback_sources", "station_reservation_hold_feedback_sources"},
    {"station_reservation_hold_feedback_scopes", "station_reservation_hold_feedback_scopes"},
    {"station_reservation_hold_trust_boundaries", "station_reservation_hold_trust_boundaries"},
    {"source_station_reservation_hold_import_readiness_summaries",
     "source_station_reservation_hold_import_readiness_summaries"},
    {"station_reservation_hold_expiration_statuses",
     "station_reservation_hold_expiration_statuses"}
  ]
  @contact_allocation_context_field_pairs [
    {"contact_allocation_pressure_risk_types", "contact_allocation_pressure_risk_types"},
    {"contact_allocation_pressure_contact_ids", "contact_allocation_pressure_contact_ids"},
    {"contact_allocation_pressure_scenario_ids", "contact_allocation_pressure_scenario_ids"},
    {"contact_allocation_pressure_spacecraft_ids", "contact_allocation_pressure_spacecraft_ids"},
    {"contact_allocation_pressure_ground_station_ids",
     "contact_allocation_pressure_ground_station_ids"},
    {"contact_allocation_pressure_source_activity_ids",
     "contact_allocation_pressure_source_activity_ids"},
    {"contact_allocation_pressure_source_window_ids",
     "contact_allocation_pressure_source_window_ids"},
    {"contact_allocation_pressure_required_contact_values",
     "contact_allocation_pressure_required_contact_values"},
    {"contact_allocation_pressure_planned_contact_values",
     "contact_allocation_pressure_planned_contact_values"},
    {"contact_allocation_pressure_required_downlink_values_mb",
     "contact_allocation_pressure_required_downlink_values_mb"},
    {"contact_allocation_pressure_planned_downlink_values_mb",
     "contact_allocation_pressure_planned_downlink_values_mb"},
    {"contact_allocation_pressure_start_values_s", "contact_allocation_pressure_start_values_s"},
    {"contact_allocation_pressure_end_values_s", "contact_allocation_pressure_end_values_s"},
    {"contact_allocation_pressure_realized_statuses",
     "contact_allocation_pressure_realized_statuses"},
    {"contact_allocation_pressure_contact_results",
     "contact_allocation_pressure_contact_results"},
    {"contact_allocation_pressure_allocation_statuses",
     "contact_allocation_pressure_allocation_statuses"},
    {"contact_allocation_pressure_effective_allocation_statuses",
     "contact_allocation_pressure_effective_allocation_statuses"},
    {"contact_allocation_pressure_allocation_reasons",
     "contact_allocation_pressure_allocation_reasons"},
    {"contact_allocation_pressure_review_statuses",
     "contact_allocation_pressure_review_statuses"},
    {"contact_allocation_pressure_approval_statuses",
     "contact_allocation_pressure_approval_statuses"},
    {"contact_allocation_pressure_policy_classifications",
     "contact_allocation_pressure_policy_classifications"},
    {"contact_allocation_pressure_policy_bundle_ids",
     "contact_allocation_pressure_policy_bundle_ids"},
    {"contact_allocation_pressure_station_reservation_ids",
     "contact_allocation_pressure_station_reservation_ids"},
    {"contact_allocation_pressure_station_reserved_by",
     "contact_allocation_pressure_station_reserved_by"},
    {"contact_allocation_pressure_station_reservation_statuses",
     "contact_allocation_pressure_station_reservation_statuses"},
    {"contact_allocation_pressure_station_reservation_match_statuses",
     "contact_allocation_pressure_station_reservation_match_statuses"},
    {"contact_allocation_pressure_station_calendar_entry_ids",
     "contact_allocation_pressure_station_calendar_entry_ids"},
    {"contact_allocation_pressure_station_calendar_entry_statuses",
     "contact_allocation_pressure_station_calendar_entry_statuses"},
    {"contact_allocation_pressure_station_calendar_directions",
     "contact_allocation_pressure_station_calendar_directions"},
    {"contact_allocation_pressure_downlink_demand_sources",
     "contact_allocation_pressure_downlink_demand_sources"},
    {"contact_allocation_pressure_downlink_completion_sources",
     "contact_allocation_pressure_downlink_completion_sources"},
    {"contact_allocation_pressure_feedback_sources",
     "contact_allocation_pressure_feedback_sources"},
    {"contact_allocation_pressure_feedback_scopes",
     "contact_allocation_pressure_feedback_scopes"},
    {"contact_allocation_pressure_trust_boundaries",
     "contact_allocation_pressure_trust_boundaries"},
    {"contact_allocation_pressure_derivation_reasons",
     "contact_allocation_pressure_derivation_reasons"}
  ]
  @contact_intent_context_field_pairs [
    {"contact_intent_pressure_risk_types", "contact_intent_pressure_risk_types"},
    {"contact_intent_pressure_contact_ids", "contact_intent_pressure_contact_ids"},
    {"contact_intent_pressure_source_activity_ids",
     "contact_intent_pressure_source_activity_ids"},
    {"contact_intent_pressure_ground_station_ids", "contact_intent_pressure_ground_station_ids"},
    {"contact_intent_pressure_required_contact_values",
     "contact_intent_pressure_required_contact_values"},
    {"contact_intent_pressure_planned_contact_values",
     "contact_intent_pressure_planned_contact_values"},
    {"contact_intent_pressure_required_downlink_values_mb",
     "contact_intent_pressure_required_downlink_values_mb"},
    {"contact_intent_pressure_planned_downlink_values_mb",
     "contact_intent_pressure_planned_downlink_values_mb"},
    {"contact_intent_pressure_start_values_s", "contact_intent_pressure_start_values_s"},
    {"contact_intent_pressure_end_values_s", "contact_intent_pressure_end_values_s"},
    {"contact_intent_pressure_source_window_ids", "contact_intent_pressure_source_window_ids"},
    {"contact_intent_pressure_timeline_ids", "contact_intent_pressure_timeline_ids"},
    {"contact_intent_pressure_approval_statuses", "contact_intent_pressure_approval_statuses"},
    {"contact_intent_pressure_required_operator_actions",
     "contact_intent_pressure_required_operator_actions"},
    {"contact_intent_pressure_cadence_import_statuses",
     "contact_intent_pressure_cadence_import_statuses"},
    {"contact_intent_pressure_gate_statuses", "contact_intent_pressure_gate_statuses"},
    {"contact_intent_pressure_policy_classifications",
     "contact_intent_pressure_policy_classifications"},
    {"contact_intent_pressure_policy_bundle_ids", "contact_intent_pressure_policy_bundle_ids"},
    {"contact_intent_pressure_invalid_cadence_import_values",
     "contact_intent_pressure_invalid_cadence_import_values"},
    {"contact_intent_pressure_invalid_cadence_import_reasons",
     "contact_intent_pressure_invalid_cadence_import_reasons"},
    {"contact_intent_pressure_invalid_activity_input_values",
     "contact_intent_pressure_invalid_activity_input_values"},
    {"contact_intent_pressure_invalid_activity_input_reasons",
     "contact_intent_pressure_invalid_activity_input_reasons"},
    {"contact_intent_pressure_station_availabilities",
     "contact_intent_pressure_station_availabilities"},
    {"contact_intent_pressure_station_contention_statuses",
     "contact_intent_pressure_station_contention_statuses"},
    {"contact_intent_pressure_station_calendar_entry_ids",
     "contact_intent_pressure_station_calendar_entry_ids"},
    {"contact_intent_pressure_station_calendar_provider_ids",
     "contact_intent_pressure_station_calendar_provider_ids"},
    {"contact_intent_pressure_station_calendar_provider_entry_ids",
     "contact_intent_pressure_station_calendar_provider_entry_ids"},
    {"contact_intent_pressure_station_calendar_directions",
     "contact_intent_pressure_station_calendar_directions"},
    {"contact_intent_pressure_station_calendar_statuses",
     "contact_intent_pressure_station_calendar_statuses"},
    {"contact_intent_pressure_station_calendar_trust_boundary_statuses",
     "contact_intent_pressure_station_calendar_trust_boundary_statuses"},
    {"contact_intent_pressure_station_reservation_ids",
     "contact_intent_pressure_station_reservation_ids"},
    {"contact_intent_pressure_station_reserved_by",
     "contact_intent_pressure_station_reserved_by"},
    {"contact_intent_pressure_station_reservation_statuses",
     "contact_intent_pressure_station_reservation_statuses"},
    {"contact_intent_pressure_station_reservation_match_statuses",
     "contact_intent_pressure_station_reservation_match_statuses"},
    {"contact_intent_pressure_feedback_sources", "contact_intent_pressure_feedback_sources"},
    {"contact_intent_pressure_feedback_scopes", "contact_intent_pressure_feedback_scopes"},
    {"contact_intent_pressure_trust_boundaries", "contact_intent_pressure_trust_boundaries"},
    {"contact_intent_pressure_derivation_reasons", "contact_intent_pressure_derivation_reasons"}
  ]
  @station_calendar_context_field_pairs [
    {"station_calendar_pressure_risk_types", "station_calendar_pressure_risk_types"},
    {"station_calendar_pressure_ground_station_ids",
     "station_calendar_pressure_ground_station_ids"},
    {"station_calendar_pressure_start_values_s", "station_calendar_pressure_start_values_s"},
    {"station_calendar_pressure_end_values_s", "station_calendar_pressure_end_values_s"},
    {"station_calendar_pressure_capacity_fraction_values",
     "station_calendar_pressure_capacity_fraction_values"},
    {"station_calendar_pressure_station_reservation_expiration_statuses",
     "station_calendar_pressure_station_reservation_expiration_statuses"},
    {"station_calendar_pressure_station_reservation_expires_at_values_s",
     "station_calendar_pressure_station_reservation_expires_at_values_s"},
    {"station_calendar_pressure_station_reservation_ids",
     "station_calendar_pressure_station_reservation_ids"},
    {"station_calendar_pressure_station_reserved_by",
     "station_calendar_pressure_station_reserved_by"},
    {"station_calendar_pressure_station_reservation_statuses",
     "station_calendar_pressure_station_reservation_statuses"},
    {"station_calendar_pressure_station_reservation_match_statuses",
     "station_calendar_pressure_station_reservation_match_statuses"},
    {"station_calendar_pressure_station_calendar_entry_ids",
     "station_calendar_pressure_station_calendar_entry_ids"},
    {"station_calendar_pressure_station_calendar_provider_ids",
     "station_calendar_pressure_station_calendar_provider_ids"},
    {"station_calendar_pressure_station_calendar_provider_entry_ids",
     "station_calendar_pressure_station_calendar_provider_entry_ids"},
    {"station_calendar_pressure_station_calendar_directions",
     "station_calendar_pressure_station_calendar_directions"},
    {"station_calendar_pressure_station_calendar_statuses",
     "station_calendar_pressure_station_calendar_statuses"},
    {"station_calendar_pressure_station_availabilities",
     "station_calendar_pressure_station_availabilities"},
    {"station_calendar_pressure_station_contention_statuses",
     "station_calendar_pressure_station_contention_statuses"},
    {"station_calendar_pressure_station_calendar_overlap_count_values",
     "station_calendar_pressure_station_calendar_overlap_count_values"},
    {"station_calendar_pressure_station_calendar_overlap_entry_ids",
     "station_calendar_pressure_station_calendar_overlap_entry_ids"},
    {"station_calendar_pressure_station_calendar_overlap_availabilities",
     "station_calendar_pressure_station_calendar_overlap_availabilities"},
    {"station_calendar_pressure_station_calendar_entry_ambiguous_values",
     "station_calendar_pressure_station_calendar_entry_ambiguous_values"},
    {"station_calendar_pressure_station_calendar_ambiguous_entry_count_values",
     "station_calendar_pressure_station_calendar_ambiguous_entry_count_values"},
    {"station_calendar_pressure_station_calendar_ambiguous_entry_ids",
     "station_calendar_pressure_station_calendar_ambiguous_entry_ids"},
    {"station_calendar_pressure_station_calendar_reservation_overlap_count_values",
     "station_calendar_pressure_station_calendar_reservation_overlap_count_values"},
    {"station_calendar_pressure_station_calendar_reservation_ids",
     "station_calendar_pressure_station_calendar_reservation_ids"},
    {"station_calendar_pressure_station_calendar_reserved_by",
     "station_calendar_pressure_station_calendar_reserved_by"},
    {"station_calendar_pressure_station_calendar_reservation_statuses",
     "station_calendar_pressure_station_calendar_reservation_statuses"},
    {"station_calendar_pressure_station_calendar_trust_boundary_statuses",
     "station_calendar_pressure_station_calendar_trust_boundary_statuses"},
    {"station_calendar_pressure_provider_calendar_contention_group_ids",
     "station_calendar_pressure_provider_calendar_contention_group_ids"},
    {"station_calendar_pressure_provider_calendar_contention_statuses",
     "station_calendar_pressure_provider_calendar_contention_statuses"},
    {"station_calendar_pressure_provider_calendar_contention_entry_ids",
     "station_calendar_pressure_provider_calendar_contention_entry_ids"},
    {"station_calendar_pressure_provider_calendar_contention_provider_ids",
     "station_calendar_pressure_provider_calendar_contention_provider_ids"},
    {"station_calendar_pressure_provider_calendar_contention_provider_entry_ids",
     "station_calendar_pressure_provider_calendar_contention_provider_entry_ids"},
    {"station_calendar_pressure_provider_calendar_contention_availabilities",
     "station_calendar_pressure_provider_calendar_contention_availabilities"},
    {"station_calendar_pressure_provider_calendar_contention_directions",
     "station_calendar_pressure_provider_calendar_contention_directions"},
    {"station_calendar_pressure_provider_calendar_contention_reservation_ids",
     "station_calendar_pressure_provider_calendar_contention_reservation_ids"},
    {"station_calendar_pressure_provider_calendar_contention_reserved_by",
     "station_calendar_pressure_provider_calendar_contention_reserved_by"},
    {"station_calendar_pressure_provider_calendar_contention_reservation_statuses",
     "station_calendar_pressure_provider_calendar_contention_reservation_statuses"},
    {"station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses",
     "station_calendar_pressure_provider_calendar_contention_trust_boundary_statuses"},
    {"station_calendar_pressure_provider_calendar_contention_overlap_pairs",
     "station_calendar_pressure_provider_calendar_contention_overlap_pairs"},
    {"station_calendar_pressure_required_operator_actions",
     "station_calendar_pressure_required_operator_actions"},
    {"station_calendar_pressure_feedback_sources", "station_calendar_pressure_feedback_sources"},
    {"station_calendar_pressure_feedback_scopes", "station_calendar_pressure_feedback_scopes"},
    {"station_calendar_pressure_trust_boundaries", "station_calendar_pressure_trust_boundaries"},
    {"station_calendar_pressure_derivation_reasons",
     "station_calendar_pressure_derivation_reasons"}
  ]
  @strategy_recommendation_risk_context_specs [
    {@approval_boundary_context_field_pairs, :approval_boundary_context},
    {@provider_reservation_request_context_field_pairs, :provider_reservation_request_context},
    {@capacity_pack_context_field_pairs, :capacity_pack_context},
    {@contact_contention_resolution_context_field_pairs, :contact_contention_resolution_context},
    {@contact_contention_context_field_pairs, :contact_contention_context},
    {@contact_filter_context_field_pairs, :contact_filter_context},
    {@resource_filter_context_field_pairs, :resource_filter_context},
    {@resource_margin_context_field_pairs, :resource_margin_context},
    {@resource_projection_context_field_pairs, :resource_projection_context},
    {@execution_success_feedback_context_field_pairs, :execution_success_feedback_context},
    {@timeline_dependency_impact_context_field_pairs, :timeline_dependency_impact_context},
    {@timeline_publication_context_field_pairs, :timeline_publication_context},
    {@maneuver_execution_uncertainty_context_field_pairs,
     :maneuver_execution_uncertainty_context},
    {@relay_data_path_context_field_pairs, :relay_data_path_context},
    {@link_capacity_context_field_pairs, :link_capacity_context},
    {@score_term_context_field_pairs, :score_term_context},
    {@objective_satisfaction_context_field_pairs, :objective_satisfaction_context},
    {@objective_tradeoff_context_field_pairs, :objective_tradeoff_context},
    {@station_reservation_conflict_context_field_pairs, :station_reservation_conflict_context},
    {@station_reservation_hold_context_field_pairs,
     :station_reservation_hold_import_readiness_context},
    {@contact_allocation_context_field_pairs, :contact_allocation_context},
    {@contact_intent_context_field_pairs, :contact_intent_context},
    {@station_calendar_context_field_pairs, :station_calendar_context}
  ]
  @strategy_recommendation_risk_context_field_pairs Enum.flat_map(
                                                      @strategy_recommendation_risk_context_specs,
                                                      &elem(&1, 0)
                                                    )
  @strategy_recommendation_source_review_fields Enum.map(
                                                  [
                                                    "subject_id",
                                                    "branch_id",
                                                    "recommended_branch_id",
                                                    "ranked_branch_ids",
                                                    "tradeoff_count",
                                                    "risk_count",
                                                    "approval_requirement_count",
                                                    "approval_status",
                                                    "required_operator_action",
                                                    "reason",
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
                                                    "quality_gate_unavailable_resource_reason_ids",
                                                    "branch_source_window_ids",
                                                    "branch_source_window_count",
                                                    "branch_source_window_bounds",
                                                    "branch_source_window_bound_count",
                                                    "branch_untimed_source_window_ids",
                                                    "branch_untimed_source_window_count",
                                                    "branch_partially_timed_source_window_ids",
                                                    "branch_partially_timed_source_window_count",
                                                    "branch_source_window_timing_coverage_status",
                                                    "branch_earliest_starts_at_s",
                                                    "branch_latest_ends_at_s",
                                                    "branch_station_reservation_expiration_statuses",
                                                    "provider_reservation_request_station_reservation_expiration_statuses",
                                                    "station_reservation_conflict_expiration_statuses",
                                                    "station_reservation_hold_expiration_statuses",
                                                    "station_calendar_pressure_station_reservation_expiration_statuses",
                                                    "source_recommendation"
                                                  ],
                                                  &{&1, &1}
                                                )
  @strategy_tradeoff_source_tradeoff_field_pairs [
    {"subject_id", "dimension"},
    {"dimension", "dimension"},
    {"baseline", "baseline"},
    {"recommended", "recommended"},
    {"delta", "delta"}
  ]
  @strategy_tradeoff_source_branch_comparison_field_pairs [
    {"subject_id", "branch_id"},
    {"branch_id", "branch_id"},
    {"baseline", "score"},
    {"delta", "score_delta_from_recommended"},
    {"risk_count", "risk_count"},
    {"risk_types", "risk_types"},
    {"high_risk_types", "high_risk_types"},
    {"projected_storage_remaining_mb", "projected_storage_remaining_mb"},
    {"projected_downlink_remaining_mb", "projected_downlink_remaining_mb"},
    {"branch_target_ids", "branch_target_ids"},
    {"branch_source_activity_ids", "branch_source_activity_ids"},
    {"branch_source_window_ids", "branch_source_window_ids"},
    {"branch_source_window_count", "branch_source_window_count"},
    {"branch_source_window_bounds", "branch_source_window_bounds"},
    {"branch_source_window_bound_count", "branch_source_window_bound_count"},
    {"branch_untimed_source_window_ids", "branch_untimed_source_window_ids"},
    {"branch_untimed_source_window_count", "branch_untimed_source_window_count"},
    {"branch_partially_timed_source_window_ids", "branch_partially_timed_source_window_ids"},
    {"branch_partially_timed_source_window_count", "branch_partially_timed_source_window_count"},
    {"branch_source_window_timing_coverage_status",
     "branch_source_window_timing_coverage_status"},
    {"branch_earliest_starts_at_s", "branch_earliest_starts_at_s"},
    {"branch_latest_ends_at_s", "branch_latest_ends_at_s"},
    {"branch_station_reservation_expiration_statuses",
     "branch_station_reservation_expiration_statuses"},
    {"capacity_pack_statuses", "capacity_pack_statuses"},
    {"repair_score", "repair_score"},
    {"repair_constraint_status", "repair_constraint_status"}
  ]
  @strategy_branch_comparison_source_field_pairs [
    {"subject_id", "branch_id"},
    {"branch_id", "branch_id"},
    {"selected", "selected"},
    {"score", "score"},
    {"score_delta_from_recommended", "score_delta_from_recommended"},
    {"raw_score", "raw_score"},
    {"branch_probability", "branch_probability"},
    {"expected_score", "expected_score"},
    {"risk_count", "risk_count"},
    {"risk_types", "risk_types"},
    {"high_risk_types", "high_risk_types"},
    {"approval_requirement_count", "approval_requirement_count"},
    {"repair_delta_count", "repair_delta_count"},
    {"branch_target_ids", "branch_target_ids"},
    {"branch_source_activity_ids", "branch_source_activity_ids"},
    {"branch_source_window_ids", "branch_source_window_ids"},
    {"branch_source_window_count", "branch_source_window_count"},
    {"branch_source_window_bounds", "branch_source_window_bounds"},
    {"branch_source_window_bound_count", "branch_source_window_bound_count"},
    {"branch_untimed_source_window_ids", "branch_untimed_source_window_ids"},
    {"branch_untimed_source_window_count", "branch_untimed_source_window_count"},
    {"branch_partially_timed_source_window_ids", "branch_partially_timed_source_window_ids"},
    {"branch_partially_timed_source_window_count", "branch_partially_timed_source_window_count"},
    {"branch_source_window_timing_coverage_status",
     "branch_source_window_timing_coverage_status"},
    {"branch_earliest_starts_at_s", "branch_earliest_starts_at_s"},
    {"branch_latest_ends_at_s", "branch_latest_ends_at_s"},
    {"branch_station_reservation_expiration_statuses",
     "branch_station_reservation_expiration_statuses"},
    {"branch_actual_downlink_completion_ratio", "branch_actual_downlink_completion_ratio"},
    {"resource_risk_types", "resource_risk_types"},
    {"projected_storage_remaining_mb", "projected_storage_remaining_mb"},
    {"projected_downlink_remaining_mb", "projected_downlink_remaining_mb"},
    {"repair_score", "repair_score"},
    {"repair_link_actual_downlink_completion_ratio",
     "repair_link_actual_downlink_completion_ratio"},
    {"repair_link_actual_downlink_requirement_status",
     "repair_link_actual_downlink_requirement_status"}
  ]
  @strategy_tradeoff_source_review_fields Enum.map(
                                            [
                                              "subject_id",
                                              "branch_id",
                                              "dimension",
                                              "baseline",
                                              "recommended",
                                              "delta",
                                              "risk_count",
                                              "risk_types",
                                              "high_risk_types",
                                              "branch_target_ids",
                                              "branch_source_activity_ids",
                                              "branch_source_window_ids",
                                              "branch_source_window_count",
                                              "branch_source_window_bounds",
                                              "branch_source_window_bound_count",
                                              "branch_untimed_source_window_ids",
                                              "branch_untimed_source_window_count",
                                              "branch_partially_timed_source_window_ids",
                                              "branch_partially_timed_source_window_count",
                                              "branch_source_window_timing_coverage_status",
                                              "branch_earliest_starts_at_s",
                                              "branch_latest_ends_at_s",
                                              "branch_station_reservation_expiration_statuses",
                                              "capacity_pack_statuses",
                                              "repair_score",
                                              "repair_constraint_status",
                                              "approval_status",
                                              "required_operator_action",
                                              "reason",
                                              "source_tradeoff",
                                              "source_branch_comparison"
                                            ],
                                            &{&1, &1}
                                          )
  @ranking_comparison_source_field_pairs [
    {"subject_id", "scenario_id"},
    {"scenario_id", "scenario_id"},
    {"status", "status"},
    {"left_rank", "left_rank"},
    {"right_rank", "right_rank"},
    {"rank_delta", "rank_delta"},
    {"left_value", "left_value"},
    {"right_value", "right_value"},
    {"value_delta", "value_delta"}
  ]
  @ranking_comparison_source_review_fields Enum.map(
                                             [
                                               "subject_id",
                                               "scenario_id",
                                               "status",
                                               "left_rank",
                                               "right_rank",
                                               "rank_delta",
                                               "left_value",
                                               "right_value",
                                               "value_delta",
                                               "approval_status",
                                               "required_operator_action",
                                               "reason",
                                               "source_ranking_comparison"
                                             ],
                                             &{&1, &1}
                                           )
  @pareto_frontier_source_field_pairs [
    {"subject_id", "scenario_id"},
    {"scenario_id", "scenario_id"},
    {"branch_id", "scenario_id"},
    {"frontier", "frontier"},
    {"objective_keys", "objective_keys"},
    {"objective_values", "objective_values"},
    {"dominated_by_ids", "dominated_by_ids"},
    {"dominates_ids", "dominates_ids"}
  ]
  @pareto_frontier_source_review_fields Enum.map(
                                          [
                                            "subject_id",
                                            "scenario_id",
                                            "branch_id",
                                            "frontier",
                                            "objective_keys",
                                            "objective_values",
                                            "dominated_by_ids",
                                            "dominates_ids",
                                            "approval_status",
                                            "required_operator_action",
                                            "reason",
                                            "source_pareto_frontier"
                                          ],
                                          &{&1, &1}
                                        )

  def validate_strategy_recommendation_matches_source(
        issues,
        path,
        %{"source_recommendation" => %{} = source_row} = row
      ) do
    if strategy_recommendation_handoff_row?(row) do
      issues
      |> validate_source_pairs(
        path,
        row,
        source_row,
        @strategy_recommendation_source_field_pairs,
        "source_recommendation"
      )
      |> validate_strategy_recommendation_source_count_matches(path, row, source_row)
      |> validate_strategy_recommendation_branch_event_context(path, row, source_row)
      |> validate_strategy_recommendation_risk_contexts(
        path,
        row,
        source_row
      )
    else
      issues
    end
  end

  def validate_strategy_recommendation_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_strategy_recommendation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if strategy_recommendation_handoff_row?(row) do
      issues
      |> validate_cadence_source_review_pairs(
        path,
        row,
        source_review_row,
        @strategy_recommendation_source_review_fields
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_review_row,
        @branch_window_context_field_pairs,
        "source_review_row"
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_review_row,
        @branch_reservation_expiration_context_field_pairs,
        "source_review_row"
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_review_row,
        @strategy_recommendation_risk_context_field_pairs,
        "source_review_row"
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_strategy_recommendation_matches(issues, _path, _row),
    do: issues

  def validate_strategy_tradeoff_matches_source(issues, path, row) do
    if strategy_tradeoff_handoff_row?(row) do
      issues
      |> validate_strategy_tradeoff_source_tradeoff_matches(path, row)
      |> validate_strategy_tradeoff_source_branch_comparison_matches(path, row)
    else
      issues
    end
  end

  def validate_cadence_source_review_strategy_tradeoff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if strategy_tradeoff_handoff_row?(row) do
      issues
      |> validate_cadence_source_review_pairs(
        path,
        row,
        source_review_row,
        @strategy_tradeoff_source_review_fields
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_review_row,
        @branch_window_context_field_pairs,
        "source_review_row"
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_review_row,
        @branch_reservation_expiration_context_field_pairs,
        "source_review_row"
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_strategy_tradeoff_matches(issues, _path, _row),
    do: issues

  def validate_branch_comparison_matches_source(
        issues,
        path,
        %{"source_branch_comparison" => %{} = source_row} = row
      ) do
    if strategy_branch_comparison_handoff_row?(row) do
      issues
      |> validate_source_pairs(
        path,
        row,
        source_row,
        @strategy_branch_comparison_source_field_pairs,
        "source_branch_comparison"
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_row,
        @branch_window_context_field_pairs,
        "source_branch_comparison"
      )
      |> validate_required_source_pairs(
        path,
        row,
        source_row,
        @branch_reservation_expiration_context_field_pairs,
        "source_branch_comparison"
      )
      |> validate_strategy_import_recommendation_risk_contexts(path, row)
    else
      issues
    end
  end

  def validate_branch_comparison_matches_source(issues, _path, _row), do: issues

  def validate_ranking_comparison_matches_source(
        issues,
        path,
        %{"source_ranking_comparison" => %{} = source_row} = row
      ) do
    if ranking_comparison_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @ranking_comparison_source_field_pairs,
        "source_ranking_comparison"
      )
    else
      issues
    end
  end

  def validate_ranking_comparison_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_ranking_comparison_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if ranking_comparison_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @ranking_comparison_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_ranking_comparison_matches(issues, _path, _row),
    do: issues

  def validate_pareto_frontier_matches_source(
        issues,
        path,
        %{"source_pareto_frontier" => %{} = source_row} = row
      ) do
    if pareto_frontier_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @pareto_frontier_source_field_pairs,
        "source_pareto_frontier"
      )
    else
      issues
    end
  end

  def validate_pareto_frontier_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_pareto_frontier_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if pareto_frontier_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @pareto_frontier_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_pareto_frontier_matches(issues, _path, _row), do: issues

  def strategy_recommendation_handoff_row?(row) do
    Map.get(row, "review_type") == "strategy_recommendation" or
      Map.get(row, "source_review_type") == "strategy_recommendation" or
      Map.get(row, "import_action") == "review_strategy_recommendation"
  end

  def strategy_tradeoff_handoff_row?(row) do
    Map.get(row, "review_type") == "strategy_tradeoff" or
      Map.get(row, "source_review_type") == "strategy_tradeoff" or
      Map.get(row, "import_action") == "review_strategy_tradeoff"
  end

  def strategy_branch_comparison_handoff_row?(row) do
    Map.get(row, "source_review_type") == "strategy_branch_comparison" or
      Map.get(row, "import_action") in [
        "import_strategy_recommendation",
        "review_strategy_branch_alternative"
      ]
  end

  def ranking_comparison_handoff_row?(row) do
    Map.get(row, "review_type") == "ranking_comparison_review" or
      Map.get(row, "source_review_type") == "ranking_comparison_review" or
      Map.get(row, "import_action") == "review_ranking_comparison"
  end

  def pareto_frontier_handoff_row?(row) do
    Map.get(row, "review_type") == "pareto_frontier_review" or
      Map.get(row, "source_review_type") == "pareto_frontier_review" or
      Map.get(row, "import_action") == "review_pareto_frontier"
  end

  defp validate_strategy_recommendation_source_count_matches(issues, path, row, source_row) do
    Enum.reduce(@strategy_recommendation_source_count_fields, issues, fn {row_field, source_field},
                                                                         acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if is_integer(row_value) and is_list(source_value) and row_value != length(source_value) do
        [
          error(
            "#{path}.#{row_field}",
            "must match source_recommendation.#{source_field} count"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_strategy_recommendation_branch_event_context(issues, path, row, source_row) do
    source_summary =
      source_row
      |> Map.get("explanation", [])
      |> List.wrap()
      |> Enum.find(fn
        %{"type" => "branch_event_summary"} -> true
        _row -> false
      end)

    case source_summary do
      %{} ->
        issues
        |> validate_source_pairs(
          path,
          row,
          source_summary,
          @branch_reservation_expiration_context_field_pairs,
          "source_recommendation.explanation.branch_event_summary"
        )
        |> validate_required_source_pairs(
          path,
          row,
          source_summary,
          @branch_reservation_expiration_context_field_pairs,
          "source_recommendation.explanation.branch_event_summary"
        )

      _summary ->
        issues
    end
  end

  defp validate_strategy_recommendation_risk_contexts(
         issues,
         path,
         row,
         source_row
       ) do
    risks = Map.get(source_row, "risks_remaining", [])

    Enum.reduce(
      @strategy_recommendation_risk_context_specs,
      issues,
      fn {field_pairs, context_function}, acc ->
        source_context =
          apply(OrbitalDynamics.RecommendationRiskContext, context_function, [risks])

        acc
        |> validate_source_pairs(
          path,
          row,
          source_context,
          field_pairs,
          "source_recommendation.risks_remaining"
        )
        |> validate_required_source_pairs(
          path,
          row,
          source_context,
          field_pairs,
          "source_recommendation.risks_remaining"
        )
      end
    )
  end

  defp validate_strategy_import_recommendation_risk_contexts(
         issues,
         path,
         %{
           "import_action" => "import_strategy_recommendation",
           "source_recommendation" => %{} = source_row
         } = row
       ) do
    validate_strategy_recommendation_risk_contexts(
      issues,
      path,
      row,
      source_row
    )
  end

  defp validate_strategy_import_recommendation_risk_contexts(
         issues,
         _path,
         _row
       ),
       do: issues

  defp validate_strategy_tradeoff_source_tradeoff_matches(
         issues,
         path,
         %{"source_tradeoff" => %{} = source_row} = row
       ) do
    validate_source_pairs(
      issues,
      path,
      row,
      source_row,
      @strategy_tradeoff_source_tradeoff_field_pairs,
      "source_tradeoff"
    )
  end

  defp validate_strategy_tradeoff_source_tradeoff_matches(issues, _path, _row), do: issues

  defp validate_strategy_tradeoff_source_branch_comparison_matches(
         issues,
         path,
         %{"source_branch_comparison" => %{} = source_row} = row
       ) do
    issues
    |> validate_source_pairs(
      path,
      row,
      source_row,
      @strategy_tradeoff_source_branch_comparison_field_pairs,
      "source_branch_comparison"
    )
    |> validate_required_source_pairs(
      path,
      row,
      source_row,
      @branch_window_context_field_pairs,
      "source_branch_comparison"
    )
    |> validate_required_source_pairs(
      path,
      row,
      source_row,
      @branch_reservation_expiration_context_field_pairs,
      "source_branch_comparison"
    )
  end

  defp validate_strategy_tradeoff_source_branch_comparison_matches(issues, _path, _row),
    do: issues

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp validate_required_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      if not is_nil(Map.get(source_row, source_field)) and is_nil(Map.get(row, row_field)) do
        [error("#{path}.#{row_field}", "must preserve #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp validate_cadence_source_review_pairs(
         issues,
         path,
         row,
         source_review_row,
         field_pairs
       ) do
    Enum.reduce(field_pairs, issues, fn {source_field, row_field}, acc ->
      source_value = Map.get(source_review_row, source_field)
      row_value = Map.get(row, row_field)

      if not is_nil(source_value) and not is_nil(row_value) and source_value != row_value do
        [
          error(
            "#{path}.source_review_row.#{source_field}",
            "must match #{row_field} on Cadence import row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
