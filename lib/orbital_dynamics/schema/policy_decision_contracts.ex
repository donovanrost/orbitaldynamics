defmodule OrbitalDynamics.Schema.PolicyDecisionContracts do
  @moduledoc false

  @classification_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  def validate(issues, path, decision, policy_model_limits, callbacks)
      when is_list(policy_model_limits) and is_list(callbacks) do
    issues
    |> require_fields(path, decision, ["schema_contract", "classification"], callbacks)
    |> validate_stable_ids(path, decision, ["policy_bundle_id"], callbacks)
    |> expect_equal(path, decision, "schema_contract", "policy_decision.v1", callbacks)
    |> expect_one_of(path, decision, "classification", @classification_values, callbacks)
    |> expect_optional_list(path, decision, "rule_matches", callbacks)
    |> validate_optional_rows(
      path <> ".rule_matches",
      Map.get(decision, "rule_matches"),
      :validate_policy_rule_match,
      callbacks
    )
    |> expect_optional_list(path, decision, "escalations", callbacks)
    |> validate_optional_rows(
      path <> ".escalations",
      Map.get(decision, "escalations"),
      :validate_policy_escalation,
      callbacks
    )
    |> expect_optional_non_negative_integer(
      path,
      decision,
      "approval_requirement_count",
      callbacks
    )
    |> expect_optional_non_negative_integer(path, decision, "risk_count", callbacks)
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
    |> validate_policy_decision_counts(path, decision, callbacks)
  end

  defp require_fields(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, path, map, field, expected, callbacks),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, path, map, field, allowed, callbacks),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_list(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_optional_rows(issues, path, rows, validator_name, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [
        issues,
        path,
        rows,
        require_callback(callbacks, validator_name)
      ])

  defp expect_optional_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_policy_decision_counts(issues, path, decision, callbacks),
    do:
      apply(require_callback(callbacks, :validate_policy_decision_counts), [
        issues,
        path,
        decision
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
