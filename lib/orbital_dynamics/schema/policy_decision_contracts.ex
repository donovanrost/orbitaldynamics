defmodule OrbitalDynamics.Schema.PolicyDecisionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_one_of: 5,
      expect_optional_list: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  @classification_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  def validate(issues, path, decision, policy_model_limits, rule_match_field_groups)
      when is_map(decision) and is_list(policy_model_limits) and
             is_list(rule_match_field_groups) do
    issues
    |> require_fields(path, decision, ["schema_contract", "classification"])
    |> validate_stable_ids(path, decision, ["policy_bundle_id"])
    |> expect_equal(path, decision, "schema_contract", "policy_decision.v1")
    |> expect_one_of(path, decision, "classification", @classification_values)
    |> expect_optional_list(path, decision, "rule_matches")
    |> validate_optional_rows(
      path <> ".rule_matches",
      Map.get(decision, "rule_matches"),
      fn acc, row_path, match ->
        OrbitalDynamics.Schema.PolicyRuleMatchContracts.validate(
          acc,
          row_path,
          match,
          rule_match_field_groups
        )
      end
    )
    |> expect_optional_list(path, decision, "escalations")
    |> validate_optional_rows(
      path <> ".escalations",
      Map.get(decision, "escalations"),
      &OrbitalDynamics.Schema.PolicyEscalationContracts.validate/3
    )
    |> expect_optional_non_negative_integer(path, decision, "approval_requirement_count")
    |> expect_optional_non_negative_integer(path, decision, "risk_count")
    |> expect_optional_type(path, decision, "assumptions", :map)
    |> expect_optional_type(path, decision, "authority_context", :map)
    |> expect_optional_type(path, decision, "authority_context_evaluation", :map)
    |> expect_optional_type(path, decision, "eligibility_status", :binary)
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_policy_boundary(path, decision)
    |> expect_optional_type(path, decision, "model_limits", :list)
    |> validate_string_list_items(path, decision, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      decision,
      policy_model_limits,
      "must match policy model limits"
    )
    |> OrbitalDynamics.Schema.PolicyDecisionCountContracts.validate(path, decision)
  end

  def validate(issues, path, _decision, policy_model_limits, rule_match_field_groups)
      when is_list(policy_model_limits) and is_list(rule_match_field_groups) do
    [error(path, "must be an object") | issues]
  end
end
