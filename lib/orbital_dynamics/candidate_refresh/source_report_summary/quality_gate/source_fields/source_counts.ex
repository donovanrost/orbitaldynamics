defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.SourceFields.SourceCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def source_summary_model_counts(reports) do
    reports
    |> Enum.map(&source_summary_model/1)
    |> count_source_report_values()
  end

  def source_summary_schema_contract_counts(reports) do
    reports
    |> Enum.map(&source_summary_schema_contract/1)
    |> count_source_report_values()
  end

  def source_artifact_type_counts(reports) do
    reports
    |> Enum.map(&source_artifact_type/1)
    |> count_source_report_values()
  end

  def source_readiness_report_count(reports) do
    reports
    |> Enum.map(&Map.get(&1, "source_readiness_report_id"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> length()
  end

  defp source_summary_model(report),
    do: Map.get(report, "source_summary_model") || Map.get(report, "model")

  defp source_summary_schema_contract(report),
    do: Map.get(report, "source_summary_schema_contract") || Map.get(report, "schema_contract")

  defp source_artifact_type(report), do: Map.get(report, "source_artifact_type")
end
