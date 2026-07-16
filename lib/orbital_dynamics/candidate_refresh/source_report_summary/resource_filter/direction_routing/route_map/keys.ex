defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.RouteMap.Keys do
  @moduledoc false

  alias __MODULE__.KeyLists

  def direction_keys(direction_counts, candidate_ids_by_direction) do
    direction_counts
    |> KeyLists.combined(candidate_ids_by_direction)
    |> KeyLists.non_empty_sorted()
  end

  def entry_keys(direction_counts, candidate_ids_by_direction) do
    direction_counts
    |> KeyLists.combined(candidate_ids_by_direction)
    |> KeyLists.sorted()
  end
end
