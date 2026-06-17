defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary.ProviderContention do
  @moduledoc false

  def fields(station_summary) do
    %{
      "provider_calendar_contention_group_count" =>
        summary_integer(station_summary, "provider_calendar_contention_group_count"),
      "provider_calendar_contention_provider_counts" =>
        Map.get(station_summary, "provider_calendar_contention_provider_counts", %{}),
      "provider_calendar_contention_ground_station_counts" =>
        Map.get(station_summary, "provider_calendar_contention_ground_station_counts", %{}),
      "provider_calendar_contention_group_ids" =>
        Map.get(station_summary, "provider_calendar_contention_group_ids", []),
      "provider_calendar_contention_source_entry_ids" =>
        Map.get(station_summary, "provider_calendar_contention_source_entry_ids", []),
      "provider_calendar_contention_provider_entry_ids" =>
        Map.get(station_summary, "provider_calendar_contention_provider_entry_ids", []),
      "provider_calendar_contention_capacity_fractions" =>
        Map.get(station_summary, "provider_calendar_contention_capacity_fractions", []),
      "provider_calendar_contention_minimum_capacity_fraction" =>
        Map.get(station_summary, "provider_calendar_contention_minimum_capacity_fraction"),
      "provider_calendar_contention_capacity_fractions_by_provider" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_capacity_fractions_by_provider",
          %{}
        ),
      "provider_calendar_contention_capacity_fractions_by_ground_station" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_capacity_fractions_by_ground_station",
          %{}
        ),
      "provider_calendar_contention_provider_entry_ids_by_provider" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_provider_entry_ids_by_provider",
          %{}
        ),
      "provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_provider_entry_ids_by_ground_station",
          %{}
        ),
      "provider_calendar_contention_provider_ids_by_direction" =>
        Map.get(station_summary, "provider_calendar_contention_provider_ids_by_direction", %{}),
      "provider_calendar_contention_direction_counts" =>
        Map.get(station_summary, "provider_calendar_contention_direction_counts", %{}),
      "provider_calendar_contention_group_ids_by_direction" =>
        Map.get(station_summary, "provider_calendar_contention_group_ids_by_direction", %{}),
      "provider_calendar_contention_source_entry_ids_by_direction" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_source_entry_ids_by_direction",
          %{}
        ),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_provider_entry_ids_by_direction",
          %{}
        ),
      "provider_calendar_contention_capacity_fractions_by_direction" =>
        Map.get(
          station_summary,
          "provider_calendar_contention_capacity_fractions_by_direction",
          %{}
        )
    }
  end

  def pressure?(replay) do
    (replay["provider_calendar_contention_group_count"] || 0) > 0 or
      replay["provider_calendar_contention_group_ids"] != [] or
      replay["provider_calendar_contention_source_entry_ids"] != [] or
      replay["provider_calendar_contention_provider_entry_ids"] != [] or
      availability_pressure?(replay) or
      Enum.any?(
        [
          "provider_calendar_contention_provider_counts",
          "provider_calendar_contention_ground_station_counts",
          "provider_calendar_contention_provider_entry_ids_by_provider",
          "provider_calendar_contention_provider_entry_ids_by_ground_station",
          "provider_calendar_contention_provider_ids_by_direction",
          "provider_calendar_contention_direction_counts",
          "provider_calendar_contention_group_ids_by_direction",
          "provider_calendar_contention_source_entry_ids_by_direction",
          "provider_calendar_contention_provider_entry_ids_by_direction"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
  end

  def availability_pressure?(replay) do
    replay["provider_calendar_contention_capacity_fractions"] != [] or
      not is_nil(replay["provider_calendar_contention_minimum_capacity_fraction"]) or
      Enum.any?(
        [
          "provider_calendar_contention_capacity_fractions_by_provider",
          "provider_calendar_contention_capacity_fractions_by_ground_station",
          "provider_calendar_contention_capacity_fractions_by_direction"
        ],
        &(map_size(replay[&1] || %{}) > 0)
      )
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
