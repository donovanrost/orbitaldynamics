defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.Summary.Throughput.Pressure do
  @moduledoc false

  def capacity_adjusted_pressure?(replay) do
    (replay["capacity_adjusted_throughput_row_count"] || 0) > 0 or
      (replay["capacity_adjusted_throughput_mb_total"] || 0.0) > 0.0 or
      (replay["selected_capacity_adjusted_throughput_mb_total"] || 0.0) > 0.0 or
      (replay["unused_capacity_adjusted_throughput_mb_total"] || 0.0) > 0.0 or
      map_size(replay["capacity_adjusted_throughput_mb_by_ground_station"] || %{}) > 0 or
      map_size(replay["selected_capacity_adjusted_throughput_mb_by_ground_station"] || %{}) >
        0 or
      map_size(replay["unused_capacity_adjusted_throughput_mb_by_ground_station"] || %{}) > 0 or
      map_size(replay["capacity_adjusted_throughput_mb_by_direction"] || %{}) > 0 or
      map_size(replay["selected_capacity_adjusted_throughput_mb_by_direction"] || %{}) > 0 or
      map_size(replay["unused_capacity_adjusted_throughput_mb_by_direction"] || %{}) > 0
  end

  def shortfall_pressure?(replay) do
    (replay["selected_shortfall_row_count"] || 0) + (replay["actual_shortfall_row_count"] || 0) >
      0 or
      map_size(replay["downlink_requirement_status_counts"] || %{}) > 0 or
      map_size(replay["contact_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["source_window_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["station_calendar_entry_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["station_calendar_provider_entry_ids_by_requirement_status"] || %{}) > 0
  end

  def actual_pressure?(replay) do
    (replay["actual_throughput_row_count"] || 0) > 0 or
      map_size(replay["actual_throughput_contact_id_counts"] || %{}) > 0 or
      replay["actual_throughput_contact_ids"] != [] or
      replay["actual_throughput_source_window_ids"] != [] or
      replay["actual_throughput_station_calendar_entry_ids"] != [] or
      replay["actual_throughput_station_calendar_provider_entry_ids"] != [] or
      actual_requirement_status_pressure?(replay["contact_ids_by_requirement_status"]) or
      actual_requirement_status_pressure?(replay["source_window_ids_by_requirement_status"]) or
      actual_requirement_status_pressure?(
        replay["station_calendar_entry_ids_by_requirement_status"]
      ) or
      actual_requirement_status_pressure?(
        replay["station_calendar_provider_entry_ids_by_requirement_status"]
      )
  end

  def link_capacity_pressure?(replay) do
    (replay["selected_shortfall_row_count"] || 0) + (replay["actual_shortfall_row_count"] || 0) +
      (replay["actual_throughput_row_count"] || 0) +
      (replay["capacity_adjusted_throughput_row_count"] || 0) > 0 or
      map_size(replay["downlink_requirement_status_counts"] || %{}) > 0 or
      map_size(replay["contact_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["source_window_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["station_calendar_entry_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["station_calendar_provider_entry_ids_by_requirement_status"] || %{}) > 0 or
      map_size(replay["actual_throughput_contact_id_counts"] || %{}) > 0 or
      replay["actual_throughput_contact_ids"] != [] or
      replay["actual_throughput_source_window_ids"] != [] or
      replay["actual_throughput_station_calendar_entry_ids"] != [] or
      replay["actual_throughput_station_calendar_provider_entry_ids"] != [] or
      capacity_adjusted_pressure?(replay)
  end

  defp actual_requirement_status_pressure?(%{} = ids_by_status) do
    ids_by_status
    |> Map.keys()
    |> Enum.map(&normalized_timeline_diff_token/1)
    |> Enum.any?(&String.starts_with?(&1 || "", "actual_"))
  end

  defp actual_requirement_status_pressure?(_value), do: false

  defp normalized_timeline_diff_token(nil), do: nil

  defp normalized_timeline_diff_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> String.trim("_")
  end
end
