defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps.GroundStations do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def correlated_counts(resource_scope_counts, counts)
      when is_map(resource_scope_counts) and is_map(counts) do
    ground_station_scope_count = Map.get(resource_scope_counts, "ground_station")

    correlated =
      Enum.reduce(counts, %{}, fn {ground_station_id, count}, acc ->
        ground_station_id = StableIds.stable_id_or_nil(ground_station_id)

        if ground_station_id && is_integer(count) && count > 0 do
          Map.update(acc, ground_station_id, count, &(&1 + count))
        else
          acc
        end
      end)

    if is_integer(ground_station_scope_count) and ground_station_scope_count > 0 and
         Enum.sum(Map.values(correlated)) <= ground_station_scope_count do
      non_empty_counts(correlated)
    end
  end

  def correlated_counts(_resource_scope_counts, _counts), do: nil

  defp non_empty_counts(counts) when map_size(counts) == 0, do: nil
  defp non_empty_counts(counts), do: counts
end
