defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication.SourceReportPaths.ResultArtifactPaths do
  @moduledoc false

  alias __MODULE__.ReportPath

  def source_report?(path, :all), do: ReportPath.source_report?(path)

  def source_report?(path, report_keys) when is_list(report_keys) do
    case ReportPath.report_key(path) do
      nil -> false
      report_key -> report_key in report_keys
    end
  end

  def source_report?(_path, _report_keys), do: false
end
