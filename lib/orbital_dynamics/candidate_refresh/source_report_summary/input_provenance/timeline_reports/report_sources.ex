defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources do
  @moduledoc false

  alias __MODULE__.InheritedSources

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollection,
    as: TimelineFeedbackCollectionSourceReports

  def reports(refresh, :source_timeline_feedback_reports) do
    result_artifact_source_reports(
      refresh,
      &TimelineFeedbackCollectionSourceReports.reports/2
    )
  end

  def reports(refresh, source),
    do: InheritedSources.reports(refresh, source)

  defp result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(refresh, &ResultArtifactCollectionSourceReports.reports/1)
  end
end
