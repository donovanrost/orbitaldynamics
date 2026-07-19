defmodule OrbitalDynamics.Communications.ContactFilter.ContactNormalization do
  @moduledoc false

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    ground_station_id
    source_window_id
    station_calendar_entry_id
    station_reservation_id
  )

  def provider_direction_aliases, do: @provider_direction_aliases
  def stable_identity_fields, do: @stable_identity_fields

  def normalize(%{} = contact, unavailable_aliases, suppressed_directions) do
    contact
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_contact_time("starts_at_s", "start_s")
    |> normalize_contact_time("ends_at_s", "end_s")
    |> normalize_station_calendar_status_fields(unavailable_aliases)
    |> normalize_activity_type_alias()
    |> normalize_contact_direction(suppressed_directions)
  end

  def normalize(contact, _unavailable_aliases, _suppressed_directions) do
    %{
      "invalid_contact_shape" => true,
      "raw_input" => inspect(contact)
    }
  end

  def contact_spacecraft_id(contact) do
    spacecraft_identity_value(contact["spacecraft_id"]) ||
      spacecraft_identity_value(contact["satellite_id"]) ||
      spacecraft_identity_value(contact["spacecraft"]) ||
      spacecraft_identity_value(contact["satellite"]) ||
      stable_id_or_nil(contact["scenario_id"])
  end

  def candidate_id(candidate) do
    case Map.get(candidate, "id") || Map.get(candidate, "contact_id") ||
           Map.get(candidate, "activity_id") do
      value when is_binary(value) and value != "" ->
        stable_id_or_nil(value)

      value when is_atom(value) and not is_nil(value) ->
        value |> Atom.to_string() |> stable_id_or_nil()

      value when is_integer(value) ->
        value |> Integer.to_string() |> stable_id_or_nil()

      _value ->
        nil
    end
  end

  def contact_id_issue(candidate) do
    raw_id =
      Map.get(candidate, "id") || Map.get(candidate, "contact_id") ||
        Map.get(candidate, "activity_id")

    cond do
      raw_id in [nil, ""] -> "missing_contact_id"
      stable_id?(raw_id) -> nil
      true -> "invalid_contact_id"
    end
  end

  def contact_identity_issue(candidate) do
    Enum.find_value(@stable_identity_fields, fn field ->
      value = Map.get(candidate, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  def stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  def stable_id?("nil"), do: false
  def stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  def stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  def stable_id?(_value), do: false

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def normalize_station_calendar_status_fields(row, unavailable_aliases) do
    row
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

  defp normalized_status_token(nil, _unavailable_aliases), do: nil

  defp normalized_status_token(value, unavailable_aliases) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token(unavailable_aliases)
  end

  defp normalized_status_token(value, unavailable_aliases) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalized_status_token(unavailable_aliases)
  end

  defp normalized_status_token(value, _unavailable_aliases), do: value

  def normalize_direction(direction) when direction in [nil, ""], do: nil

  def normalize_direction(direction) do
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
      "contact" -> "contact"
      "nil" -> nil
      "" -> nil
      value -> Map.get(@provider_direction_aliases, value, value)
    end
  end

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value) when is_boolean(value), do: value
  def stringify_keys(nil), do: nil
  def stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  def stringify_keys(value), do: value

  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

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

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

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

  defp canonical_status_token(value, unavailable_aliases) do
    if value in unavailable_aliases, do: "unavailable", else: value
  end

  defp normalize_contact_time(contact, canonical_key, alternate_key) do
    case numeric_or_nil(Map.get(contact, canonical_key)) ||
           numeric_or_nil(Map.get(contact, alternate_key)) do
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

  defp normalize_contact_direction(%{"direction" => direction} = contact, _directions) do
    case normalize_direction(direction) do
      nil -> contact
      direction -> Map.put(contact, "direction", direction)
    end
  end

  defp normalize_contact_direction(%{"type" => type} = contact, suppressed_directions) do
    if type in suppressed_directions, do: Map.put(contact, "direction", type), else: contact
  end

  defp normalize_contact_direction(contact, _suppressed_directions), do: contact

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
