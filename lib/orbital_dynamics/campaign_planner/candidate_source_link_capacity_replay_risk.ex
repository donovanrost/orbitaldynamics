defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceLinkCapacityReplayRisk do
  @moduledoc false

  def link_capacity(%{"branch_local_link_capacity_pressure" => true} = replay_summary) do
    if link_capacity_scoring_pressure?(replay_summary) do
      link_capacity_pressure_risk(replay_summary)
    else
      []
    end
  end

  def link_capacity(_replay_summary), do: []

  defp link_capacity_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_downlink_shortfall_pressure") == true or
      Map.get(replay_summary, "branch_local_actual_throughput_pressure") == true or
      Map.get(replay_summary, "branch_local_capacity_adjusted_throughput_pressure") == true
  end

  defp link_capacity_pressure_risk(replay_summary) do
    ground_station_ids =
      replay_summary
      |> Map.get("ground_station_counts", %{})
      |> map_keys()

    directions =
      replay_summary
      |> Map.get("direction_counts", %{})
      |> map_keys()
      |> Kernel.++(List.wrap(Map.get(replay_summary, "directions", [])))
      |> sorted_encoded_values()

    spacecraft_ids =
      replay_summary
      |> Map.get("spacecraft_counts", %{})
      |> map_keys()

    [
      %{
        "type" => "downlink_completion_gap",
        "severity" => "medium",
        "reason" =>
          "candidate source link-capacity replay reports downlink shortfall, actual-throughput, or capacity-adjusted pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "selected_shortfall_row_count" => Map.get(replay_summary, "selected_shortfall_row_count"),
        "actual_shortfall_row_count" => Map.get(replay_summary, "actual_shortfall_row_count"),
        "actual_throughput_row_count" => Map.get(replay_summary, "actual_throughput_row_count"),
        "capacity_adjusted_throughput_row_count" =>
          Map.get(replay_summary, "capacity_adjusted_throughput_row_count"),
        "capacity_adjusted_throughput_mb_total" =>
          Map.get(replay_summary, "capacity_adjusted_throughput_mb_total"),
        "selected_capacity_adjusted_throughput_mb_total" =>
          Map.get(replay_summary, "selected_capacity_adjusted_throughput_mb_total"),
        "unused_capacity_adjusted_throughput_mb_total" =>
          Map.get(replay_summary, "unused_capacity_adjusted_throughput_mb_total"),
        "ground_station_ids" => ground_station_ids,
        "directions" => directions,
        "spacecraft_ids" => spacecraft_ids,
        "contact_ids_by_ground_station" =>
          Map.get(replay_summary, "contact_ids_by_ground_station"),
        "source_window_ids_by_ground_station" =>
          Map.get(replay_summary, "source_window_ids_by_ground_station"),
        "station_calendar_entry_ids_by_ground_station" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_ground_station"),
        "station_calendar_provider_entry_ids_by_ground_station" =>
          Map.get(replay_summary, "station_calendar_provider_entry_ids_by_ground_station"),
        "selected_contact_ids" => Map.get(replay_summary, "selected_contact_ids"),
        "selected_source_window_ids" => Map.get(replay_summary, "selected_source_window_ids"),
        "selected_station_calendar_entry_ids" =>
          Map.get(replay_summary, "selected_station_calendar_entry_ids"),
        "selected_station_calendar_provider_entry_ids" =>
          Map.get(replay_summary, "selected_station_calendar_provider_entry_ids"),
        "actual_throughput_contact_ids" =>
          Map.get(replay_summary, "actual_throughput_contact_ids"),
        "actual_throughput_source_window_ids" =>
          Map.get(replay_summary, "actual_throughput_source_window_ids"),
        "actual_throughput_station_calendar_entry_ids" =>
          Map.get(replay_summary, "actual_throughput_station_calendar_entry_ids"),
        "actual_throughput_station_calendar_provider_entry_ids" =>
          Map.get(replay_summary, "actual_throughput_station_calendar_provider_entry_ids"),
        "downlink_requirement_status_counts" =>
          Map.get(replay_summary, "downlink_requirement_status_counts"),
        "contact_ids_by_requirement_status" =>
          Map.get(replay_summary, "contact_ids_by_requirement_status"),
        "source_window_ids_by_requirement_status" =>
          Map.get(replay_summary, "source_window_ids_by_requirement_status"),
        "station_calendar_entry_ids_by_requirement_status" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_requirement_status"),
        "station_calendar_provider_entry_ids_by_requirement_status" =>
          Map.get(replay_summary, "station_calendar_provider_entry_ids_by_requirement_status"),
        "direction_routing" => Map.get(replay_summary, "direction_routing"),
        "branch_local_capacity_adjusted_throughput_pressure" =>
          Map.get(replay_summary, "branch_local_capacity_adjusted_throughput_pressure"),
        "branch_local_downlink_shortfall_pressure" =>
          Map.get(replay_summary, "branch_local_downlink_shortfall_pressure"),
        "branch_local_actual_throughput_pressure" =>
          Map.get(replay_summary, "branch_local_actual_throughput_pressure"),
        "feedback_source" => "candidate_source.link_capacity_replay_summary",
        "feedback_scope" => "link_capacity",
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries")
      }
      |> compact_map()
    ]
  end

  defp map_keys(%{} = map), do: map |> Map.keys() |> sorted_encoded_values()
  defp map_keys(_map), do: []

  defp sorted_encoded_values(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
