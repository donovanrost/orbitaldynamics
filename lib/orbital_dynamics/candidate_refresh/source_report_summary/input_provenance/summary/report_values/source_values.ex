defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.ReportValues.SourceValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.SourceReports
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.Deduplication

  def summary(refresh, source, summarizer) do
    refresh
    |> SourceReports.reports(source)
    |> summarizer.()
  end

  def deduplicated_summary(refresh, source, summarizer) do
    refresh
    |> SourceReports.reports(source)
    |> Deduplication.deduplicate_shadowed_result_artifact_sources()
    |> summarizer.()
  end
end
