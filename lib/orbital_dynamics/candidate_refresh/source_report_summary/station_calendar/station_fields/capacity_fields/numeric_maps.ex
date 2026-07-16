defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.StationFields.CapacityFields.NumericMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_numeric_list_maps: 1
    ]

  def fields(reports) do
    %{
      "station_capacity_fractions_by_status" =>
        reports
        |> Enum.map(&StationCalendarReport.capacity_fractions_by_status/1)
        |> merge_numeric_list_maps(),
      "station_capacity_fractions_by_ground_station" =>
        reports
        |> Enum.map(&StationCalendarReport.capacity_fractions_by_ground_station/1)
        |> merge_numeric_list_maps(),
      "station_capacity_fractions_by_availability" =>
        reports
        |> Enum.map(&StationCalendarReport.capacity_fractions_by_availability/1)
        |> merge_numeric_list_maps()
    }
  end
end
