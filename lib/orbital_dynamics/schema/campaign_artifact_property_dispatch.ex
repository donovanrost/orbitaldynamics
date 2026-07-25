defmodule OrbitalDynamics.Schema.CampaignArtifactPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CampaignPlanJsonSchema, CampaignRepairJsonSchema}

  def campaign_plan(
        field,
        contract_name,
        contract,
        default_property,
        {
          proposed_contact_schema,
          campaign_activity_schema,
          contact_intent_schema,
          ranked_timeline_schema,
          target_commitment_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CampaignPlanJsonSchema.property_field?/1,
      CampaignPlanJsonSchema.property_fun_from_context(
        proposed_contact_schema: proposed_contact_schema,
        campaign_activity_schema: campaign_activity_schema,
        contact_intent_schema: contact_intent_schema,
        ranked_timeline_schema: ranked_timeline_schema,
        target_commitment_schema: target_commitment_schema
      ),
      default_property
    )
  end

  def campaign_repair(
        field,
        contract_name,
        contract,
        default_property,
        timeline_transition_contract,
        timeline_transition_property,
        {
          planned_activity_schema,
          candidate_activity_schema,
          plan_delta_schema,
          approval_requirement_schema,
          policy_action_rule_schema,
          policy_decision_schema,
          candidate_refresh_provenance_schema,
          candidate_refresh_validation_records_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &CampaignRepairJsonSchema.property_field?/1,
      CampaignRepairJsonSchema.property_fun_from_context(
        planned_activity_schema: planned_activity_schema,
        candidate_activity_schema: candidate_activity_schema,
        plan_delta_schema: plan_delta_schema,
        approval_requirement_schema: approval_requirement_schema,
        policy_action_rule_schema: policy_action_rule_schema,
        policy_decision_schema: policy_decision_schema,
        candidate_refresh_provenance_schema: candidate_refresh_provenance_schema,
        candidate_refresh_validation_records_schema: candidate_refresh_validation_records_schema,
        timeline_transition_required_fields: timeline_transition_contract["required_fields"],
        timeline_transition_optional_fields: timeline_transition_contract["optional_fields"],
        timeline_transition_property_fun: timeline_transition_property
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
