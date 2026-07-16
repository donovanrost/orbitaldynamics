defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryRecognition do
  @moduledoc false

  def summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    model = Map.get(summary, "model") || Map.get(summary, :model)

    schema_contract in [nil, "operational_quality_gate_summary.v1"] and
      model == "artifact_only_quality_gate_summary"
  end

  def summary?(_summary), do: false
end
