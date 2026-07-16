defmodule OrbitalDynamics.Schema.TimelineDiffRowContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "rank",
      "timeline_id",
      "diff_status",
      "changed_fields",
      "requires_operator_review",
      "required_operator_action",
      "reason"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "id",
      "timeline_id",
      "source_activity_id",
      "replacement_activity_id",
      "scenario_id",
      "source_spacecraft_id",
      "replacement_spacecraft_id",
      "source_ground_station_id",
      "replacement_ground_station_id",
      "source_target_id",
      "replacement_target_id",
      "source_source_window_id",
      "replacement_source_window_id"
    ])
    |> expect_type(callbacks, path, row, "diff_status", :binary)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "diff_status",
      timeline_capability().timeline_diff_statuses
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_type(callbacks, path, row, "transition_decision_reason", :binary)
    |> expect_number(callbacks, path, row, "rank")
    |> expect_type(callbacks, path, row, "changed_fields", :list)
    |> expect_type(callbacks, path, row, "requires_operator_review", :boolean)
    |> expect_type(callbacks, path, row, "required_operator_action", :binary)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      timeline_capability().timeline_diff_required_operator_actions
    )
    |> expect_optional_type(callbacks, path, row, "operator_action_reason", :binary)
    |> expect_type(callbacks, path, row, "reason", :binary)
    |> expect_optional_number(callbacks, path, row, "source_starts_at_s")
    |> expect_optional_number(callbacks, path, row, "source_ends_at_s")
    |> expect_optional_number(callbacks, path, row, "replacement_starts_at_s")
    |> expect_optional_number(callbacks, path, row, "replacement_ends_at_s")
    |> expect_optional_number(callbacks, path, row, "start_delta_s")
    |> expect_optional_number(callbacks, path, row, "end_delta_s")
    |> expect_optional_type(callbacks, path, row, "source_allow_overlap", :boolean)
    |> expect_optional_type(callbacks, path, row, "replacement_allow_overlap", :boolean)
    |> expect_optional_type(callbacks, path, row, "status_transition", :map)
    |> expect_optional_type(callbacks, path, row, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, row, "status_transition")
    |> validate_optional_lifecycle_transition(callbacks, path, row, "approval_transition")
    |> expect_optional_type(callbacks, path, row, "source_timeline_identity", :map)
    |> expect_optional_type(callbacks, path, row, "replacement_timeline_identity", :map)
    |> validate_optional_timeline_identity(callbacks, path, row, "source_timeline_identity")
    |> validate_optional_timeline_identity(callbacks, path, row, "replacement_timeline_identity")
    |> expect_optional_type(callbacks, path, row, "source_activity_context", :map)
    |> expect_optional_type(callbacks, path, row, "replacement_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, row, "source_activity_context")
    |> validate_optional_activity_context(callbacks, path, row, "replacement_activity_context")
    |> expect_optional_type(callbacks, path, row, "source_protection_category", :binary)
    |> expect_optional_type(callbacks, path, row, "replacement_protection_category", :binary)
    |> expect_optional_type(callbacks, path, row, "source_protection_decision", :map)
    |> expect_optional_type(callbacks, path, row, "replacement_protection_decision", :map)
    |> validate_optional_protection_decision(callbacks, path, row, "source_protection_decision")
    |> validate_optional_protection_decision(
      callbacks,
      path,
      row,
      "replacement_protection_decision"
    )
    |> expect_optional_type(callbacks, path, row, "source_protection_reason", :binary)
    |> expect_optional_type(callbacks, path, row, "replacement_protection_reason", :binary)
    |> validate_timeline_identity_collision_fields(callbacks, path, row)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp expect_number(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_number).(issues, path, row, field)
  end

  defp expect_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_one_of).(issues, path, row, field, values)
  end

  defp expect_optional_number(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_number).(issues, path, row, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, row, field, values)
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

  defp validate_optional_activity_context(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_activity_context).(issues, path, row, field)
  end

  defp validate_optional_lifecycle_transition(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_lifecycle_transition).(issues, path, row, field)
  end

  defp validate_optional_protection_decision(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_protection_decision).(issues, path, row, field)
  end

  defp validate_optional_timeline_identity(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_timeline_identity).(issues, path, row, field)
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, row, fields)
  end

  defp validate_timeline_identity_collision_fields(issues, callbacks, path, row) do
    callback!(callbacks, :validate_timeline_identity_collision_fields).(issues, path, row)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
