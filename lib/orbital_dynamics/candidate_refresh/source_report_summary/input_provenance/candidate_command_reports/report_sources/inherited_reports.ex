defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.CandidateCommandReports.ReportSources.InheritedReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  def reports(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end
end
