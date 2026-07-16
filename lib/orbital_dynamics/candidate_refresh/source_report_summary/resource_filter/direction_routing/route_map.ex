defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.RouteMap do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.ValueMaps,
    as: ResourceValueMaps

  alias __MODULE__.Entry
  alias __MODULE__.Keys

  def direction_keys(direction_counts, candidate_ids_by_direction) do
    Keys.direction_keys(direction_counts, candidate_ids_by_direction)
  end

  def entries(direction_counts, candidate_ids_by_direction) do
    direction_counts = direction_counts || %{}

    candidate_ids_by_direction =
      ResourceValueMaps.map_value_lists(candidate_ids_by_direction) || %{}

    direction_counts
    |> Keys.entry_keys(candidate_ids_by_direction)
    |> route_entries(direction_counts, candidate_ids_by_direction)
    |> ResourceValueMaps.non_empty_map()
  end

  defp route_entries(directions, direction_counts, candidate_ids_by_direction) do
    Map.new(directions, fn direction ->
      {direction, Entry.for_direction(direction, direction_counts, candidate_ids_by_direction)}
    end)
  end
end
