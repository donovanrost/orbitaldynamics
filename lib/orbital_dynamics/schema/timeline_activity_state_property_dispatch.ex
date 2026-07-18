defmodule OrbitalDynamics.Schema.TimelineActivityStatePropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    TimelineActivityLifecycleStateJsonSchema,
    TimelineActivityStateJsonSchema
  }

  def state(
        field,
        contract_name,
        contract,
        default_property,
        schema_contract,
        stable_id_pattern,
        {
          row_schema,
          capability,
          stable_id_array_schema,
          string_array_schema,
          timeline_identity_schema,
          activity_context_schema,
          lifecycle_transition_schema,
          protection_decision_schema,
          assumptions_schema,
          model_limits
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineActivityStateJsonSchema.property_field?/1,
      TimelineActivityStateJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        schema_contract: schema_contract,
        capability: capability,
        stable_id_pattern: stable_id_pattern,
        stable_id_array_schema: stable_id_array_schema,
        string_array_schema: string_array_schema,
        timeline_identity_schema: timeline_identity_schema,
        activity_context_schema: activity_context_schema,
        lifecycle_transition_schema: lifecycle_transition_schema,
        protection_decision_schema: protection_decision_schema,
        assumptions_schema: assumptions_schema,
        model_limits: model_limits
      ),
      default_property
    )
  end

  def lifecycle(
        field,
        contract_name,
        contract,
        default_property,
        stable_id_pattern,
        {
          model_limits,
          transition_decisions,
          string_array_schema,
          lifecycle_transition_schema,
          protection_decision_schema,
          activity_context_schema,
          lifecycle_assumptions_schema,
          default_assumptions_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineActivityLifecycleStateJsonSchema.property_field?/1,
      TimelineActivityLifecycleStateJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        model_limits: model_limits,
        stable_id_pattern: stable_id_pattern,
        transition_decisions: transition_decisions,
        string_array_schema: string_array_schema,
        lifecycle_transition_schema: lifecycle_transition_schema,
        protection_decision_schema: protection_decision_schema,
        activity_context_schema: activity_context_schema,
        lifecycle_assumptions_schema: lifecycle_assumptions_schema,
        default_assumptions_schema: default_assumptions_schema
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
