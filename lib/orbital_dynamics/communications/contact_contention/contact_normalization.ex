defmodule OrbitalDynamics.Communications.ContactContention.ContactNormalization do
  @moduledoc false

  def normalize(
        %{} = contact,
        unavailable_aliases,
        default_resolution_priority_fields,
        provider_direction_aliases
      ) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_contact_numeric_fields(default_resolution_priority_fields)
    |> normalize_station_calendar_status_fields(unavailable_aliases)
    |> normalize_activity_type_alias()
    |> normalize_contact_direction(provider_direction_aliases)
  end

  def normalize(
        contact,
        _unavailable_aliases,
        _default_resolution_priority_fields,
        _provider_direction_aliases
      ) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  def first_number(values), do: Enum.find_value(values, &numeric_or_nil/1)

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value) when is_boolean(value), do: value
  def stringify_keys(nil), do: nil
  def stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  def stringify_keys(value), do: value

  def normalize_station_calendar_status_fields(contact, unavailable_aliases) do
    contact
    |> normalize_status_field("availability", unavailable_aliases)
    |> normalize_status_field("status", unavailable_aliases)
    |> normalize_status_field("station_availability", unavailable_aliases)
    |> normalize_status_field("station_calendar_status", unavailable_aliases)
    |> normalize_status_field("station_contention_status", unavailable_aliases)
    |> normalize_status_field("reservation_status", unavailable_aliases)
    |> normalize_status_field("station_reservation_status", unavailable_aliases)
    |> normalize_status_field("reservation_match_status", unavailable_aliases)
    |> normalize_status_field("station_reservation_match_status", unavailable_aliases)
    |> normalize_status_list_field("station_calendar_overlap_availabilities", unavailable_aliases)
    |> normalize_status_list_field("station_calendar_reservation_statuses", unavailable_aliases)
    |> normalize_source_station_calendar_field(
      "source_station_calendar_entry",
      unavailable_aliases
    )
    |> normalize_source_station_calendar_field(
      "source_station_calendar_overlaps",
      unavailable_aliases
    )
  end

  def normalized_status_token(value, unavailable_aliases) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token(unavailable_aliases)
  end

  def normalized_status_token(value, unavailable_aliases) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalized_status_token(unavailable_aliases)
  end

  def normalized_status_token(value, _unavailable_aliases), do: value

  def normalize_direction(direction, _provider_direction_aliases)
      when direction in [nil, ""],
      do: nil

  def normalize_direction(direction, provider_direction_aliases) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "uplink" -> "uplink"
      "downlink" -> "downlink"
      "tracking" -> "tracking"
      "health_check" -> "health_check"
      "nil" -> nil
      "" -> nil
      value -> Map.get(provider_direction_aliases, value, value)
    end
  end

  def compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def encode_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 6)

  def encode_value(value), do: to_string(value)

  defp normalize_station_id(%{"ground_station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: contact

  defp normalize_station_id(%{"station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: Map.put(contact, "ground_station_id", station_id)

  defp normalize_station_id(contact) do
    case nested_station_id(contact) do
      nil -> contact
      station_id -> Map.put(contact, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(contact) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(contact, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp normalize_status_field(contact, field, unavailable_aliases) do
    case Map.fetch(contact, field) do
      {:ok, value} when value in [nil, ""] ->
        contact

      {:ok, value} ->
        Map.put(contact, field, normalized_status_token(value, unavailable_aliases))

      :error ->
        contact
    end
  end

  defp normalize_status_list_field(contact, field, unavailable_aliases) do
    case Map.fetch(contact, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token(&1, unavailable_aliases))
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(contact, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(contact, field, [normalized_status_token(value, unavailable_aliases)])

      _missing_or_empty ->
        contact
    end
  end

  defp normalize_source_station_calendar_field(contact, field, unavailable_aliases) do
    case Map.fetch(contact, field) do
      {:ok, values} when is_list(values) ->
        Map.put(
          contact,
          field,
          Enum.map(values, &normalize_source_station_calendar(&1, unavailable_aliases))
        )

      {:ok, value} ->
        Map.put(contact, field, normalize_source_station_calendar(value, unavailable_aliases))

      :error ->
        contact
    end
  end

  defp normalize_source_station_calendar(%{} = source, unavailable_aliases),
    do: normalize_station_calendar_status_fields(source, unavailable_aliases)

  defp normalize_source_station_calendar(value, _unavailable_aliases), do: value

  defp canonical_status_token(value, unavailable_aliases) do
    if value in unavailable_aliases, do: "unavailable", else: value
  end

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case first_number([Map.get(contact, canonical_key), Map.get(contact, alternate_key)]) do
      nil -> contact
      value -> Map.put(contact, canonical_key, value)
    end
  end

  defp normalize_contact_numeric_fields(contact, default_resolution_priority_fields) do
    ["score" | default_resolution_priority_fields]
    |> Enum.uniq()
    |> Enum.reduce(contact, &normalize_contact_numeric_field(&2, &1))
  end

  defp normalize_contact_numeric_field(contact, field) do
    case Map.fetch(contact, field) do
      {:ok, value} ->
        case numeric_or_nil(value) do
          number when is_number(number) -> Map.put(contact, field, number)
          _value -> contact
        end

      :error ->
        contact
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = contact) when not is_nil(type),
    do: contact

  defp normalize_activity_type_alias(%{"activity_type" => type} = contact)
       when is_binary(type) and type != "",
       do: Map.put(contact, "type", type)

  defp normalize_activity_type_alias(contact), do: contact

  defp normalize_contact_direction(%{"direction" => direction} = contact, aliases) do
    case normalize_direction(direction, aliases) do
      nil -> contact
      direction -> Map.put(contact, "direction", direction)
    end
  end

  defp normalize_contact_direction(%{"type" => "downlink"} = contact, _aliases),
    do: Map.put(contact, "direction", "downlink")

  defp normalize_contact_direction(%{"type" => "tracking"} = contact, _aliases),
    do: Map.put(contact, "direction", "tracking")

  defp normalize_contact_direction(%{"type" => "command"} = contact, _aliases),
    do: Map.put(contact, "direction", "command")

  defp normalize_contact_direction(%{"type" => "health_check"} = contact, _aliases),
    do: Map.put(contact, "direction", "health_check")

  defp normalize_contact_direction(contact, _aliases), do: contact

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
