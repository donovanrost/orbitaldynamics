defmodule OrbitalDynamics.ResourceFilter.CandidateInput do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @candidate_stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    ground_station_id
    target_id
    source_window_id
    station_calendar_entry_id
    station_reservation_id
  )
  @station_calendar_id_list_fields ~w(
    station_calendar_overlap_entry_ids
    station_calendar_ambiguous_entry_ids
    station_calendar_reservation_ids
  )
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
  @station_calendar_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "command",
    "up" => "command",
    "up_link" => "command",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "x_band_downlink" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @resource_activity_type_aliases Map.merge(@station_calendar_direction_aliases, %{
                                    "uplink_command" => "command"
                                  })

  def stable_identity_fields, do: @candidate_stable_identity_fields
  def station_calendar_id_list_fields, do: @station_calendar_id_list_fields
  def provider_direction_aliases, do: @provider_direction_aliases
  def station_calendar_direction_aliases, do: @station_calendar_direction_aliases
  def resource_activity_type_aliases, do: @resource_activity_type_aliases

  def normalize(%{} = candidate, index) do
    candidate
    |> stringify_keys()
    |> put_ground_station_alias()
    |> put_time_alias("starts_at_s", "start_s")
    |> put_time_alias("ends_at_s", "end_s")
    |> put_activity_type_alias()
    |> put_provider_direction_alias()
    |> put_station_calendar_directions()
    |> put_provider_downlink_shape()
    |> put_direction_contact_shape()
    |> maybe_invalid_candidate_input(index)
  end

  def normalize(candidate, _index) do
    %{
      "id" => "missing_candidate_id",
      "type" => "invalid_candidate_input",
      "scenario_id" => "missing_scenario_id",
      "invalid_candidate_input" => true,
      "invalid_candidate_input_reason" => "invalid_candidate_shape",
      "source_candidate" => %{"raw_input" => inspect(candidate)}
    }
  end

  def station_calendar_entry_id(candidate) do
    stable_id_or_nil(candidate["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(candidate, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(candidate, ["source_station_calendar_entry", "id"]))
  end

  def normalize_station_calendar_id_lists(context) do
    Enum.reduce(@station_calendar_id_list_fields, context, fn field, acc ->
      case normalize_id_list(Map.get(acc, field)) do
        nil -> Map.delete(acc, field)
        ids -> Map.put(acc, field, ids)
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

  defp maybe_invalid_candidate_input(candidate, index) do
    cond do
      reason = candidate_id_issue(candidate["id"]) ->
        invalid_candidate_input(candidate, index, reason)

      not valid_candidate_kind?(candidate) ->
        invalid_candidate_input(candidate, index, "missing_candidate_type")

      reason = candidate_identity_issue(candidate) ->
        invalid_candidate_input(candidate, index, reason)

      reason = candidate_feedback_factor_issue(candidate) ->
        invalid_candidate_input(candidate, index, reason)

      true ->
        candidate
    end
  end

  defp candidate_feedback_factor_issue(candidate) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      case Map.get(candidate, field) do
        nil ->
          nil

        value ->
          case numeric_or_nil(value) do
            number when is_number(number) ->
              if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

            _value ->
              "invalid_#{field}"
          end
      end
    end)
  end

  defp invalid_candidate_input(candidate, index, reason) do
    candidate_id =
      case candidate["id"] do
        value when is_binary(value) and value != "" ->
          stable_id_or_nil(value) || "#{reason}:#{index}"

        _value ->
          "#{reason}:#{index}"
      end

    %{
      "id" => candidate_id,
      "type" => candidate_type_or_invalid(candidate),
      "scenario_id" =>
        stable_id_or_nil(Map.get(candidate, "scenario_id")) ||
          "missing_scenario_id:#{candidate_id}",
      "spacecraft_id" => stable_id_or_nil(candidate["spacecraft_id"]),
      "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
      "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
      "target_id" => stable_id_or_nil(candidate["target_id"]),
      "station_calendar_entry_id" => station_calendar_entry_id(candidate),
      "station_calendar_directions" => candidate["station_calendar_directions"],
      "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
      "station_calendar_ambiguous_entry_ids" => candidate["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
      "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
      "station_reservation_id" => stable_id_or_nil(candidate["station_reservation_id"]),
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "invalid_candidate_input" => true,
      "invalid_candidate_input_reason" => reason,
      "source_candidate" => candidate
    }
    |> normalize_station_calendar_id_lists()
    |> compact_map()
  end

  defp candidate_id_issue(id) when id in [nil, ""], do: "missing_candidate_id"
  defp candidate_id_issue(id), do: if(stable_id?(id), do: nil, else: "invalid_candidate_id")

  defp candidate_identity_issue(candidate) do
    Enum.find_value(@candidate_stable_identity_fields, fn field ->
      value = Map.get(candidate, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []

  defp candidate_type_or_invalid(%{"type" => type}) when is_binary(type) and type != "",
    do: type

  defp candidate_type_or_invalid(_candidate), do: "invalid_candidate_input"

  defp valid_candidate_kind?(%{"type" => type}) when is_binary(type) and type != "", do: true

  defp valid_candidate_kind?(%{"direction" => direction})
       when direction in ["downlink", "tracking"],
       do: true

  defp valid_candidate_kind?(_candidate), do: false

  defp put_ground_station_alias(%{"ground_station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: candidate

  defp put_ground_station_alias(%{"station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: Map.put(candidate, "ground_station_id", station_id)

  defp put_ground_station_alias(candidate) do
    case nested_station_id(candidate) do
      nil -> candidate
      station_id -> Map.put(candidate, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp put_time_alias(candidate, canonical_key, alternate_key) do
    case numeric_or_nil(Map.get(candidate, canonical_key)) ||
           numeric_or_nil(Map.get(candidate, alternate_key)) do
      value when is_number(value) -> Map.put(candidate, canonical_key, value)
      _value -> candidate
    end
  end

  defp put_provider_downlink_shape(candidate) do
    if provider_downlink_candidate?(candidate) do
      candidate
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      candidate
    end
  end

  defp put_direction_contact_shape(candidate) do
    type = Map.get(candidate, "type") || Map.get(candidate, "activity_type")
    direction = Map.get(candidate, "direction")

    cond do
      typed_contact_window?(type, direction, candidate) and direction == "health_check" ->
        Map.put_new(candidate, "type", "health_check")

      typed_contact_window?(type, direction, candidate) ->
        Map.put_new(candidate, "type", "planned_contact")

      true ->
        candidate
    end
  end

  defp typed_contact_window?(type, direction, candidate) do
    type in [nil, "contact", "planned_contact"] and
      direction in ["tracking", "uplink", "command", "health_check"] and
      not is_nil(Map.get(candidate, "ground_station_id")) and
      is_number(Map.get(candidate, "starts_at_s")) and
      is_number(Map.get(candidate, "ends_at_s"))
  end

  defp put_activity_type_alias(%{"type" => type} = candidate) when not is_nil(type),
    do: candidate

  defp put_activity_type_alias(%{"activity_type" => type} = candidate)
       when is_binary(type) and type != "",
       do: Map.put(candidate, "type", type)

  defp put_activity_type_alias(candidate), do: candidate

  defp put_provider_direction_alias(%{"direction" => direction} = candidate) do
    case normalize_provider_direction(direction) do
      nil -> candidate
      direction -> Map.put(candidate, "direction", direction)
    end
  end

  defp put_provider_direction_alias(candidate), do: candidate

  defp normalize_provider_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_provider_direction(direction) do
    direction
    |> normalized_direction_token()
    |> case do
      nil -> nil
      token -> Map.get(@provider_direction_aliases, token, token)
    end
  end

  defp put_station_calendar_directions(candidate) do
    case station_calendar_directions(candidate) do
      [] -> candidate
      directions -> Map.put(candidate, "station_calendar_directions", directions)
    end
  end

  defp station_calendar_directions(candidate) do
    [
      Map.get(candidate, "station_calendar_directions"),
      Map.get(candidate, "station_calendar_direction"),
      get_in(candidate, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(candidate, ["source_station_calendar_entry", "directions"]),
      get_in(candidate, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(&normalize_station_calendar_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_station_calendar_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_station_calendar_direction(direction) do
    direction
    |> normalized_direction_token()
    |> case do
      nil -> nil
      token -> Map.get(@station_calendar_direction_aliases, token, token)
    end
  end

  defp provider_downlink_candidate?(candidate) do
    type = Map.get(candidate, "type") || Map.get(candidate, "activity_type")
    direction = Map.get(candidate, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback_candidate?(candidate) and
      not is_nil(Map.get(candidate, "ground_station_id")) and
      is_number(Map.get(candidate, "starts_at_s")) and
      is_number(Map.get(candidate, "ends_at_s"))
  end

  defp command_feedback_candidate?(candidate) do
    Map.has_key?(candidate, "command_success") or Map.has_key?(candidate, "command_result")
  end

  defp normalized_direction_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "" -> nil
      "nil" -> nil
      token -> token
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
