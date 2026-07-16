defmodule OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    CollectionValidation,
    LifecycleTransitionContracts,
    ProtectionDecisionContracts
  }

  def validate_status_state(issues, path, state, model_limits) when is_list(model_limits) do
    transition = Map.get(state, "status_transition")
    transition_decision = transition_decision(transition)

    issues
    |> validate_common(
      path,
      state,
      "timeline_activity_status_state.v1",
      "artifact_only_timeline_activity_status_state",
      [
        "artifact_only",
        "no_schedule_mutation",
        "no_operator_authority_grant",
        "no_command_execution"
      ]
    )
    |> validate_model_limits(path, state, model_limits)
    |> expect_optional_type(path, state, "status_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, state, "status_transition")
    |> expect_optional_type(path, state, "planned_status", :binary)
    |> expect_optional_type(path, state, "realized_status", :binary)
    |> expect_optional_type(path, state, "planned_status_category", :binary)
    |> expect_optional_type(path, state, "realized_status_category", :binary)
    |> expect_optional_type(path, state, "planned_activity_context", :map)
    |> expect_optional_type(path, state, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, state, "planned_activity_context")
    |> ActivityContextContracts.validate_optional(path, state, "realized_activity_context")
    |> validate_optional_invalid_input(path, state)
    |> expect_type(path, state, "operator_action_reason", :binary)
    |> expect_field_equals(
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal transition-derived transition_decision"
    )
    |> expect_field_equals(
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal transition-derived review_required"
    )
    |> expect_field_equals(
      path,
      state,
      "required_operator_action",
      status_state_action(transition_decision),
      "must equal transition-derived required_operator_action"
    )
    |> expect_field_equals(
      path,
      state,
      "operator_action_reason",
      state_reason(transition, "no_status_change"),
      "must equal transition-derived operator_action_reason"
    )
    |> expect_field_equals(
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal transition-derived import_action"
    )
  end

  def validate_approval_state(issues, path, state, model_limits) when is_list(model_limits) do
    transition = Map.get(state, "approval_transition")
    transition_decision = transition_decision(transition)

    issues
    |> validate_common(
      path,
      state,
      "timeline_activity_approval_state.v1",
      "artifact_only_timeline_activity_approval_state",
      [
        "artifact_only",
        "no_schedule_mutation",
        "no_operator_authority_grant",
        "no_command_execution"
      ]
    )
    |> validate_model_limits(path, state, model_limits)
    |> expect_optional_type(path, state, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, state, "approval_transition")
    |> expect_optional_type(path, state, "planned_approval_status", :binary)
    |> expect_optional_type(path, state, "realized_approval_status", :binary)
    |> expect_optional_type(path, state, "planned_approval_category", :binary)
    |> expect_optional_type(path, state, "realized_approval_category", :binary)
    |> expect_optional_type(path, state, "planned_activity_context", :map)
    |> expect_optional_type(path, state, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, state, "planned_activity_context")
    |> ActivityContextContracts.validate_optional(path, state, "realized_activity_context")
    |> validate_optional_invalid_input(path, state)
    |> expect_type(path, state, "operator_action_reason", :binary)
    |> expect_field_equals(
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal transition-derived transition_decision"
    )
    |> expect_field_equals(
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal transition-derived review_required"
    )
    |> expect_field_equals(
      path,
      state,
      "required_operator_action",
      approval_state_action(transition_decision),
      "must equal transition-derived required_operator_action"
    )
    |> expect_field_equals(
      path,
      state,
      "operator_action_reason",
      state_reason(transition, "no_approval_status_change"),
      "must equal transition-derived operator_action_reason"
    )
    |> expect_field_equals(
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal transition-derived import_action"
    )
  end

  def validate_lifecycle_state(issues, path, state, model_limits) when is_list(model_limits) do
    status_decision = transition_decision(Map.get(state, "status_transition"))
    approval_decision = transition_decision(Map.get(state, "approval_transition"))

    protections = [
      Map.get(state, "planned_protection_decision"),
      Map.get(state, "realized_protection_decision")
    ]

    transition_decision =
      lifecycle_transition_decision(status_decision, approval_decision, protections)

    required_operator_actions =
      lifecycle_required_actions(
        status_decision,
        approval_decision,
        protections,
        transition_decision
      )

    issues
    |> validate_common(
      path,
      state,
      "timeline_activity_lifecycle_state.v1",
      "artifact_only_timeline_activity_lifecycle_state",
      [
        "artifact_only",
        "no_schedule_mutation",
        "no_operator_authority_grant",
        "no_cadence_import",
        "no_command_execution"
      ]
    )
    |> validate_model_limits(path, state, model_limits)
    |> expect_optional_one_of(
      path,
      state,
      "status_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      path,
      state,
      "approval_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_type(path, state, "required_operator_actions", :list)
    |> expect_optional_type(path, state, "operator_action_reasons", :list)
    |> CollectionValidation.validate_optional_string_list(
      path,
      state,
      "required_operator_actions"
    )
    |> CollectionValidation.validate_optional_string_list(path, state, "operator_action_reasons")
    |> expect_optional_type(path, state, "status_transition", :map)
    |> expect_optional_type(path, state, "approval_transition", :map)
    |> LifecycleTransitionContracts.validate_optional(path, state, "status_transition")
    |> LifecycleTransitionContracts.validate_optional(path, state, "approval_transition")
    |> expect_optional_type(path, state, "planned_status", :binary)
    |> expect_optional_type(path, state, "realized_status", :binary)
    |> expect_optional_type(path, state, "planned_status_category", :binary)
    |> expect_optional_type(path, state, "realized_status_category", :binary)
    |> expect_optional_type(path, state, "planned_approval_status", :binary)
    |> expect_optional_type(path, state, "realized_approval_status", :binary)
    |> expect_optional_type(path, state, "planned_approval_category", :binary)
    |> expect_optional_type(path, state, "realized_approval_category", :binary)
    |> expect_optional_type(path, state, "planned_activity_context", :map)
    |> expect_optional_type(path, state, "realized_activity_context", :map)
    |> ActivityContextContracts.validate_optional(path, state, "planned_activity_context")
    |> ActivityContextContracts.validate_optional(path, state, "realized_activity_context")
    |> expect_optional_type(path, state, "planned_protection_decision", :map)
    |> expect_optional_type(path, state, "realized_protection_decision", :map)
    |> ProtectionDecisionContracts.validate_optional(
      path,
      state,
      "planned_protection_decision"
    )
    |> ProtectionDecisionContracts.validate_optional(
      path,
      state,
      "realized_protection_decision"
    )
    |> ProtectionDecisionContracts.validate_lifecycle_state_consistency(path, state, "planned")
    |> ProtectionDecisionContracts.validate_lifecycle_state_consistency(path, state, "realized")
    |> expect_optional_type(path, state, "planned_locked", :boolean)
    |> expect_optional_type(path, state, "realized_locked", :boolean)
    |> expect_optional_type(path, state, "planned_executed", :boolean)
    |> expect_optional_type(path, state, "realized_executed", :boolean)
    |> validate_optional_invalid_input(path, state)
    |> expect_field_equals(
      path,
      state,
      "status_transition_decision",
      status_decision,
      "must equal status-transition-derived decision"
    )
    |> expect_field_equals(
      path,
      state,
      "approval_transition_decision",
      approval_decision,
      "must equal approval-transition-derived decision"
    )
    |> expect_field_equals(
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal lifecycle-derived transition_decision"
    )
    |> expect_field_equals(
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal lifecycle-derived review_required"
    )
    |> expect_field_equals(
      path,
      state,
      "required_operator_actions",
      required_operator_actions,
      "must equal lifecycle-derived required_operator_actions"
    )
    |> expect_field_equals(
      path,
      state,
      "required_operator_action",
      lifecycle_required_action(required_operator_actions, transition_decision),
      "must equal lifecycle-derived required_operator_action"
    )
    |> expect_field_equals(
      path,
      state,
      "operator_action_reasons",
      lifecycle_reasons(state, protections),
      "must equal lifecycle-derived operator_action_reasons"
    )
    |> expect_field_equals(
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal lifecycle-derived import_action"
    )
  end

  defp validate_common(issues, path, state, schema_contract, model, assumption_fields) do
    issues
    |> expect_equal(path, state, "schema_contract", schema_contract)
    |> expect_equal(path, state, "model", model)
    |> expect_equal(path, state, "validation_level", "artifact_contract")
    |> validate_stable_ids(path, state, [
      "activity_id",
      "planned_activity_id",
      "realized_activity_id",
      "timeline_id",
      "planned_timeline_id",
      "realized_timeline_id"
    ])
    |> expect_one_of(
      path,
      state,
      "transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_type(path, state, "review_required", :boolean)
    |> expect_type(path, state, "required_operator_action", :binary)
    |> expect_type(path, state, "import_action", :binary)
    |> expect_type(path, state, "assumptions", :map)
    |> validate_assumptions(path, state, assumption_fields)
  end

  defp validate_assumptions(issues, path, state, fields) do
    case Map.get(state, "assumptions") do
      assumptions when is_map(assumptions) ->
        Enum.reduce(fields, issues, fn field, acc ->
          expect_equal(acc, path <> ".assumptions", assumptions, field, true)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_model_limits(issues, path, state, model_limits) do
    issues
    |> expect_optional_type(path, state, "model_limits", :list)
    |> validate_string_list_items(path, state, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      state,
      model_limits,
      "must match timeline report model limits"
    )
  end

  defp validate_optional_invalid_input(issues, path, state) do
    issues
    |> expect_optional_type(path, state, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      path,
      state,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(path, state, "invalid_activity_input_reasons", :list)
    |> CollectionValidation.validate_optional_string_list(
      path,
      state,
      "invalid_activity_input_reasons"
    )
  end

  defp transition_decision(nil), do: "none"
  defp transition_decision(%{"requires_operator_review" => true}), do: "review"
  defp transition_decision(%{}), do: "record"
  defp transition_decision(_transition), do: "none"

  defp state_reason(nil, fallback), do: fallback
  defp state_reason(%{"operator_action_reason" => reason}, _fallback), do: reason
  defp state_reason(_transition, fallback), do: fallback

  defp status_state_action("none"), do: "none"
  defp status_state_action("review"), do: "review_activity_transition"
  defp status_state_action("record"), do: "record_timeline_change"

  defp approval_state_action("none"), do: "none"
  defp approval_state_action("review"), do: "review_activity_approval"
  defp approval_state_action("record"), do: "record_timeline_change"

  defp import_action("none"), do: "record_preserved_activity"
  defp import_action("review"), do: "review_timeline_diff"
  defp import_action("record"), do: "import_replacement_activity"

  defp lifecycle_transition_decision(status_decision, approval_decision, protections) do
    cond do
      status_decision == "review" or approval_decision == "review" or
          lifecycle_protection_review?(protections) ->
        "review"

      status_decision == "record" or approval_decision == "record" ->
        "record"

      true ->
        "none"
    end
  end

  defp lifecycle_required_actions(
         status_decision,
         approval_decision,
         protections,
         transition_decision
       ) do
    actions =
      [
        status_state_action(status_decision),
        approval_state_action(approval_decision)
      ] ++ lifecycle_protection_actions(protections)

    actions =
      actions
      |> Enum.reject(&(&1 in [nil, "none"]))
      |> sorted_unique_binary_values()

    case {transition_decision, actions} do
      {"none", []} -> ["none"]
      {"record", []} -> ["record_timeline_change"]
      {_decision, actions} -> actions
    end
  end

  defp lifecycle_required_action(actions, "review") do
    cond do
      "review_activity_transition" in actions -> "review_activity_transition"
      "review_activity_approval" in actions -> "review_activity_approval"
      "review_timeline_change" in actions -> "review_timeline_change"
      true -> List.first(actions) || "review_activity_transition"
    end
  end

  defp lifecycle_required_action(_actions, "record"), do: "record_timeline_change"
  defp lifecycle_required_action(_actions, "none"), do: "none"

  defp lifecycle_reasons(state, protections) do
    [
      state_reason(Map.get(state, "status_transition"), "no_status_change"),
      state_reason(Map.get(state, "approval_transition"), "no_approval_status_change")
    ]
    |> Kernel.++(lifecycle_protection_reasons(protections))
    |> Enum.reject(&(&1 in [nil, "no_status_change", "no_approval_status_change"]))
    |> sorted_unique_binary_values()
    |> case do
      [] -> nil
      reasons -> reasons
    end
  end

  defp lifecycle_protection_review?(protections) do
    Enum.any?(protections, fn
      %{"protection_decision" => "review_change"} -> true
      _protection -> false
    end)
  end

  defp lifecycle_protection_actions(protections) do
    Enum.flat_map(protections, fn
      %{"protection_decision" => "review_change"} -> ["review_timeline_change"]
      _protection -> []
    end)
  end

  defp lifecycle_protection_reasons(protections) do
    protections
    |> Enum.filter(&(Map.get(&1 || %{}, "protection_decision") == "review_change"))
    |> Enum.map(&Map.get(&1, "reason"))
  end

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
