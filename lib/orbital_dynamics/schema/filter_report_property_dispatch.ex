defmodule OrbitalDynamics.Schema.FilterReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactFilterReportJsonSchema
  alias OrbitalDynamics.Schema.ResourceFilterReportJsonSchema

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
       when contract_name == contracts.contact do
    {
      &ContactFilterReportJsonSchema.property_field?/1,
      ContactFilterReportJsonSchema.property_fun_from_context(
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        trust_boundary_count_map_schema: Keyword.fetch!(deps, :trust_boundary_count_map_schema),
        model_limits: Keyword.fetch!(deps, :contact_model_limits),
        assumptions_schema: Keyword.fetch!(deps, :contact_assumptions_schema),
        suppressed_candidate_schema: Keyword.fetch!(deps, :suppressed_candidate_schema)
      )
    }
  end

  defp property_dispatch(contract_name, contracts, deps)
       when contract_name == contracts.resource do
    {
      &ResourceFilterReportJsonSchema.property_field?/1,
      ResourceFilterReportJsonSchema.property_fun_from_context(
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern),
        model_limits: Keyword.fetch!(deps, :resource_model_limits),
        assumptions_schema: Keyword.fetch!(deps, :resource_assumptions_schema),
        suppressed_candidate_schema: Keyword.fetch!(deps, :suppressed_candidate_schema)
      )
    }
  end
end
