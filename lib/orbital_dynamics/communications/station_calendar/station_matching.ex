defmodule OrbitalDynamics.Communications.StationCalendar.StationMatching do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.ProviderCounteroffer

  @command_contact_directions ~w(command uplink)
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

  def command_contact_directions, do: @command_contact_directions
  def provider_direction_aliases, do: @provider_direction_aliases

  def normalize_contact(contact) do
    contact
    |> stringify_keys()
    |> normalize_contact_station_id()
  end

  def matches(contact, entries) do
    entries
    |> Enum.filter(&(Map.get(&1, "ground_station_id") == contact["ground_station_id"]))
    |> Enum.filter(&station_calendar_entry_affects_contact?(&1, contact))
    |> Enum.sort_by(&priority/1)
  end

  def applied_entry([entry | _rest] = matches) do
    top_priority = priority(entry)

    top_entries =
      matches
      |> Enum.filter(&(priority(&1) == top_priority))
      |> Enum.sort_by(& &1["id"])

    case top_entries do
      [top_entry] -> top_entry
      ambiguous_entries -> ambiguous_station_calendar_entry(ambiguous_entries)
    end
  end

  def contact_row?(contact) do
    contact = normalize_contact(contact)

    (Map.get(contact, "type") in [
       "downlink",
       "planned_contact",
       "contact",
       "command",
       "tracking",
       "health_check"
     ] or
       Map.get(contact, "direction") in [
         "downlink",
         "uplink",
         "command",
         "tracking",
         "health_check"
       ]) and
      not is_nil(Map.get(contact, "ground_station_id"))
  end

  def priority(%{"availability" => availability})
      when availability in ["unavailable", "maintenance"],
      do: 0

  def priority(%{"availability" => "reserved"}), do: 1
  def priority(%{"availability" => "reduced_capacity"}), do: 2
  def priority(_entry), do: 3

  defp ambiguous_station_calendar_entry([entry | _rest] = entries) do
    entry_ids = Enum.map(entries, & &1["id"])

    %{
      "id" => ambiguous_station_calendar_entry_id(entry_ids),
      "ground_station_id" => entry["ground_station_id"],
      "starts_at_s" => nil,
      "ends_at_s" => nil,
      "status" => "ambiguous",
      "availability" => entry["availability"],
      "station_calendar_entry_ambiguous" => true,
      "station_calendar_ambiguous_entry_count" => length(entries),
      "station_calendar_ambiguous_entry_ids" => entry_ids
    }
    |> maybe_put("directions", unambiguous_directions(entries))
    |> maybe_put("capacity_fraction", unambiguous_capacity_fraction(entries))
  end

  defp ambiguous_station_calendar_entry_id(entry_ids) do
    entry_ids
    |> Enum.map(&encode_value/1)
    |> then(&["ambiguous_station_calendar" | &1])
    |> Enum.join(":")
  end

  defp unambiguous_capacity_fraction(entries) do
    entries
    |> Enum.map(& &1["capacity_fraction"])
    |> Enum.uniq()
    |> case do
      [capacity_fraction] -> capacity_fraction
      _ambiguous_capacity -> nil
    end
  end

  defp unambiguous_directions(entries) do
    entries
    |> Enum.map(&Map.get(&1, "directions", []))
    |> Enum.uniq()
    |> case do
      [directions] -> directions
      _ambiguous_directions -> []
    end
  end

  defp station_calendar_entry_affects_contact?(entry, contact) do
    contact_row?(contact) and
      station_calendar_direction_matches?(entry, contact) and
      window_overlaps?(
        Map.get(entry, "starts_at_s"),
        Map.get(entry, "ends_at_s"),
        contact["starts_at_s"] || contact["start_s"],
        contact["ends_at_s"] || contact["end_s"]
      ) and
      (Map.get(entry, "availability") != "available" or ProviderCounteroffer.entry?(entry))
  end

  defp station_calendar_direction_matches?(entry, contact) do
    case Map.get(entry, "directions", []) do
      [] -> true
      directions -> Enum.any?(directions, &compatible_station_calendar_direction?(&1, contact))
    end
  end

  defp compatible_station_calendar_direction?(entry_direction, contact) do
    contact_direction = contact_direction(contact)

    entry_direction == contact_direction or
      (entry_direction in @command_contact_directions and
         contact_direction in @command_contact_directions)
  end

  def contact_direction(contact) do
    direction = Map.get(contact, "direction")
    type = Map.get(contact, "type") || Map.get(contact, "activity_type")

    cond do
      direction in [nil, ""] and type == "command" -> "command"
      direction in [nil, ""] and type == "health_check" -> "health_check"
      direction in [nil, ""] and type == "tracking" -> "tracking"
      direction in [nil, ""] and type in ["downlink", "planned_contact", "contact"] -> "downlink"
      true -> normalize_direction(direction)
    end
  end

  defp normalize_contact_station_id(%{"ground_station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: contact

  defp normalize_contact_station_id(%{"station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: Map.put(contact, "ground_station_id", station_id)

  defp normalize_contact_station_id(contact), do: contact

  defp window_overlaps?(nil, nil, _starts_at_s, _ends_at_s), do: true

  defp window_overlaps?(nil, entry_end, contact_start, _contact_end),
    do: contact_start < entry_end

  defp window_overlaps?(entry_start, nil, _contact_start, contact_end),
    do: entry_start < contact_end

  defp window_overlaps?(entry_start, entry_end, contact_start, contact_end)
       when is_number(entry_start) and is_number(entry_end) and is_number(contact_start) and
              is_number(contact_end) do
    contact_start < entry_end and entry_start < contact_end
  end

  defp window_overlaps?(_entry_start, _entry_end, _contact_start, _contact_end), do: false

  def normalize_direction(direction) when direction in [nil, ""], do: nil

  def normalize_direction(direction) do
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

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  defp encode_value(value), do: to_string(value)
end
