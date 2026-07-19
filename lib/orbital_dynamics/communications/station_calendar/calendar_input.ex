defmodule OrbitalDynamics.Communications.StationCalendar.CalendarInput do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.Availability
  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def to_ground_network(provider) when is_map(provider) do
    provider = stringify_keys(provider)

    provider_id =
      provider
      |> Map.get("provider_id", Map.get(provider, "id"))
      |> stable_provider_id!("provider_id")

    trust_boundary = provider_trust_boundary(provider)
    entries = provider_entries!(provider)

    Enum.map(entries, &normalize_entry(&1, provider_id, trust_boundary))
  end

  def to_ground_network(providers) when is_list(providers) do
    Enum.flat_map(providers, &to_ground_network/1)
  end

  def to_ground_network(_provider),
    do: raise(ArgumentError, "station calendar provider must be an object or list")

  defp provider_entries!(provider) do
    entries =
      Map.get(provider, "entries") || Map.get(provider, "station_calendar") ||
        Map.get(provider, "ground_network")

    if is_list(entries) do
      Enum.map(entries, &stringify_keys/1)
    else
      raise ArgumentError, "station calendar provider entries must be a list"
    end
  end

  defp provider_trust_boundary(provider) do
    Map.get(provider, "trust_boundary") || get_in(provider, ["provenance", "trust_boundary"])
  end

  defp normalize_entry(entry, provider_id, trust_boundary) when is_map(entry) do
    ground_station_id =
      entry
      |> Map.get("ground_station_id", Map.get(entry, "station_id"))
      |> stable_provider_id!("ground_station_id")

    entry_id = entry |> Map.get("id") |> stable_provider_id!("id")

    reservation_id =
      entry
      |> first_present_value(["reservation_id", "reservation_hold_id", "hold_id"])
      |> stable_provider_id!("reservation_id")

    reservation_expires_at_s = reservation_expires_at_s(entry)
    raw_availability = Map.get(entry, "availability") || Map.get(entry, "status", "available")
    reservation_status = provider_reservation_status(entry, raw_availability)

    capacity_fraction =
      entry
      |> normalized_capacity_fraction(raw_availability)
      |> validate_station_capacity_fraction!()

    availability = normalized_availability(raw_availability, capacity_fraction)
    capacity_pack_capacity_fraction = normalized_capacity_pack_capacity_fraction(entry)
    starts_at_s = numeric_or_nil(Map.get(entry, "starts_at_s") || Map.get(entry, "start_s"))
    ends_at_s = numeric_or_nil(Map.get(entry, "ends_at_s") || Map.get(entry, "end_s"))

    cond do
      ground_station_id in [nil, ""] ->
        raise ArgumentError, "station calendar entry ground_station_id is required"

      availability not in Availability.values() ->
        raise ArgumentError,
              "station calendar availability must be one of #{inspect(Availability.values())}"

      not valid_interval?(starts_at_s, ends_at_s) ->
        raise ArgumentError,
              "station calendar interval must have ends_at_s greater than starts_at_s"

      true ->
        %{
          "id" =>
            entry_id ||
              station_calendar_entry_id(provider_id, ground_station_id, starts_at_s, ends_at_s),
          "provider_id" => provider_id,
          "provider_entry_id" =>
            entry_id ||
              station_calendar_entry_id(provider_id, ground_station_id, starts_at_s, ends_at_s),
          "ground_station_id" => ground_station_id,
          "status" => availability,
          "availability" => availability,
          "capacity_pack_capacity_fraction" => capacity_pack_capacity_fraction,
          "capacity_fraction" => capacity_fraction,
          "reservation_id" => reservation_id,
          "reservation_expires_at_s" => reservation_expires_at_s,
          "reserved_by" => provider_reserved_by(entry),
          "reservation_status" => reservation_status,
          "provider_counteroffer_id" => provider_counteroffer_id(entry),
          "provider_counteroffer_status" => provider_counteroffer_status(entry),
          "provider_counteroffer_negotiation_state" =>
            provider_counteroffer_negotiation_state(entry),
          "provider_counteroffer_reason_code" => provider_counteroffer_reason_code(entry),
          "provider_counteroffer_cost_delta" => provider_counteroffer_cost_delta(entry),
          "provider_counteroffer_lock_deadline_s" => provider_counteroffer_lock_deadline_s(entry),
          "provider_counteroffer_starts_at_s" => provider_counteroffer_starts_at_s(entry),
          "provider_counteroffer_ends_at_s" => provider_counteroffer_ends_at_s(entry),
          "directions" => station_calendar_entry_directions(entry),
          "starts_at_s" => starts_at_s,
          "ends_at_s" => ends_at_s,
          "provenance" => %{
            "source" => "station_calendar_provider",
            "provider_id" => provider_id || "declared",
            "trust_boundary" => trust_boundary
          }
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
    end
  end

  defp normalize_entry(_entry, _provider_id, _trust_boundary),
    do: raise(ArgumentError, "station calendar entry must be an object")

  def normalize(nil), do: []

  def normalize(%{"schema_contract" => "station_calendar_provider.v1"} = provider),
    do: provider |> to_ground_network() |> normalize()

  def normalize(%{schema_contract: "station_calendar_provider.v1"} = provider),
    do: provider |> to_ground_network() |> normalize()

  def normalize(%{} = provider) do
    provider
    |> stringify_keys()
    |> provider_entries!()
    |> normalize()
  end

  def normalize(entries) when is_list(entries) do
    entries
    |> Enum.flat_map(&normalize_entry_or_provider/1)
    |> Enum.filter(&station_calendar_entry?/1)
    |> Enum.map(&normalize_station_calendar_entry/1)
    |> Enum.sort_by(&{&1["ground_station_id"], &1["starts_at_s"] || 0.0, &1["id"]})
  end

  def normalize(_station_calendar),
    do: raise(ArgumentError, "station calendar must be a list or provider object")

  defp normalize_entry_or_provider(%{} = entry) do
    entry = stringify_keys(entry)

    if station_calendar_provider_artifact?(entry) do
      to_ground_network(entry)
    else
      [entry]
    end
  end

  defp normalize_entry_or_provider(_entry), do: []

  defp station_calendar_provider_artifact?(%{
         "schema_contract" => "station_calendar_provider.v1"
       }),
       do: true

  defp station_calendar_provider_artifact?(_entry), do: false

  defp station_calendar_entry?(%{} = entry) do
    not is_nil(
      Map.get(entry, "ground_station_id") || Map.get(entry, "station_id") || Map.get(entry, "id")
    )
  end

  defp station_calendar_entry?(_entry), do: false

  defp normalize_station_calendar_entry(entry) do
    ground_station_id =
      Map.get(entry, "ground_station_id") || Map.get(entry, "station_id") || Map.get(entry, "id")

    starts_at_s = numeric_or_nil(Map.get(entry, "starts_at_s") || Map.get(entry, "start_s"))
    ends_at_s = numeric_or_nil(Map.get(entry, "ends_at_s") || Map.get(entry, "end_s"))
    capacity_fraction = station_capacity_fraction(entry)
    capacity_pack_capacity_fraction = normalized_capacity_pack_capacity_fraction(entry)
    status = station_calendar_status(entry, capacity_fraction)

    %{
      "id" =>
        Map.get(entry, "id") ||
          station_calendar_entry_id("declared", ground_station_id, starts_at_s, ends_at_s),
      "ground_station_id" => ground_station_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "status" => status,
      "capacity_pack_capacity_fraction" => capacity_pack_capacity_fraction,
      "capacity_fraction" => capacity_fraction,
      "availability" =>
        station_availability(
          entry
          |> Map.put("status", status)
          |> Map.put("capacity_fraction", capacity_fraction)
        ),
      "provider_id" =>
        Map.get(entry, "provider_id") || get_in(entry, ["provenance", "provider_id"]),
      "provider_entry_id" => Map.get(entry, "provider_entry_id") || Map.get(entry, "id"),
      "reservation_id" =>
        first_present_value(entry, ["reservation_id", "reservation_hold_id", "hold_id"]),
      "reservation_expires_at_s" => reservation_expires_at_s(entry),
      "reserved_by" => provider_reserved_by(entry),
      "reservation_status" =>
        provider_reservation_status(
          entry,
          Map.get(entry, "availability") || Map.get(entry, "status")
        ),
      "provider_counteroffer_id" => provider_counteroffer_id(entry),
      "provider_counteroffer_status" => provider_counteroffer_status(entry),
      "provider_counteroffer_negotiation_state" => provider_counteroffer_negotiation_state(entry),
      "provider_counteroffer_reason_code" => provider_counteroffer_reason_code(entry),
      "provider_counteroffer_cost_delta" => provider_counteroffer_cost_delta(entry),
      "provider_counteroffer_lock_deadline_s" => provider_counteroffer_lock_deadline_s(entry),
      "provider_counteroffer_starts_at_s" => provider_counteroffer_starts_at_s(entry),
      "provider_counteroffer_ends_at_s" => provider_counteroffer_ends_at_s(entry),
      "directions" => station_calendar_entry_directions(entry),
      "provenance" => Map.get(entry, "provenance"),
      "trust_boundary" => Map.get(entry, "trust_boundary"),
      "source_contact_allocation" => Map.get(entry, "source_contact_allocation")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp station_calendar_status(entry, capacity_fraction) do
    case {Map.get(entry, "status"), Map.get(entry, "availability")} do
      {nil, nil} ->
        "available"

      {nil, availability} when is_number(availability) ->
        normalized_availability(availability, capacity_fraction)

      {nil, availability} ->
        normalized_availability(availability, capacity_fraction)

      {status, _availability} ->
        normalized_availability(status, capacity_fraction)
    end
  end

  defp reservation_expires_at_s(entry) do
    entry
    |> first_present_value([
      "reservation_expires_at_s",
      "reservation_hold_expires_at_s",
      "hold_expires_at_s",
      "expires_at_s",
      "expires_at",
      "valid_until_s"
    ])
    |> numeric_or_nil()
  end

  defp provider_counteroffer_id(entry) do
    ProviderCounteroffer.id(entry)
  end

  defp provider_counteroffer_status(entry) do
    ProviderCounteroffer.status(entry)
  end

  defp provider_counteroffer_negotiation_state(%{} = entry) do
    ProviderCounteroffer.negotiation_state(entry)
  end

  defp provider_counteroffer_reason_code(entry) do
    ProviderCounteroffer.reason_code(entry)
  end

  defp provider_counteroffer_cost_delta(entry) do
    ProviderCounteroffer.cost_delta(entry)
  end

  defp provider_counteroffer_lock_deadline_s(entry) do
    ProviderCounteroffer.lock_deadline_s(entry)
  end

  defp provider_counteroffer_starts_at_s(entry) do
    ProviderCounteroffer.starts_at_s(entry)
  end

  defp provider_counteroffer_ends_at_s(entry) do
    ProviderCounteroffer.ends_at_s(entry)
  end

  defp station_calendar_entry_directions(entry) do
    [
      Map.get(entry, "directions"),
      Map.get(entry, "station_calendar_directions"),
      Map.get(entry, "direction")
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> then(fn
      "" -> nil
      value -> Map.get(@provider_direction_aliases, value, value)
    end)
  end

  defp station_capacity_fraction(station), do: Availability.capacity_fraction(station)

  defp station_availability(station), do: Availability.station_value(station)

  defp normalized_availability(value, capacity_fraction),
    do: Availability.normalize(value, capacity_fraction)

  defp provider_reserved_by(entry) do
    first_present_value(entry, ["reserved_by", "held_by", "hold_owner"])
  end

  defp provider_reservation_status(entry, raw_availability) do
    first_present_value(entry, ["reservation_status", "hold_status"]) ||
      default_reservation_status(raw_availability)
  end

  defp default_reservation_status(raw_availability),
    do: Availability.default_reservation_status(raw_availability)

  defp normalized_capacity_fraction(entry, raw_availability),
    do: Availability.normalized_capacity_fraction(entry, raw_availability)

  defp normalized_capacity_pack_capacity_fraction(entry),
    do: Availability.normalized_capacity_pack_capacity_fraction(entry)

  defp validate_station_capacity_fraction!(value),
    do: Availability.validate_capacity_fraction!(value)

  defp first_present_value(map, keys) do
    keys
    |> Enum.map(&Map.get(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp valid_interval?(nil, nil), do: true
  defp valid_interval?(start_s, nil) when is_number(start_s), do: true
  defp valid_interval?(nil, end_s) when is_number(end_s), do: true

  defp valid_interval?(start_s, end_s) when is_number(start_s) and is_number(end_s),
    do: end_s > start_s

  defp valid_interval?(_start_s, _end_s), do: false

  defp station_calendar_entry_id(provider_id, ground_station_id, starts_at_s, ends_at_s) do
    [provider_id || "declared", ground_station_id, starts_at_s || "open", ends_at_s || "open"]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_provider_id!(value, _field) when value in [nil, ""], do: nil

  defp stable_provider_id!(value, field) when is_binary(value) do
    if stable_id?(value) do
      value
    else
      raise ArgumentError, "station calendar #{field} must match stable ID pattern"
    end
  end

  defp stable_provider_id!(value, field) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_provider_id!(field)
  end

  defp stable_provider_id!(value, field) when is_integer(value) do
    value
    |> Integer.to_string()
    |> stable_provider_id!(field)
  end

  defp stable_provider_id!(_value, field) do
    raise ArgumentError, "station calendar #{field} must match stable ID pattern"
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)

  defp numeric_or_nil(value), do: Availability.numeric_or_nil(value)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 6)
  defp encode_value(value), do: to_string(value)
end
