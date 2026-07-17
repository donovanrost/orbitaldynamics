defmodule OrbitalDynamics.Schema.OperationalReadinessGateSummaryPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalExecutionBoundarySummaryJsonSchema
  alias OrbitalDynamics.Schema.OperationalImportEligibilitySummaryJsonSchema
  alias OrbitalDynamics.Schema.OperationalReadinessGateSummaryJsonSchema

  @execution_boundary_summary "operational_execution_boundary_summary.v1"
  @import_eligibility_summary "operational_import_eligibility_summary.v1"
  @readiness_gate_summary "operational_readiness_gate_summary.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [
             @import_eligibility_summary,
             @readiness_gate_summary,
             @execution_boundary_summary
           ] do
    {property_field?, property} = property_dispatch(contract_name, deps)

    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp property_dispatch(@import_eligibility_summary, deps) do
    {
      &OperationalImportEligibilitySummaryJsonSchema.property_field?/1,
      OperationalImportEligibilitySummaryJsonSchema.property_fun_from_context(
        capability: Keyword.fetch!(deps, :capability).(),
        gate_schema: Keyword.fetch!(deps, :gate_schema).(),
        model_limits: Keyword.fetch!(deps, :import_eligibility_model_limits).()
      )
    }
  end

  defp property_dispatch(@readiness_gate_summary, deps) do
    {
      &OperationalReadinessGateSummaryJsonSchema.property_field?/1,
      OperationalReadinessGateSummaryJsonSchema.property_fun_from_context(
        capability: Keyword.fetch!(deps, :capability).(),
        gate_schema: Keyword.fetch!(deps, :gate_schema).(),
        model_limits: Keyword.fetch!(deps, :readiness_gate_model_limits).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(@execution_boundary_summary, deps) do
    {
      &OperationalExecutionBoundarySummaryJsonSchema.property_field?/1,
      OperationalExecutionBoundarySummaryJsonSchema.property_fun_from_context(
        capability: Keyword.fetch!(deps, :capability).(),
        gate_schema: Keyword.fetch!(deps, :gate_schema).(),
        model_limits: Keyword.fetch!(deps, :execution_boundary_model_limits).(),
        string_array_schema: Keyword.fetch!(deps, :string_array_schema).()
      )
    }
  end
end
