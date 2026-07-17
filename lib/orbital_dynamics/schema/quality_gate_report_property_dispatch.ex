defmodule OrbitalDynamics.Schema.QualityGateReportPropertyDispatch do
  @moduledoc false

  alias OrbitalDynamics.Schema.OperationalQualityGateSummaryJsonSchema
  alias OrbitalDynamics.Schema.QualityGateReportJsonSchema

  @operational_summary "operational_quality_gate_summary.v1"
  @report "quality_gate_report.v1"

  def property(field, contract_name, contract, deps)
      when contract_name in [@operational_summary, @report] do
    {property_field?, property} = property_dispatch(contract_name, deps)

    if property_field?.(field) do
      property.(field)
    else
      Keyword.fetch!(deps, :default_property).(field, contract_name, contract)
    end
  end

  defp property_dispatch(@operational_summary, deps) do
    {
      &OperationalQualityGateSummaryJsonSchema.property_field?/1,
      OperationalQualityGateSummaryJsonSchema.property_fun_from_context(
        capability: Keyword.fetch!(deps, :capability).(),
        model_limits: Keyword.fetch!(deps, :operational_summary_model_limits).(),
        row_schema: Keyword.fetch!(deps, :row_schema).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end

  defp property_dispatch(@report, deps) do
    {
      &QualityGateReportJsonSchema.property_field?/1,
      QualityGateReportJsonSchema.property_fun_from_context(
        capability: Keyword.fetch!(deps, :capability).(),
        model_limits: Keyword.fetch!(deps, :report_model_limits).(),
        row_schema: Keyword.fetch!(deps, :row_schema).(),
        stable_id_pattern: Keyword.fetch!(deps, :stable_id_pattern)
      )
    }
  end
end
