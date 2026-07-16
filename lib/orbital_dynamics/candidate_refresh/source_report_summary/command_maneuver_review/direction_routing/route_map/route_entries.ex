defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.RouteMap.RouteEntries do
  @moduledoc false

  alias __MODULE__.Inputs
  alias __MODULE__.RouteFields

  def build(direction_counts, activity_ids_by_direction, window_ids_by_direction) do
    direction_counts
    |> Inputs.build(activity_ids_by_direction, window_ids_by_direction)
    |> direction_routing_fields()
  end

  defp direction_routing_fields(inputs) do
    inputs
    |> Inputs.routing_directions()
    |> Map.new(fn direction ->
      {direction, RouteFields.fields(direction, inputs)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
