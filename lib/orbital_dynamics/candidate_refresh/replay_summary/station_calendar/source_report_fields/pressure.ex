defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_pressure_fields(summary) do
    %{
      "source_report_station_calendar_branch_local_station_calendar_pressure" =>
        Map.get(summary, "branch_local_station_calendar_pressure"),
      "source_report_station_calendar_branch_local_affected_contact_pressure" =>
        Map.get(summary, "branch_local_affected_contact_pressure"),
      "source_report_station_calendar_branch_local_provider_contention_pressure" =>
        Map.get(summary, "branch_local_provider_contention_pressure"),
      "source_report_station_calendar_branch_local_station_availability_pressure" =>
        Map.get(summary, "branch_local_station_availability_pressure")
    }
  end
end
