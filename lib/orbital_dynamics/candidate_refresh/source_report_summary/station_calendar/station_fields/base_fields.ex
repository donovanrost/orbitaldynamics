defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &StationCalendarReport.row_count/1),
      "affected_contact_count" =>
        sum_report_count(reports, &StationCalendarReport.affected_contact_count/1),
      "affected_contact_ids" => StationCalendarReport.affected_contact_ids(reports),
      "affected_station_calendar_entry_ids" =>
        StationCalendarReport.affected_station_calendar_entry_ids(reports),
      "affected_station_reservation_ids" =>
        StationCalendarReport.affected_station_reservation_ids(reports),
      "reserved_by_counts" => count_map(reports, &StationCalendarReport.reserved_by_counts/1),
      "station_calendar_status_counts" =>
        count_map(reports, &StationCalendarReport.status_counts/1),
      "affected_contact_ground_station_counts" =>
        count_map(reports, &StationCalendarReport.affected_contact_ground_station_counts/1),
      "affected_contact_availability_counts" =>
        count_map(reports, &StationCalendarReport.affected_contact_availability_counts/1)
    }
  end

  defp count_map(reports, fun) do
    reports
    |> Enum.map(fun)
    |> merge_count_maps()
  end
end
