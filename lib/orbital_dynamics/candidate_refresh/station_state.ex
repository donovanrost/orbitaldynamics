defmodule OrbitalDynamics.CandidateRefresh.StationState do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    StationAvailability,
    StationCapacity,
    StationProviderContention
  }

  def state(refresh, ground_station_id, starts_at_s, ends_at_s, direction, refresh_ground_network) do
    refresh
    |> refresh_ground_network.()
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&normalize_ground_network_station/1)
    |> Enum.filter(fn station ->
      station_id = ground_network_station_id(station)

      station_id == encode_value(ground_station_id) and
        station_direction_matches?(station, direction) and
        station_window_matches?(station, starts_at_s, ends_at_s)
    end)
    |> unambiguous_highest_severity_station_state()
  end

  def calendar_entry_id(station) do
    Map.get(station, "station_calendar_entry_id") || Map.get(station, "id") ||
      get_in(station, ["source_station_calendar_entry", "station_calendar_entry_id"]) ||
      get_in(station, ["source_station_calendar_entry", "id"]) ||
      Map.get(station, "reservation_id")
  end

  def calendar_provider_id(station) do
    Map.get(station, "station_calendar_provider_id") ||
      Map.get(station, "provider_id") ||
      get_in(station, ["source_station_calendar_entry", "station_calendar_provider_id"]) ||
      get_in(station, ["source_station_calendar_entry", "provider_id"]) ||
      get_in(station, ["provenance", "provider_id"])
  end

  def calendar_provider_entry_id(station) do
    Map.get(station, "station_calendar_provider_entry_id") ||
      Map.get(station, "provider_entry_id") ||
      get_in(station, ["source_station_calendar_entry", "station_calendar_provider_entry_id"]) ||
      get_in(station, ["source_station_calendar_entry", "provider_entry_id"]) ||
      calendar_entry_id(station)
  end

  def calendar_reservation_expires_at_s(stations, numeric_value_fun) when is_list(stations) do
    stations
    |> Enum.flat_map(&calendar_reservation_expires_at_s_candidates/1)
    |> normalize_number_list(numeric_value_fun)
  end

  def calendar_reservation_expires_at_s(station, numeric_value_fun) do
    station
    |> calendar_reservation_expires_at_s_candidates()
    |> normalize_number_list(numeric_value_fun)
  end

  def nonempty_directions(station) do
    case directions(station) do
      [] -> nil
      directions -> directions
    end
  end

  def nonempty_directions(station, encode_value_fun, normalize_direction_fun) do
    case directions(station, encode_value_fun, normalize_direction_fun) do
      [] -> nil
      directions -> directions
    end
  end

  def normalize_ground_network_station(station) do
    station
    |> normalize_ground_network_station_id()
    |> normalize_ground_network_station_field("availability")
    |> normalize_ground_network_station_field("status")
    |> normalize_ground_network_station_field("station_contention_status")
    |> normalize_ground_network_station_time("starts_at_s", "start_s")
    |> normalize_ground_network_station_time("ends_at_s", "end_s")
    |> normalize_ground_network_reservation_expires_at_s()
  end

  defp normalize_ground_network_station_id(%{"ground_station_id" => station_id} = station)
       when not is_nil(station_id),
       do: station

  defp normalize_ground_network_station_id(%{"station_id" => station_id} = station)
       when not is_nil(station_id),
       do: Map.put(station, "ground_station_id", station_id)

  defp normalize_ground_network_station_id(station) do
    case nested_station_id(station) do
      nil -> station
      station_id -> Map.put(station, "ground_station_id", station_id)
    end
  end

  defp normalize_ground_network_station_field(station, field) do
    case Map.fetch(station, field) do
      {:ok, value} when value in [nil, ""] ->
        station

      {:ok, value} ->
        value =
          value
          |> encode_value()
          |> StationAvailability.normalized_token()

        Map.put(station, field, value)

      :error ->
        station
    end
  end

  defp normalize_ground_network_station_time(station, canonical_key, alias_key) do
    case numeric_or_nil(Map.get(station, canonical_key)) ||
           numeric_or_nil(Map.get(station, alias_key)) do
      value when is_number(value) -> Map.put(station, canonical_key, value)
      _value -> station
    end
  end

  defp normalize_ground_network_reservation_expires_at_s(station) do
    [
      "reservation_expires_at_s",
      "station_reservation_expires_at_s",
      "reservation_hold_expires_at_s",
      "hold_expires_at_s",
      "expires_at_s",
      "expires_at"
    ]
    |> Enum.find_value(&(station |> Map.get(&1) |> numeric_or_nil()))
    |> case do
      value when is_number(value) -> Map.put(station, "reservation_expires_at_s", value)
      _value -> station
    end
  end

  defp ground_network_station_id(station) do
    Map.get(station, "ground_station_id") || Map.get(station, "station_id") ||
      Map.get(station, "id")
  end

  defp unambiguous_highest_severity_station_state([]), do: %{}

  defp unambiguous_highest_severity_station_state(stations) do
    reservations = Enum.filter(stations, &station_reserved?/1)

    stations
    |> Enum.group_by(&station_severity/1)
    |> Enum.max_by(fn {severity, _stations} -> severity end)
    |> elem(1)
    |> case do
      [station] ->
        station
        |> put_station_reservation_overlap(reservations)
        |> put_station_trust_context(stations)

      ambiguous_stations ->
        ambiguous_stations
        |> ambiguous_station_state(stations)
        |> put_station_trust_context(stations)
    end
  end

  defp ambiguous_station_state([station | _rest] = ambiguous_stations, stations) do
    ambiguous_entry_ids = station_entry_ids(ambiguous_stations)
    overlap_entry_ids = station_entry_ids(stations)

    %{
      "id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "station_calendar_entry_id" => ambiguous_station_entry_id(ambiguous_entry_ids),
      "ground_station_id" => ground_network_station_id(station),
      "status" => "ambiguous",
      "availability" => station_availability(station),
      "station_calendar_entry_ambiguous" => true,
      "station_calendar_ambiguous_entry_count" => length(ambiguous_stations),
      "station_calendar_ambiguous_entry_ids" => ambiguous_entry_ids,
      "station_calendar_overlap_count" => length(stations),
      "station_calendar_overlap_entry_ids" => overlap_entry_ids,
      "station_calendar_overlap_availabilities" =>
        stations |> Enum.map(&station_availability/1) |> Enum.uniq()
    }
    |> maybe_put(
      "capacity_fraction",
      unambiguous_capacity_fraction(ambiguous_stations)
    )
    |> put_ambiguous_station_reservation_context(stations)
  end

  defp station_entry_ids(stations) do
    stations
    |> Enum.with_index(1)
    |> Enum.map(fn {station, index} -> station_entry_id(station, index) end)
    |> Enum.sort()
  end

  defp station_entry_id(station, index) do
    Map.get(station, "id") || Map.get(station, "station_calendar_entry_id") ||
      Map.get(station, "reservation_id") || derived_station_entry_id(station, index)
  end

  defp derived_station_entry_id(station, index) do
    [
      "ground_network",
      ground_network_station_id(station) || "unknown_station",
      station_availability(station),
      Map.get(station, "starts_at_s", "open"),
      Map.get(station, "ends_at_s", "open"),
      index
    ]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp ambiguous_station_entry_id(entry_ids) do
    entry_ids
    |> then(&["ambiguous_station_calendar" | &1])
    |> Enum.join(":")
  end

  defp put_station_trust_context(station, stations) do
    trust_status = station_calendar_trust_boundary_status(stations)
    trust_boundary = station_calendar_trust_boundary(station)
    provenance = station_calendar_provenance(station)

    station
    |> Map.put("station_calendar_trust_boundary_status", trust_status)
    |> maybe_put("trust_boundary", trust_boundary)
    |> maybe_put("provenance", provenance)
    |> Map.put("source_station_calendar_entry", station)
    |> Map.put("source_station_calendar_overlaps", stations)
  end

  defp station_calendar_trust_boundary_status(stations) do
    if Enum.all?(stations, &(station_calendar_trust_boundary(&1) not in [nil, ""])),
      do: "declared",
      else: "missing"
  end

  defp station_calendar_trust_boundary(station) do
    Map.get(station, "trust_boundary") || get_in(station, ["provenance", "trust_boundary"])
  end

  defp station_calendar_provenance(%{"provenance" => provenance}) when is_map(provenance),
    do: provenance

  defp station_calendar_provenance(_station), do: nil

  defp unambiguous_capacity_fraction(stations) do
    stations
    |> Enum.map(&station_capacity_fraction/1)
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_capacity -> nil
    end
  end

  defp station_direction_matches?(station, direction) do
    case directions(station) do
      [] -> true
      directions -> normalize_direction(direction) in directions
    end
  end

  def directions(station) do
    directions(station, &encode_value/1, &normalize_direction/1)
  end

  def directions(station, encode_value_fun, normalize_direction_fun) do
    [
      Map.get(station, "directions"),
      Map.get(station, "station_calendar_directions"),
      Map.get(station, "direction"),
      get_in(station, ["source_station_calendar_entry", "directions"]),
      get_in(station, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(station, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(encode_value_fun)
    |> Enum.map(normalize_direction_fun)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_window_matches?(station, starts_at_s, ends_at_s) do
    case {Map.get(station, "starts_at_s"), Map.get(station, "ends_at_s")} do
      {nil, nil} ->
        true

      {start_s, end_s} when is_number(start_s) and is_number(end_s) ->
        ends_at_s > start_s and starts_at_s < end_s

      _other ->
        true
    end
  end

  defp station_severity(station) do
    cond do
      station_unavailable?(station) -> 4
      station_reserved?(station) -> 3
      station_capacity_fraction(station) < 1.0 -> 2
      true -> 1
    end
  end

  defp put_station_reservation_overlap(station, []), do: station

  defp put_station_reservation_overlap(station, reservations) do
    reservation_ids =
      reservations
      |> Enum.flat_map(fn station ->
        [Map.get(station, "reservation_id")] ++
          List.wrap(station["station_calendar_reservation_ids"])
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    reserved_by =
      reservations
      |> Enum.flat_map(fn station ->
        [Map.get(station, "reserved_by")] ++ List.wrap(station["station_calendar_reserved_by"])
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    reservation_statuses =
      reservations
      |> Enum.flat_map(fn station ->
        [station["reservation_status"]] ++
          List.wrap(station["station_calendar_reservation_statuses"])
      end)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> case do
        [] -> ["reserved"]
        statuses -> statuses
      end
      |> Enum.uniq()
      |> Enum.sort()

    reservation_expires_at_s =
      calendar_reservation_expires_at_s(reservations, &numeric_or_nil/1) || []

    station
    |> Map.put_new("station_contention_status", "reserved_overlap")
    |> put_singular_reservation_field("reservation_id", reservation_ids)
    |> put_singular_reservation_field("reserved_by", reserved_by)
    |> put_singular_reservation_field("reservation_status", reservation_statuses)
    |> put_singular_reservation_field("reservation_expires_at_s", reservation_expires_at_s)
    |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
    |> maybe_put_nonempty("station_calendar_reservation_ids", reservation_ids)
    |> maybe_put_nonempty("station_calendar_reserved_by", reserved_by)
    |> maybe_put_nonempty("station_calendar_reservation_statuses", reservation_statuses)
    |> maybe_put_nonempty("station_calendar_reservation_expires_at_s", reservation_expires_at_s)
  end

  defp put_singular_reservation_field(station, field, [value]) do
    Map.put_new(station, field, value)
  end

  defp put_singular_reservation_field(station, _field, _values), do: station

  defp put_ambiguous_station_reservation_context(station, stations) do
    reservations = Enum.filter(stations, &station_reserved?/1)

    case reservations do
      [] ->
        station

      reservations ->
        reservation_ids =
          reservations
          |> Enum.flat_map(fn station ->
            [Map.get(station, "reservation_id")] ++
              List.wrap(station["station_calendar_reservation_ids"])
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        reserved_by =
          reservations
          |> Enum.flat_map(fn station ->
            [Map.get(station, "reserved_by")] ++
              List.wrap(station["station_calendar_reserved_by"])
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort()

        reservation_statuses =
          reservations
          |> Enum.flat_map(fn station ->
            [station["reservation_status"]] ++
              List.wrap(station["station_calendar_reservation_statuses"])
          end)
          |> Enum.reject(&(&1 in [nil, ""]))
          |> case do
            [] -> ["reserved"]
            statuses -> statuses
          end
          |> Enum.uniq()
          |> Enum.sort()

        reservation_expires_at_s =
          calendar_reservation_expires_at_s(reservations, &numeric_or_nil/1) || []

        station
        |> Map.put_new("station_contention_status", "reserved_overlap")
        |> Map.put("station_calendar_reservation_overlap_count", length(reservations))
        |> maybe_put_nonempty("station_calendar_reservation_ids", reservation_ids)
        |> maybe_put_nonempty("station_calendar_reserved_by", reserved_by)
        |> maybe_put_nonempty("station_calendar_reservation_statuses", reservation_statuses)
        |> maybe_put_nonempty(
          "station_calendar_reservation_expires_at_s",
          reservation_expires_at_s
        )
    end
  end

  defp maybe_put(map, _key, value) when value in [nil, ""], do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_nonempty(map, _key, value) when value in [nil, "", []], do: map
  defp maybe_put_nonempty(map, key, value), do: Map.put(map, key, value)

  defp station_unavailable?(station) do
    StationAvailability.unavailable?(station, &encode_value/1)
  end

  defp station_reserved?(station) do
    StationAvailability.reserved?(station, &encode_value/1)
  end

  defp station_availability(station) do
    StationAvailability.availability(
      station,
      &encode_value/1,
      &station_capacity_fraction/1
    )
  end

  defp station_capacity_fraction(station) do
    StationCapacity.fraction(station, &numeric_or_nil/1)
  end

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "cmd" -> "command"
      "commanding" -> "command"
      "commands" -> "command"
      "sband_command" -> "command"
      "s_band_command" -> "command"
      "up" -> "uplink"
      "up_link" -> "uplink"
      "dl" -> "downlink"
      "down" -> "downlink"
      "downlinking" -> "downlink"
      "down_link" -> "downlink"
      "track" -> "tracking"
      "track_ing" -> "tracking"
      "tracking_pass" -> "tracking"
      "health" -> "health_check"
      "healthcheck" -> "health_check"
      "health_check_window" -> "health_check"
      "nil" -> nil
      "" -> nil
      value -> value
    end
  end

  defp nested_station_id(station) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(station, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp numeric_or_nil(value) when is_number(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

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

  defp normalize_number_list(nil, _numeric_value_fun), do: nil

  defp normalize_number_list(values, numeric_value_fun) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(numeric_value_fun)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value, numeric_value_fun),
    do: normalize_number_list([value], numeric_value_fun)

  defp calendar_reservation_expires_at_s_candidates(%{} = station) do
    [
      Map.get(station, "station_calendar_reservation_expires_at_s"),
      Map.get(station, "station_reservation_expires_at_s"),
      Map.get(station, "reservation_expires_at_s"),
      StationProviderContention.values(station, "reservation_expires_at_s"),
      get_in(station, [
        "source_station_calendar_entry",
        "station_calendar_reservation_expires_at_s"
      ]),
      get_in(station, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "reservation_hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "hold_expires_at_s"]),
      get_in(station, ["source_station_calendar_entry", "expires_at_s"]),
      source_station_calendar_overlap_reservation_expires_at_s(station)
    ]
  end

  defp calendar_reservation_expires_at_s_candidates(_station), do: []

  defp source_station_calendar_overlap_reservation_expires_at_s(%{
         "source_station_calendar_overlaps" => overlaps
       })
       when is_list(overlaps) do
    overlaps
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(&calendar_reservation_expires_at_s_candidates/1)
  end

  defp source_station_calendar_overlap_reservation_expires_at_s(_station), do: []
end
