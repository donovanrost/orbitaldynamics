defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.DirectionKeys.KeyValues do
  @moduledoc false

  alias __MODULE__.NormalizedValues

  def from_maps(resource_pressure_direction_counts, resource_pressure_activity_ids_by_direction) do
    [
      map_keys(resource_pressure_direction_counts),
      map_keys(resource_pressure_activity_ids_by_direction)
    ]
    |> List.flatten()
    |> NormalizedValues.non_empty_sorted()
  end

  defp map_keys(%{} = map), do: Map.keys(map)
  defp map_keys(_map), do: []
end
