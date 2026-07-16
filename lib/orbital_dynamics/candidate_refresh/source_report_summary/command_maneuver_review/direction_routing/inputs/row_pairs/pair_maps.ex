defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.PairMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.DirectionValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias __MODULE__.KeyedLists

  def direction_counts(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {DirectionValues.normalize(direction), NumericValue.value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> non_empty_map()
  end

  def direction_counts(_counts), do: nil

  defdelegate value_lists(value_map), to: KeyedLists
  defdelegate ids_from_pairs(pairs), to: KeyedLists
  defdelegate counts_from_pairs(pairs), to: KeyedLists

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
