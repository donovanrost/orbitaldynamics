defmodule OrbitalDynamics.Schema.CampaignArtifactPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [fallback: 4, provider: 3]

  def property(
        field,
        "campaign_plan.v1" = contract_name,
        contract,
        context,
        _property_fun
      ) do
    OrbitalDynamics.Schema.CampaignArtifactPropertyDispatch.campaign_plan(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      {fn -> provider(context, :proposed_contact_row_json_schema, []) end,
       fn -> provider(context, :campaign_activity_json_schema, []) end,
       fn -> provider(context, :contact_intent_row_json_schema, []) end,
       fn -> provider(context, :ranked_timeline_json_schema, []) end}
    )
  end

  def property(
        field,
        "campaign_repair.v2" = contract_name,
        contract,
        context,
        property_fun
      ) do
    timeline_transition_contract =
      provider(context, :registry_contract!, ["timeline_transition_application_report.v1"])

    OrbitalDynamics.Schema.CampaignArtifactPropertyDispatch.campaign_repair(
      field,
      contract_name,
      contract,
      fn arg1, arg2, arg3 -> fallback(arg1, arg2, arg3, context) end,
      timeline_transition_contract,
      fn transition_field ->
        property_fun.(
          transition_field,
          "timeline_transition_application_report.v1",
          timeline_transition_contract
        )
      end,
      {fn -> provider(context, :planned_activity_json_schema, []) end,
       fn -> provider(context, :candidate_activity_json_schema, []) end,
       fn -> provider(context, :plan_delta_json_schema, []) end,
       fn -> provider(context, :approval_requirement_json_schema, []) end,
       fn -> provider(context, :policy_action_rule_json_schema, []) end,
       fn -> provider(context, :policy_decision_json_schema, []) end}
    )
  end
end
