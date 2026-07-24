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
    {"capacity_pack_risk_group_ids", "capacity_pack_risk_group_ids"}
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
    {@provider_reservation_request_context_field_pairs, :provider_reservation_request_context},
    {@capacity_pack_context_field_pairs, :capacity_pack_context},
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
