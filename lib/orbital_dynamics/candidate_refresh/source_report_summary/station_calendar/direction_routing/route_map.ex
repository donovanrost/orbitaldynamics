defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.Entry
  alias __MODULE__.Inputs

  def direction_routing(station_direction_fields, provider_contention_fields) do
    station_direction_fields
    |> Inputs.from_fields(provider_contention_fields)
    |> build_direction_routing()
  end

  defp build_direction_routing(maps) when is_map(maps) do
    maps
    |> route_directions()
    |> Map.new(fn direction ->
      {direction, Entry.route_entry(direction, maps)}
    end)
    |> non_empty_map()
  end

  defp route_directions(maps) do
    maps
    |> Map.values()
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
