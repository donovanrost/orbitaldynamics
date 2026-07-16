defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendar
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservation
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleDirectReportSources

  def station_calendar_reports(refresh) do
    refresh
    |> StationScheduleDirectReportSources.station_calendar_sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      StationCalendar.entries(path, report_or_reports)
    end)
  end

  def station_reservation_reports(refresh) do
    refresh
    |> StationScheduleDirectReportSources.station_reservation_sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      StationReservation.entries(path, report_or_reports)
    end)
  end
end
