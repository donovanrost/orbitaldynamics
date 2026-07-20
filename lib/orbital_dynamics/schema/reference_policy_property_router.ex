defmodule OrbitalDynamics.Schema.ReferencePolicyPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "activity_template.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.activity_template(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"activity_template.v1", context_value(context, :stable_id_pattern)}
    )
  end

  def property(field, "policy_bundle.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.bundle(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :policy_action_rule_json_schema, []) end,
       fn -> provider(context, :policy_model_limits, []) end}
    )
  end

  def property(field, "policy_decision.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.decision(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :policy_decision_rule_match_json_schema, []) end,
       fn -> provider(context, :policy_escalation_json_schema, []) end,
       fn -> provider(context, :policy_model_limits, []) end}
    )
  end

  def property(field, "capability_catalog.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.capability_catalog(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "accepted_planning_state.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.accepted_state(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :spacecraft_state_estimate_json_schema, []) end,
       fn -> provider(context, :maneuver_execution_delta_json_schema, []) end}
    )
  end

  def property(field, "manifest_field_reference.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PlanningReferencePropertyDispatch.manifest_field_reference(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end
    )
  end

  def property(field, "approval_requirement.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.PolicyArtifactPropertyDispatch.approval_requirement(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {context_value(context, :stable_id_pattern),
       fn -> provider(context, :policy_decision_rule_match_json_schema, []) end,
       fn -> provider(context, :activity_context_json_schema, []) end,
       fn -> provider(context, :policy_escalation_json_schema, []) end}
    )
  end
end
