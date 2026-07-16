defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Entry do
  @moduledoc false

  alias __MODULE__.ProviderContentionFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  def route_entry(direction, maps) do
    %{
      "contact_count" => get(maps, :direction_counts, direction),
      "contact_ids" => get(maps, :contact_ids_by_direction, direction, []),
      "station_calendar_entry_ids" =>
        get(maps, :station_calendar_entry_ids_by_direction, direction, []),
      "station_reservation_ids" =>
        get(maps, :station_reservation_ids_by_direction, direction, []),
      "station_capacity_fractions" =>
        get(maps, :station_capacity_fractions_by_direction, direction, [])
    }
    |> Map.merge(ProviderContentionFields.fields(direction, maps))
    |> compact_map()
  end

  defp get(maps, key, direction, default \\ nil) do
    maps
    |> Map.fetch!(key)
    |> Map.get(direction, default)
  end
end
