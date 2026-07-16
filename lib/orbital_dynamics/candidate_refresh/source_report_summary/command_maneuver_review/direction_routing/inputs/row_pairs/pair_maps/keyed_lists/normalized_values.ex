defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.PairMaps.KeyedLists.NormalizedValues do
  @moduledoc false

  def sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map
end
