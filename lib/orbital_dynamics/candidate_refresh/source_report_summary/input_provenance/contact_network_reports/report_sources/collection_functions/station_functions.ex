defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.ReportSources.CollectionFunctions.StationFunctions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer,
    as: ProviderCounterofferSourceReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationSchedule,
    as: StationScheduleSourceReports

  def function_for(:source_provider_counteroffer_reports),
    do: &ProviderCounterofferSourceReports.reports/3

  def function_for(:source_station_calendar_reports),
    do: &StationScheduleSourceReports.station_calendar_reports/3

  def function_for(:source_station_reservation_reports),
    do: &StationScheduleSourceReports.station_reservation_reports/3
end
