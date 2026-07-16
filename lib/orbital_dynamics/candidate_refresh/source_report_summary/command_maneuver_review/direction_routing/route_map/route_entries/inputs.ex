defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.RouteMap.RouteEntries.Inputs do
  @moduledoc false

  def build(direction_counts, activity_ids_by_direction, window_ids_by_direction) do
    %{
      direction_counts: empty_map_if_nil(direction_counts),
      activity_ids_by_direction: empty_map_if_nil(activity_ids_by_direction),
      window_ids_by_direction: empty_map_if_nil(window_ids_by_direction)
    }
  end

  def routing_directions(%{
        direction_counts: direction_counts,
        activity_ids_by_direction: activity_ids_by_direction,
        window_ids_by_direction: window_ids_by_direction
      }) do
    [
      Map.keys(direction_counts),
      Map.keys(activity_ids_by_direction),
      Map.keys(window_ids_by_direction)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
