defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceStationCalendarReplayRisk do
  @moduledoc false

  def station_calendar(%{"branch_local_station_calendar_pressure" => true} = replay_summary) do
    if station_calendar_scoring_pressure?(replay_summary) do
      station_calendar_pressure_risk(replay_summary)
    else
      []
    end
  end

  def station_calendar(_replay_summary), do: []

  defp station_calendar_scoring_pressure?(replay_summary) do
    Map.get(replay_summary, "branch_local_affected_contact_pressure") == true or
      Map.get(replay_summary, "branch_local_provider_contention_pressure") == true or
      Map.get(replay_summary, "branch_local_station_availability_pressure") == true
  end

  defp station_calendar_pressure_risk(replay_summary) do
    affected_ground_station_ids =
      replay_summary
      |> Map.get("affected_contact_ground_station_counts", %{})
      |> map_keys()

    provider_ground_station_ids =
      replay_summary
      |> Map.get("provider_calendar_contention_ground_station_counts", %{})
      |> map_keys()

    ground_station_ids =
      affected_ground_station_ids
      |> Kernel.++(provider_ground_station_ids)
      |> sorted_encoded_values()

    station_calendar_statuses =
      replay_summary
      |> Map.get("station_calendar_status_counts", %{})
      |> map_keys()

    affected_contact_availabilities =
      replay_summary
      |> Map.get("affected_contact_availability_counts", %{})
      |> map_keys()

    directions =
      replay_summary
      |> Map.get("direction_counts", %{})
      |> map_keys()
      |> Kernel.++(
        replay_summary
        |> Map.get("provider_calendar_contention_direction_counts", %{})
        |> map_keys()
      )
      |> sorted_encoded_values()

    [
      %{
        "type" => "station_calendar_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source station-calendar replay reports affected-contact, provider-contention, or station-availability pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "affected_contact_count" => Map.get(replay_summary, "affected_contact_count"),
        "provider_calendar_contention_group_count" =>
          Map.get(replay_summary, "provider_calendar_contention_group_count"),
        "affected_contact_ids" => Map.get(replay_summary, "affected_contact_ids"),
        "affected_station_calendar_entry_ids" =>
          Map.get(replay_summary, "affected_station_calendar_entry_ids"),
        "affected_station_reservation_ids" =>
          Map.get(replay_summary, "affected_station_reservation_ids"),
        "ground_station_ids" => ground_station_ids,
        "station_calendar_statuses" => station_calendar_statuses,
        "affected_contact_availabilities" => affected_contact_availabilities,
        "directions" => directions,
        "station_calendar_status_counts" =>
          Map.get(replay_summary, "station_calendar_status_counts"),
        "affected_contact_ground_station_counts" =>
          Map.get(replay_summary, "affected_contact_ground_station_counts"),
        "affected_contact_availability_counts" =>
          Map.get(replay_summary, "affected_contact_availability_counts"),
        "contact_ids_by_status" => Map.get(replay_summary, "contact_ids_by_status"),
        "contact_ids_by_ground_station" =>
          Map.get(replay_summary, "contact_ids_by_ground_station"),
        "contact_ids_by_availability" => Map.get(replay_summary, "contact_ids_by_availability"),
        "station_calendar_entry_ids_by_status" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_status"),
        "station_calendar_entry_ids_by_ground_station" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_ground_station"),
        "station_calendar_entry_ids_by_availability" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_availability"),
        "station_reservation_ids_by_status" =>
          Map.get(replay_summary, "station_reservation_ids_by_status"),
        "station_reservation_ids_by_ground_station" =>
          Map.get(replay_summary, "station_reservation_ids_by_ground_station"),
        "station_reservation_ids_by_availability" =>
          Map.get(replay_summary, "station_reservation_ids_by_availability"),
        "direction_counts" => Map.get(replay_summary, "direction_counts"),
        "contact_ids_by_direction" => Map.get(replay_summary, "contact_ids_by_direction"),
        "station_calendar_entry_ids_by_direction" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_direction"),
        "station_reservation_ids_by_direction" =>
          Map.get(replay_summary, "station_reservation_ids_by_direction"),
        "station_capacity_fractions_by_direction" =>
          Map.get(replay_summary, "station_capacity_fractions_by_direction"),
        "direction_routing" => Map.get(replay_summary, "direction_routing"),
        "reserved_by_counts" => Map.get(replay_summary, "reserved_by_counts"),
        "contact_ids_by_reserved_by" => Map.get(replay_summary, "contact_ids_by_reserved_by"),
        "station_calendar_entry_ids_by_reserved_by" =>
          Map.get(replay_summary, "station_calendar_entry_ids_by_reserved_by"),
        "station_reservation_ids_by_reserved_by" =>
          Map.get(replay_summary, "station_reservation_ids_by_reserved_by"),
        "station_reservation_expires_at_s" =>
          Map.get(replay_summary, "station_reservation_expires_at_s"),
        "earliest_station_reservation_expires_at_s" =>
          Map.get(replay_summary, "earliest_station_reservation_expires_at_s"),
        "station_capacity_fractions" => Map.get(replay_summary, "station_capacity_fractions"),
        "minimum_station_capacity_fraction" =>
          Map.get(replay_summary, "minimum_station_capacity_fraction"),
        "station_capacity_fractions_by_status" =>
          Map.get(replay_summary, "station_capacity_fractions_by_status"),
        "station_capacity_fractions_by_ground_station" =>
          Map.get(replay_summary, "station_capacity_fractions_by_ground_station"),
        "station_capacity_fractions_by_availability" =>
          Map.get(replay_summary, "station_capacity_fractions_by_availability"),
        "provider_calendar_contention_provider_counts" =>
          Map.get(replay_summary, "provider_calendar_contention_provider_counts"),
        "provider_calendar_contention_ground_station_counts" =>
          Map.get(replay_summary, "provider_calendar_contention_ground_station_counts"),
        "provider_calendar_contention_group_ids" =>
          Map.get(replay_summary, "provider_calendar_contention_group_ids"),
        "provider_calendar_contention_source_entry_ids" =>
          Map.get(replay_summary, "provider_calendar_contention_source_entry_ids"),
        "provider_calendar_contention_provider_entry_ids" =>
          Map.get(replay_summary, "provider_calendar_contention_provider_entry_ids"),
        "provider_calendar_contention_direction_counts" =>
          Map.get(replay_summary, "provider_calendar_contention_direction_counts"),
        "provider_calendar_contention_group_ids_by_direction" =>
          Map.get(replay_summary, "provider_calendar_contention_group_ids_by_direction"),
        "provider_calendar_contention_source_entry_ids_by_direction" =>
          Map.get(replay_summary, "provider_calendar_contention_source_entry_ids_by_direction"),
        "provider_calendar_contention_provider_entry_ids_by_direction" =>
          Map.get(replay_summary, "provider_calendar_contention_provider_entry_ids_by_direction"),
        "provider_calendar_contention_capacity_fractions" =>
          Map.get(replay_summary, "provider_calendar_contention_capacity_fractions"),
        "provider_calendar_contention_minimum_capacity_fraction" =>
          Map.get(replay_summary, "provider_calendar_contention_minimum_capacity_fraction"),
        "provider_calendar_contention_capacity_fractions_by_provider" =>
          Map.get(replay_summary, "provider_calendar_contention_capacity_fractions_by_provider"),
        "provider_calendar_contention_capacity_fractions_by_ground_station" =>
          Map.get(
            replay_summary,
            "provider_calendar_contention_capacity_fractions_by_ground_station"
          ),
        "provider_calendar_contention_capacity_fractions_by_direction" =>
          Map.get(replay_summary, "provider_calendar_contention_capacity_fractions_by_direction"),
        "branch_local_affected_contact_pressure" =>
          Map.get(replay_summary, "branch_local_affected_contact_pressure"),
        "branch_local_provider_contention_pressure" =>
          Map.get(replay_summary, "branch_local_provider_contention_pressure"),
        "branch_local_station_availability_pressure" =>
          Map.get(replay_summary, "branch_local_station_availability_pressure"),
        "feedback_source" => "candidate_source.station_calendar_replay_summary",
        "feedback_scope" => "station_calendar",
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
