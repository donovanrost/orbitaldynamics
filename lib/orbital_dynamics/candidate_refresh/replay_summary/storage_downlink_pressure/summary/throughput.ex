defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.Throughput do
  @moduledoc false

  def fields(link_summary) do
    %{
      "actual_throughput_row_count" =>
        summary_integer(link_summary, "actual_throughput_row_count"),
      "capacity_adjusted_throughput_row_count" =>
        summary_integer(link_summary, "capacity_adjusted_throughput_row_count"),
      "capacity_adjusted_throughput_mb_total" =>
        numeric_value(Map.get(link_summary, "capacity_adjusted_throughput_mb_total")) || 0.0,
      "selected_capacity_adjusted_throughput_mb_total" =>
        numeric_value(Map.get(link_summary, "selected_capacity_adjusted_throughput_mb_total")) ||
          0.0,
      "unused_capacity_adjusted_throughput_mb_total" =>
        numeric_value(Map.get(link_summary, "unused_capacity_adjusted_throughput_mb_total")) ||
          0.0,
      "capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(link_summary, "capacity_adjusted_throughput_mb_by_ground_station", %{}),
      "selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(link_summary, "selected_capacity_adjusted_throughput_mb_by_ground_station", %{}),
      "unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        Map.get(link_summary, "unused_capacity_adjusted_throughput_mb_by_ground_station", %{}),
      "capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(link_summary, "capacity_adjusted_throughput_mb_by_direction", %{}),
      "selected_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(link_summary, "selected_capacity_adjusted_throughput_mb_by_direction", %{}),
      "unused_capacity_adjusted_throughput_mb_by_direction" =>
        Map.get(link_summary, "unused_capacity_adjusted_throughput_mb_by_direction", %{}),
      "actual_throughput_contact_id_counts" =>
        Map.get(link_summary, "actual_throughput_contact_id_counts", %{}),
      "actual_throughput_contact_ids" =>
        Map.get(link_summary, "actual_throughput_contact_ids", []),
      "actual_throughput_source_window_ids" =>
        Map.get(link_summary, "actual_throughput_source_window_ids", []),
      "actual_throughput_station_calendar_entry_ids" =>
        Map.get(link_summary, "actual_throughput_station_calendar_entry_ids", []),
      "actual_throughput_station_calendar_provider_entry_ids" =>
        Map.get(link_summary, "actual_throughput_station_calendar_provider_entry_ids", [])
    }
  end

  def capacity_adjusted_pressure?(replay) do
    replay["capacity_adjusted_throughput_row_count"] > 0 or
      replay["capacity_adjusted_throughput_mb_total"] +
        replay["selected_capacity_adjusted_throughput_mb_total"] +
        replay["unused_capacity_adjusted_throughput_mb_total"] > 0.0 or
      Enum.any?(
        [
          "capacity_adjusted_throughput_mb_by_ground_station",
          "selected_capacity_adjusted_throughput_mb_by_ground_station",
          "unused_capacity_adjusted_throughput_mb_by_ground_station",
          "capacity_adjusted_throughput_mb_by_direction",
          "selected_capacity_adjusted_throughput_mb_by_direction",
          "unused_capacity_adjusted_throughput_mb_by_direction"
        ],
        &(map_size(replay[&1]) > 0)
      )
  end

  def actual_pressure?(replay) do
    replay["actual_throughput_row_count"] > 0 or
      map_size(replay["actual_throughput_contact_id_counts"]) > 0 or
      replay["actual_throughput_contact_ids"] != [] or
      replay["actual_throughput_source_window_ids"] != [] or
      replay["actual_throughput_station_calendar_entry_ids"] != [] or
      replay["actual_throughput_station_calendar_provider_entry_ids"] != []
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

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
