defmodule OrbitalDynamics.Schema.OperatorReviewRowContracts do
  @moduledoc false

  @required_fields [
    "id",
    "rank",
    "review_type",
    "source",
    "subject_id",
    "action",
    "required_operator_action",
    "reason"
  ]

  @stable_id_fields [
    "id",
    "subject_id",
    "candidate_id",
    "scenario_id",
    "spacecraft_id",
    "timeline_id",
    "activity_id",
    "contact_id",
    "source_activity_id",
    "planned_timeline_id",
    "realized_activity_id",
    "realized_timeline_id",
    "maneuver_id",
    "branch_id",
    "ground_station_id",
    "source_target_id",
    "source_window_id",
    "replacement_candidate_id",
    "replacement_source_window_id",
    "selected_contact_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "provider_counteroffer_id",
    "first_resource_pressure_activity_id",
    "first_resource_pressure_source_window_id",
    "source_timeline_id",
    "replacement_activity_id",
    "replacement_timeline_id",
    "recommended_branch_id",
    "baseline_branch_id"
  ]

  @protection_categories [
    "preserved_locked_or_approved",
    "preserved_executed",
    "changed_locked_or_approved",
    "changed_executed"
  ]

  def validate(issues, path, row, review_types, provider_counteroffer_states, callbacks)
      when is_list(review_types) and is_list(provider_counteroffer_states) and
             is_list(callbacks) do
    issues
    |> validate_identity_and_activity_fields(path, row, review_types, callbacks)
    |> validate_activity_metadata_and_quality_fields(path, row, callbacks)
    |> validate_relationship_and_source_window_fields(path, row, callbacks)
    |> validate_station_calendar_and_counteroffer_fields(
      path,
      row,
      provider_counteroffer_states,
      callbacks
    )
    |> validate_resource_capacity_and_contention_fields(path, row, callbacks)
    |> validate_cadence_policy_and_repair_fields(path, row, callbacks)
    |> validate_timing_feedback_and_lifecycle_fields(path, row, callbacks)
    |> validate_contact_priority_and_capacity_pack_fields(path, row, callbacks)
    |> validate_source_context_fields(path, row, callbacks)
    |> call(callbacks, :validate_source_operational_readiness_gate_handoff_matches, [path, row])
    |> call(callbacks, :validate_source_quality_gate_row_handoff_matches, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_fields, [path, row])
    |> call(callbacks, :validate_resource_projection_battery_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_resource_projection_count_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_resource_projection_flow_summary_context_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_link_capacity_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_link_capacity_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_fields, [path, row])
    |> call(callbacks, :validate_contact_allocation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_command_window_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_maneuver_review_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_timeline_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_timeline_transition_application_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_candidate_rejection_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_candidate_diff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_constraint_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_objective_satisfaction_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_score_term_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_objective_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_approval_requirement_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_plan_delta_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_risk_explanation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_operational_timeline_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_strategy_recommendation_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_strategy_tradeoff_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_ranking_comparison_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_pareto_frontier_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_realized_feedback_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_provider_counteroffer_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_intent_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_station_calendar_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_provider_calendar_contention_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_station_calendar_handoff_count_lists, [path, row])
    |> call(callbacks, :validate_suppression_duplicate_handoff_row_fields, [path, row])
    |> call(callbacks, :validate_suppression_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_contact_contention_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_operator_review_row_links, [path, row])
  end

  def validate_identity_and_activity_fields(issues, path, row, review_types, callbacks)
      when is_list(review_types) and is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, [path, row, @required_fields])
    |> call(callbacks, :validate_stable_ids, [path, row, @stable_id_fields])
    |> call(callbacks, :expect_number, [path, row, "rank"])
    |> call(callbacks, :expect_one_of, [path, row, "review_type", review_types])
    |> call(callbacks, :expect_type, [path, row, "source", :binary])
    |> call(callbacks, :expect_type, [path, row, "action", :binary])
    |> call(callbacks, :expect_type, [path, row, "required_operator_action", :binary])
    |> call(callbacks, :expect_type, [path, row, "reason", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "scenario_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "approval_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "locked", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "diff_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "repair_action", :binary])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "protection_category",
      @protection_categories
    ])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "protection_decision",
      ["preserved", "changed"]
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "activity_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "candidate_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "candidate_rejection_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "candidate_rejection_reasons", :list])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "candidate_rejection_reasons"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "primary_rejection_reason", :binary])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "candidate_rejection_reason_count"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "reviewable", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "violated_constraint", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "required_margin"])
    |> call(callbacks, :expect_optional_number, [path, row, "actual_margin"])
    |> call(callbacks, :expect_optional_type, [path, row, "activity_context", :map])
    |> call(callbacks, :validate_optional_activity_context, [path, row, "activity_context"])
  end

  def validate_activity_metadata_and_quality_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "spacecraft_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "window_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "maneuver_type", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "epoch_s"])
    |> call(callbacks, :expect_optional_type, [path, row, "epoch_scale", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "frame", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "delta_v_km_s", :list])
    |> call(callbacks, :expect_optional_number, [path, row, "delta_v_magnitude_km_s"])
    |> call(callbacks, :expect_optional_type, [path, row, "maneuver_model", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_activity_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_activity_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "planned_timeline_id", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "source_starts_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "source_ends_at_s"])
    |> call(callbacks, :expect_optional_type, [path, row, "source_approval_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_protection_category", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_protection_decision", :map])
    |> call(callbacks, :validate_optional_protection_decision, [
      path,
      row,
      "source_protection_decision"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_protection_reason", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "replacement_starts_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "replacement_ends_at_s"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_approval_status",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_protection_category",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_protection_decision",
      :map
    ])
    |> call(callbacks, :validate_optional_protection_decision, [
      path,
      row,
      "replacement_protection_decision"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_protection_reason",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "planned_activity", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_activity", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_activity_context", :map])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "realized_activity_context"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_activity_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_timeline_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_provider", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_adapter", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_adapter_version", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_external_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_schema_contract", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_received_at", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_ingested_at", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_trust_boundary", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_provenance", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_source", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "feedback_kind", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "direction", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "ground_station_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "target_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_target", :map])
    |> call(callbacks, :validate_scoped_downlink_context_fields, [path, row])
    |> call(callbacks, :validate_observation_quality_handoff_fields, [path, row])
    |> call(callbacks, :validate_feedback_maneuver_handoff_fields, [path, row])
    |> call(callbacks, :validate_link_handoff_fields, [path, row])
    |> call(callbacks, :validate_completion_fraction_fields, [path, row])
    |> call(callbacks, :validate_eclipse_lighting_handoff_fields, [path, row])
    |> call(callbacks, :validate_thermal_handoff_fields, [path, row])
    |> call(callbacks, :expect_optional_probability, [path, row, "attitude_confidence"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_latitude_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_longitude_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_minimum_elevation_deg"])
    |> call(callbacks, :expect_optional_number, [path, row, "target_priority"])
    |> call(callbacks, :expect_optional_type, [path, row, "target_priority_source", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "target_priority_objective_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "target_priority_objective_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "target_priority_objective_type",
      :binary
    ])
    |> call(callbacks, :validate_semantic_change_details, [path, row])
    |> call(callbacks, :validate_candidate_diff_changed_fields, [path, row])
  end

  def validate_relationship_and_source_window_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_non_negative_integer, [path, row, "contact_count"])
    |> call(callbacks, :expect_optional_type, [path, row, "contact_ids", :list])
    |> call(callbacks, :expect_optional_type, [path, row, "scenario_ids", :list])
    |> call(callbacks, :expect_optional_non_negative_integer, [path, row, "activity_count"])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "effective_activity_count"
    ])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "ignored_activity_count"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "ignored_activity_ids", :list])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "ignored_activity_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "dependency_activity_ids", :list])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "dependency_activity_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "dependency_timeline_ids", :list])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "dependency_timeline_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "exclusive_with_activity_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "exclusive_with_activity_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "exclusive_with_timeline_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "exclusive_with_timeline_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "match_strategy", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_ids", :list])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "source_window_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_types", :list])
    |> call(callbacks, :validate_string_list_items, [path, row, "source_window_types"])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_type", :binary])
    |> call(callbacks, :validate_optional_source_window, [path, row, "source_window"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_source_window_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_activity_type",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_kind",
      :binary
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "first_resource_pressure_starts_at_s"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_source_window_type",
      :binary
    ])
    |> call(callbacks, :validate_optional_source_window, [
      path,
      row,
      "first_resource_pressure_source_window"
    ])
    |> call(callbacks, :validate_nested_id_match, [
      path,
      row,
      "first_resource_pressure_source_window",
      "id",
      "first_resource_pressure_source_window_id",
      "must match first_resource_pressure_source_window_id"
    ])
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "source_window_lineage"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_candidate_id", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_source_window_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_source_window_type",
      :binary
    ])
    |> call(callbacks, :validate_optional_source_window, [
      path,
      row,
      "replacement_source_window"
    ])
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "replacement_source_window_lineage"
    ])
  end

  def validate_station_calendar_and_counteroffer_fields(
        issues,
        path,
        row,
        provider_counteroffer_negotiation_states,
        callbacks
      )
      when is_list(provider_counteroffer_negotiation_states) and is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "station_availability", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_entry_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_provider_id", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_provider_entry_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "provider_counteroffer_status", :binary])
    |> call(callbacks, :expect_optional_one_of, [
      path,
      row,
      "provider_counteroffer_negotiation_state",
      provider_counteroffer_negotiation_states
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "provider_counteroffer_reason_code",
      :binary
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "provider_counteroffer_cost_delta"])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_lock_deadline_s"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_starts_at_s"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_ends_at_s"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_start_delta_s"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_end_delta_s"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "provider_counteroffer_duration_delta_s"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_provider_counteroffer", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_station_calendar_provider_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "first_resource_pressure_station_calendar_provider_entry_id",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_directions", :list])
    |> call(callbacks, :validate_string_list_items, [path, row, "station_calendar_directions"])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_status", :binary])
    |> call(callbacks, :expect_optional_integer, [path, row, "station_calendar_overlap_count"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_overlap_entry_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_overlap_entry_ids"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_overlap_availabilities",
      :list
    ])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_overlap_availabilities"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_entry_ambiguous",
      :boolean
    ])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "station_calendar_ambiguous_entry_count"
    ])
    |> call(callbacks, :expect_field_at_least, [
      path,
      row,
      "station_calendar_ambiguous_entry_count",
      0
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_ambiguous_entry_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    ])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "station_calendar_reservation_overlap_count"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_ids",
      :list
    ])
    |> call(callbacks, :validate_optional_stable_id_list, [
      path,
      row,
      "station_calendar_reservation_ids"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "station_calendar_reserved_by", :list])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_reserved_by"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_statuses",
      :list
    ])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "station_calendar_reservation_statuses"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_reservation_expires_at_s",
      :list
    ])
    |> call(callbacks, :validate_number_list_items, [
      path,
      row,
      "station_calendar_reservation_expires_at_s"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "station_calendar_trust_boundary_status",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "trust_boundary", :binary])
  end

  def validate_resource_capacity_and_contention_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :validate_contact_allocation_capacity_pack_group, [path, row])
    |> call(callbacks, :validate_contact_allocation_capacity_pack_handoff_matches_source, [
      path,
      row
    ])
    |> call(callbacks, :validate_station_capacity_fraction_fields, [path, row])
    |> call(callbacks, :expect_optional_number, [path, row, "estimated_throughput_mb"])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "selected_contact_count"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "selected_contact_ids", :list])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "selected_estimated_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "capacity_adjusted_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "selected_capacity_adjusted_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "observation_count"
    ])
    |> call(callbacks, :expect_optional_non_negative_integer, [path, row, "downlink_count"])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "estimated_storage_produced_mb"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "estimated_downlink_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "starting_storage_used_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_storage_used_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "storage_capacity_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "starting_storage_margin"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_storage_margin"])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "projected_storage_remaining_mb"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "downlink_capacity_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "starting_downlink_margin"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_downlink_margin"])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "projected_downlink_remaining_mb"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "resource_source_quality", :binary])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "resource_flow_count"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "peak_storage_overflow_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "peak_downlink_shortfall_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_storage_overflow_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_downlink_shortfall_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "peak_unused_downlink_capacity_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "projected_battery_overuse_wh"])
    |> call(callbacks, :expect_optional_number, [path, row, "fuel_margin"])
    |> call(callbacks, :expect_optional_number, [path, row, "power_margin"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "resource_trust_boundary_status",
      :binary
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "storage_limited_downlinked_mb"])
    |> call(callbacks, :expect_optional_number, [path, row, "unused_downlink_capacity_mb"])
    |> call(callbacks, :validate_resource_availability_variance_fields, [path, row])
    |> call(callbacks, :expect_optional_type, [path, row, "warnings", :list])
    |> call(callbacks, :expect_optional_type, [path, row, "station_contention_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "station_reservation_id", :binary])
    |> call(callbacks, :expect_optional_number_or_number_list, [
      path,
      row,
      "station_reservation_expires_at_s"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "station_reserved_by", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "station_reservation_status", :binary])
  end

  def validate_cadence_policy_and_repair_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "cadence_import_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "cadence_import_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "operator_action_reason", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "execution_boundary", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_window_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "has_source_window", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "has_cadence_import", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "planned_operator_action", :binary])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "planned_operator_action_reason",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "planned_protection_category",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "planned_protection_decision",
      :binary
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "planned_protection_reason", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "review_queue", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "review_queue_key", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "requirement_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "policy_bundle_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "rule_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "risk_type", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "dimension", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "left_rank"])
    |> call(callbacks, :expect_optional_number, [path, row, "right_rank"])
    |> call(callbacks, :expect_optional_number, [path, row, "rank_delta"])
    |> call(callbacks, :expect_optional_number, [path, row, "left_value"])
    |> call(callbacks, :expect_optional_number, [path, row, "right_value"])
    |> call(callbacks, :expect_optional_number, [path, row, "value_delta"])
    |> call(callbacks, :expect_optional_type, [path, row, "severity", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "baseline"])
    |> call(callbacks, :expect_optional_number, [path, row, "recommended"])
    |> call(callbacks, :expect_optional_number, [path, row, "delta"])
    |> call(callbacks, :expect_optional_number, [path, row, "repair_score"])
    |> call(callbacks, :expect_optional_number, [path, row, "repair_activity_score"])
    |> call(callbacks, :expect_optional_number, [path, row, "repair_schedule_churn_penalty"])
    |> call(callbacks, :expect_optional_number, [path, row, "repair_schedule_move_penalty"])
    |> call(callbacks, :expect_optional_type, [path, row, "repair_score_term_keys", :list])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "repair_link_selected_estimated_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "repair_link_actual_throughput_mb"])
    |> call(callbacks, :expect_optional_probability, [
      path,
      row,
      "repair_link_actual_downlink_completion_ratio"
    ])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "repair_link_actual_downlink_shortfall_mb"
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "repair_link_actual_downlink_requirement_status",
      :binary
    ])
  end

  def validate_timing_feedback_and_lifecycle_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_number, [path, row, "starts_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "ends_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "contention_window_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "total_contact_duration_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "overlap_duration_s"])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "max_concurrent_contacts"
    ])
    |> call(callbacks, :expect_optional_non_negative_integer, [
      path,
      row,
      "overlap_contact_pair_count"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "planned_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "realized_status", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "feedback_status", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "planned_starts_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "planned_ends_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "actual_starts_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "actual_ends_at_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "start_delta_s"])
    |> call(callbacks, :expect_optional_number, [path, row, "end_delta_s"])
    |> call(callbacks, :expect_optional_number, [
      path,
      row,
      "planned_estimated_throughput_mb"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "actual_throughput_mb"])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "actual_data_rate_throughput_derivation",
      :map
    ])
    |> call(callbacks, :validate_optional_actual_data_rate_throughput_derivation, [
      path,
      row,
      "actual_data_rate_throughput_derivation"
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "throughput_delta_mb"])
    |> call(callbacks, :expect_optional_probability, [
      path,
      row,
      "throughput_completion_fraction"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "contact_success", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "command_success", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "command_result", :binary])
    |> call(callbacks, :expect_optional_probability, [path, row, "completed_fraction"])
    |> call(callbacks, :expect_optional_type, [path, row, "requires_operator_review", :boolean])
    |> call(callbacks, :expect_optional_type, [path, row, "changed_fields", :list])
    |> call(callbacks, :expect_optional_type, [path, row, "status_transition", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "approval_transition", :map])
    |> call(callbacks, :validate_optional_lifecycle_transition, [
      path,
      row,
      "status_transition"
    ])
    |> call(callbacks, :validate_optional_lifecycle_transition, [
      path,
      row,
      "approval_transition"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "escalation_level", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "escalation_queue", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "escalation_role", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "required_authority", :binary])
    |> call(callbacks, :expect_optional_number, [path, row, "sla_s"])
  end

  def validate_contact_priority_and_capacity_pack_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "selected_contact_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "deferred_contact_ids", :list])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_contact_ids_by_direction",
      :map
    ])
    |> call(callbacks, :validate_stable_id_array_map, [
      path <> ".capacity_pack_contact_ids_by_direction",
      Map.get(row, "capacity_pack_contact_ids_by_direction")
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_selected_contact_ids_by_direction",
      :map
    ])
    |> call(callbacks, :validate_stable_id_array_map, [
      path <> ".capacity_pack_selected_contact_ids_by_direction",
      Map.get(row, "capacity_pack_selected_contact_ids_by_direction")
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_deferred_contact_ids_by_direction",
      :map
    ])
    |> call(callbacks, :validate_stable_id_array_map, [
      path <> ".capacity_pack_deferred_contact_ids_by_direction",
      Map.get(row, "capacity_pack_deferred_contact_ids_by_direction")
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    ])
    |> call(callbacks, :validate_non_negative_number_map, [
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_required_capacity_fraction_by_direction")
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      :map
    ])
    |> call(callbacks, :validate_non_negative_number_map, [
      path <> ".capacity_pack_selected_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_selected_required_capacity_fraction_by_direction")
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      :map
    ])
    |> call(callbacks, :validate_non_negative_number_map, [
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_deferred_required_capacity_fraction_by_direction")
    ])
    |> call(callbacks, :expect_optional_number, [path, row, "selected_priority"])
    |> call(callbacks, :expect_optional_type, [path, row, "selected_priority_source", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "deferred_contact_priorities", :list])
    |> call(callbacks, :validate_optional_rows, [
      path <> ".deferred_contact_priorities",
      Map.get(row, "deferred_contact_priorities"),
      require_callback(callbacks, :validate_contact_contention_deferred_priority)
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "resolution_priority_fields", :list])
    |> call(callbacks, :validate_string_list_items, [path, row, "resolution_priority_fields"])
    |> call(callbacks, :expect_optional_type, [path, row, "requested_priority_fields", :list])
    |> call(callbacks, :validate_string_list_items, [path, row, "requested_priority_fields"])
    |> call(callbacks, :expect_optional_type, [path, row, "priority_field_evidence_counts", :map])
    |> call(callbacks, :validate_priority_field_evidence_counts, [
      path <> ".priority_field_evidence_counts",
      Map.get(row, "priority_field_evidence_counts")
    ])
    |> call(callbacks, :expect_optional_integer, [
      path,
      row,
      "priority_fields_without_numeric_evidence_count"
    ])
    |> call(callbacks, :expect_field_at_least, [
      path,
      row,
      "priority_fields_without_numeric_evidence_count",
      0
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "priority_fields_without_numeric_evidence",
      :list
    ])
    |> call(callbacks, :validate_string_list_items, [
      path,
      row,
      "priority_fields_without_numeric_evidence"
    ])
  end

  def validate_source_context_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_source_reference_fields(path, row, callbacks)
    |> validate_source_status_fields(path, row, callbacks)
    |> validate_timeline_source_context_fields(path, row, callbacks)
    |> validate_activity_context_fields(path, row, callbacks)
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_protection", :map])
    |> call(callbacks, :validate_optional_timeline_protection_summary, [
      path,
      row,
      "source_timeline_protection"
    ])
    |> call(callbacks, :validate_operational_readiness_resource_context, [path, row])
  end

  defp validate_source_reference_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_activity_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_timeline_id", :binary])
    |> call(callbacks, :expect_optional_type, [path, row, "source_requirement", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "candidate_diff", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_risk", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_recommendation", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_tradeoff", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_branch_comparison", :map])
    |> call(callbacks, :validate_optional_branch_comparison_source_row, [
      path <> ".source_branch_comparison",
      Map.get(row, "source_branch_comparison")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_pareto_frontier", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_ranking_comparison", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_feedback", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_contention_group", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_invalid_contact_input", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_command_window", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_maneuver_review", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_station_calendar_review", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_link_capacity", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_resource_projection", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_resource_projection_flow_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_delta", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_policy_decision", :map])
    |> call(callbacks, :validate_optional_policy_decision_evidence, [
      "#{path}.source_policy_decision",
      Map.get(row, "source_policy_decision")
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_policy_escalation", :map])
    |> call(callbacks, :validate_optional_policy_escalation, [
      path,
      row,
      "source_policy_escalation"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_contact_suppression", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_resource_suppression", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_candidate_rejection", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_dependency_impact",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_publication_summary",
      :map
    ])
    |> call(callbacks, :validate_optional_timeline_dependency_impact_source_row, [
      path <> ".source_timeline_dependency_impact",
      Map.get(row, "source_timeline_dependency_impact")
    ])
    |> call(callbacks, :validate_optional_timeline_publication_summary_source, [
      path <> ".source_timeline_publication_summary",
      Map.get(row, "source_timeline_publication_summary")
    ])
    |> call(callbacks, :validate_timeline_publication_handoff_matches_source, [path, row])
  end

  defp validate_source_status_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_diff", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_quality_gate_row", :map])
    |> call(callbacks, :validate_source_evidence_fields, [path, row])
    |> call(callbacks, :validate_source_operational_readiness_report_handoff_matches, [
      path,
      row
    ])
    |> call(callbacks, :validate_source_quality_gate_report_handoff_matches, [path, row])
    |> call(callbacks, :validate_freshness_source_status_matches, [path, row])
    |> call(callbacks, :validate_refresh_budget_handoff_matches_source, [path, row])
    |> call(callbacks, :validate_schema_validation_source_status_matches, [path, row])
    |> call(callbacks, :validate_execution_source_status_matches, [path, row])
    |> call(callbacks, :validate_selected_timeline_integrity_fields, [path, row])
  end

  defp validate_timeline_source_context_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_diff_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_transition_application_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_application", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_integrity", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_activity_state",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_lifecycle_state",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_activity_precondition_summary",
      :map
    ])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "source_timeline_preservation",
      :map
    ])
    |> call(callbacks, :validate_optional_timeline_diff_summary_source, [
      path <> ".source_timeline_diff_summary",
      Map.get(row, "source_timeline_diff_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_summary_source, [
      path <> ".source_timeline_transition_application_summary",
      Map.get(row, "source_timeline_transition_application_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_transition_application_row, [
      path <> ".source_timeline_application",
      Map.get(row, "source_timeline_application")
    ])
    |> call(callbacks, :validate_optional_timeline_integrity_source_row, [
      path <> ".source_timeline_integrity",
      Map.get(row, "source_timeline_integrity")
    ])
    |> call(callbacks, :validate_optional_timeline_activity_state_source, [
      path <> ".source_timeline_activity_state",
      Map.get(row, "source_timeline_activity_state")
    ])
    |> call(callbacks, :validate_optional_timeline_lifecycle_state_source_row, [
      path <> ".source_timeline_lifecycle_state",
      Map.get(row, "source_timeline_lifecycle_state")
    ])
    |> call(callbacks, :validate_optional_timeline_activity_precondition_summary_source, [
      path <> ".source_timeline_activity_precondition_summary",
      Map.get(row, "source_timeline_activity_precondition_summary")
    ])
    |> call(callbacks, :validate_optional_timeline_preservation_source_row, [
      path <> ".source_timeline_preservation",
      Map.get(row, "source_timeline_preservation")
    ])
    |> call(callbacks, :validate_branch_event_summary_fields, [path, row])
  end

  defp validate_activity_context_fields(issues, path, row, callbacks) do
    issues
    |> call(callbacks, :expect_optional_type, [path, row, "timeline_identity", :map])
    |> call(callbacks, :validate_optional_timeline_identity, [path, row, "timeline_identity"])
    |> call(callbacks, :expect_optional_type, [path, row, "timeline_link", :map])
    |> call(callbacks, :validate_optional_timeline_link, [path, row, "timeline_link"])
    |> call(callbacks, :expect_optional_type, [path, row, "source_activity_context", :map])
    |> call(callbacks, :expect_optional_type, [path, row, "replacement_activity_context", :map])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "source_activity_context"
    ])
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "replacement_activity_context"
    ])
    |> call(callbacks, :expect_optional_type, [path, row, "source_timeline_identity", :map])
    |> call(callbacks, :expect_optional_type, [
      path,
      row,
      "replacement_timeline_identity",
      :map
    ])
    |> call(callbacks, :validate_optional_timeline_identity, [
      path,
      row,
      "source_timeline_identity"
    ])
    |> call(callbacks, :validate_optional_timeline_identity, [
      path,
      row,
      "replacement_timeline_identity"
    ])
  end

  defp call(issues, callbacks, name, args) do
    apply(require_callback(callbacks, name), [issues | args])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
