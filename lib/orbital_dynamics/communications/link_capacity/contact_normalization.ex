defmodule OrbitalDynamics.Communications.LinkCapacity.ContactNormalization do
  @moduledoc false

  def normalize(%{} = contact, unavailable_aliases, provider_direction_aliases) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_station_calendar_status_fields(unavailable_aliases, provider_direction_aliases)
    |> normalize_activity_type_alias()
    |> normalize_direction_field("direction", provider_direction_aliases)
    |> normalize_direction_list_field("station_calendar_directions", provider_direction_aliases)
    |> normalize_throughput_model()
  end

  def normalize(contact, _unavailable_aliases, _provider_direction_aliases) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  def numeric_value(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_value(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  def numeric_value(_value), do: nil

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value) when is_boolean(value), do: value
  def stringify_keys(nil), do: nil
  def stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  def stringify_keys(value), do: value

  def compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

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

  def normalize_station_calendar_status_fields(
        row,
        unavailable_aliases,
        provider_direction_aliases
      ) do
    row
    |> normalize_status_field("availability", unavailable_aliases)
    |> normalize_status_field("status", unavailable_aliases)
    |> normalize_status_field("station_availability", unavailable_aliases)
    |> normalize_status_field("station_calendar_status", unavailable_aliases)
    |> normalize_status_field("reservation_status", unavailable_aliases)
    |> normalize_status_field("station_reservation_status", unavailable_aliases)
    |> normalize_status_field("reservation_match_status", unavailable_aliases)
    |> normalize_status_field("station_reservation_match_status", unavailable_aliases)
    |> normalize_status_list_field("station_calendar_overlap_availabilities", unavailable_aliases)
    |> normalize_status_list_field("station_calendar_reservation_statuses", unavailable_aliases)
    |> normalize_direction_list_field("directions", provider_direction_aliases)
    |> normalize_direction_list_field("station_calendar_directions", provider_direction_aliases)
    |> normalize_source_station_calendar_field(
      "source_station_calendar_entry",
      unavailable_aliases,
      provider_direction_aliases
    )
    |> normalize_source_station_calendar_field(
      "source_station_calendar_overlaps",
      unavailable_aliases,
      provider_direction_aliases
    )
  end

  defp normalize_status_field(row, field, unavailable_aliases) do
    case Map.fetch(row, field) do
      {:ok, value} when value in [nil, ""] ->
        row

      {:ok, value} ->
        Map.put(row, field, normalized_status_token(value, unavailable_aliases))

      :error ->
        row
    end
  end

  defp normalize_status_list_field(row, field, unavailable_aliases) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token(&1, unavailable_aliases))
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(row, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(row, field, [normalized_status_token(value, unavailable_aliases)])

      _missing_or_empty ->
        row
    end
  end

  defp normalize_source_station_calendar_field(
         row,
         field,
         unavailable_aliases,
         provider_direction_aliases
       ) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        Map.put(
          row,
          field,
          Enum.map(
            values,
            &normalize_source_station_calendar(
              &1,
              unavailable_aliases,
              provider_direction_aliases
            )
          )
        )

      {:ok, value} ->
        Map.put(
          row,
          field,
          normalize_source_station_calendar(
            value,
            unavailable_aliases,
            provider_direction_aliases
          )
        )

      :error ->
        row
    end
  end

  defp normalize_source_station_calendar(
         %{} = source,
         unavailable_aliases,
         provider_direction_aliases
       ),
       do:
         normalize_station_calendar_status_fields(
           source,
           unavailable_aliases,
           provider_direction_aliases
         )

  defp normalize_source_station_calendar(
         value,
         _unavailable_aliases,
         _provider_direction_aliases
       ),
       do: value

  defp normalize_direction_field(row, field, provider_direction_aliases) do
    case Map.fetch(row, field) do
      {:ok, value} when value in [nil, ""] ->
        row

      {:ok, value} ->
        case normalized_direction_token(value, provider_direction_aliases) do
          nil -> row
          direction -> Map.put(row, field, direction)
        end

      :error ->
        row
    end
  end

  defp normalize_direction_list_field(row, field, provider_direction_aliases) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        directions =
          values
          |> Enum.map(&normalized_direction_token(&1, provider_direction_aliases))
          |> Enum.reject(&is_nil/1)

        Map.put(row, field, directions)

      {:ok, value} when value not in [nil, ""] ->
        case normalized_direction_token(value, provider_direction_aliases) do
          nil -> row
          direction -> Map.put(row, field, [direction])
        end

      _missing_or_empty ->
        row
    end
  end

  def normalized_status_token(nil, _unavailable_aliases), do: nil

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

  defp canonical_status_token(value, unavailable_aliases) do
    if value in unavailable_aliases, do: "unavailable", else: value
  end

  def normalized_direction_token(value, _provider_direction_aliases)
      when value in [nil, ""],
      do: nil

  def normalized_direction_token(value, provider_direction_aliases) do
    value
    |> to_string()
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
      direction -> Map.get(provider_direction_aliases, direction, direction)
    end
  end

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case numeric_value(Map.get(contact, canonical_key)) ||
           numeric_value(Map.get(contact, alternate_key)) do
      value when is_number(value) -> Map.put(contact, canonical_key, value)
      _value -> contact
    end
  end

  defp normalize_activity_type_alias(%{"type" => type} = contact) when not is_nil(type),
    do: contact

  defp normalize_activity_type_alias(%{"activity_type" => type} = contact)
       when is_binary(type) and type != "",
       do: Map.put(contact, "type", type)

  defp normalize_activity_type_alias(contact), do: contact

  defp normalize_throughput_model(contact) do
    case Map.get(contact, "throughput_model") do
      %{} = model -> Map.put(contact, "throughput_model", stringify_keys(model))
      _model -> contact
    end
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
