defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields do
  @moduledoc false

  alias __MODULE__.GroupedIdMaps
  alias __MODULE__.RouteMap
  alias __MODULE__.RouteInputs
  alias __MODULE__.ThroughputMaps

  def fields(reports) do
    grouped_ids = GroupedIdMaps.fields(reports)
    throughput_maps = ThroughputMaps.from_reports(reports)
    route_inputs = RouteInputs.values(grouped_ids, throughput_maps)

    %{
      "direction_counts" => grouped_ids.direction_counts,
      "directions" => RouteMap.directions(route_inputs),
      "contact_ids_by_direction" => grouped_ids.contact_ids_by_direction,
      "source_window_ids_by_direction" => grouped_ids.source_window_ids_by_direction,
      "station_calendar_entry_ids_by_direction" =>
        grouped_ids.station_calendar_entry_ids_by_direction,
      "station_calendar_provider_entry_ids_by_direction" =>
        grouped_ids.station_calendar_provider_entry_ids_by_direction,
      "direction_routing" => RouteMap.direction_routing(route_inputs)
    }
    |> Map.merge(ThroughputMaps.fields(throughput_maps))
  end
end
