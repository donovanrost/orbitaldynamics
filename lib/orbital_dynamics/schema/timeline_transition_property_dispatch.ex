defmodule OrbitalDynamics.Schema.TimelineTransitionPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    TimelineLifecycleStateSummaryJsonSchema,
    TimelineTransitionApplicationJsonSchema
  }

  def lifecycle_summary(
        field,
        contract_name,
        contract,
        default_property,
        {
          row_schema,
          model_limits,
          count_map_schema,
          stable_id_array_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineLifecycleStateSummaryJsonSchema.property_field?/1,
      TimelineLifecycleStateSummaryJsonSchema.property_fun_from_context(
        row_schema,
        model_limits,
        count_map_schema,
        stable_id_array_schema
      ),
      default_property
    )
  end

  def application(
        field,
        contract_name,
        contract,
        default_property,
        {
          application_row_schema,
          selected_activity_schema,
          model_limits,
          timeline_capability,
          enum_count_map_schema,
          stable_id_array_schema,
          stable_id_array_map_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &TimelineTransitionApplicationJsonSchema.property_field?(&1, contract_name),
      TimelineTransitionApplicationJsonSchema.property_fun_from_context(
        contract_name: contract_name,
        application_row_schema: application_row_schema,
        selected_activity_schema: selected_activity_schema,
        model_limits: model_limits,
        timeline_capability: timeline_capability,
        enum_count_map_schema: enum_count_map_schema,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema
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
