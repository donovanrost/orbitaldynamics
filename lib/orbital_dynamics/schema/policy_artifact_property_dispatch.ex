defmodule OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ApprovalRequirementJsonSchema,
    PolicyBundleJsonSchema,
    PolicyDecisionJsonSchema
  }

  def bundle(
        field,
        contract_name,
        contract,
        default_property,
        {policy_action_rule_schema, policy_model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &PolicyBundleJsonSchema.property_field?/1,
      PolicyBundleJsonSchema.property_fun_from_context(
        policy_action_rule_schema: policy_action_rule_schema,
        policy_model_limits: policy_model_limits
      ),
      default_property
    )
  end

  def decision(
        field,
        contract_name,
        contract,
        default_property,
        {policy_decision_rule_match_schema, policy_escalation_schema, policy_model_limits}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &PolicyDecisionJsonSchema.property_field?/1,
      PolicyDecisionJsonSchema.property_fun_from_context(
        policy_decision_rule_match_schema: policy_decision_rule_match_schema,
        policy_escalation_schema: policy_escalation_schema,
        policy_model_limits: policy_model_limits
      ),
      default_property
    )
  end

  def approval_requirement(
        field,
        contract_name,
        contract,
        default_property,
        {
          stable_id_pattern,
          rule_match_schema,
          activity_context_schema,
          policy_escalation_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ApprovalRequirementJsonSchema.property_field?/1,
      ApprovalRequirementJsonSchema.property_fun_from_context(
        stable_id_pattern: stable_id_pattern,
        rule_match_schema: rule_match_schema,
        activity_context_schema: activity_context_schema,
        policy_escalation_schema: policy_escalation_schema
      ),
      default_property
    )
  end

  defp dispatch(
         field,
         contract_name,
         contract,
         property_field?,
         property,
         default_property
       ) do
    if property_field?.(field) do
      property.(field)
    else
      default_property.(field, contract_name, contract)
    end
  end
end
