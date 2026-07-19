defmodule OrbitalDynamics.Communications.ContactAllocation.ContactNormalization do
  @moduledoc false

  def normalize(%{} = contact, {unavailable_aliases, direction_aliases}, stringify, numeric) do
    contact
    |> stringify.()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s", numeric)
    |> normalize_contact_time("ends_at_s", "end_s", numeric)
    |> normalize_source_window()
    |> normalize_station_calendar_status_fields(unavailable_aliases)
    |> normalize_activity_type_alias()
    |> normalize_contact_direction(direction_aliases)
  end

  def normalize(contact, _policy, _stringify, _numeric) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  defp normalize_station_id(%{"ground_station_id" => station_id} = contact)
       when not is_nil(station_id),
       do: contact

  defp normalize_station_id(%{"station_id" => station_id} = contact) when not is_nil(station_id),
    do: Map.put(contact, "ground_station_id", station_id)

  defp normalize_station_id(contact) do
    case nested_station_id(contact) do
      nil -> contact
      station_id -> Map.put(contact, "ground_station_id", station_id)
    end
  end

  defp normalize_source_window(%{"source_window" => %{} = source_window} = contact) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", Map.get(contact, "source_window_kind"))
  end

  defp normalize_source_window(
         %{"metadata" => %{"source_window" => %{} = source_window}} = contact
       ) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", get_in(contact, ["metadata", "source_window_kind"]))
  end

  defp normalize_source_window(
         %{"activity_context" => %{"source_window" => %{} = source_window}} = contact
       ) do
    source_window = normalize_source_window_payload(source_window)

    contact
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present(
      "source_window_type",
      get_in(contact, ["activity_context", "source_window_kind"])
    )
  end

  defp normalize_source_window(contact) do
    contact
    |> put_new_present("source_window_type", Map.get(contact, "source_window_kind"))
    |> put_new_present("source_window_type", get_in(contact, ["metadata", "source_window_kind"]))
    |> put_new_present(
      "source_window_type",
      get_in(contact, ["activity_context", "source_window_kind"])
    )
  end

  defp normalize_source_window_payload(source_window) do
    source_window
    |> put_new_present("id", source_window_id_value(source_window))
    |> put_new_present("type", source_window_type_value(source_window))
  end

  defp source_window_id_value(%{} = source_window) do
    Map.get(source_window, "id") || Map.get(source_window, "window_id")
  end

  defp source_window_type_value(%{} = source_window) do
    Map.get(source_window, "type") || Map.get(source_window, "kind") ||
      Map.get(source_window, "window_type")
  end

  defp put_new_present(contact, _key, value) when value in [nil, ""], do: contact
  defp put_new_present(contact, key, value), do: Map.put_new(contact, key, value)

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

  def normalize_station_calendar_status_fields(row, unavailable_aliases) do
    row
    |> normalize_status_field("availability", unavailable_aliases)
    |> normalize_status_field("status", unavailable_aliases)
    |> normalize_status_field("station_availability", unavailable_aliases)
    |> normalize_status_field("station_calendar_status", unavailable_aliases)
    |> normalize_status_field("station_calendar_precedence_availability", unavailable_aliases)
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

  defp normalize_source_station_calendar_field(row, field, unavailable_aliases) do
    case Map.fetch(row, field) do
      {:ok, values} when is_list(values) ->
        Map.put(
          row,
          field,
          Enum.map(values, &normalize_source_station_calendar(&1, unavailable_aliases))
        )

      {:ok, value} ->
        Map.put(row, field, normalize_source_station_calendar(value, unavailable_aliases))

      :error ->
        row
    end
  end

  defp normalize_source_station_calendar(%{} = source, unavailable_aliases),
    do: normalize_station_calendar_status_fields(source, unavailable_aliases)

  defp normalize_source_station_calendar(value, _unavailable_aliases), do: value

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

  defp normalize_contact_time(contact, canonical_key, alternate_key, numeric) do
    case numeric.(Map.get(contact, canonical_key)) ||
           numeric.(Map.get(contact, alternate_key)) do
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

  defp normalize_contact_direction(%{"direction" => direction} = contact, direction_aliases) do
    case normalize_direction(direction, direction_aliases) do
      nil -> contact
      direction -> Map.put(contact, "direction", direction)
    end
  end

  defp normalize_contact_direction(%{"type" => "downlink"} = contact, _direction_aliases),
    do: Map.put(contact, "direction", "downlink")

  defp normalize_contact_direction(%{"type" => "tracking"} = contact, _direction_aliases),
    do: Map.put(contact, "direction", "tracking")

  defp normalize_contact_direction(%{"type" => "command"} = contact, _direction_aliases),
    do: Map.put(contact, "direction", "command")

  defp normalize_contact_direction(%{"type" => "health_check"} = contact, _direction_aliases),
    do: Map.put(contact, "direction", "health_check")

  defp normalize_contact_direction(contact, _direction_aliases), do: contact

  def normalize_direction(direction, _direction_aliases) when direction in [nil, ""], do: nil

  def normalize_direction(direction, direction_aliases) do
    direction
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
      value -> Map.get(direction_aliases, value, value)
    end
  end
end
