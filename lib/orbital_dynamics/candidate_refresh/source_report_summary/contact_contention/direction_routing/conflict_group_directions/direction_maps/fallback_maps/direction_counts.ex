defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.DirectionMaps.FallbackMaps.DirectionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections.ContactPairs

  def direction_counts(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {ContactPairs.normalize_direction(direction), NumericValue.value(count)} do
        {nil, _count} ->
          acc

        {_direction, nil} ->
          acc

        {direction, count} when direction not in ["mixed", "contact"] ->
          direction = StableIds.stable_id_or_nil(direction)
          count = trunc(count)

          if direction && count > 0,
            do: Map.update(acc, direction, count, &(&1 + count)),
            else: acc

        {_direction, _count} ->
          acc
      end
    end)
    |> non_empty_map()
  end

  def direction_counts(_counts), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
