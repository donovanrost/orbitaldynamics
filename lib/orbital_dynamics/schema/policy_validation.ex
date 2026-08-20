defmodule OrbitalDynamics.Schema.PolicyValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  def validate_artifact(issues, path, artifact, contract_name) do
    issues
    |> require_fields(path, artifact, required_fields(contract_name))
    |> validate_registered_artifact(path, artifact, contract_name)
  end

  def validate_approval_requirement(issues, path, requirement),
    do:
      validate_approval_requirement(
        issues,
        path,
        requirement,
        policy_model_limits(),
        OrbitalDynamics.Schema.PolicyFieldGroups.rule_match()
      )

  def validate_approval_requirement(
        issues,
        path,
        requirement,
        model_limits,
        rule_match_field_groups
      ) do
    OrbitalDynamics.Schema.ApprovalRequirementContracts.validate(
      issues,
      path,
      requirement,
      model_limits,
      rule_match_field_groups
    )
  end

  def validate_optional_decision_evidence(issues, path, decision, model_limits) do
    OrbitalDynamics.Schema.ApprovalRequirementContracts.validate_policy_decision_evidence(
      issues,
      path,
      decision,
      model_limits
    )
  end

  def validate_optional_decision_evidence(issues, path, decision),
    do: validate_optional_decision_evidence(issues, path, decision, policy_model_limits())

  def validate_optional_escalation(issues, path, row, field) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = escalation ->
        OrbitalDynamics.Schema.PolicyEscalationContracts.validate(
          issues,
          "#{path}.#{field}",
          escalation
        )

      _value ->
        [error("#{path}.#{field}", "must be an object") | issues]
    end
  end

  def validate_decision(issues, path, decision, model_limits, rule_match_field_groups) do
    OrbitalDynamics.Schema.PolicyDecisionContracts.validate(
      issues,
      path,
      decision,
      model_limits,
      rule_match_field_groups
    )
  end

  def validate_decision(issues, path, decision),
    do:
      validate_decision(
        issues,
        path,
        decision,
        policy_model_limits(),
        OrbitalDynamics.Schema.PolicyFieldGroups.rule_match()
      )

  def validate_rule_match(issues, path, match, rule_match_field_groups) do
    OrbitalDynamics.Schema.PolicyRuleMatchContracts.validate(
      issues,
      path,
      match,
      rule_match_field_groups
    )
  end

  def validate_rule_match(issues, path, match),
    do:
      validate_rule_match(
        issues,
        path,
        match,
        OrbitalDynamics.Schema.PolicyFieldGroups.rule_match()
      )

  def validate_bundle(issues, path, bundle, model_limits, action_rule_field_groups) do
    OrbitalDynamics.Schema.PolicyBundleContracts.validate(
      issues,
      path,
      bundle,
      model_limits,
      action_rule_field_groups
    )
  end

  def validate_bundle(issues, path, bundle),
    do:
      validate_bundle(
        issues,
        path,
        bundle,
        policy_model_limits(),
        OrbitalDynamics.Schema.PolicyFieldGroups.action_rule()
      )

  defp validate_registered_artifact(issues, path, artifact, "approval_requirement.v1"),
    do: validate_approval_requirement(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "authority_context.v1"),
    do: OrbitalDynamics.Schema.AuthorityContextContracts.validate(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "policy_decision.v1"),
    do: validate_decision(issues, path, artifact)

  defp validate_registered_artifact(issues, path, artifact, "policy_bundle.v1"),
    do: validate_bundle(issues, path, artifact)

  defp required_fields(contract_name) do
    OrbitalDynamics.Schema.ApprovalPolicyRegistryContracts.contracts()
    |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
    |> Map.fetch!("required_fields")
  end

  defp policy_model_limits,
    do: OrbitalDynamics.Schema.PolicyCapabilityContext.policy_model_limits()
end
