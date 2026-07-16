defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.RouteMap.Inputs.NormalizedInputs do
  @moduledoc false

  def values(%{} = values) do
    %{
      direction_counts: empty_map_if_nil(values.direction_counts),
      contact_ids_by_direction: empty_map_if_nil(values.contact_ids_by_direction),
      station_calendar_entry_ids_by_direction:
        empty_map_if_nil(values.station_calendar_entry_ids_by_direction),
      station_reservation_ids_by_direction:
        empty_map_if_nil(values.station_reservation_ids_by_direction),
      station_capacity_fractions_by_direction:
        empty_map_if_nil(values.station_capacity_fractions_by_direction),
      provider_contention_direction_counts:
        empty_map_if_nil(values.provider_contention_direction_counts),
      provider_contention_group_ids_by_direction:
        empty_map_if_nil(values.provider_contention_group_ids_by_direction),
      provider_contention_source_entry_ids_by_direction:
        empty_map_if_nil(values.provider_contention_source_entry_ids_by_direction),
      provider_contention_provider_ids_by_direction:
        empty_map_if_nil(values.provider_contention_provider_ids_by_direction),
      provider_contention_provider_entry_ids_by_direction:
        empty_map_if_nil(values.provider_contention_provider_entry_ids_by_direction),
      provider_contention_capacity_fractions_by_direction:
        empty_map_if_nil(values.provider_contention_capacity_fractions_by_direction)
    }
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}
end
