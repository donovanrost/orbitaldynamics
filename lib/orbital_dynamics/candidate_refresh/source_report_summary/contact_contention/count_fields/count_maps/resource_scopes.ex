defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.ResourceScopes do
  @moduledoc false

  @canonical_scopes ["ground_station", "spacecraft"]

  def correlated_counts(conflict_group_count, counts)
      when is_number(conflict_group_count) and conflict_group_count > 0 and is_map(counts) do
    correlated =
      Enum.reduce(@canonical_scopes, %{}, fn scope, acc ->
        case Map.get(counts, scope) do
          count when is_integer(count) and count > 0 -> Map.put(acc, scope, count)
          _count -> acc
        end
      end)

    if Enum.sum(Map.values(correlated)) <= conflict_group_count,
      do: non_empty_counts(correlated),
      else: nil
  end

  def correlated_counts(_conflict_group_count, _counts), do: nil

  def canonical_scopes, do: @canonical_scopes

  defp non_empty_counts(counts) when map_size(counts) == 0, do: nil
  defp non_empty_counts(counts), do: counts
end
