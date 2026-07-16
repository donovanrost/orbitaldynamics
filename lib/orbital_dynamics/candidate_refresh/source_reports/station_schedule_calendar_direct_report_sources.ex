defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationScheduleCalendarDirectReportSources do
  @moduledoc false

  def station_calendar_sources(refresh) do
    [
      {"accepted_planning_state.source_station_calendar_report",
       get_in(refresh, ["accepted_planning_state", "source_station_calendar_report"])},
      {"accepted_planning_state.station_calendar_report",
       get_in(refresh, ["accepted_planning_state", "station_calendar_report"])},
      {"accepted_planning_state.source_station_calendar_precedence_summary",
       get_in(refresh, ["accepted_planning_state", "source_station_calendar_precedence_summary"])},
      {"accepted_planning_state.station_calendar_precedence_summary",
       get_in(refresh, ["accepted_planning_state", "station_calendar_precedence_summary"])},
      {"mission_state.source_station_calendar_report",
       get_in(refresh, ["mission_state", "source_station_calendar_report"])},
      {"mission_state.station_calendar_report",
       get_in(refresh, ["mission_state", "station_calendar_report"])},
      {"mission_state.source_station_calendar_precedence_summary",
       get_in(refresh, ["mission_state", "source_station_calendar_precedence_summary"])},
      {"mission_state.station_calendar_precedence_summary",
       get_in(refresh, ["mission_state", "station_calendar_precedence_summary"])},
      {"source_station_calendar_report", Map.get(refresh, "source_station_calendar_report")},
      {"station_calendar_report", Map.get(refresh, "station_calendar_report")},
      {"source_station_calendar_precedence_summary",
       Map.get(refresh, "source_station_calendar_precedence_summary")},
      {"station_calendar_precedence_summary",
       Map.get(refresh, "station_calendar_precedence_summary")}
    ]
  end
end
