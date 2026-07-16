defmodule OrbitalDynamics.Schema.TimelineLifecycleStateSourceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    CollectionValidation,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts
  }

  def validate_optional(issues, _path, nil), do: issues

  def validate_optional(issues, path, %{} = row) do
    issues
    |> validate_stable_ids(path, row, [
      "timeline_id",
      "activity_id",
      "planned_activity_id",
      "realized_activity_id"
    ])
    |> expect_optional_one_of(
      path,
      row,
      "transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_one_of(
      path,
      row,
      "status_transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_one_of(
      path,
      row,
      "approval_transition_decision",
      timeline_capability().transition_decisions
    )
    |> expect_optional_type(path, row, "state_status", :binary)
    |> expect_optional_type(path, row, "review_required", :boolean)
    |> expect_optional_type(path, row, "required_operator_action", :binary)
    |> expect_optional_type(path, row, "import_action", :binary)
    |> expect_optional_type(path, row, "required_operator_actions", :list)
    |> expect_optional_type(path, row, "operator_action_reasons", :list)
    |> expect_optional_type(path, row, "planned_activity_ids", :list)
    |> expect_optional_type(path, row, "realized_activity_ids", :list)
    |> CollectionValidation.validate_optional_string_list(path, row, "required_operator_actions")
    |> CollectionValidation.validate_optional_string_list(path, row, "operator_action_reasons")
    |> validate_optional_stable_id_list(path, row, "planned_activity_ids")
    |> validate_optional_stable_id_list(path, row, "realized_activity_ids")
    |> expect_optional_type(path, row, "status_transition", :map)
    |> expect_optional_type(path, row, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, row, "status_transition")
    |> LifecycleTransitionContracts.validate_optional(path, row, "approval_transition")
    |> expect_optional_type(path, row, "planned_activity_context", :map)
    |> expect_optional_type(path, row, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, row, "planned_activity_context")
    |> ActivityContextContracts.validate_optional(path, row, "realized_activity_context")
    |> validate_optional_lifecycle_state_source_protection_decision(
      path,
      row,
      "planned_protection_decision"
    )
    |> validate_optional_lifecycle_state_source_protection_decision(
      path,
      row,
      "realized_protection_decision"
    )
    |> expect_optional_type(path, row, "planned_locked", :boolean)
    |> expect_optional_type(path, row, "realized_locked", :boolean)
    |> expect_optional_type(path, row, "planned_executed", :boolean)
    |> expect_optional_type(path, row, "realized_executed", :boolean)
    |> expect_optional_type(path, row, "timeline_identity_collision", :boolean)
    |> expect_optional_type(path, row, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      path,
      row,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(path, row, "invalid_activity_input_reasons", :list)
    |> CollectionValidation.validate_optional_string_list(
      path,
      row,
      "invalid_activity_input_reasons"
    )
  end

  def validate_optional(issues, path, _row) do
    [error(path, "must be an object") | issues]
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp validate_optional_lifecycle_state_source_protection_decision(
         issues,
         path,
         row,
         field
       ) do
    case Map.get(row, field) do
      nil -> issues
      %{} -> ProtectionDecisionContracts.validate_optional(issues, path, row, field)
      value when is_binary(value) -> issues
      _value -> [error("#{path}.#{field}", "must be a map or string") | issues]
    end
  end
end
