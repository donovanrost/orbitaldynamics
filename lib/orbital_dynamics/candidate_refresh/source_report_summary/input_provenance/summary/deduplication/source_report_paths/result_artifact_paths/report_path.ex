defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportPaths.ResultArtifactPaths.ReportPath do
  @moduledoc false

  def source_report?("mission_state.source_result_artifact." <> rest) do
    not indexed_source_report_path?(rest)
  end

  def source_report?("mission_state.result_artifact." <> rest) do
    not indexed_source_report_path?(rest)
  end

  def source_report?(_path), do: false

  def report_key("mission_state.source_result_artifact." <> report_key),
    do: strip_report_index(report_key)

  def report_key("mission_state.result_artifact." <> report_key),
    do: strip_report_index(report_key)

  def report_key(_path), do: nil

  defp strip_report_index(report_key) when is_binary(report_key) do
    report_key
    |> String.replace(~r/\[\d+\]$/, "")
    |> String.split(".")
    |> List.first()
  end

  defp indexed_source_report_path?(path) when is_binary(path),
    do: Regex.match?(~r/\[\d+\]$/, path)
end
