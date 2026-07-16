defmodule OrbitalDynamics.Schema.ApprovalRequirementContracts do
  @moduledoc false

  @classification_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  @requirement_types [
    "cancellation",
    "command_review",
    "contact_schedule_change",
    "downstream_window_review",
    "ground_station_unavailable",
    "health_check_review",
    "maneuver_authority_review",
    "maneuver_timing_change",
    "observation_reassignment",
    "operator_review",
    "operator_review_queue",
    "realized_feedback_review",
    "strategic_addition",
    "tracking_review"
  ]

  def validate(issues, path, requirement, policy_model_limits, callbacks)
      when is_list(policy_model_limits) and is_list(callbacks) do
    issues
    |> require_fields(
      path,
      requirement,
      [
        "activity_id",
        "activity_type",
        "action",
        "reason"
      ],
      callbacks
    )
    |> validate_stable_ids(path, requirement, ["activity_id"], callbacks)
    |> validate_stable_ids(path, requirement, ["policy_bundle_id", "rule_id"], callbacks)
    |> validate_optional_schema_contract(
      path,
      requirement,
      "approval_requirement.v1",
      callbacks
    )
    |> expect_optional_type(path, requirement, "activity_context", :map, callbacks)
    |> validate_optional_activity_context(path, requirement, "activity_context", callbacks)
    |> expect_optional_type(path, requirement, "approval_rule_matches", :list, callbacks)
    |> validate_optional_rows(
      path <> ".approval_rule_matches",
      Map.get(requirement, "approval_rule_matches"),
      :validate_policy_rule_match,
      callbacks
    )
    |> expect_optional_type(path, requirement, "policy_bundle_id", :binary, callbacks)
    |> expect_optional_one_of(
      path,
      requirement,
      "policy_classification",
      @classification_values,
      callbacks
    )
    |> expect_optional_type(path, requirement, "policy_decision", :map, callbacks)
    |> validate_optional_policy_decision_evidence(
      path,
      Map.get(requirement, "policy_decision"),
      policy_model_limits,
      callbacks
    )
    |> expect_optional_type(path, requirement, "required_authority", :binary, callbacks)
    |> expect_optional_type(path, requirement, "rule_id", :binary, callbacks)
    |> expect_optional_one_of(
      path,
      requirement,
      "requirement_type",
      @requirement_types,
      callbacks
    )
    |> validate_consistency(path, requirement, callbacks)
  end

  def validate_policy_decision_evidence(issues, path, decision, policy_model_limits, callbacks)
      when is_list(policy_model_limits) and is_list(callbacks) do
    validate_optional_policy_decision_evidence(
      issues,
      path,
      decision,
      policy_model_limits,
      callbacks
    )
  end

  defp validate_consistency(issues, path, requirement, callbacks) do
    issues
    |> validate_decision_consistency(path, requirement, callbacks)
    |> validate_rule_match_consistency(path, requirement, callbacks)
    |> validate_escalation_consistency(path, requirement, callbacks)
  end

  defp validate_decision_consistency(issues, path, requirement, callbacks) do
    case Map.get(requirement, "policy_decision") do
      %{} = decision ->
        issues
        |> expect_field_equals(
          path <> ".policy_decision",
          decision,
          "classification",
          Map.get(requirement, "policy_classification"),
          callbacks
        )
        |> expect_field_equals(
          path <> ".policy_decision",
          decision,
          "policy_bundle_id",
          Map.get(requirement, "policy_bundle_id"),
          callbacks
        )

      _decision ->
        issues
    end
  end

  defp validate_rule_match_consistency(issues, path, requirement, callbacks) do
    rule_id = Map.get(requirement, "rule_id")
    rule_matches = Map.get(requirement, "approval_rule_matches")

    cond do
      not is_binary(rule_id) or not is_list(rule_matches) ->
        issues

      Enum.any?(rule_matches, &(is_map(&1) and Map.get(&1, "rule_id") == rule_id)) ->
        issues

      true ->
        [error(path <> ".approval_rule_matches", "must include root rule_id", callbacks) | issues]
    end
  end

  defp validate_escalation_consistency(issues, path, requirement, callbacks) do
    authority = Map.get(requirement, "required_authority")
    escalations = get_in(requirement, ["policy_decision", "escalations"])

    cond do
      not is_binary(authority) or not is_list(escalations) ->
        issues

      Enum.any?(escalations, &(is_map(&1) and Map.get(&1, "required_authority") == authority)) ->
        issues

      true ->
        [
          error(
            path <> ".policy_decision.escalations",
            "must include root required_authority",
            callbacks
          )
          | issues
        ]
    end
  end

  defp validate_optional_policy_decision_evidence(issues, _path, nil, _limits, _callbacks),
    do: issues

  defp validate_optional_policy_decision_evidence(
         issues,
         path,
         %{} = decision,
         policy_model_limits,
         callbacks
       ) do
    issues
    |> validate_stable_ids(path, decision, ["policy_bundle_id"], callbacks)
    |> expect_optional_one_of(path, decision, "classification", @classification_values, callbacks)
    |> expect_optional_type(path, decision, "escalations", :list, callbacks)
    |> validate_optional_rows(
      path <> ".escalations",
      Map.get(decision, "escalations"),
      :validate_policy_escalation,
      callbacks
    )
    |> expect_optional_type(path, decision, "assumptions", :map, callbacks)
    |> expect_optional_type(path, decision, "model_limits", :list, callbacks)
    |> validate_string_list_items(path, decision, "model_limits", callbacks)
    |> validate_optional_exact_model_limits(
      path,
      decision,
      policy_model_limits,
      "must match policy model limits",
      callbacks
    )
  end

  defp validate_optional_policy_decision_evidence(issues, path, _decision, _limits, callbacks),
    do: [error(path, "must be an object", callbacks) | issues]

  defp require_fields(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_schema_contract(issues, path, map, expected, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_schema_contract), [
        issues,
        path,
        map,
        expected
      ])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_optional_activity_context(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_activity_context), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_rows(issues, path, rows, validator_name, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [
        issues,
        path,
        rows,
        require_callback(callbacks, validator_name)
      ])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_field_equals(issues, path, map, field, expected, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_exact_model_limits(
         issues,
         path,
         map,
         expected,
         message,
         callbacks
       ) do
    apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      map,
      expected,
      message
    ])
  end

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
