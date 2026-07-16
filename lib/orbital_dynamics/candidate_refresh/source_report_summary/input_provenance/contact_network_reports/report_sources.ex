defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.ReportSources do
  @moduledoc false

  alias __MODULE__.CollectionFunctions
  alias OrbitalDynamics.CandidateRefresh.ResultArtifactTrustBoundary

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection,
    as: ResultArtifactCollectionSourceReports

  @sources [
    :source_provider_counteroffer_reports,
    :source_station_calendar_reports,
    :source_station_reservation_reports,
    :source_contact_intents,
    :source_contact_filter_reports,
    :source_link_capacity_reports,
    :source_contact_allocation_reports,
    :source_contact_contention_reports,
    :source_contact_contention_resolution_reports
  ]

  def source?(source), do: source in @sources

  def reports(refresh, source) do
    inherited_result_artifact_source_reports(refresh, CollectionFunctions.function_for(source))
  end

  defp inherited_result_artifact_source_reports(refresh, reports_fun) do
    reports_fun.(
      refresh,
      &ResultArtifactCollectionSourceReports.reports/1,
      &ResultArtifactTrustBoundary.inherit/2
    )
  end
end
