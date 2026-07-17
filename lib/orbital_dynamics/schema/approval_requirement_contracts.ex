defmodule OrbitalDynamics.Schema.ApprovalRequirementContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_rows: 4]
  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_equals: 6,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      require_fields: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    PolicyEscalationContracts,
    PolicyRuleMatchContracts,
    SchemaContractField
  }

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

  def validate(
        issues,
        path,
        requirement,
        policy_model_limits,
        policy_rule_match_field_groups
      )
      when is_list(policy_model_limits) and is_list(policy_rule_match_field_groups) do
    issues
    |> require_fields(
      path,
      requirement,
      [
        "activity_id",
        "activity_type",
        "action",
        "reason"
      ]
    )
    |> validate_stable_ids(path, requirement, ["activity_id"])
    |> validate_stable_ids(path, requirement, ["policy_bundle_id", "rule_id"])
    |> validate_optional_schema_contract(
      path,
      requirement,
      "approval_requirement.v1"
    )
    |> expect_optional_type(path, requirement, "activity_context", :map)
    |> validate_optional_activity_context(path, requirement, "activity_context")
    |> expect_optional_type(path, requirement, "approval_rule_matches", :list)
    |> validate_optional_rows(
      path <> ".approval_rule_matches",
      Map.get(requirement, "approval_rule_matches"),
      fn acc, row_path, row ->
        PolicyRuleMatchContracts.validate(
          acc,
          row_path,
          row,
          policy_rule_match_field_groups
        )
      end
    )
    |> expect_optional_type(path, requirement, "policy_bundle_id", :binary)
    |> expect_optional_one_of(
      path,
      requirement,
      "policy_classification",
      @classification_values
    )
    |> expect_optional_type(path, requirement, "policy_decision", :map)
    |> validate_optional_policy_decision_evidence(
      path,
      Map.get(requirement, "policy_decision"),
      policy_model_limits
    )
    |> expect_optional_type(path, requirement, "required_authority", :binary)
    |> expect_optional_type(path, requirement, "rule_id", :binary)
    |> expect_optional_one_of(
      path,
      requirement,
      "requirement_type",
      @requirement_types
    )
    |> validate_consistency(path, requirement)
  end

  def validate_policy_decision_evidence(issues, path, decision, policy_model_limits)
      when is_list(policy_model_limits) do
    validate_optional_policy_decision_evidence(
      issues,
      path,
      decision,
      policy_model_limits
    )
  end

  defp validate_consistency(issues, path, requirement) do
    issues
    |> validate_decision_consistency(path, requirement)
    |> validate_rule_match_consistency(path, requirement)
    |> validate_escalation_consistency(path, requirement)
  end

  defp validate_decision_consistency(issues, path, requirement) do
    case Map.get(requirement, "policy_decision") do
      %{} = decision ->
        issues
        |> expect_field_equals(
          path <> ".policy_decision",
          decision,
          "classification",
          Map.get(requirement, "policy_classification")
        )
        |> expect_field_equals(
          path <> ".policy_decision",
          decision,
          "policy_bundle_id",
          Map.get(requirement, "policy_bundle_id")
        )

      _decision ->
        issues
    end
  end

  defp validate_rule_match_consistency(issues, path, requirement) do
    rule_id = Map.get(requirement, "rule_id")
    rule_matches = Map.get(requirement, "approval_rule_matches")

    cond do
      not is_binary(rule_id) or not is_list(rule_matches) ->
        issues

      Enum.any?(rule_matches, &(is_map(&1) and Map.get(&1, "rule_id") == rule_id)) ->
        issues

      true ->
        [error(path <> ".approval_rule_matches", "must include root rule_id") | issues]
    end
  end

  defp validate_escalation_consistency(issues, path, requirement) do
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
            "must include root required_authority"
          )
          | issues
        ]
    end
  end

  defp validate_optional_policy_decision_evidence(issues, _path, nil, _limits),
    do: issues

  defp validate_optional_policy_decision_evidence(
         issues,
         path,
         %{} = decision,
         policy_model_limits
       ) do
    issues
    |> validate_stable_ids(path, decision, ["policy_bundle_id"])
    |> expect_optional_one_of(path, decision, "classification", @classification_values)
    |> expect_optional_type(path, decision, "escalations", :list)
    |> validate_optional_rows(
      path <> ".escalations",
      Map.get(decision, "escalations"),
      &PolicyEscalationContracts.validate/3
    )
    |> expect_optional_type(path, decision, "assumptions", :map)
    |> expect_optional_type(path, decision, "model_limits", :list)
    |> validate_string_list_items(path, decision, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      decision,
      policy_model_limits,
      "must match policy model limits"
    )
  end

  defp validate_optional_policy_decision_evidence(issues, path, _decision, _limits),
    do: [error(path, "must be an object") | issues]

  defp validate_optional_schema_contract(issues, path, map, expected),
    do: SchemaContractField.validate_optional(issues, path, map, expected)

  defp validate_optional_activity_context(issues, path, map, field),
    do: ActivityContextContracts.validate_optional(issues, path, map, field)

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
