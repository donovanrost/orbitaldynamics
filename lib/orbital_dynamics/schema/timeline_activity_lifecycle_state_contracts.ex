defmodule OrbitalDynamics.Schema.TimelineActivityLifecycleStateContracts do
  @moduledoc false

  def validate_status_state(issues, path, state, callbacks) when is_list(callbacks) do
    transition = Map.get(state, "status_transition")
    transition_decision = transition_decision(transition)

    issues
    |> validate_common(
      callbacks,
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
    |> validate_model_limits(callbacks, path, state)
    |> expect_optional_type(callbacks, path, state, "status_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, state, "status_transition")
    |> expect_optional_type(callbacks, path, state, "planned_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_status", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_activity_context", :map)
    |> expect_optional_type(callbacks, path, state, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, state, "planned_activity_context")
    |> validate_optional_activity_context(callbacks, path, state, "realized_activity_context")
    |> validate_optional_invalid_input(callbacks, path, state)
    |> expect_type(callbacks, path, state, "operator_action_reason", :binary)
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal transition-derived transition_decision"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal transition-derived review_required"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "required_operator_action",
      status_state_action(transition_decision),
      "must equal transition-derived required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "operator_action_reason",
      state_reason(transition, "no_status_change"),
      "must equal transition-derived operator_action_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal transition-derived import_action"
    )
  end

  def validate_approval_state(issues, path, state, callbacks) when is_list(callbacks) do
    transition = Map.get(state, "approval_transition")
    transition_decision = transition_decision(transition)

    issues
    |> validate_common(
      callbacks,
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
    |> validate_model_limits(callbacks, path, state)
    |> expect_optional_type(callbacks, path, state, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, state, "approval_transition")
    |> expect_optional_type(callbacks, path, state, "planned_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_activity_context", :map)
    |> expect_optional_type(callbacks, path, state, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, state, "planned_activity_context")
    |> validate_optional_activity_context(callbacks, path, state, "realized_activity_context")
    |> validate_optional_invalid_input(callbacks, path, state)
    |> expect_type(callbacks, path, state, "operator_action_reason", :binary)
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal transition-derived transition_decision"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal transition-derived review_required"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "required_operator_action",
      approval_state_action(transition_decision),
      "must equal transition-derived required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "operator_action_reason",
      state_reason(transition, "no_approval_status_change"),
      "must equal transition-derived operator_action_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal transition-derived import_action"
    )
  end

  def validate_lifecycle_state(issues, path, state, callbacks) when is_list(callbacks) do
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
      callbacks,
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
    |> validate_model_limits(callbacks, path, state)
    |> expect_optional_one_of(
      callbacks,
      path,
      state,
      "status_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_one_of(
      callbacks,
      path,
      state,
      "approval_transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_optional_type(callbacks, path, state, "required_operator_actions", :list)
    |> expect_optional_type(callbacks, path, state, "operator_action_reasons", :list)
    |> validate_optional_string_list(callbacks, path, state, "required_operator_actions")
    |> validate_optional_string_list(callbacks, path, state, "operator_action_reasons")
    |> expect_optional_type(callbacks, path, state, "status_transition", :map)
    |> expect_optional_type(callbacks, path, state, "approval_transition", :map)
    |> validate_optional_lifecycle_transition(callbacks, path, state, "status_transition")
    |> validate_optional_lifecycle_transition(callbacks, path, state, "approval_transition")
    |> expect_optional_type(callbacks, path, state, "planned_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_status", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_status_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_status", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "realized_approval_category", :binary)
    |> expect_optional_type(callbacks, path, state, "planned_activity_context", :map)
    |> expect_optional_type(callbacks, path, state, "realized_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, state, "planned_activity_context")
    |> validate_optional_activity_context(callbacks, path, state, "realized_activity_context")
    |> expect_optional_type(callbacks, path, state, "planned_protection_decision", :map)
    |> expect_optional_type(callbacks, path, state, "realized_protection_decision", :map)
    |> validate_optional_protection_decision(
      callbacks,
      path,
      state,
      "planned_protection_decision"
    )
    |> validate_optional_protection_decision(
      callbacks,
      path,
      state,
      "realized_protection_decision"
    )
    |> validate_lifecycle_state_protection_consistency(callbacks, path, state, "planned")
    |> validate_lifecycle_state_protection_consistency(callbacks, path, state, "realized")
    |> expect_optional_type(callbacks, path, state, "planned_locked", :boolean)
    |> expect_optional_type(callbacks, path, state, "realized_locked", :boolean)
    |> expect_optional_type(callbacks, path, state, "planned_executed", :boolean)
    |> expect_optional_type(callbacks, path, state, "realized_executed", :boolean)
    |> validate_optional_invalid_input(callbacks, path, state)
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "status_transition_decision",
      status_decision,
      "must equal status-transition-derived decision"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "approval_transition_decision",
      approval_decision,
      "must equal approval-transition-derived decision"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "transition_decision",
      transition_decision,
      "must equal lifecycle-derived transition_decision"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "review_required",
      transition_decision == "review",
      "must equal lifecycle-derived review_required"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "required_operator_actions",
      required_operator_actions,
      "must equal lifecycle-derived required_operator_actions"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "required_operator_action",
      lifecycle_required_action(required_operator_actions, transition_decision),
      "must equal lifecycle-derived required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "operator_action_reasons",
      lifecycle_reasons(state, protections),
      "must equal lifecycle-derived operator_action_reasons"
    )
    |> expect_field_equals(
      callbacks,
      path,
      state,
      "import_action",
      import_action(transition_decision),
      "must equal lifecycle-derived import_action"
    )
  end

  defp validate_common(issues, callbacks, path, state, schema_contract, model, assumption_fields) do
    issues
    |> expect_equal(callbacks, path, state, "schema_contract", schema_contract)
    |> expect_equal(callbacks, path, state, "model", model)
    |> expect_equal(callbacks, path, state, "validation_level", "artifact_contract")
    |> validate_stable_ids(callbacks, path, state, [
      "activity_id",
      "planned_activity_id",
      "realized_activity_id",
      "timeline_id",
      "planned_timeline_id",
      "realized_timeline_id"
    ])
    |> expect_one_of(
      callbacks,
      path,
      state,
      "transition_decision",
      OrbitalDynamics.Timeline.capabilities().transition_decisions
    )
    |> expect_type(callbacks, path, state, "review_required", :boolean)
    |> expect_type(callbacks, path, state, "required_operator_action", :binary)
    |> expect_type(callbacks, path, state, "import_action", :binary)
    |> expect_type(callbacks, path, state, "assumptions", :map)
    |> validate_assumptions(callbacks, path, state, assumption_fields)
  end

  defp validate_assumptions(issues, callbacks, path, state, fields) do
    case Map.get(state, "assumptions") do
      assumptions when is_map(assumptions) ->
        Enum.reduce(fields, issues, fn field, acc ->
          expect_equal(acc, callbacks, path <> ".assumptions", assumptions, field, true)
        end)

      _assumptions ->
        issues
    end
  end

  defp validate_model_limits(issues, callbacks, path, state) do
    issues
    |> expect_optional_type(callbacks, path, state, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, state, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      state,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
  end

  defp validate_optional_invalid_input(issues, callbacks, path, state) do
    issues
    |> expect_optional_type(callbacks, path, state, "invalid_activity_input", :boolean)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      state,
      "invalid_activity_input_count"
    )
    |> expect_optional_type(callbacks, path, state, "invalid_activity_input_reasons", :list)
    |> validate_optional_string_list(callbacks, path, state, "invalid_activity_input_reasons")
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

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed) do
    apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
      issues,
      path,
      map,
      field,
      allowed
    ])
  end

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_optional_lifecycle_transition(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_lifecycle_transition), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_activity_context(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_activity_context), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_string_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_string_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_protection_decision(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_protection_decision), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_lifecycle_state_protection_consistency(issues, callbacks, path, state, prefix) do
    apply(Keyword.fetch!(callbacks, :validate_lifecycle_state_protection_consistency), [
      issues,
      path,
      state,
      prefix
    ])
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])
end
