defmodule OrbitalDynamics.Schema.TimelineProtectionPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    TimelineActivityPreconditionSummaryJsonSchema,
    TimelinePreservationJsonSchema
  }

  def precondition(
        field,
        contract_name,
        contract,
        default_property,
        schema_contract,
        stable_id_pattern,
        {
          model_limits,
          precondition_statuses,
          string_array_schema,
          precondition_schema,
          stable_id_array_schema,
          timeline_identity_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineActivityPreconditionSummaryJsonSchema.property_field?/1,
      TimelineActivityPreconditionSummaryJsonSchema.property_fun_from_context(
        schema_contract: schema_contract,
        model_limits: model_limits,
        precondition_statuses: precondition_statuses,
        string_array_schema: string_array_schema,
        precondition_schema: precondition_schema,
        stable_id_pattern: stable_id_pattern,
        stable_id_array_schema: stable_id_array_schema,
        timeline_identity_schema: timeline_identity_schema
      ),
      default_property
    )
  end

  def preservation(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        model_limits,
        {
          count_map_schema,
          stable_id_array_schema,
          stable_id_array_map_schema,
          protection_decision_schema,
          timeline_identity_schema,
          assumptions_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelinePreservationJsonSchema.property_field?(&1, contract_name),
      TimelinePreservationJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        model_limits: model_limits,
        count_map_schema: count_map_schema,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema,
        protection_decision_schema: protection_decision_schema,
        stable_id_pattern: stable_id_pattern,
        timeline_identity_schema: timeline_identity_schema,
        assumptions_schema: assumptions_schema
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
