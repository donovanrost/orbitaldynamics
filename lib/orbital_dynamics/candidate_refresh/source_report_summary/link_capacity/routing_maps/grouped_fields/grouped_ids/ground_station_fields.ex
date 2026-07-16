defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.RoutingMaps.GroupedFields.GroupedIds.GroundStationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.GroupedIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    %{
      "contact_ids_by_ground_station" =>
        string_list_map_merge(reports, &GroupedIds.contact_ids_by_ground_station/1),
      "source_window_ids_by_ground_station" =>
        string_list_map_merge(reports, &GroupedIds.source_window_ids_by_ground_station/1),
      "station_calendar_entry_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          &GroupedIds.station_calendar_entry_ids_by_ground_station/1
        ),
      "station_calendar_provider_entry_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          &GroupedIds.station_calendar_provider_entry_ids_by_ground_station/1
        )
    }
  end

  defp string_list_map_merge(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end
end
