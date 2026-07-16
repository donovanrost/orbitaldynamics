defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.RouteMap.InputMaps do
  @moduledoc false

  def normalized(maps), do: Enum.map(maps, &empty_map_if_nil/1)

  def sorted_directions(maps) do
    maps
    |> normalized()
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
