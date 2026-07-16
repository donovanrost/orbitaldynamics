defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryReportFields

  def import_readiness_summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    model = Map.get(summary, "model") || Map.get(summary, :model)

    schema_contract in [nil, "operational_quality_gate_import_readiness_summary.v1"] and
      model == "artifact_only_quality_gate_import_readiness_summary"
  end

  def import_readiness_summary?(_summary), do: false

  def report_from_import_readiness_summary(%{} = summary) do
    summary = QualityGateImportReadinessSummaryEncoding.stringify_keys(summary)

    summary
    |> QualityGateImportReadinessSummaryReportFields.fields()
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
