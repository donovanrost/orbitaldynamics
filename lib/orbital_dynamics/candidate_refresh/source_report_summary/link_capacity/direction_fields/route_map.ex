defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.RouteMap do
  @moduledoc false

  alias __MODULE__.Entry
  alias __MODULE__.InputMaps

  def directions(inputs) do
    inputs
    |> InputMaps.sorted_directions()
    |> case do
      [] -> nil
      values -> values
    end
  end

  def direction_routing(inputs) do
    inputs = InputMaps.normalized(inputs)

    inputs
    |> InputMaps.sorted_directions()
    |> Map.new(fn direction ->
      {direction, Entry.for_direction(direction, inputs)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
