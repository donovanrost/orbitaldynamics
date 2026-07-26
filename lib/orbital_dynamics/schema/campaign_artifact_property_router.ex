defmodule OrbitalDynamics.Schema.CampaignArtifactPropertyRouter do
  @moduledoc false

  import OrbitalDynamics.Schema.JsonSchemaPropertySupport,
    only: [context_value: 2, fallback: 4, provider: 3]

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
       fn -> provider(context, :ranked_timeline_json_schema, []) end,
       fn ->
         OrbitalDynamics.Schema.CampaignPlanJsonSchema.target_commitment_from_context(
           context_value(context, :stable_id_pattern)
         )
       end}
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
       fn -> provider(context, :policy_decision_json_schema, []) end,
       fn ->
         candidate_refresh_contract =
           provider(context, :registry_contract!, ["candidate_refresh.v1"])

         property_fun.("provenance", "candidate_refresh.v1", candidate_refresh_contract)
       end,
       fn ->
         candidate_refresh_contract =
           provider(context, :registry_contract!, ["candidate_refresh.v1"])

         property_fun.("model_limits", "candidate_refresh.v1", candidate_refresh_contract)
       end,
       fn ->
         candidate_refresh_contract =
           provider(context, :registry_contract!, ["candidate_refresh.v1"])

         property_fun.(
           "accepted_planning_state",
           "candidate_refresh.v1",
           candidate_refresh_contract
         )
       end,
       fn ->
         candidate_refresh_contract =
           provider(context, :registry_contract!, ["candidate_refresh.v1"])

         property_fun.("operational_feedback", "candidate_refresh.v1", candidate_refresh_contract)
       end,
       fn ->
         candidate_refresh_contract =
           provider(context, :registry_contract!, ["candidate_refresh.v1"])

         property_fun.("validation_records", "candidate_refresh.v1", candidate_refresh_contract)
       end}
    )
  end
end
