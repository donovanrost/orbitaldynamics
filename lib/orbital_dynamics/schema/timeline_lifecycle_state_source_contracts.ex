defmodule OrbitalDynamics.Schema.TimelineLifecycleStateSourceContracts do
  @moduledoc false

  def validate_optional(issues, _path, nil, _callbacks), do: issues

  def validate_optional(issues, path, %{} = row, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, [
      "timeline_id",
      "activity_id",
      "planned_activity_id",
      "realized_activity_id"
    ])
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "status_transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "approval_transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_type(callbacks, path, row, "state_status", :binary)
    |> expect_optional_type(callbacks, path, row, "review_required", :boolean)
    |> expect_optional_type(callbacks, path, row, "required_operator_action", :binary)
    |> expect_optional_type(callbacks, path, row, "import_action", :binary)
    |> expect_optional_type(callbacks, path, row, "required_operator_actions", :list)
    |> expect_optional_type(callbacks, path, row, "operator_action_reasons", :list)
    |> expect_optional_type(callbacks, path, row, "planned_activity_ids", :list)
    |> expect_optional_type(callbacks, path, row, "realized_activity_ids", :list)
    |> validate_optional_string_list(callbacks, path, row, "required_operator_actions")
    |> validate_optional_string_list(callbacks, path, row, "operator_action_reasons")
    |> validate_optional_stable_id_list(callbacks, path, row, "planned_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, row, "realized_activity_ids")
    |> expect_optional_type(callbacks, path, row, "status_transition", :map)
    |> expect_optional_type(callbacks, path, row, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, row, "status_transition")
    |> validate_optional_lifecycle_transition(callbacks, path, row, "approval_transition")
    |> expect_optional_type(callbacks, path, row, "planned_activity_context", :map)
    |> expect_optional_type(callbacks, path, row, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, row, "planned_activity_context")
    |> validate_optional_activity_context(callbacks, path, row, "realized_activity_context")
    |> validate_optional_lifecycle_state_source_protection_decision(
      callbacks,
      path,
      row,
      "planned_protection_decision"
    )
    |> validate_optional_lifecycle_state_source_protection_decision(
      callbacks,
      path,
      row,
      "realized_protection_decision"
    )
    |> expect_optional_type(callbacks, path, row, "planned_locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_locked", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_executed", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_executed", :boolean)
    |> expect_optional_type(callbacks, path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      row,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(callbacks, path, row, "invalid_activity_input_reasons", :list)
    |> validate_optional_string_list(callbacks, path, row, "invalid_activity_input_reasons")
  end

  def validate_optional(issues, path, _row, callbacks) when is_list(callbacks) do
    [error(callbacks, path, "must be an object") | issues]
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])

  defp expect_optional_non_negative_integer(issues, callbacks, path, row, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, row, field)
  end

  defp expect_optional_one_of(issues, callbacks, path, row, field, values) do
    callback!(callbacks, :expect_optional_one_of).(issues, path, row, field, values)
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, row, field, type)
  end

  defp validate_optional_activity_context(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_activity_context).(issues, path, row, field)
  end

  defp validate_optional_lifecycle_state_source_protection_decision(
         issues,
         callbacks,
         path,
         row,
         field
       ) do
    callback!(callbacks, :validate_optional_lifecycle_state_source_protection_decision).(
      issues,
      path,
      row,
      field
    )
  end

  defp validate_optional_lifecycle_transition(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_lifecycle_transition).(issues, path, row, field)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, row, field)
  end

  defp validate_optional_string_list(issues, callbacks, path, row, field) do
    callback!(callbacks, :validate_optional_string_list).(issues, path, row, field)
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, row, fields)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
