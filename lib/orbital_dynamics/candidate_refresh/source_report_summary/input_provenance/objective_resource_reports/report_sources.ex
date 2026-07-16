defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.ReportSources do
  @moduledoc false

  alias __MODULE__.CollectionFunctions
  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  @sources [
    :source_constraint_reports,
    :source_objective_satisfaction_reports,
    :source_objective_tradeoff_reports,
    :source_score_term_reports,
    :source_resource_projection_reports,
    :source_resource_filter_reports
  ]

  def source?(source), do: source in @sources

  def reports(refresh, source) do
    inherited(refresh, CollectionFunctions.function_for(source))
  end

  defp inherited(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end
end
