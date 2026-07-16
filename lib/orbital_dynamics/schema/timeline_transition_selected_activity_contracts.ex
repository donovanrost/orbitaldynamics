defmodule OrbitalDynamics.Schema.TimelineTransitionSelectedActivityContracts do
  @moduledoc false

  def validate(issues, path, activity, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, activity, [
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
    |> validate_stable_ids(callbacks, path, activity, ["activity_id", "timeline_id"])
    |> validate_stable_ids(callbacks, path, activity, ["target_id"])
    |> expect_type(callbacks, path, activity, "activity_type", :binary)
    |> expect_one_of(callbacks, path, activity, "status", timeline_capability().activity_statuses)
    |> expect_one_of(
      callbacks,
      path,
      activity,
      "approval_status",
      timeline_capability().approval_statuses
    )
    |> expect_type(callbacks, path, activity, "locked", :boolean)
    |> expect_optional_type(callbacks, path, activity, "allow_overlap", :boolean)
    |> expect_optional_one_of(
      callbacks,
      path,
      activity,
      "operational_kind",
      timeline_capability().operational_kinds
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      activity,
      "required_operator_action",
      timeline_capability().required_operator_actions
    )
    |> expect_optional_type(callbacks, path, activity, "operator_action_reason", :binary)
    |> expect_optional_one_of(
      callbacks,
      path,
      activity,
      "execution_boundary",
      timeline_capability().execution_boundaries
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      activity,
      "cadence_import_status",
      timeline_capability().cadence_import_statuses
    )
    |> expect_optional_number(callbacks, path, activity, "starts_at_s")
    |> expect_optional_number(callbacks, path, activity, "ends_at_s")
    |> expect_optional_type(callbacks, path, activity, "target_id", :binary)
    |> expect_optional_type(callbacks, path, activity, "command_window_id", :binary)
    |> expect_optional_type(callbacks, path, activity, "command_window_type", :binary)
    |> expect_optional_type(callbacks, path, activity, "approved", :boolean)
    |> expect_type(callbacks, path, activity, "has_source_window", :boolean)
    |> expect_type(callbacks, path, activity, "has_cadence_import", :boolean)
    |> expect_type(callbacks, path, activity, "timeline_identity", :map)
    |> expect_optional_type(callbacks, path, activity, "activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, activity, "activity_context")
    |> expect_optional_type(callbacks, path, activity, "protection_decision", :binary)
    |> expect_optional_type(callbacks, path, activity, "protection_category", :binary)
    |> expect_optional_type(callbacks, path, activity, "protection_reason", :binary)
    |> expect_optional_type(callbacks, path, activity, "timeline_integrity_status", :binary)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      activity,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_type(callbacks, path, activity, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      activity,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, activity, "timeline_integrity_issues", :list)
    |> validate_timeline_integrity_evidence(callbacks, path, activity)
    |> validate_interval(callbacks, path, activity)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp expect_one_of(issues, callbacks, path, activity, field, values) do
    callback!(callbacks, :expect_one_of).(issues, path, activity, field, values)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, activity, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, activity, field)
  end

  defp expect_optional_number(issues, callbacks, path, activity, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, activity, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, activity, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, activity, field, values)
  end

  defp expect_optional_type(issues, callbacks, path, activity, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, activity, field, type)
  end

  defp expect_type(issues, callbacks, path, activity, field, type) do
    callback!(callbacks, :expect_type).(issues, path, activity, field, type)
  end

  defp require_fields(issues, callbacks, path, activity, fields) do
    callback!(callbacks, :require_fields).(issues, path, activity, fields)
  end

  defp validate_interval(issues, callbacks, path, activity) do
    callback!(callbacks, :validate_interval).(issues, path, activity)
  end

  defp validate_optional_activity_context(issues, callbacks, path, activity, field) do
    callback!(callbacks, :validate_optional_activity_context).(issues, path, activity, field)
  end

  defp validate_stable_ids(issues, callbacks, path, activity, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, activity, fields)
  end

  defp validate_string_list_allowed(issues, callbacks, path, activity, field, values) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, activity, field, values)
  end

  defp validate_timeline_integrity_evidence(issues, callbacks, path, activity) do
    callback!(callbacks, :validate_timeline_integrity_evidence).(issues, path, activity)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
