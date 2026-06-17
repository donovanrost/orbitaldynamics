defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary.ProviderContention do
  @moduledoc false

  def fields(reservation_summary) do
    %{
      "provider_calendar_contention_group_count" =>
        summary_integer(reservation_summary, "provider_calendar_contention_group_count"),
      "provider_calendar_contention_provider_counts" =>
        Map.get(reservation_summary, "provider_calendar_contention_provider_counts", %{}),
      "provider_calendar_contention_ground_station_counts" =>
        Map.get(reservation_summary, "provider_calendar_contention_ground_station_counts", %{}),
      "provider_calendar_contention_group_ids" =>
        Map.get(reservation_summary, "provider_calendar_contention_group_ids", []),
      "provider_calendar_contention_source_entry_ids" =>
        Map.get(reservation_summary, "provider_calendar_contention_source_entry_ids", []),
      "provider_calendar_contention_provider_entry_ids" =>
        Map.get(reservation_summary, "provider_calendar_contention_provider_entry_ids", []),
      "provider_calendar_contention_provider_entry_ids_by_provider" =>
        Map.get(
          reservation_summary,
          "provider_calendar_contention_provider_entry_ids_by_provider",
          %{}
        ),
      "provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        Map.get(
          reservation_summary,
          "provider_calendar_contention_provider_entry_ids_by_ground_station",
          %{}
        ),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        Map.get(
          reservation_summary,
          "provider_calendar_contention_provider_entry_ids_by_direction",
          %{}
        )
    }
  end

  def pressure?(replay) do
    station_reservation_pressure?(replay) or
      map_size(replay["provider_calendar_contention_provider_counts"] || %{}) > 0 or
      map_size(replay["provider_calendar_contention_ground_station_counts"] || %{}) > 0
  end

  def station_reservation_pressure?(replay) do
    (replay["provider_calendar_contention_group_count"] || 0) > 0 or
      replay["provider_calendar_contention_group_ids"] != [] or
      replay["provider_calendar_contention_source_entry_ids"] != [] or
      replay["provider_calendar_contention_provider_entry_ids"] != [] or
      map_size(replay["provider_calendar_contention_provider_entry_ids_by_provider"] || %{}) >
        0 or
      map_size(replay["provider_calendar_contention_provider_entry_ids_by_ground_station"] || %{}) >
        0 or
      map_size(replay["provider_calendar_contention_provider_entry_ids_by_direction"] || %{}) >
        0
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0
end
