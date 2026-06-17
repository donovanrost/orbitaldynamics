defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary.Throughput do
  @moduledoc false

  alias __MODULE__.Pressure

  def fields(link_summary) do
    %{
      "selected_shortfall_row_count" =>
        summary_integer(link_summary, "selected_shortfall_row_count"),
      "actual_shortfall_row_count" => summary_integer(link_summary, "actual_shortfall_row_count"),
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
        Map.get(
          link_summary,
          "selected_capacity_adjusted_throughput_mb_by_ground_station",
          %{}
        ),
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
        Map.get(link_summary, "actual_throughput_station_calendar_provider_entry_ids", []),
      "downlink_requirement_status_counts" =>
        Map.get(link_summary, "downlink_requirement_status_counts", %{}),
      "contact_ids_by_requirement_status" =>
        Map.get(link_summary, "contact_ids_by_requirement_status", %{}),
      "source_window_ids_by_requirement_status" =>
        Map.get(link_summary, "source_window_ids_by_requirement_status", %{}),
      "station_calendar_entry_ids_by_requirement_status" =>
        Map.get(link_summary, "station_calendar_entry_ids_by_requirement_status", %{}),
      "station_calendar_provider_entry_ids_by_requirement_status" =>
        Map.get(link_summary, "station_calendar_provider_entry_ids_by_requirement_status", %{})
    }
  end

  def capacity_adjusted_pressure?(replay) do
    Pressure.capacity_adjusted_pressure?(replay)
  end

  def shortfall_pressure?(replay) do
    Pressure.shortfall_pressure?(replay)
  end

  def actual_pressure?(replay) do
    Pressure.actual_pressure?(replay)
  end

  def link_capacity_pressure?(replay) do
    Pressure.link_capacity_pressure?(replay)
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
