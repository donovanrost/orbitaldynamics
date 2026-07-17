defmodule OrbitalDynamics.Schema.ContactAllocationSummaryPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema
  alias OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema
  alias OrbitalDynamics.Schema.ContactAllocationReservationConflictSummaryJsonSchema
  alias OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema
  alias OrbitalDynamics.Schema.ContactAllocationSummaryJsonSchema

  def property(field, contract_name, contract, deps) do
    contracts = Keyword.fetch!(deps, :contracts)

    {property_field?, property} =
      property_dispatch(contract_name, contracts, deps)

    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.summary do
    {
      &ContactAllocationSummaryJsonSchema.property_field?/1,
      ContactAllocationSummaryJsonSchema.property_fun_from_context(
        common_context(contract_name, :summary, deps) ++
          [capacity_pack_group_schema: Keyword.fetch!(deps, :capacity_pack_group_schema)]
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.reservation_conflict_summary do
    {
      &ContactAllocationReservationConflictSummaryJsonSchema.property_field?/1,
      ContactAllocationReservationConflictSummaryJsonSchema.property_fun_from_context(
        common_context(contract_name, :reservation_conflict_summary, deps)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.station_pressure_summary do
    {
      &ContactAllocationStationPressureSummaryJsonSchema.property_field?/1,
      ContactAllocationStationPressureSummaryJsonSchema.property_fun_from_context(
        common_context(contract_name, :station_pressure_summary, deps)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.capacity_pack_summary do
    {
      &ContactAllocationCapacityPackSummaryJsonSchema.property_field?/1,
      ContactAllocationCapacityPackSummaryJsonSchema.property_fun_from_context(
        common_context(contract_name, :capacity_pack_summary, deps) ++
          [capacity_pack_group_schema: Keyword.fetch!(deps, :capacity_pack_group_schema)]
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.provider_reservation_request_summary do
    {
      &ContactAllocationProviderReservationRequestSummaryJsonSchema.property_field?/1,
      ContactAllocationProviderReservationRequestSummaryJsonSchema.property_fun_from_context(
        common_context(contract_name, :provider_reservation_request_summary, deps)
      )
    }
  end

  defp common_context(contract_name, assumptions_key, deps) do
    [
      schema_contract: contract_name,
      stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
      model_limits: Keyword.fetch!(deps, :model_limits),
      assumptions_schema:
        deps
        |> Keyword.fetch!(:assumptions)
        |> Map.fetch!(assumptions_key),
      row_schema: Keyword.fetch!(deps, :row_schema)
    ]
  end
end
