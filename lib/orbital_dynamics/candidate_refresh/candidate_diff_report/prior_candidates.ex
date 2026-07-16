defmodule OrbitalDynamics.CandidateRefresh.CandidateDiffReport.PriorCandidates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    SourceReportSummary.Common,
    ValueEncoding
  }

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
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
  @optional_stable_identity_fields ~w(
    spacecraft_id
    ground_station_id
    target_id
    source_window_id
    station_calendar_entry_id
    station_calendar_provider_id
    station_calendar_provider_entry_id
    station_reservation_id
  )
  @station_calendar_id_list_fields ~w(
    station_calendar_overlap_entry_ids
    station_calendar_ambiguous_entry_ids
    station_calendar_reservation_ids
  )
  @station_calendar_number_list_fields ~w(
    station_calendar_reservation_expires_at_s
  )

  def optional_stable_identity_fields, do: @optional_stable_identity_fields

  def station_calendar_id_list_fields, do: @station_calendar_id_list_fields

  def station_calendar_number_list_fields, do: @station_calendar_number_list_fields

  def activities(refresh) do
    refresh
    |> Map.get("prior_candidate_activities", [])
    |> Enum.with_index(1)
    |> Enum.map(&normalize/1)
  end

  def valid_activities(refresh) do
    refresh
    |> activities()
    |> Enum.reject(&invalid_input?/1)
  end

  def invalid_input?(%{"invalid_prior_candidate_input" => true}), do: true
  def invalid_input?(_candidate), do: false

  defp normalize({candidate, index}) when is_map(candidate) do
    candidate =
      candidate
      |> stringify_keys()
      |> normalize_candidate_station_id()
      |> normalize_candidate_time("starts_at_s", "start_s")
      |> normalize_candidate_time("ends_at_s", "end_s")
      |> normalize_candidate_direction()
      |> normalize_candidate_type_alias()
      |> normalize_candidate_type()

    cond do
      reason = prior_candidate_id_issue(candidate["id"]) ->
        invalid_input(candidate, index, reason)

      not valid_candidate_type?(candidate["type"]) ->
        invalid_input(candidate, index, "missing_candidate_type")

      reason = prior_candidate_identity_issue(candidate) ->
        invalid_input(candidate, index, reason)

      true ->
        candidate
    end
  end

  defp normalize({candidate, index}) do
    invalid_input(
      %{"raw_input" => inspect(candidate)},
      index,
      "invalid_candidate_shape"
    )
  end

  defp invalid_input(candidate, index, reason) do
    candidate_id = invalid_candidate_id(candidate, index, reason)

    %{
      "id" => candidate_id,
      "type" => candidate_type_or_invalid(candidate),
      "scenario_id" =>
        stable_id_or_nil(candidate["scenario_id"]) ||
          "missing_scenario_id:#{candidate_id}",
      "spacecraft_id" => stable_id_or_nil(candidate["spacecraft_id"]),
      "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
      "target_id" => stable_id_or_nil(candidate["target_id"]),
      "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
      "station_calendar_entry_id" => stable_id_or_nil(candidate["station_calendar_entry_id"]),
      "station_calendar_provider_id" =>
        stable_id_or_nil(candidate["station_calendar_provider_id"]),
      "station_calendar_provider_entry_id" =>
        stable_id_or_nil(candidate["station_calendar_provider_entry_id"]),
      "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
      "station_calendar_ambiguous_entry_ids" => candidate["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
      "station_reservation_id" => stable_id_or_nil(candidate["station_reservation_id"]),
      "station_calendar_reservation_expires_at_s" =>
        candidate["station_calendar_reservation_expires_at_s"],
      "station_reservation_expires_at_s" =>
        ValueEncoding.numeric_value(candidate["station_reservation_expires_at_s"]),
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "invalid_prior_candidate_input" => true,
      "invalid_prior_candidate_input_reason" => reason,
      "source_candidate" => candidate
    }
    |> normalize_station_calendar_id_lists()
    |> normalize_station_calendar_number_lists()
    |> Common.compact_map()
  end

  defp invalid_candidate_id(candidate, index, reason) do
    case candidate["id"] do
      value when is_binary(value) and value != "" ->
        stable_id_or_nil(value) || "invalid_prior_candidate:#{reason}:#{index}"

      value when is_atom(value) and not is_nil(value) ->
        stable_id_or_nil(value) || "invalid_prior_candidate:#{reason}:#{index}"

      value when is_integer(value) ->
        stable_id_or_nil(value) || "invalid_prior_candidate:#{reason}:#{index}"

      _value ->
        "invalid_prior_candidate:#{reason}:#{index}"
    end
  end

  defp prior_candidate_id_issue(id) when id in [nil, ""], do: "missing_candidate_id"

  defp prior_candidate_id_issue(id) do
    if stable_id?(id), do: nil, else: "invalid_candidate_id"
  end

  defp prior_candidate_identity_issue(candidate) do
    cond do
      Map.get(candidate, "scenario_id") in [nil, ""] ->
        "missing_scenario_id"

      not stable_id?(Map.get(candidate, "scenario_id")) ->
        "invalid_scenario_id"

      true ->
        Enum.find_value(
          @optional_stable_identity_fields,
          fn field ->
            value = Map.get(candidate, field)

            cond do
              value in [nil, ""] -> nil
              stable_id?(value) -> nil
              true -> "invalid_#{field}"
            end
          end
        )
    end
  end

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(@station_calendar_id_list_fields, context, fn field, acc ->
      case normalize_id_list(Map.get(acc, field)) do
        nil -> Map.delete(acc, field)
        ids -> Map.put(acc, field, ids)
      end
    end)
  end

  defp normalize_station_calendar_number_lists(context) do
    Enum.reduce(@station_calendar_number_list_fields, context, fn field, acc ->
      case normalize_number_list(Map.get(acc, field)) do
        nil -> Map.delete(acc, field)
        values -> Map.put(acc, field, values)
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

  defp normalize_number_list(nil), do: nil

  defp normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&ValueEncoding.numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value), do: normalize_number_list([value])

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

  defp candidate_type_or_invalid(_candidate), do: "invalid_prior_candidate_input"

  defp valid_candidate_type?(type) when is_binary(type), do: type != ""
  defp valid_candidate_type?(_type), do: false

  defp normalize_candidate_station_id(%{"ground_station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: candidate

  defp normalize_candidate_station_id(%{"station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: Map.put(candidate, "ground_station_id", station_id)

  defp normalize_candidate_station_id(candidate) do
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

  defp normalize_candidate_type(%{"type" => "contact", "direction" => "downlink"} = candidate),
    do: Map.put(candidate, "type", "downlink")

  defp normalize_candidate_type(candidate) do
    cond do
      provider_downlink_candidate?(candidate) ->
        candidate
        |> Map.put_new("type", "downlink")
        |> Map.put_new("direction", "downlink")

      direction_contact_candidate?(candidate) and candidate["direction"] == "health_check" ->
        Map.put_new(candidate, "type", "health_check")

      direction_contact_candidate?(candidate) ->
        Map.put_new(candidate, "type", "planned_contact")

      true ->
        candidate
    end
  end

  defp normalize_candidate_type_alias(%{"type" => type} = candidate) when not is_nil(type),
    do: candidate

  defp normalize_candidate_type_alias(%{"activity_type" => type} = candidate)
       when is_binary(type) and type != "",
       do: Map.put(candidate, "type", type)

  defp normalize_candidate_type_alias(candidate), do: candidate

  defp normalize_candidate_time(candidate, canonical_key, alternate_key) do
    case ValueEncoding.numeric_value(Map.get(candidate, canonical_key)) ||
           ValueEncoding.numeric_value(Map.get(candidate, alternate_key)) do
      value when is_number(value) -> Map.put(candidate, canonical_key, value)
      _value -> candidate
    end
  end

  defp normalize_candidate_direction(%{"direction" => direction} = candidate) do
    case normalize_direction(direction) do
      nil -> candidate
      normalized -> Map.put(candidate, "direction", normalized)
    end
  end

  defp normalize_candidate_direction(candidate), do: candidate

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

  defp direction_contact_candidate?(candidate) do
    type = Map.get(candidate, "type") || Map.get(candidate, "activity_type")
    direction = Map.get(candidate, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in ["tracking", "uplink", "command", "health_check"] and
      not is_nil(Map.get(candidate, "ground_station_id")) and
      is_number(Map.get(candidate, "starts_at_s")) and
      is_number(Map.get(candidate, "ends_at_s"))
  end

  defp command_feedback_candidate?(candidate) do
    Map.has_key?(candidate, "command_success") or Map.has_key?(candidate, "command_result")
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp normalize_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_direction(direction) do
    direction
    |> encode_value()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      token when is_map_key(@provider_direction_aliases, token) ->
        Map.fetch!(@provider_direction_aliases, token)

      "nil" ->
        nil

      "" ->
        nil

      value ->
        value
    end
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

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
