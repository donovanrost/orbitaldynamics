defmodule OrbitalDynamics.Schema.ContactPlanningPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

  def property(field, "contact_intent.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.intent(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :approval_requirement_json_schema, []) end,
       fn -> provider(context, :policy_decision_rule_match_json_schema, []) end,
       fn -> provider(context, :policy_decision_json_schema, []) end,
       fn -> provider(context, :contact_intent_model_limits, []) end,
       fn -> provider(context, :timeline_integrity_issue_types, []) end}
    )
  end

  def property(field, "contact_intent_summary.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.summary(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {"contact_intent_summary.v1", context_value(context, :stable_id_pattern),
       fn -> provider(context, :contact_intent_model_limits, []) end,
       fn -> provider(context, :contact_intent_summary_assumptions_json_schema, []) end}
    )
  end

  def property(field, "proposed_contact.v1" = contract_name, contract, context) do
    OrbitalDynamics.Schema.ContactPlanningPropertyDispatch.proposed_contact(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :cadence_import_json_schema, ["proposed_contact.v1"]) end,
       &OrbitalDynamics.Schema.ProposedContactContracts.model_limits/0,
       fn -> provider(context, :candidate_activity_source_window_json_schema, []) end,
       fn -> provider(context, :timeline_identity_json_schema, []) end}
    )
  end
end
