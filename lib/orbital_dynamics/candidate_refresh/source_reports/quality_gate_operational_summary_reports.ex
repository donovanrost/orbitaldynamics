defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperationalSummaryReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperationalSummaryReportFields

  def unavailable_resource_summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    model = Map.get(summary, "model") || Map.get(summary, :model)

    schema_contract in [nil, "operational_quality_gate_unavailable_resource_summary.v1"] and
      model == "artifact_only_quality_gate_unavailable_resource_summary"
  end

  def unavailable_resource_summary?(_summary), do: false

  def operator_training_summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    model = Map.get(summary, "model") || Map.get(summary, :model)

    schema_contract in [nil, "operational_quality_gate_operator_training_summary.v1"] and
      model == "artifact_only_quality_gate_operator_training_summary"
  end

  def operator_training_summary?(_summary), do: false

  def report_from_unavailable_resource_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> QualityGateOperationalSummaryReportFields.unavailable_resource_fields()
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  def report_from_operator_training_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> QualityGateOperationalSummaryReportFields.operator_training_fields()
    |> maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp stringify_keys(value), do: QualityGateEncoding.stringify_keys(value)
end
