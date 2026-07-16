defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.GroupedIds.GroupedMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows,
    only: [
      explicit_string_list_map: 2,
      grouped_source_report_ids: 1,
      rows_for_summary: 1,
      string_list_map_or_summary: 3
    ]

  def grouped_ids_by_ground_station_summary(report, summary_field, pair_fun, fallback_field) do
    string_list_map_or_summary(report, summary_field, fn report ->
      grouped_ids_by_ground_station(report, pair_fun, fallback_field)
    end)
  end

  def grouped_ids_by_ground_station(report, pair_fun, fallback_field) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(pair_fun)
    |> grouped_source_report_ids()
    |> case do
      nil -> explicit_string_list_map(report, fallback_field)
      ids_by_ground_station -> ids_by_ground_station
    end
  end
end
