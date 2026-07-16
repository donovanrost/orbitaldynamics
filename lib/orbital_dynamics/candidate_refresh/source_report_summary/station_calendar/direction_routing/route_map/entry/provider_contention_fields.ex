defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Entry.ProviderContentionFields do
  @moduledoc false

  def fields(direction, maps) do
    %{
      "provider_contention_group_count" =>
        get(maps, :provider_contention_direction_counts, direction),
      "provider_contention_group_ids" =>
        get(maps, :provider_contention_group_ids_by_direction, direction, []),
      "provider_contention_source_entry_ids" =>
        get(maps, :provider_contention_source_entry_ids_by_direction, direction, []),
      "provider_contention_provider_ids" =>
        get(maps, :provider_contention_provider_ids_by_direction, direction, []),
      "provider_contention_provider_entry_ids" =>
        get(maps, :provider_contention_provider_entry_ids_by_direction, direction, []),
      "provider_contention_capacity_fractions" =>
        get(maps, :provider_contention_capacity_fractions_by_direction, direction, [])
    }
  end

  defp get(maps, key, direction, default \\ nil) do
    maps
    |> Map.fetch!(key)
    |> Map.get(direction, default)
  end
end
