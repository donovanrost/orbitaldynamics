defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.RouteMap.Keys.KeyLists do
  @moduledoc false

  def combined(direction_counts, candidate_ids_by_direction) do
    [
      map_keys(direction_counts),
      map_keys(candidate_ids_by_direction)
    ]
    |> List.flatten()
  end

  def sorted(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def non_empty_sorted(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> sorted()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp map_keys(%{} = map), do: Map.keys(map)
  defp map_keys(_map), do: []
end
