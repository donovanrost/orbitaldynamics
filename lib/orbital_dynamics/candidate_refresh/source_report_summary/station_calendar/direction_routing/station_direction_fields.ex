defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.StationDirectionFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_numeric_list_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    %{
      "direction_counts" =>
        reports
        |> Enum.map(&StationCalendarReport.direction_counts/1)
        |> merge_count_maps(),
      "contact_ids_by_direction" =>
        reports
        |> Enum.map(&StationCalendarReport.contact_ids_by_direction/1)
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_direction" =>
        reports
        |> Enum.map(&StationCalendarReport.entry_ids_by_direction/1)
        |> merge_string_list_maps(),
      "station_reservation_ids_by_direction" =>
        reports
        |> Enum.map(&StationCalendarReport.reservation_ids_by_direction/1)
        |> merge_string_list_maps(),
      "station_capacity_fractions_by_direction" =>
        reports
        |> Enum.map(&StationCalendarReport.capacity_fractions_by_direction/1)
        |> merge_numeric_list_maps()
    }
  end
end
