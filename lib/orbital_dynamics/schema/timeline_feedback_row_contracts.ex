defmodule OrbitalDynamics.Schema.TimelineFeedbackRowContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    ExecutionMetricContracts,
    HandoffFieldContracts,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_number_list_items: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, row, handoff_callbacks) when is_list(handoff_callbacks) do
    issues
    |> require_fields(path, row, ["activity_id", "status"])
    |> validate_stable_ids(path, row, ["activity_id"])
    |> expect_one_of(
      path,
      row,
      "status",
      OrbitalDynamics.TimelineFeedback.capabilities().report_statuses
    )
    |> validate_stable_ids(path, row, [
      "planned_timeline_id",
      "realized_timeline_id",
      "realized_activity_id",
      "ground_station_id",
      "target_id",
      "planned_ground_station_id",
      "realized_ground_station_id",
      "planned_target_id",
      "planned_source_window_id",
      "realized_source_window_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id"
    ])
    |> expect_optional_one_of(
      path,
      row,
      "match_strategy",
      OrbitalDynamics.TimelineFeedback.capabilities().match_strategies
    )
    |> expect_optional_one_of(
      path,
      row,
      "feedback_kind",
      OrbitalDynamics.TimelineFeedback.capabilities().feedback_kinds
    )
    |> expect_optional_type(path, row, "planned_type", :binary)
    |> expect_optional_type(path, row, "planned_status", :binary)
    |> expect_optional_one_of(
      path,
      row,
      "realized_status",
      ["invalid" | OrbitalDynamics.TimelineFeedback.capabilities().supported_realized_statuses]
    )
    |> expect_optional_type(path, row, "direction", :binary)
    |> expect_optional_type(path, row, "source_window_id", :binary)
    |> expect_optional_type(path, row, "source_window_ids", :list)
    |> validate_optional_stable_id_list(path, row, "source_window_ids")
    |> expect_optional_type(path, row, "source_window_types", :list)
    |> validate_string_list_items(path, row, "source_window_types")
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> expect_optional_type(path, row, "collection_ids", :list)
    |> validate_optional_stable_id_list(path, row, "collection_ids")
    |> expect_optional_type(path, row, "product_ids", :list)
    |> validate_optional_stable_id_list(path, row, "product_ids")
    |> expect_optional_type(path, row, "payload_ids", :list)
    |> validate_optional_stable_id_list(path, row, "payload_ids")
    |> expect_optional_type(path, row, "instrument_ids", :list)
    |> validate_optional_stable_id_list(path, row, "instrument_ids")
    |> expect_optional_one_of(
      path,
      row,
      "cadence_import_status",
      OrbitalDynamics.TimelineFeedback.capabilities().cadence_import_statuses
    )
    |> expect_optional_type(path, row, "cadence_import_type", :binary)
    |> expect_optional_probability(path, row, "capacity_fraction")
    |> expect_optional_probability(path, row, "capacity_fraction_min")
    |> expect_optional_probability(path, row, "capacity_fraction_max")
    |> expect_optional_probability(path, row, "battery_state_of_charge")
    |> expect_optional_type(path, row, "source_station_calendar_entry", :map)
    |> expect_optional_type(path, row, "source_station_calendar_overlaps", :list)
    |> expect_optional_type(path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(path, row, "station_calendar_directions")
    |> expect_optional_type(path, row, "station_calendar_status", :binary)
    |> expect_optional_integer(path, row, "station_calendar_overlap_count")
    |> expect_field_at_least(path, row, "station_calendar_overlap_count", 0)
    |> expect_optional_type(path, row, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_overlap_entry_ids")
    |> expect_optional_type(path, row, "station_calendar_overlap_availabilities", :list)
    |> validate_string_list_items(path, row, "station_calendar_overlap_availabilities")
    |> expect_optional_type(path, row, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_integer(path, row, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(path, row, "station_calendar_ambiguous_entry_count", 0)
    |> expect_optional_type(path, row, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_ambiguous_entry_ids")
    |> expect_optional_integer(path, row, "station_calendar_reservation_overlap_count")
    |> expect_field_at_least(path, row, "station_calendar_reservation_overlap_count", 0)
    |> expect_optional_type(path, row, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_reservation_ids")
    |> expect_optional_type(path, row, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(path, row, "station_calendar_reserved_by")
    |> expect_optional_type(path, row, "station_calendar_reservation_statuses", :list)
    |> validate_string_list_items(path, row, "station_calendar_reservation_statuses")
    |> expect_optional_type(path, row, "station_calendar_reservation_expires_at_s", :list)
    |> validate_number_list_items(path, row, "station_calendar_reservation_expires_at_s")
    |> expect_optional_type(path, row, "station_calendar_trust_boundary_status", :binary)
    |> expect_optional_type(path, row, "station_contention_status", :binary)
    |> expect_optional_type(path, row, "station_reservation_match_status", :binary)
    |> expect_optional_number(path, row, "station_reservation_expires_at_s")
    |> expect_optional_type(path, row, "station_reserved_by", :binary)
    |> expect_optional_type(path, row, "station_reservation_status", :binary)
    |> expect_optional_type(path, row, "planned_operator_action", :binary)
    |> expect_optional_type(path, row, "planned_operator_action_reason", :binary)
    |> expect_optional_type(path, row, "planned_direction", :binary)
    |> expect_optional_type(path, row, "realized_direction", :binary)
    |> expect_optional_type(path, row, "source_activity_context", :map)
    |> expect_optional_type(path, row, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, row, "source_activity_context")
    |> ActivityContextContracts.validate_optional(path, row, "realized_activity_context")
    |> expect_optional_type(path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "dependency_activity_ids")
    |> expect_optional_type(path, row, "dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "dependency_timeline_ids")
    |> expect_optional_type(path, row, "exclusive_with_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "exclusive_with_activity_ids")
    |> expect_optional_type(path, row, "exclusive_with_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "exclusive_with_timeline_ids")
    |> expect_optional_type(path, row, "identity_match_status", :binary)
    |> expect_optional_integer(path, row, "identity_mismatch_count")
    |> expect_optional_type(path, row, "identity_mismatch_fields", :list)
    |> validate_string_list_items(path, row, "identity_mismatch_fields")
    |> expect_optional_type(path, row, "direction_match_status", :binary)
    |> expect_optional_type(path, row, "ground_station_match_status", :binary)
    |> expect_optional_type(path, row, "target_match_status", :binary)
    |> expect_optional_type(path, row, "source_window_match_status", :binary)
    |> expect_optional_type(path, row, "delta_v_match_status", :binary)
    |> expect_optional_type(path, row, "operational_feedback_status", :binary)
    |> expect_optional_type(path, row, "operational_feedback_excluded", :boolean)
    |> expect_optional_type(path, row, "operational_feedback_exclusion_reason", :binary)
    |> expect_optional_type(path, row, "execution_uncertainty_status", :binary)
    |> expect_optional_type(path, row, "execution_uncertainty", :map)
    |> ExecutionMetricContracts.validate_optional_execution_uncertainty(
      path,
      row,
      "execution_uncertainty"
    )
    |> expect_optional_type(path, row, "planned_protection_category", :binary)
    |> expect_optional_one_of(
      path,
      row,
      "planned_protection_decision",
      OrbitalDynamics.TimelineFeedback.capabilities().planned_protection_decisions
    )
    |> expect_optional_type(path, row, "planned_protection_reason", :binary)
    |> expect_optional_type(path, row, "source_protection_decision", :map)
    |> ProtectionDecisionContracts.validate_optional(path, row, "source_protection_decision")
    |> expect_optional_type(path, row, "status_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, row, "status_transition")
    |> expect_optional_number(path, row, "planned_starts_at_s")
    |> expect_optional_number(path, row, "planned_ends_at_s")
    |> expect_optional_number(path, row, "actual_starts_at_s")
    |> expect_optional_number(path, row, "actual_ends_at_s")
    |> expect_optional_number(path, row, "start_delta_s")
    |> expect_optional_number(path, row, "end_delta_s")
    |> expect_optional_number(path, row, "planned_estimated_throughput_mb")
    |> expect_optional_number(path, row, "actual_throughput_mb")
    |> expect_optional_type(path, row, "actual_data_rate_throughput_derivation", :map)
    |> ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation(
      path,
      row,
      "actual_data_rate_throughput_derivation"
    )
    |> expect_optional_number(path, row, "actual_data_volume_mb")
    |> expect_optional_number(path, row, "throughput_delta_mb")
    |> expect_optional_probability(path, row, "throughput_completion_fraction")
    |> expect_optional_type(path, row, "contact_success", :boolean)
    |> expect_optional_probability(path, row, "contact_success_factor")
    |> expect_optional_type(path, row, "contact_success_factor_source", :binary)
    |> expect_optional_type(path, row, "command_success", :boolean)
    |> expect_optional_probability(path, row, "command_success_factor")
    |> expect_optional_type(path, row, "command_success_factor_source", :binary)
    |> expect_optional_type(path, row, "command_result", :binary)
    |> expect_optional_type(path, row, "command_authority_status", :binary)
    |> expect_optional_type(path, row, "planned_command_authority_status", :binary)
    |> expect_optional_type(path, row, "realized_command_authority_status", :binary)
    |> expect_optional_type(path, row, "command_authority_status_match_status", :binary)
    |> expect_optional_type(path, row, "required_authority", :binary)
    |> expect_optional_type(path, row, "planned_required_authority", :binary)
    |> expect_optional_type(path, row, "realized_required_authority", :binary)
    |> expect_optional_type(path, row, "required_authority_match_status", :binary)
    |> expect_optional_type(path, row, "command_safety_status", :binary)
    |> expect_optional_type(path, row, "planned_command_safety_status", :binary)
    |> expect_optional_type(path, row, "realized_command_safety_status", :binary)
    |> expect_optional_type(path, row, "command_safety_status_match_status", :binary)
    |> expect_optional_type(path, row, "command_authorized", :boolean)
    |> expect_optional_type(path, row, "planned_command_authorized", :boolean)
    |> expect_optional_type(path, row, "realized_command_authorized", :boolean)
    |> expect_optional_type(path, row, "command_authorized_match_status", :binary)
    |> expect_optional_type(path, row, "command_safety_checked", :boolean)
    |> expect_optional_type(path, row, "planned_command_safety_checked", :boolean)
    |> expect_optional_type(path, row, "realized_command_safety_checked", :boolean)
    |> expect_optional_type(path, row, "command_safety_checked_match_status", :binary)
    |> expect_optional_type(path, row, "observation_success", :boolean)
    |> expect_optional_probability(path, row, "observation_success_factor")
    |> expect_optional_type(path, row, "observation_success_factor_source", :binary)
    |> expect_optional_type(path, row, "maneuver_success", :boolean)
    |> expect_optional_probability(path, row, "maneuver_success_factor")
    |> expect_optional_type(path, row, "maneuver_success_factor_source", :binary)
    |> expect_optional_type(path, row, "maneuver_result", :binary)
    |> expect_optional_type(path, row, "planned_delta_v_km_s", :list)
    |> expect_optional_number(path, row, "planned_delta_v_magnitude_km_s")
    |> expect_optional_type(path, row, "reason", :binary)
    |> expect_optional_type(path, row, "has_cadence_import", :boolean)
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
    |> expect_optional_type(path, row, "timeline_identity", :map)
    |> HandoffFieldContracts.validate_resource_availability_variance_fields(
      path,
      row,
      handoff_callbacks
    )
    |> HandoffFieldContracts.validate_eclipse_lighting_handoff_fields(
      path,
      row,
      handoff_callbacks
    )
    |> HandoffFieldContracts.validate_link_handoff_fields(path, row, handoff_callbacks)
    |> HandoffFieldContracts.validate_image_quality_score_fields(path, row, handoff_callbacks)
    |> expect_optional_number(path, row, "image_quality_score_delta")
    |> expect_optional_type(path, row, "image_quality_status", :binary)
    |> expect_optional_type(path, row, "planned_image_quality_status", :binary)
    |> expect_optional_type(path, row, "realized_image_quality_status", :binary)
    |> expect_optional_type(path, row, "image_quality_status_match_status", :binary)
    |> expect_optional_type(path, row, "image_quality_source", :binary)
    |> expect_optional_probability(path, row, "cloud_cover_fraction")
    |> expect_optional_probability(path, row, "planned_cloud_cover_fraction")
    |> expect_optional_probability(path, row, "realized_cloud_cover_fraction")
    |> expect_optional_number(path, row, "cloud_cover_fraction_delta")
    |> expect_optional_probability(path, row, "blur_score")
    |> expect_optional_probability(path, row, "planned_blur_score")
    |> expect_optional_probability(path, row, "realized_blur_score")
    |> expect_optional_number(path, row, "blur_score_delta")
    |> expect_optional_type(path, row, "attitude_mode", :binary)
    |> expect_optional_type(path, row, "planned_attitude_mode", :binary)
    |> expect_optional_type(path, row, "realized_attitude_mode", :binary)
    |> expect_optional_type(path, row, "attitude_mode_match_status", :binary)
    |> validate_stable_ids(path, row, [
      "attitude_target_id",
      "planned_attitude_target_id",
      "realized_attitude_target_id"
    ])
    |> expect_optional_type(path, row, "attitude_target_match_status", :binary)
    |> expect_optional_number(path, row, "planned_roll_deg")
    |> expect_optional_number(path, row, "realized_roll_deg")
    |> expect_optional_number(path, row, "roll_delta_deg")
    |> expect_optional_number(path, row, "planned_pitch_deg")
    |> expect_optional_number(path, row, "realized_pitch_deg")
    |> expect_optional_number(path, row, "pitch_delta_deg")
    |> expect_optional_number(path, row, "planned_yaw_deg")
    |> expect_optional_number(path, row, "realized_yaw_deg")
    |> expect_optional_number(path, row, "yaw_delta_deg")
    |> expect_optional_number(path, row, "attitude_error_deg")
    |> expect_optional_type(path, row, "attitude_status", :binary)
    |> expect_optional_type(path, row, "attitude_model", :binary)
    |> expect_optional_type(path, row, "attitude_source", :binary)
    |> expect_optional_probability(path, row, "attitude_confidence")
    |> expect_optional_probability(path, row, "completed_fraction")
  end
end
