defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryFields

  def schema_validation_summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    model = Map.get(summary, "model") || Map.get(summary, :model)

    schema_contract in [nil, "operational_quality_gate_schema_validation_summary.v1"] and
      model == "artifact_only_quality_gate_schema_validation_summary"
  end

  def schema_validation_summary?(_summary), do: false

  def report_from_schema_validation_summary(%{} = summary) do
    QualityGateSchemaValidationSummaryFields.report_from_schema_validation_summary(summary)
  end
end
