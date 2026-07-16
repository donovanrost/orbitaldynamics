defmodule OrbitalDynamics.Schema.OperationalTimelineRowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_string_list: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_number_list_items: 4,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(
        issues,
        path,
        row,
        precondition_validator,
        activity_context_validator,
        integrity_evidence_validator,
        timeline_identity_validator
      )
      when is_function(precondition_validator, 4) and
             is_function(activity_context_validator, 4) and
             is_function(integrity_evidence_validator, 3) and
             is_function(timeline_identity_validator, 3) do
    issues
    |> require_fields(path, row, [
      "id",
      "activity_id",
      "timeline_id",
      "activity_type",
      "status",
      "approval_status",
      "locked",
      "has_source_window",
      "has_cadence_import",
      "timeline_identity"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "activity_id",
      "timeline_id",
      "scenario_id",
      "ground_station_id",
      "target_id",
      "source_window_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id"
    ])
    |> expect_type(path, row, "activity_type", :binary)
    |> expect_one_of(path, row, "status", timeline_capability().activity_statuses)
    |> expect_one_of(
      path,
      row,
      "approval_status",
      timeline_capability().approval_statuses
    )
    |> expect_type(path, row, "locked", :boolean)
    |> expect_optional_type(path, row, "allow_overlap", :boolean)
    |> expect_optional_one_of(
      path,
      row,
      "operational_kind",
      timeline_capability().operational_kinds
    )
    |> expect_optional_one_of(
      path,
      row,
      "required_operator_action",
      timeline_capability().required_operator_actions
    )
    |> expect_optional_type(path, row, "operator_action_reason", :binary)
    |> expect_optional_one_of(
      path,
      row,
      "precondition_status",
      timeline_capability().activity_precondition_statuses
    )
    |> expect_optional_non_negative_integer(path, row, "blocked_precondition_count")
    |> expect_optional_non_negative_integer(path, row, "review_precondition_count")
    |> expect_optional_type(path, row, "blocked_precondition_types", :list)
    |> validate_optional_string_list(path, row, "blocked_precondition_types")
    |> expect_optional_type(path, row, "review_precondition_types", :list)
    |> validate_optional_string_list(path, row, "review_precondition_types")
    |> expect_optional_type(path, row, "preconditions", :list)
    |> precondition_validator.(path, row, "preconditions")
    |> expect_optional_one_of(
      path,
      row,
      "execution_boundary",
      timeline_capability().execution_boundaries
    )
    |> expect_optional_one_of(
      path,
      row,
      "cadence_import_status",
      timeline_capability().cadence_import_statuses
    )
    |> expect_optional_non_negative_number(path, row, "setup_duration_s")
    |> expect_optional_non_negative_number(path, row, "cooldown_duration_s")
    |> expect_optional_type(path, row, "telemetry_confirmation_required", :boolean)
    |> expect_optional_type(path, row, "telemetry_confirmation_status", :binary)
    |> expect_optional_type(path, row, "station_availability", :binary)
    |> expect_optional_type(path, row, "source_station_calendar_entry", :map)
    |> expect_optional_type(path, row, "source_station_calendar_overlaps", :list)
    |> expect_optional_type(path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(path, row, "station_calendar_directions")
    |> expect_optional_type(path, row, "station_calendar_status", :binary)
    |> expect_optional_integer(path, row, "station_calendar_overlap_count")
    |> expect_field_at_least(path, row, "station_calendar_overlap_count", 0)
    |> expect_optional_type(path, row, "station_calendar_overlap_entry_ids", :list)
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
    |> validate_string_list_items(path, row, "station_calendar_overlap_availabilities")
    |> expect_optional_type(path, row, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_integer(path, row, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(path, row, "station_calendar_ambiguous_entry_count", 0)
    |> expect_optional_type(path, row, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_integer(path, row, "station_calendar_reservation_overlap_count")
    |> expect_field_at_least(
      path,
      row,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(path, row, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "station_calendar_reservation_ids")
    |> expect_optional_type(path, row, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(path, row, "station_calendar_reserved_by")
    |> expect_optional_type(path, row, "station_calendar_reservation_statuses", :list)
    |> validate_string_list_items(path, row, "station_calendar_reservation_statuses")
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
    |> expect_optional_type(path, row, "station_contention_status", :binary)
    |> expect_optional_type(path, row, "station_reservation_match_status", :binary)
    |> expect_optional_number(path, row, "station_reservation_expires_at_s")
    |> expect_optional_type(path, row, "station_reserved_by", :binary)
    |> expect_optional_type(path, row, "station_reservation_status", :binary)
    |> expect_optional_type(path, row, "schedule_conflict_status", :binary)
    |> expect_optional_type(path, row, "activity_context", :map)
    |> activity_context_validator.(path, row, "activity_context")
    |> expect_optional_type(path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "dependency_activity_ids")
    |> expect_optional_type(
      path,
      row,
      "dependency_order_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      row,
      "dependency_order_violation_activity_ids"
    )
    |> expect_optional_type(path, row, "missing_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "missing_dependency_activity_ids")
    |> expect_optional_type(path, row, "self_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "self_dependency_activity_ids")
    |> expect_optional_type(path, row, "self_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "self_dependency_timeline_ids")
    |> expect_optional_type(path, row, "duplicate_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "duplicate_dependency_activity_ids")
    |> expect_optional_type(path, row, "duplicate_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(path, row, "duplicate_dependency_timeline_ids")
    |> expect_optional_type(path, row, "duplicate_exclusivity_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "duplicate_exclusivity_activity_ids"
    )
    |> expect_optional_type(path, row, "duplicate_exclusivity_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "duplicate_exclusivity_timeline_ids"
    )
    |> expect_optional_type(path, row, "exclusive_with_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "exclusive_with_activity_ids")
    |> expect_optional_type(path, row, "exclusivity_group", :binary)
    |> expect_optional_type(path, row, "exclusivity_violation_activity_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "exclusivity_violation_activity_ids"
    )
    |> expect_optional_type(path, row, "exclusivity_violation_group", :binary)
    |> expect_optional_type(path, row, "exclusivity_violation_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      row,
      "exclusivity_violation_timeline_ids"
    )
    |> expect_optional_type(path, row, "superseded_required_operator_action", :binary)
    |> expect_optional_type(path, row, "superseded_operator_action_reason", :binary)
    |> expect_optional_type(path, row, "timeline_integrity_status", :binary)
    |> expect_optional_type(path, row, "attitude_mode", :binary)
    |> validate_stable_ids(path, row, ["attitude_target_id"])
    |> expect_optional_number(path, row, "roll_deg")
    |> expect_optional_number(path, row, "pitch_deg")
    |> expect_optional_number(path, row, "yaw_deg")
    |> expect_optional_number(path, row, "attitude_error_deg")
    |> expect_optional_type(path, row, "attitude_status", :binary)
    |> expect_optional_type(path, row, "attitude_model", :binary)
    |> expect_optional_type(path, row, "attitude_source", :binary)
    |> expect_optional_probability(path, row, "attitude_confidence")
    |> expect_optional_non_negative_integer(
      path,
      row,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_type(path, row, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      row,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, row, "timeline_integrity_issues", :list)
    |> integrity_evidence_validator.(path, row)
    |> expect_type(path, row, "has_source_window", :boolean)
    |> expect_type(path, row, "has_cadence_import", :boolean)
    |> expect_type(path, row, "timeline_identity", :map)
    |> timeline_identity_validator.(
      path <> ".timeline_identity",
      Map.get(row, "timeline_identity", %{})
    )
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()
end
