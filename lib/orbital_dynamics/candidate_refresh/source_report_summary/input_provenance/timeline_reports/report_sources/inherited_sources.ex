defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.TimelineReports.ReportSources.InheritedSources do
  @moduledoc false

  alias __MODULE__.CollectionFunctions
  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  def reports(refresh, source) do
    refresh
    |> inherited_result_artifact_source_reports(CollectionFunctions.function_for(source))
  end

  defp inherited_result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end
end
