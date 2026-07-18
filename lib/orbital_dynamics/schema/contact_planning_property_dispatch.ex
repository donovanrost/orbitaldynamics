defmodule OrbitalDynamics.Schema.ContactPlanningPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ContactIntentJsonSchema,
    ContactIntentSummaryJsonSchema,
    ProposedContactJsonSchema
  }

  def intent(
        field,
        contract_name,
        contract,
        default_property,
        {
          approval_requirement_schema,
          policy_decision_rule_match_schema,
          policy_decision_schema,
          model_limits,
          timeline_integrity_issue_types
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ContactIntentJsonSchema.property_field?/1,
      ContactIntentJsonSchema.property_fun_from_context(
        approval_requirement_schema: approval_requirement_schema,
        policy_decision_rule_match_schema: policy_decision_rule_match_schema,
        policy_decision_schema: policy_decision_schema,
        model_limits: model_limits,
        timeline_integrity_issue_types: timeline_integrity_issue_types
      ),
      default_property
    )
  end

  def summary(
        field,
        contract_name,
        contract,
        default_property,
        {schema_contract, stable_id_pattern, model_limits, assumptions_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ContactIntentSummaryJsonSchema.property_field?/1,
      ContactIntentSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits,
        assumptions_schema: assumptions_schema
      ),
      default_property
    )
  end

  def proposed_contact(
        field,
        contract_name,
        contract,
        default_property,
        {cadence_import_schema, model_limits, source_window_schema, timeline_identity_schema}
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ProposedContactJsonSchema.property_field?/1,
      ProposedContactJsonSchema.property_fun_from_context(
        cadence_import_schema: cadence_import_schema,
        model_limits: model_limits,
        source_window_schema: source_window_schema,
        timeline_identity_schema: timeline_identity_schema
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
