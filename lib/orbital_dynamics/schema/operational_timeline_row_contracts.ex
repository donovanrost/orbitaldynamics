defmodule OrbitalDynamics.Schema.OperationalTimelineRowContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
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
    |> validate_stable_ids(callbacks, path, row, [
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
    |> expect_type(callbacks, path, row, "activity_type", :binary)
    |> expect_one_of(callbacks, path, row, "status", timeline_capability().activity_statuses)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "approval_status",
      timeline_capability().approval_statuses
    )
    |> expect_type(callbacks, path, row, "locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "allow_overlap", :boolean)
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "operational_kind",
      timeline_capability().operational_kinds
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      timeline_capability().required_operator_actions
    )
    |> expect_optional_type(callbacks, path, row, "operator_action_reason", :binary)
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "precondition_status",
      timeline_capability().activity_precondition_statuses
    )
    |> expect_optional_non_negative_integer(callbacks, path, row, "blocked_precondition_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "review_precondition_count")
    |> expect_optional_type(callbacks, path, row, "blocked_precondition_types", :list)
    |> validate_optional_string_list(callbacks, path, row, "blocked_precondition_types")
    |> expect_optional_type(callbacks, path, row, "review_precondition_types", :list)
    |> validate_optional_string_list(callbacks, path, row, "review_precondition_types")
    |> expect_optional_type(callbacks, path, row, "preconditions", :list)
    |> validate_optional_timeline_preconditions(callbacks, path, row, "preconditions")
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "execution_boundary",
      timeline_capability().execution_boundaries
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "cadence_import_status",
      timeline_capability().cadence_import_statuses
    )
    |> expect_optional_non_negative_number(callbacks, path, row, "setup_duration_s")
    |> expect_optional_non_negative_number(callbacks, path, row, "cooldown_duration_s")
    |> expect_optional_type(callbacks, path, row, "telemetry_confirmation_required", :boolean)
    |> expect_optional_type(callbacks, path, row, "telemetry_confirmation_status", :binary)
    |> expect_optional_type(callbacks, path, row, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, row, "source_station_calendar_entry", :map)
    |> expect_optional_type(callbacks, path, row, "source_station_calendar_overlaps", :list)
    |> expect_optional_type(callbacks, path, row, "station_calendar_directions", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_directions")
    |> expect_optional_type(callbacks, path, row, "station_calendar_status", :binary)
    |> expect_optional_integer(callbacks, path, row, "station_calendar_overlap_count")
    |> expect_field_at_least(callbacks, path, row, "station_calendar_overlap_count", 0)
    |> expect_optional_type(callbacks, path, row, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "station_calendar_overlap_entry_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_overlap_availabilities",
      :list
    )
    |> validate_string_list_items(callbacks, path, row, "station_calendar_overlap_availabilities")
    |> expect_optional_type(callbacks, path, row, "station_calendar_entry_ambiguous", :boolean)
    |> expect_optional_integer(callbacks, path, row, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(callbacks, path, row, "station_calendar_ambiguous_entry_count", 0)
    |> expect_optional_type(callbacks, path, row, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_integer(callbacks, path, row, "station_calendar_reservation_overlap_count")
    |> expect_field_at_least(
      callbacks,
      path,
      row,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(callbacks, path, row, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "station_calendar_reservation_ids")
    |> expect_optional_type(callbacks, path, row, "station_calendar_reserved_by", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_reserved_by")
    |> expect_optional_type(callbacks, path, row, "station_calendar_reservation_statuses", :list)
    |> validate_string_list_items(callbacks, path, row, "station_calendar_reservation_statuses")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      row,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "station_calendar_trust_boundary_status",
      :binary
    )
    |> expect_optional_type(callbacks, path, row, "station_contention_status", :binary)
    |> expect_optional_type(callbacks, path, row, "station_reservation_match_status", :binary)
    |> expect_optional_number(callbacks, path, row, "station_reservation_expires_at_s")
    |> expect_optional_type(callbacks, path, row, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, row, "station_reservation_status", :binary)
    |> expect_optional_type(callbacks, path, row, "schedule_conflict_status", :binary)
    |> expect_optional_type(callbacks, path, row, "activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, row, "activity_context")
    |> expect_optional_type(callbacks, path, row, "dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "dependency_activity_ids")
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "dependency_order_violation_activity_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "dependency_order_violation_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "missing_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "missing_dependency_activity_ids")
    |> expect_optional_type(callbacks, path, row, "self_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "self_dependency_activity_ids")
    |> expect_optional_type(callbacks, path, row, "self_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "self_dependency_timeline_ids")
    |> expect_optional_type(callbacks, path, row, "duplicate_dependency_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "duplicate_dependency_activity_ids")
    |> expect_optional_type(callbacks, path, row, "duplicate_dependency_timeline_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "duplicate_dependency_timeline_ids")
    |> expect_optional_type(callbacks, path, row, "duplicate_exclusivity_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "duplicate_exclusivity_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "duplicate_exclusivity_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "duplicate_exclusivity_timeline_ids"
    )
    |> expect_optional_type(callbacks, path, row, "exclusive_with_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "exclusive_with_activity_ids")
    |> expect_optional_type(callbacks, path, row, "exclusivity_group", :binary)
    |> expect_optional_type(callbacks, path, row, "exclusivity_violation_activity_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "exclusivity_violation_activity_ids"
    )
    |> expect_optional_type(callbacks, path, row, "exclusivity_violation_group", :binary)
    |> expect_optional_type(callbacks, path, row, "exclusivity_violation_timeline_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      row,
      "exclusivity_violation_timeline_ids"
    )
    |> expect_optional_type(callbacks, path, row, "superseded_required_operator_action", :binary)
    |> expect_optional_type(callbacks, path, row, "superseded_operator_action_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "timeline_integrity_status", :binary)
    |> expect_optional_type(callbacks, path, row, "attitude_mode", :binary)
    |> validate_stable_ids(callbacks, path, row, ["attitude_target_id"])
    |> expect_optional_number(callbacks, path, row, "roll_deg")
    |> expect_optional_number(callbacks, path, row, "pitch_deg")
    |> expect_optional_number(callbacks, path, row, "yaw_deg")
    |> expect_optional_number(callbacks, path, row, "attitude_error_deg")
    |> expect_optional_type(callbacks, path, row, "attitude_status", :binary)
    |> expect_optional_type(callbacks, path, row, "attitude_model", :binary)
    |> expect_optional_type(callbacks, path, row, "attitude_source", :binary)
    |> expect_optional_probability(callbacks, path, row, "attitude_confidence")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_type(callbacks, path, row, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      row,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, row, "timeline_integrity_issues", :list)
    |> validate_timeline_integrity_evidence(callbacks, path, row)
    |> expect_type(callbacks, path, row, "has_source_window", :boolean)
    |> expect_type(callbacks, path, row, "has_cadence_import", :boolean)
    |> expect_type(callbacks, path, row, "timeline_identity", :map)
    |> validate_timeline_identity(
      callbacks,
      path <> ".timeline_identity",
      Map.get(row, "timeline_identity", %{})
    )
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp expect_field_at_least(issues, callbacks, path, row, field, min) do
    callback!(callbacks, :expect_field_at_least).(issues, path, row, field, min)
  end

  defp expect_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_one_of).(issues, path, row, field, values)
  end

  defp expect_optional_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_integer).(issues, path, row, field)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, row, field)
  end

  defp expect_optional_non_negative_number(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_number).(issues, path, row, field)
  end

  defp expect_optional_number(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, row, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, row, field, values)
  end

  defp expect_optional_probability(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_probability).(issues, path, row, field)
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, row, field, type)
  end

  defp expect_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_type).(issues, path, row, field, type)
  end

  defp require_fields(issues, callbacks, path, row, fields) do
    callback!(callbacks, :require_fields).(issues, path, row, fields)
  end

  defp validate_number_list_items(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_number_list_items).(issues, path, row, field)
  end

  defp validate_optional_activity_context(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_activity_context).(issues, path, row, field)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, row, field)
  end

  defp validate_optional_string_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_string_list).(issues, path, row, field)
  end

  defp validate_optional_timeline_preconditions(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_timeline_preconditions).(issues, path, row, field)
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, row, fields)
  end

  defp validate_string_list_allowed(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, row, field, values)
  end

  defp validate_string_list_items(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, row, field)
  end

  defp validate_timeline_identity(issues, callbacks, path, identity) do
    callback!(callbacks, :validate_timeline_identity).(issues, path, identity)
  end

  defp validate_timeline_integrity_evidence(issues, callbacks, path, row) do
    callback!(callbacks, :validate_timeline_integrity_evidence).(issues, path, row)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
