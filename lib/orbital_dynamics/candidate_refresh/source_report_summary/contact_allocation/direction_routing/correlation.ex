defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.DirectionRouting.Correlation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report.Rows.RowValues.Normalization
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def direction_counts(%{} = counts) do
    Enum.reduce(counts, %{}, fn {direction, count}, normalized ->
      direction = canonical_direction(direction)

      if direction && is_integer(count) && count > 0,
        do: Map.update(normalized, direction, count, &(&1 + count)),
        else: normalized
    end)
  end

  def direction_counts(_counts), do: %{}

  def contact_ids_by_direction(direction_counts, %{} = contact_ids_by_direction) do
    normalized_ids =
      Enum.reduce(contact_ids_by_direction, %{}, fn {direction, contact_ids}, normalized ->
        direction = canonical_direction(direction)

        contact_ids =
          contact_ids
          |> list_or_empty()
          |> Enum.map(&StableIds.stable_id_or_nil/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        if direction && contact_ids != [] do
          Map.update(normalized, direction, contact_ids, fn existing ->
            existing |> Kernel.++(contact_ids) |> Enum.uniq() |> Enum.sort()
          end)
        else
          normalized
        end
      end)

    direction_counts
    |> direction_counts()
    |> Enum.reduce(%{}, fn {direction, count}, correlated ->
      case Map.get(normalized_ids, direction, []) do
        [] ->
          correlated

        contact_ids when length(contact_ids) <= count ->
          Map.put(correlated, direction, contact_ids)

        _contact_ids ->
          correlated
      end
    end)
    |> non_empty_map()
  end

  def contact_ids_by_direction(_direction_counts, _contact_ids_by_direction), do: nil

  defp canonical_direction(direction) do
    direction
    |> Normalization.normalize_direction()
    |> StableIds.stable_id_or_nil()
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
