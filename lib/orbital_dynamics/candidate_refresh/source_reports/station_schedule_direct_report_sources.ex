defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleDirectReportSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleCalendarDirectReportSources

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleReservationDirectReportSources

  def station_calendar_sources(refresh) do
    StationScheduleCalendarDirectReportSources.station_calendar_sources(refresh)
  end

  def station_reservation_sources(refresh) do
    StationScheduleReservationDirectReportSources.station_reservation_sources(refresh)
  end
end
