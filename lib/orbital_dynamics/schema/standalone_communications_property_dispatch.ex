defmodule OrbitalDynamics.Schema.StandaloneCommunicationsPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    ContactAllocationReportJsonSchema,
    RelayDataPathSummaryJsonSchema,
    StationCalendarProviderJsonSchema
  }

  def station_calendar_provider(
        field,
        contract_name,
        contract,
        default_property,
        entry_schema
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &StationCalendarProviderJsonSchema.property_field?/1,
      StationCalendarProviderJsonSchema.property_fun_from_context(entry_schema: entry_schema),
      default_property
    )
  end

  def relay_data_path(
        field,
        contract_name,
        contract,
        default_property,
        {
          model_limits,
          assumptions_schema,
          row_schema,
          count_map_schema,
          stable_id_array_schema,
          stable_id_array_map_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &RelayDataPathSummaryJsonSchema.property_field?/1,
      RelayDataPathSummaryJsonSchema.property_fun_from_context(
        model_limits: model_limits,
        assumptions_schema: assumptions_schema,
        row_schema: row_schema,
        count_map_schema: count_map_schema,
        stable_id_array_schema: stable_id_array_schema,
        stable_id_array_map_schema: stable_id_array_map_schema
      ),
      default_property
    )
  end

  def contact_allocation(
        field,
        contract_name,
        contract,
        default_property,
        {
          row_schema,
          capacity_pack_group_schema,
          model_limits,
          stable_id_array_schema,
          nested_stable_id_array_map_schema,
          string_array_schema,
          trust_boundary_count_map_schema,
          contact_allocation_capability,
          enum_count_map_schema,
          count_map_schema,
          non_negative_number_map_schema
        }
      ) do
    dispatch(
      field,
      contract_name,
      contract,
      &ContactAllocationReportJsonSchema.property_field?/1,
      ContactAllocationReportJsonSchema.property_fun_from_context(
        row_schema: row_schema,
        capacity_pack_group_schema: capacity_pack_group_schema,
        model_limits: model_limits,
        stable_id_array_schema: stable_id_array_schema,
        nested_stable_id_array_map_schema: nested_stable_id_array_map_schema,
        string_array_schema: string_array_schema,
        trust_boundary_count_map_schema: trust_boundary_count_map_schema,
        contact_allocation_capability: contact_allocation_capability,
        enum_count_map_schema: enum_count_map_schema,
        count_map_schema: count_map_schema,
        non_negative_number_map_schema: non_negative_number_map_schema
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
