defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshGroundNetwork do
  @moduledoc false

  @unavailable_station_tokens ~w(unavailable maintenance outage offline down)

  def ground_stations(mission_state) do
    station_defaults =
      mission_state
      |> Map.get("ground_stations", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&normalize_ground_station_spec/1)
      |> unique_items_by_id()

    network_stations =
      mission_state
      |> Map.get("ground_network", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&normalize_ground_station_spec/1)
      |> unique_items_by_id()

    (station_defaults ++ network_stations)
    |> Enum.filter(fn station ->
      station["id"] not in [nil, ""] and is_number(station["latitude_deg"]) and
        is_number(station["longitude_deg"])
    end)
    |> dedupe_by_id_preserving_first()
  end

  defp normalize_ground_station_spec(station) do
    station
    |> Map.put_new("id", Map.get(station, "ground_station_id"))
    |> Map.put_new("minimum_elevation_deg", 5.0)
    |> Map.delete("ground_station_id")
  end

  def build(branch, mission_state, operational_feedback) do
    base_entries =
      mission_state
      |> base_ground_network_entries()
      |> Enum.map(&stringify_keys/1)
      |> apply_station_throughput_feedback(operational_feedback)

    station_ids =
      base_entries
      |> Enum.map(&ground_network_station_id/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    event_entries =
      branch
      |> Map.get("events", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.flat_map(&branch_ground_network_event_entries(&1, station_ids))

    merge_branch_ground_network_entries(base_entries, event_entries)
  end

  defp merge_branch_ground_network_entries(base_entries, []), do: base_entries

  defp merge_branch_ground_network_entries(base_entries, event_entries) do
    base_entries
    |> Enum.reject(fn base_entry ->
      Enum.any?(
        event_entries,
        &(same_branch_ground_network_state?(base_entry, &1) ||
            catalog_ground_station_default_shadowed?(base_entry, &1))
      )
    end)
    |> Kernel.++(event_entries)
  end

  defp catalog_ground_station_default_shadowed?(base_entry, event_entry) do
    get_in(base_entry, ["provenance", "source"]) == "mission_state.ground_stations" and
      ground_network_station_id(base_entry) == ground_network_station_id(event_entry) and
      ground_network_entries_overlap?(base_entry, event_entry)
  end

  defp same_branch_ground_network_state?(left, right) do
    ground_network_station_id(left) == ground_network_station_id(right) and
      ground_network_state_kind(left) == ground_network_state_kind(right) and
      ground_network_entries_overlap?(left, right)
  end

  defp ground_network_state_kind(entry) do
    status =
      normalized_station_availability_token(
        Map.get(entry, "status") || Map.get(entry, "availability")
      )

    capacity_fraction = ground_network_capacity_fraction(entry, nil)

    cond do
      status in @unavailable_station_tokens -> :unavailable
      status == "reserved" -> :reserved
      is_number(capacity_fraction) and capacity_fraction <= 0.0 -> :unavailable
      is_number(capacity_fraction) and capacity_fraction < 1.0 -> :reduced_capacity
      true -> :available
    end
  end

  defp ground_network_entries_overlap?(left, right) do
    left_start = Map.get(left, "starts_at_s")
    left_end = Map.get(left, "ends_at_s")
    right_start = Map.get(right, "starts_at_s")
    right_end = Map.get(right, "ends_at_s")

    cond do
      is_nil(left_start) or is_nil(left_end) or is_nil(right_start) or is_nil(right_end) ->
        true

      is_number(left_start) and is_number(left_end) and is_number(right_start) and
          is_number(right_end) ->
        left_start < right_end and right_start < left_end

      true ->
        false
    end
  end

  defp apply_station_throughput_feedback(entries, %{"station_throughput_factor" => factors})
       when is_map(factors) do
    Enum.map(entries, fn entry ->
      station_id = ground_network_station_id(entry)
      factor = numeric_or_nil(Map.get(factors, station_id) || Map.get(factors, "default"))

      if is_number(factor) do
        capacity_fraction =
          entry
          |> ground_network_capacity_fraction()
          |> Kernel.*(factor)
          |> max(0.0)
          |> min(1.0)

        entry
        |> Map.put("capacity_fraction", capacity_fraction)
        |> Map.put_new("status", "available")
        |> Map.update("provenance", %{}, fn
          %{} = provenance -> provenance
          _other -> %{}
        end)
        |> put_in(
          ["provenance", "station_throughput_factor_source"],
          "operational_feedback"
        )
      else
        entry
      end
    end)
  end

  defp apply_station_throughput_feedback(entries, _operational_feedback), do: entries

  defp base_ground_network_entries(mission_state) do
    station_defaults =
      mission_state
      |> Map.get("ground_stations", [])
      |> Enum.map(fn station ->
        station = stringify_keys(station)

        %{
          "ground_station_id" => ground_network_station_id(station),
          "status" => Map.get(station, "status", "available"),
          "capacity_fraction" => ground_network_capacity_fraction(station),
          "provenance" => %{"source" => "mission_state.ground_stations"}
        }
        |> normalize_ground_network_entry()
        |> compact_map()
      end)

    ground_network =
      mission_state
      |> Map.get("ground_network", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(&normalize_ground_network_entry/1)

    station_defaults ++ ground_network
  end

  defp branch_ground_network_event_entries(
         %{"type" => "ground_station_outage"} = event,
         station_ids
       ) do
    event
    |> event_station_ids(station_ids)
    |> Enum.map(fn station_id ->
      compact_map(%{
        "id" => event["station_calendar_entry_id"],
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"],
        "ground_station_id" => station_id,
        "status" => "unavailable",
        "capacity_fraction" => 0.0,
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "provenance" => branch_ground_network_event_provenance(event, "ground_station_outage")
      })
    end)
  end

  defp branch_ground_network_event_entries(
         %{"type" => "reduced_downlink_capacity"} = event,
         station_ids
       ) do
    event
    |> event_station_ids(station_ids)
    |> Enum.map(fn station_id ->
      compact_map(%{
        "id" => event["station_calendar_entry_id"],
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"],
        "ground_station_id" => station_id,
        "status" => "available",
        "capacity_fraction" => ground_network_capacity_fraction(event),
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "provenance" => branch_ground_network_event_provenance(event, "reduced_downlink_capacity")
      })
    end)
  end

  defp branch_ground_network_event_entries(
         %{"type" => "ground_station_reserved"} = event,
         station_ids
       ) do
    event
    |> event_station_ids(station_ids)
    |> Enum.map(fn station_id ->
      compact_map(%{
        "id" => event["station_calendar_entry_id"],
        "station_calendar_entry_id" => event["station_calendar_entry_id"],
        "station_calendar_provider_id" => event["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
        "station_calendar_directions" => event["station_calendar_directions"],
        "station_calendar_status" => event["station_calendar_status"],
        "station_calendar_trust_boundary_status" =>
          event["station_calendar_trust_boundary_status"],
        "ground_station_id" => station_id,
        "status" => "reserved",
        "capacity_fraction" => ground_network_capacity_fraction(event),
        "starts_at_s" => event["starts_at_s"],
        "ends_at_s" => event["ends_at_s"],
        "reservation_id" => Map.get(event, "reservation_id") || Map.get(event, "id"),
        "reserved_by" => event["reserved_by"],
        "reservation_status" => Map.get(event, "reservation_status", "reserved"),
        "station_reservation_match_status" => event["station_reservation_match_status"],
        "provenance" => branch_ground_network_event_provenance(event, "ground_station_reserved")
      })
    end)
  end

  defp branch_ground_network_event_entries(_event, _station_ids), do: []

  defp normalize_ground_network_entry(entry) do
    entry
    |> maybe_put_ground_network_capacity_fraction()
    |> normalize_ground_network_time_field("starts_at_s", "start_s")
    |> normalize_ground_network_time_field("ends_at_s", "end_s")
  end

  defp maybe_put_ground_network_capacity_fraction(entry) do
    case ground_network_capacity_fraction(entry, nil) do
      value when is_number(value) -> Map.put(entry, "capacity_fraction", value)
      _value -> entry
    end
  end

  defp normalize_ground_network_time_field(entry, field, alias_field) do
    value = numeric_or_nil(Map.get(entry, field)) || numeric_or_nil(Map.get(entry, alias_field))
    entry = Map.delete(entry, alias_field)

    if is_number(value) do
      Map.put(entry, field, value)
    else
      Map.delete(entry, field)
    end
  end

  def ground_network_capacity_fraction(entry, default \\ 1.0) do
    capacity_fraction =
      numeric_or_nil(Map.get(entry, "capacity_fraction")) ||
        numeric_or_nil(Map.get(entry, "availability"))

    case capacity_fraction do
      value when is_number(value) -> clamp_unit_interval(value)
      _value -> default
    end
  end

  defp branch_ground_network_event_provenance(event, event_type) do
    %{
      "source" => "strategy_branch_event",
      "event_type" => event_type,
      "trust_boundary" =>
        Map.get(event, "trust_boundary") || get_in(event, ["provenance", "trust_boundary"]),
      "source_event_provenance" => Map.get(event, "provenance")
    }
    |> compact_map()
  end

  def ground_network_station_id(station) do
    Map.get(station, "ground_station_id") || Map.get(station, "station_id") ||
      Map.get(station, "id")
  end

  defp event_station_ids(event, station_ids) do
    case event_ground_station_id(event) do
      nil -> station_ids
      station_id -> [station_id]
    end
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp nested_ground_station_id(event) do
    get_in(event, ["source_window", "ground_station_id"]) ||
      get_in(event, ["source_window", "station_id"])
  end

  defp normalized_station_availability_token(value) when is_number(value) do
    if value < 1.0, do: "reduced_capacity", else: "available"
  end

  defp normalized_station_availability_token(value) do
    case encode_value(value) do
      value when is_binary(value) ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> canonical_station_availability_token()

      value ->
        value
    end
  end

  defp canonical_station_availability_token(value) when value in ["outage", "offline", "down"],
    do: "unavailable"

  defp canonical_station_availability_token(value), do: value

  defp dedupe_by_id_preserving_first(items) do
    {items, _seen_ids} =
      Enum.reduce(items, {[], MapSet.new()}, fn item, {items, seen_ids} ->
        id = item["id"]

        if MapSet.member?(seen_ids, id) do
          {items, seen_ids}
        else
          {[item | items], MapSet.put(seen_ids, id)}
        end
      end)

    items
    |> Enum.reverse()
    |> Enum.sort_by(& &1["id"])
  end

  defp unique_items_by_id(items) do
    items
    |> Enum.group_by(&Map.get(&1, "id"))
    |> Enum.reject(fn {id, _items} -> id in [nil, ""] end)
    |> Enum.flat_map(fn
      {_id, [item]} -> [item]
      {_id, _duplicates} -> []
    end)
    |> Enum.sort_by(& &1["id"])
  end

  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

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
