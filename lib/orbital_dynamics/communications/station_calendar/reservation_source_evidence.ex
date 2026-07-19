defmodule OrbitalDynamics.Communications.StationCalendar.ReservationSourceEvidence do
  @moduledoc false

  alias OrbitalDynamics.Communications.StationCalendar.Availability

  def affected_contact?(row) do
    Map.get(row, "station_contention_status") == "reserved_overlap" or
      non_empty_string?(Map.get(row, "station_reservation_match_status")) or
      non_empty_list?(Map.get(row, "station_calendar_reservation_ids"))
  end

  def provider_contention_group?(row) do
    non_empty_list?(Map.get(row, "reservation_ids")) or
      Enum.member?(Map.get(row, "availabilities", []), "reserved")
  end

  def normalize_affected_contact(row) do
    row = stringify_keys(row)

    if affected_contact?(row) do
      row
    else
      reserved_sources = reservation_source_entries(row)

      reservation_ids =
        reserved_sources |> Enum.map(&source_reservation_id/1) |> compact_sorted_values()

      row
      |> put_reservation_source_identity(reserved_sources)
      |> put_reservation_source_overlap(reserved_sources, reservation_ids)
    end
  end

  defp put_reservation_source_identity(row, reserved_sources) do
    source_entry = row["source_station_calendar_entry"]
    first_reserved_source = List.first(reserved_sources)

    row
    |> maybe_put(
      "station_calendar_entry_id",
      row["station_calendar_entry_id"] ||
        source_station_calendar_id(source_entry) ||
        source_station_calendar_id(first_reserved_source)
    )
    |> maybe_put(
      "station_calendar_provider_id",
      row["station_calendar_provider_id"] ||
        source_station_calendar_provider_id(source_entry) ||
        source_station_calendar_provider_id(first_reserved_source)
    )
    |> maybe_put(
      "station_calendar_provider_entry_id",
      row["station_calendar_provider_entry_id"] ||
        source_station_calendar_provider_entry_id(source_entry) ||
        source_station_calendar_provider_entry_id(first_reserved_source)
    )
  end

  defp put_reservation_source_overlap(row, _reserved_sources, []), do: row

  defp put_reservation_source_overlap(row, reserved_sources, reservation_ids) do
    reserved_by = reserved_sources |> Enum.map(&source_reserved_by/1) |> compact_sorted_values()

    reservation_statuses =
      reserved_sources |> Enum.map(&source_reservation_status/1) |> compact_sorted_values()

    row
    |> Map.put_new("station_contention_status", "reserved_overlap")
    |> Map.put_new(
      "station_reservation_match_status",
      source_reservation_match_status(reserved_sources)
    )
    |> Map.put_new("station_reservation_id", List.first(reservation_ids))
    |> maybe_put("station_reserved_by", List.first(reserved_by))
    |> maybe_put("station_reservation_status", List.first(reservation_statuses))
    |> Map.put_new("station_calendar_reservation_overlap_count", length(reservation_ids))
    |> Map.put_new("station_calendar_reservation_ids", reservation_ids)
    |> maybe_put_list("station_calendar_reserved_by", reserved_by)
    |> maybe_put_list("station_calendar_reservation_statuses", reservation_statuses)
    |> maybe_put_list(
      "station_calendar_reservation_expires_at_s",
      Enum.map(reserved_sources, &source_reservation_expires_at_s/1)
    )
    |> Map.put_new("required_operator_action", "review_station_reservation_overlap")
  end

  defp reservation_source_entries(row) do
    [row["source_station_calendar_entry"] | List.wrap(row["source_station_calendar_overlaps"])]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&normalize_reservation_source_entry/1)
    |> Enum.filter(&source_reservation_entry?/1)
  end

  defp normalize_reservation_source_entry(source) do
    source = stringify_keys(source)
    availability = station_availability(source)

    source
    |> Map.put("availability", availability)
    |> maybe_put("reservation_status", source_reservation_status(source))
  end

  defp source_reservation_entry?(source) do
    source["availability"] == "reserved" or
      non_empty_string?(source["reservation_id"]) or
      non_empty_string?(source["reservation_hold_id"]) or
      non_empty_string?(source["hold_id"])
  end

  defp source_reservation_id(source) do
    first_present_value(source, ["reservation_id", "reservation_hold_id", "hold_id"]) ||
      if(source["availability"] == "reserved", do: source_station_calendar_id(source))
  end

  defp source_station_calendar_id(%{} = source),
    do: first_present_value(source, ["id", "entry_id", "station_calendar_entry_id"])

  defp source_station_calendar_id(_source), do: nil

  defp source_station_calendar_provider_id(%{} = source) do
    first_present_value(source, ["provider_id", "station_calendar_provider_id"]) ||
      get_in(source, ["provenance", "provider_id"])
  end

  defp source_station_calendar_provider_id(_source), do: nil

  defp source_station_calendar_provider_entry_id(%{} = source) do
    first_present_value(source, [
      "provider_entry_id",
      "station_calendar_provider_entry_id",
      "id"
    ])
  end

  defp source_station_calendar_provider_entry_id(_source), do: nil

  defp source_reserved_by(source),
    do: first_present_value(source, ["reserved_by", "held_by", "hold_owner"])

  defp source_reservation_status(source) do
    source
    |> first_present_value(["reservation_status", "hold_status"])
    |> normalize_status_value()
  end

  defp source_reservation_match_status(reserved_sources) do
    reserved_sources
    |> Enum.map(
      &first_present_value(&1, ["station_reservation_match_status", "reservation_match_status"])
    )
    |> Enum.map(&normalize_status_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [status] -> status
      [] -> "overlap"
      _statuses -> "ambiguous"
    end
  end

  defp source_reservation_expires_at_s(source) do
    source
    |> first_present_value([
      "station_reservation_expires_at_s",
      "reservation_expires_at_s",
      "reservation_hold_expires_at_s",
      "hold_expires_at_s",
      "expires_at_s"
    ])
    |> numeric_or_nil()
  end

  defp non_empty_list?(value), do: is_list(value) and value != []

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp compact_sorted_values(values) do
    values
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_availability(station), do: Availability.station_value(station)

  defp normalize_status_value(value), do: Availability.normalize_status(value)

  defp first_present_value(map, keys) do
    keys
    |> Enum.map(&Map.get(map, &1))
    |> Enum.find(fn value -> value not in [nil, ""] end)
  end

  defp numeric_or_nil(value), do: Availability.numeric_or_nil(value)

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

  defp maybe_put_list(map, key, values) do
    values =
      values
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    case values do
      [] -> map
      values -> Map.put(map, key, values)
    end
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
