defmodule OrbitalDynamics.Schema.OperatorReviewRowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_number_or_number_list: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_number_map: 3,
      validate_number_list_items: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_id_match: 7,
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

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
    |> require_fields(path, row, @required_fields)
    |> validate_stable_ids(path, row, @stable_id_fields)
    |> expect_number(path, row, "rank")
    |> expect_one_of(path, row, "review_type", review_types)
    |> expect_type(path, row, "source", :binary)
    |> expect_type(path, row, "action", :binary)
    |> expect_type(path, row, "required_operator_action", :binary)
    |> expect_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "scenario_id", :binary)
    |> expect_optional_type(path, row, "approval_status", :binary)
    |> expect_optional_type(path, row, "status", :binary)
    |> expect_optional_type(path, row, "locked", :boolean)
    |> expect_optional_type(path, row, "diff_status", :binary)
    |> expect_optional_type(path, row, "repair_action", :binary)
    |> expect_optional_one_of(
      path,
      row,
      "protection_category",
      @protection_categories
    )
    |> expect_optional_one_of(
      path,
      row,
      "protection_decision",
      ["preserved", "changed"]
    )
    |> expect_optional_type(path, row, "activity_type", :binary)
    |> expect_optional_type(path, row, "candidate_id", :binary)
    |> expect_optional_type(path, row, "candidate_rejection_status", :binary)
    |> expect_optional_type(path, row, "candidate_rejection_reasons", :list)
    |> validate_string_list_items(
      path,
      row,
      "candidate_rejection_reasons"
    )
    |> expect_optional_type(path, row, "primary_rejection_reason", :binary)
    |> expect_optional_integer(
      path,
      row,
      "candidate_rejection_reason_count"
    )
    |> expect_optional_type(path, row, "reviewable", :boolean)
    |> expect_optional_type(path, row, "violated_constraint", :binary)
    |> expect_optional_number(path, row, "required_margin")
    |> expect_optional_number(path, row, "actual_margin")
    |> expect_optional_type(path, row, "activity_context", :map)
    |> call(callbacks, :validate_optional_activity_context, [path, row, "activity_context"])
  end

  def validate_activity_metadata_and_quality_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(path, row, "spacecraft_id", :binary)
    |> expect_optional_type(path, row, "window_type", :binary)
    |> expect_optional_type(path, row, "maneuver_type", :binary)
    |> expect_optional_number(path, row, "epoch_s")
    |> expect_optional_type(path, row, "epoch_scale", :binary)
    |> expect_optional_type(path, row, "frame", :binary)
    |> expect_optional_type(path, row, "delta_v_km_s", :list)
    |> expect_optional_number(path, row, "delta_v_magnitude_km_s")
    |> expect_optional_type(path, row, "maneuver_model", :binary)
    |> expect_optional_type(path, row, "source_activity_type", :binary)
    |> expect_optional_type(path, row, "replacement_activity_type", :binary)
    |> expect_optional_type(path, row, "planned_timeline_id", :binary)
    |> expect_optional_number(path, row, "source_starts_at_s")
    |> expect_optional_number(path, row, "source_ends_at_s")
    |> expect_optional_type(path, row, "source_approval_status", :binary)
    |> expect_optional_type(path, row, "source_protection_category", :binary)
    |> expect_optional_type(path, row, "source_protection_decision", :map)
    |> call(callbacks, :validate_optional_protection_decision, [
      path,
      row,
      "source_protection_decision"
    ])
    |> expect_optional_type(path, row, "source_protection_reason", :binary)
    |> expect_optional_number(path, row, "replacement_starts_at_s")
    |> expect_optional_number(path, row, "replacement_ends_at_s")
    |> expect_optional_type(
      path,
      row,
      "replacement_approval_status",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "replacement_protection_category",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "replacement_protection_decision",
      :map
    )
    |> call(callbacks, :validate_optional_protection_decision, [
      path,
      row,
      "replacement_protection_decision"
    ])
    |> expect_optional_type(
      path,
      row,
      "replacement_protection_reason",
      :binary
    )
    |> expect_optional_type(path, row, "planned_activity", :map)
    |> expect_optional_type(path, row, "realized_activity", :map)
    |> expect_optional_type(path, row, "realized_activity_context", :map)
    |> call(callbacks, :validate_optional_activity_context, [
      path,
      row,
      "realized_activity_context"
    ])
    |> expect_optional_type(path, row, "realized_activity_id", :binary)
    |> expect_optional_type(path, row, "realized_timeline_id", :binary)
    |> expect_optional_type(path, row, "realized_type", :binary)
    |> expect_optional_type(path, row, "realized_provider", :binary)
    |> expect_optional_type(path, row, "realized_adapter", :binary)
    |> expect_optional_type(path, row, "realized_adapter_version", :binary)
    |> expect_optional_type(path, row, "realized_external_id", :binary)
    |> expect_optional_type(path, row, "realized_schema_contract", :binary)
    |> expect_optional_type(path, row, "realized_received_at", :binary)
    |> expect_optional_type(path, row, "realized_ingested_at", :binary)
    |> expect_optional_type(path, row, "realized_trust_boundary", :binary)
    |> expect_optional_type(path, row, "realized_provenance", :map)
    |> expect_optional_type(path, row, "realized_source", :map)
    |> expect_optional_type(path, row, "feedback_kind", :binary)
    |> expect_optional_type(path, row, "direction", :binary)
    |> expect_optional_type(path, row, "ground_station_id", :binary)
    |> expect_optional_type(path, row, "target_id", :binary)
    |> expect_optional_type(path, row, "source_target", :map)
    |> call(callbacks, :validate_scoped_downlink_context_fields, [path, row])
    |> call(callbacks, :validate_observation_quality_handoff_fields, [path, row])
    |> call(callbacks, :validate_feedback_maneuver_handoff_fields, [path, row])
    |> call(callbacks, :validate_link_handoff_fields, [path, row])
    |> call(callbacks, :validate_completion_fraction_fields, [path, row])
    |> call(callbacks, :validate_eclipse_lighting_handoff_fields, [path, row])
    |> call(callbacks, :validate_thermal_handoff_fields, [path, row])
    |> expect_optional_probability(path, row, "attitude_confidence")
    |> expect_optional_number(path, row, "target_latitude_deg")
    |> expect_optional_number(path, row, "target_longitude_deg")
    |> expect_optional_number(path, row, "target_minimum_elevation_deg")
    |> expect_optional_number(path, row, "target_priority")
    |> expect_optional_type(path, row, "target_priority_source", :binary)
    |> expect_optional_type(
      path,
      row,
      "target_priority_objective_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "target_priority_objective_type",
      :binary
    )
    |> call(callbacks, :validate_semantic_change_details, [path, row])
    |> call(callbacks, :validate_candidate_diff_changed_fields, [path, row])
  end

  def validate_relationship_and_source_window_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(path, row, "contact_count")
    |> expect_optional_type(path, row, "contact_ids", :list)
    |> expect_optional_type(path, row, "scenario_ids", :list)
    |> expect_optional_non_negative_integer(path, row, "activity_count")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "effective_activity_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "ignored_activity_count"
    )
    |> expect_optional_type(path, row, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "ignored_activity_ids"
    )
    |> expect_optional_type(path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "dependency_activity_ids"
    )
    |> expect_optional_type(path, row, "dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "dependency_timeline_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "exclusive_with_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "exclusive_with_activity_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "exclusive_with_timeline_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "exclusive_with_timeline_ids"
    )
    |> expect_optional_type(path, row, "match_strategy", :binary)
    |> expect_optional_type(path, row, "source_window_id", :binary)
    |> expect_optional_type(path, row, "source_window_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "source_window_ids"
    )
    |> expect_optional_type(path, row, "source_window_types", :list)
    |> validate_string_list_items(path, row, "source_window_types")
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> call(callbacks, :validate_optional_source_window, [path, row, "source_window"])
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_source_window_id",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_activity_type",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_kind",
      :binary
    )
    |> expect_optional_number(
      path,
      row,
      "first_resource_pressure_starts_at_s"
    )
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_source_window_type",
      :binary
    )
    |> call(callbacks, :validate_optional_source_window, [
      path,
      row,
      "first_resource_pressure_source_window"
    ])
    |> validate_nested_id_match(
      path,
      row,
      "first_resource_pressure_source_window",
      "id",
      "first_resource_pressure_source_window_id",
      "must match first_resource_pressure_source_window_id"
    )
    |> call(callbacks, :validate_optional_source_window_lineage, [
      path,
      row,
      "source_window_lineage"
    ])
    |> expect_optional_type(path, row, "replacement_candidate_id", :binary)
    |> expect_optional_type(
      path,
      row,
      "replacement_source_window_id",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "replacement_source_window_type",
      :binary
    )
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
    |> expect_optional_type(path, row, "station_availability", :binary)
    |> expect_optional_type(path, row, "station_calendar_entry_id", :binary)
    |> expect_optional_type(path, row, "station_calendar_provider_id", :binary)
    |> expect_optional_type(
      path,
      row,
      "station_calendar_provider_entry_id",
      :binary
    )
    |> expect_optional_type(path, row, "provider_counteroffer_status", :binary)
    |> expect_optional_one_of(
      path,
      row,
      "provider_counteroffer_negotiation_state",
      provider_counteroffer_negotiation_states
    )
    |> expect_optional_type(
      path,
      row,
      "provider_counteroffer_reason_code",
      :binary
    )
    |> expect_optional_number(path, row, "provider_counteroffer_cost_delta")
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_lock_deadline_s"
    )
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_starts_at_s"
    )
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_ends_at_s"
    )
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_start_delta_s"
    )
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_end_delta_s"
    )
    |> expect_optional_number(
      path,
      row,
      "provider_counteroffer_duration_delta_s"
    )
    |> expect_optional_type(path, row, "source_provider_counteroffer", :map)
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_station_calendar_provider_id",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_station_calendar_provider_entry_id",
      :binary
    )
    |> expect_optional_type(path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(path, row, "station_calendar_directions")
    |> expect_optional_type(path, row, "station_calendar_status", :binary)
    |> expect_optional_integer(path, row, "station_calendar_overlap_count")
    |> expect_optional_type(
      path,
      row,
      "station_calendar_overlap_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "station_calendar_overlap_entry_ids"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_overlap_availabilities",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "station_calendar_overlap_availabilities"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_entry_ambiguous",
      :boolean
    )
    |> expect_optional_integer(
      path,
      row,
      "station_calendar_ambiguous_entry_count"
    )
    |> expect_field_at_least(
      path,
      row,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_ambiguous_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_integer(
      path,
      row,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_reservation_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_type(path, row, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(
      path,
      row,
      "station_calendar_reserved_by"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_reservation_statuses",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "station_calendar_reservation_statuses"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      row,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_type(
      path,
      row,
      "station_calendar_trust_boundary_status",
      :binary
    )
    |> expect_optional_type(path, row, "trust_boundary", :binary)
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
    |> expect_optional_number(path, row, "estimated_throughput_mb")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "selected_contact_count"
    )
    |> expect_optional_type(path, row, "selected_contact_ids", :list)
    |> expect_optional_number(
      path,
      row,
      "selected_estimated_throughput_mb"
    )
    |> expect_optional_number(
      path,
      row,
      "capacity_adjusted_throughput_mb"
    )
    |> expect_optional_number(
      path,
      row,
      "selected_capacity_adjusted_throughput_mb"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "observation_count"
    )
    |> expect_optional_non_negative_integer(path, row, "downlink_count")
    |> expect_optional_number(
      path,
      row,
      "estimated_storage_produced_mb"
    )
    |> expect_optional_number(path, row, "estimated_downlink_mb")
    |> expect_optional_number(path, row, "starting_storage_used_mb")
    |> expect_optional_number(path, row, "projected_storage_used_mb")
    |> expect_optional_number(path, row, "storage_capacity_mb")
    |> expect_optional_number(path, row, "starting_storage_margin")
    |> expect_optional_number(path, row, "projected_storage_margin")
    |> expect_optional_number(
      path,
      row,
      "projected_storage_remaining_mb"
    )
    |> expect_optional_number(path, row, "downlink_capacity_mb")
    |> expect_optional_number(path, row, "starting_downlink_margin")
    |> expect_optional_number(path, row, "projected_downlink_margin")
    |> expect_optional_number(
      path,
      row,
      "projected_downlink_remaining_mb"
    )
    |> expect_optional_type(path, row, "resource_source_quality", :binary)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "resource_flow_count"
    )
    |> expect_optional_number(path, row, "peak_storage_overflow_mb")
    |> expect_optional_number(path, row, "peak_downlink_shortfall_mb")
    |> expect_optional_number(path, row, "projected_storage_overflow_mb")
    |> expect_optional_number(path, row, "projected_downlink_shortfall_mb")
    |> expect_optional_number(path, row, "peak_unused_downlink_capacity_mb")
    |> expect_optional_number(path, row, "projected_battery_overuse_wh")
    |> expect_optional_number(path, row, "fuel_margin")
    |> expect_optional_number(path, row, "power_margin")
    |> expect_optional_type(
      path,
      row,
      "resource_trust_boundary_status",
      :binary
    )
    |> expect_optional_number(path, row, "storage_limited_downlinked_mb")
    |> expect_optional_number(path, row, "unused_downlink_capacity_mb")
    |> call(callbacks, :validate_resource_availability_variance_fields, [path, row])
    |> expect_optional_type(path, row, "warnings", :list)
    |> expect_optional_type(path, row, "station_contention_status", :binary)
    |> expect_optional_type(path, row, "station_reservation_id", :binary)
    |> expect_optional_number_or_number_list(
      path,
      row,
      "station_reservation_expires_at_s"
    )
    |> expect_optional_type(path, row, "station_reserved_by", :binary)
    |> expect_optional_type(path, row, "station_reservation_status", :binary)
  end

  def validate_cadence_policy_and_repair_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(path, row, "cadence_import_status", :binary)
    |> expect_optional_type(path, row, "cadence_import_type", :binary)
    |> expect_optional_type(path, row, "operator_action_reason", :binary)
    |> expect_optional_type(path, row, "execution_boundary", :binary)
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> expect_optional_type(path, row, "has_source_window", :boolean)
    |> expect_optional_type(path, row, "has_cadence_import", :boolean)
    |> expect_optional_type(path, row, "planned_operator_action", :binary)
    |> expect_optional_type(
      path,
      row,
      "planned_operator_action_reason",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "planned_protection_category",
      :binary
    )
    |> expect_optional_type(
      path,
      row,
      "planned_protection_decision",
      :binary
    )
    |> expect_optional_type(path, row, "planned_protection_reason", :binary)
    |> expect_optional_type(path, row, "review_queue", :binary)
    |> expect_optional_type(path, row, "review_queue_key", :binary)
    |> expect_optional_type(path, row, "requirement_type", :binary)
    |> expect_optional_type(path, row, "policy_bundle_id", :binary)
    |> expect_optional_type(path, row, "rule_id", :binary)
    |> expect_optional_type(path, row, "risk_type", :binary)
    |> expect_optional_type(path, row, "dimension", :binary)
    |> expect_optional_number(path, row, "left_rank")
    |> expect_optional_number(path, row, "right_rank")
    |> expect_optional_number(path, row, "rank_delta")
    |> expect_optional_number(path, row, "left_value")
    |> expect_optional_number(path, row, "right_value")
    |> expect_optional_number(path, row, "value_delta")
    |> expect_optional_type(path, row, "severity", :binary)
    |> expect_optional_number(path, row, "baseline")
    |> expect_optional_number(path, row, "recommended")
    |> expect_optional_number(path, row, "delta")
    |> expect_optional_number(path, row, "repair_score")
    |> expect_optional_number(path, row, "repair_activity_score")
    |> expect_optional_number(path, row, "repair_schedule_churn_penalty")
    |> expect_optional_number(path, row, "repair_schedule_move_penalty")
    |> expect_optional_type(path, row, "repair_score_term_keys", :list)
    |> expect_optional_number(
      path,
      row,
      "repair_link_selected_estimated_throughput_mb"
    )
    |> expect_optional_number(
      path,
      row,
      "repair_link_selected_capacity_adjusted_throughput_mb"
    )
    |> expect_optional_number(path, row, "repair_link_actual_throughput_mb")
    |> expect_optional_probability(
      path,
      row,
      "repair_link_actual_downlink_completion_ratio"
    )
    |> expect_optional_number(
      path,
      row,
      "repair_link_actual_downlink_shortfall_mb"
    )
    |> expect_optional_type(
      path,
      row,
      "repair_link_actual_downlink_requirement_status",
      :binary
    )
  end

  def validate_timing_feedback_and_lifecycle_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_number(path, row, "starts_at_s")
    |> expect_optional_number(path, row, "ends_at_s")
    |> expect_optional_number(path, row, "contention_window_s")
    |> expect_optional_number(path, row, "total_contact_duration_s")
    |> expect_optional_number(path, row, "overlap_duration_s")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "max_concurrent_contacts"
    )
    |> expect_optional_non_negative_integer(
      path,
      row,
      "overlap_contact_pair_count"
    )
    |> expect_optional_type(path, row, "planned_status", :binary)
    |> expect_optional_type(path, row, "realized_status", :binary)
    |> expect_optional_type(path, row, "feedback_status", :binary)
    |> expect_optional_number(path, row, "planned_starts_at_s")
    |> expect_optional_number(path, row, "planned_ends_at_s")
    |> expect_optional_number(path, row, "actual_starts_at_s")
    |> expect_optional_number(path, row, "actual_ends_at_s")
    |> expect_optional_number(path, row, "start_delta_s")
    |> expect_optional_number(path, row, "end_delta_s")
    |> expect_optional_number(
      path,
      row,
      "planned_estimated_throughput_mb"
    )
    |> expect_optional_number(path, row, "actual_throughput_mb")
    |> expect_optional_type(
      path,
      row,
      "actual_data_rate_throughput_derivation",
      :map
    )
    |> call(callbacks, :validate_optional_actual_data_rate_throughput_derivation, [
      path,
      row,
      "actual_data_rate_throughput_derivation"
    ])
    |> expect_optional_number(path, row, "throughput_delta_mb")
    |> expect_optional_probability(
      path,
      row,
      "throughput_completion_fraction"
    )
    |> expect_optional_type(path, row, "contact_success", :boolean)
    |> expect_optional_type(path, row, "command_success", :boolean)
    |> expect_optional_type(path, row, "command_result", :binary)
    |> expect_optional_probability(path, row, "completed_fraction")
    |> expect_optional_type(path, row, "requires_operator_review", :boolean)
    |> expect_optional_type(path, row, "changed_fields", :list)
    |> expect_optional_type(path, row, "status_transition", :map)
    |> expect_optional_type(path, row, "approval_transition", :map)
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
    |> expect_optional_type(path, row, "escalation_level", :binary)
    |> expect_optional_type(path, row, "escalation_queue", :binary)
    |> expect_optional_type(path, row, "escalation_role", :binary)
    |> expect_optional_type(path, row, "required_authority", :binary)
    |> expect_optional_number(path, row, "sla_s")
  end

  def validate_contact_priority_and_capacity_pack_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(path, row, "selected_contact_id", :binary)
    |> expect_optional_type(path, row, "deferred_contact_ids", :list)
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_contact_ids_by_direction",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_contact_ids_by_direction",
      Map.get(row, "capacity_pack_contact_ids_by_direction")
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_selected_contact_ids_by_direction",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_selected_contact_ids_by_direction",
      Map.get(row, "capacity_pack_selected_contact_ids_by_direction")
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_deferred_contact_ids_by_direction",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".capacity_pack_deferred_contact_ids_by_direction",
      Map.get(row, "capacity_pack_deferred_contact_ids_by_direction")
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_selected_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_selected_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_selected_required_capacity_fraction_by_direction")
    )
    |> expect_optional_type(
      path,
      row,
      "capacity_pack_deferred_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      path <> ".capacity_pack_deferred_required_capacity_fraction_by_direction",
      Map.get(row, "capacity_pack_deferred_required_capacity_fraction_by_direction")
    )
    |> expect_optional_number(path, row, "selected_priority")
    |> expect_optional_type(path, row, "selected_priority_source", :binary)
    |> expect_optional_type(path, row, "deferred_contact_priorities", :list)
    |> validate_optional_rows(
      path <> ".deferred_contact_priorities",
      Map.get(row, "deferred_contact_priorities"),
      require_callback(callbacks, :validate_contact_contention_deferred_priority)
    )
    |> expect_optional_type(path, row, "resolution_priority_fields", :list)
    |> validate_string_list_items(path, row, "resolution_priority_fields")
    |> expect_optional_type(path, row, "requested_priority_fields", :list)
    |> validate_string_list_items(path, row, "requested_priority_fields")
    |> expect_optional_type(path, row, "priority_field_evidence_counts", :map)
    |> call(callbacks, :validate_priority_field_evidence_counts, [
      path <> ".priority_field_evidence_counts",
      Map.get(row, "priority_field_evidence_counts")
    ])
    |> expect_optional_integer(
      path,
      row,
      "priority_fields_without_numeric_evidence_count"
    )
    |> expect_field_at_least(
      path,
      row,
      "priority_fields_without_numeric_evidence_count",
      0
    )
    |> expect_optional_type(
      path,
      row,
      "priority_fields_without_numeric_evidence",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "priority_fields_without_numeric_evidence"
    )
  end

  def validate_source_context_fields(issues, path, row, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_source_reference_fields(path, row, callbacks)
    |> validate_source_status_fields(path, row, callbacks)
    |> validate_timeline_source_context_fields(path, row, callbacks)
    |> validate_activity_context_fields(path, row, callbacks)
    |> expect_optional_type(path, row, "source_timeline_protection", :map)
    |> call(callbacks, :validate_optional_timeline_protection_summary, [
      path,
      row,
      "source_timeline_protection"
    ])
    |> call(callbacks, :validate_operational_readiness_resource_context, [path, row])
  end

  defp validate_source_reference_fields(issues, path, row, callbacks) do
    issues
    |> expect_optional_type(path, row, "source_timeline_id", :binary)
    |> expect_optional_type(path, row, "replacement_activity_id", :binary)
    |> expect_optional_type(path, row, "replacement_timeline_id", :binary)
    |> expect_optional_type(path, row, "source_requirement", :map)
    |> expect_optional_type(path, row, "candidate_diff", :map)
    |> expect_optional_type(path, row, "source_risk", :map)
    |> expect_optional_type(path, row, "source_recommendation", :map)
    |> expect_optional_type(path, row, "source_tradeoff", :map)
    |> expect_optional_type(path, row, "source_branch_comparison", :map)
    |> call(callbacks, :validate_optional_branch_comparison_source_row, [
      path <> ".source_branch_comparison",
      Map.get(row, "source_branch_comparison")
    ])
    |> expect_optional_type(path, row, "source_pareto_frontier", :map)
    |> expect_optional_type(path, row, "source_ranking_comparison", :map)
    |> expect_optional_type(path, row, "source_feedback", :map)
    |> expect_optional_type(path, row, "source_contention_group", :map)
    |> expect_optional_type(path, row, "source_invalid_contact_input", :map)
    |> expect_optional_type(path, row, "source_command_window", :map)
    |> expect_optional_type(path, row, "source_maneuver_review", :map)
    |> expect_optional_type(path, row, "source_station_calendar_review", :map)
    |> expect_optional_type(path, row, "source_link_capacity", :map)
    |> expect_optional_type(path, row, "source_resource_projection", :map)
    |> expect_optional_type(
      path,
      row,
      "source_resource_projection_flow_summary",
      :map
    )
    |> expect_optional_type(path, row, "source_delta", :map)
    |> expect_optional_type(path, row, "source_policy_decision", :map)
    |> call(callbacks, :validate_optional_policy_decision_evidence, [
      "#{path}.source_policy_decision",
      Map.get(row, "source_policy_decision")
    ])
    |> expect_optional_type(path, row, "source_policy_escalation", :map)
    |> call(callbacks, :validate_optional_policy_escalation, [
      path,
      row,
      "source_policy_escalation"
    ])
    |> expect_optional_type(path, row, "source_contact_suppression", :map)
    |> expect_optional_type(path, row, "source_resource_suppression", :map)
    |> expect_optional_type(path, row, "source_candidate_rejection", :map)
    |> expect_optional_type(
      path,
      row,
      "source_timeline_dependency_impact",
      :map
    )
    |> expect_optional_type(
      path,
      row,
      "source_timeline_publication_summary",
      :map
    )
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
    |> expect_optional_type(path, row, "source_timeline_diff", :map)
    |> expect_optional_type(path, row, "source_quality_gate_row", :map)
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
    |> expect_optional_type(
      path,
      row,
      "source_timeline_diff_summary",
      :map
    )
    |> expect_optional_type(
      path,
      row,
      "source_timeline_transition_application_summary",
      :map
    )
    |> expect_optional_type(path, row, "source_timeline_application", :map)
    |> expect_optional_type(path, row, "source_timeline_integrity", :map)
    |> expect_optional_type(
      path,
      row,
      "source_timeline_activity_state",
      :map
    )
    |> expect_optional_type(
      path,
      row,
      "source_timeline_lifecycle_state",
      :map
    )
    |> expect_optional_type(
      path,
      row,
      "source_timeline_activity_precondition_summary",
      :map
    )
    |> expect_optional_type(
      path,
      row,
      "source_timeline_preservation",
      :map
    )
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
    |> expect_optional_type(path, row, "timeline_identity", :map)
    |> call(callbacks, :validate_optional_timeline_identity, [path, row, "timeline_identity"])
    |> expect_optional_type(path, row, "timeline_link", :map)
    |> call(callbacks, :validate_optional_timeline_link, [path, row, "timeline_link"])
    |> expect_optional_type(path, row, "source_activity_context", :map)
    |> expect_optional_type(path, row, "replacement_activity_context", :map)
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
    |> expect_optional_type(path, row, "source_timeline_identity", :map)
    |> expect_optional_type(
      path,
      row,
      "replacement_timeline_identity",
      :map
    )
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
