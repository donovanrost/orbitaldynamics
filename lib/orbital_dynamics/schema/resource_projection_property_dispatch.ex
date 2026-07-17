defmodule OrbitalDynamics.Schema.ResourceProjectionPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ResourceProjectionFlowSummaryJsonSchema
  alias OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema

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
      &ResourceProjectionReportJsonSchema.property_field?/1,
      ResourceProjectionReportJsonSchema.property_fun_from_context(
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        models: Keyword.fetch!(deps, :models),
        model_limits: Keyword.fetch!(deps, :model_limits),
        assumptions_schema: Keyword.fetch!(deps, :assumptions_schema),
        resource_projection_row_schema: Keyword.fetch!(deps, :projection_row_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.flow_summary do
    {
      &ResourceProjectionFlowSummaryJsonSchema.property_field?/1,
      ResourceProjectionFlowSummaryJsonSchema.property_fun_from_context(
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        model_limits: Keyword.fetch!(deps, :model_limits),
        assumptions_schema: Keyword.fetch!(deps, :assumptions_schema),
        activity_resource_flow_row_schema: Keyword.fetch!(deps, :flow_row_schema)
      )
    }
  end
end
