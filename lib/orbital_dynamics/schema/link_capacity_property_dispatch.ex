defmodule OrbitalDynamics.Schema.LinkCapacityPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.LinkCapacityReportJsonSchema
  alias OrbitalDynamics.Schema.LinkCapacitySummaryJsonSchema

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
       when contract_name == contracts.report do
    {
      &LinkCapacityReportJsonSchema.property_field?/1,
      LinkCapacityReportJsonSchema.property_fun_from_context(
        row_schema: Keyword.fetch!(deps, :row_schema),
        model_limits: Keyword.fetch!(deps, :model_limits),
        assumptions_schema: Keyword.fetch!(deps, :report_assumptions_schema),
        stable_id_array_schema: Keyword.fetch!(deps, :stable_id_array_schema),
        string_array_schema: Keyword.fetch!(deps, :string_array_schema),
        count_map_schema: Keyword.fetch!(deps, :count_map_schema),
        number_array_schema: Keyword.fetch!(deps, :number_array_schema),
        actual_data_rate_throughput_derivations_schema:
          Keyword.fetch!(deps, :actual_data_rate_throughput_derivations_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.summary do
    {
      &LinkCapacitySummaryJsonSchema.property_field?/1,
      LinkCapacitySummaryJsonSchema.property_fun_from_context(
        model_limits: Keyword.fetch!(deps, :model_limits),
        assumptions_schema: Keyword.fetch!(deps, :summary_assumptions_schema),
        count_map_schema: Keyword.fetch!(deps, :count_map_schema),
        stable_id_array_schema: Keyword.fetch!(deps, :stable_id_array_schema),
        string_array_schema: Keyword.fetch!(deps, :string_array_schema),
        number_array_schema: Keyword.fetch!(deps, :number_array_schema),
        numeric_map_schema: Keyword.fetch!(deps, :numeric_map_schema),
        stable_id_array_map_schema: Keyword.fetch!(deps, :stable_id_array_map_schema)
      )
    }
  end
end
