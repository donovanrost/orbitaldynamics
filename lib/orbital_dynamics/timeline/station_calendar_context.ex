defmodule OrbitalDynamics.Timeline.StationCalendarContext do
  @moduledoc false

  def build(activity, callbacks) when is_list(callbacks) do
    activity
    |> Map.take([
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_calendar_directions",
      "station_calendar_status",
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids",
      "station_calendar_overlap_availabilities",
      "station_calendar_entry_ambiguous",
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids",
      "station_contention_status",
      "station_reservation_id",
      "station_reservation_expires_at_s",
      "station_reserved_by",
      "station_reservation_status",
      "station_reservation_match_status",
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses"
    ])
    |> put_station_calendar_directions(activity, callbacks)
    |> put_flattened_station_calendar_entry_id(activity, callbacks)
    |> put_station_reservation_expiration_context(activity, callbacks)
    |> normalize_station_calendar_id_lists(callbacks)
    |> compact_map(callbacks)
  end

  defp source_station_calendar_overlap_values(activity, field) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> List.wrap()
    |> Enum.flat_map(fn
      %{} = overlap -> [Map.get(overlap, field)]
      _overlap -> []
    end)
  end

  defp normalize_number_list(nil, _callbacks), do: nil

  defp normalize_number_list(values, callbacks) when is_list(values) do
    values
    |> Enum.flat_map(&number_values(&1, callbacks))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp normalize_number_list(value, callbacks), do: normalize_number_list([value], callbacks)

  defp number_values(%{} = value, callbacks) do
    [
      Map.get(value, "station_calendar_reservation_expires_at_s"),
      Map.get(value, "station_reservation_expires_at_s"),
      Map.get(value, "reservation_expires_at_s")
    ]
    |> normalize_number_list(callbacks)
    |> List.wrap()
  end

  defp number_values(values, callbacks) when is_list(values),
    do: Enum.flat_map(values, &number_values(&1, callbacks))

  defp number_values(value, callbacks) do
    case numeric_value(value, callbacks) do
      nil -> []
      number -> [number]
    end
  end

  defp put_station_reservation_expiration_context(context, activity, callbacks) do
    context
    |> put_station_reservation_expires_at_s(activity, callbacks)
    |> put_station_calendar_reservation_expires_at_s(activity, callbacks)
  end

  defp put_station_reservation_expires_at_s(context, activity, callbacks) do
    case first_numeric_value(
           [
             Map.get(context, "station_reservation_expires_at_s"),
             Map.get(activity, "reservation_expires_at_s"),
             get_in(activity, [
               "source_station_calendar_entry",
               "station_reservation_expires_at_s"
             ]),
             get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"])
           ],
           callbacks
         ) do
      nil -> context
      expires_at_s -> Map.put(context, "station_reservation_expires_at_s", expires_at_s)
    end
  end

  defp put_station_calendar_reservation_expires_at_s(context, activity, callbacks) do
    expires_at_values =
      [
        Map.get(context, "station_calendar_reservation_expires_at_s"),
        Map.get(context, "station_reservation_expires_at_s"),
        get_in(activity, [
          "source_station_calendar_entry",
          "station_calendar_reservation_expires_at_s"
        ]),
        get_in(activity, ["source_station_calendar_entry", "station_reservation_expires_at_s"]),
        get_in(activity, ["source_station_calendar_entry", "reservation_expires_at_s"]),
        source_station_calendar_overlap_values(
          activity,
          "station_calendar_reservation_expires_at_s"
        ),
        source_station_calendar_overlap_values(activity, "station_reservation_expires_at_s"),
        source_station_calendar_overlap_values(activity, "reservation_expires_at_s")
      ]
      |> normalize_number_list(callbacks)

    case expires_at_values do
      nil -> context
      values -> Map.put(context, "station_calendar_reservation_expires_at_s", values)
    end
  end

  defp put_station_calendar_directions(context, activity, callbacks) do
    directions =
      [
        Map.get(context, "station_calendar_directions"),
        get_in(activity, ["source_station_calendar_entry", "station_calendar_directions"]),
        get_in(activity, ["source_station_calendar_entry", "directions"]),
        get_in(activity, ["source_station_calendar_entry", "direction"])
      ]
      |> List.flatten()
      |> Enum.map(&normalize_station_calendar_direction(&1, callbacks))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    case directions do
      [] -> context
      directions -> Map.put(context, "station_calendar_directions", directions)
    end
  end

  defp normalize_station_calendar_direction(direction, _callbacks)
       when direction in [nil, ""],
       do: nil

  defp normalize_station_calendar_direction(direction, callbacks) do
    direction
    |> encode_value(callbacks)
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "cmd" -> "command"
      "commanding" -> "command"
      "commands" -> "command"
      "sband_command" -> "command"
      "s_band_command" -> "command"
      "uplink" -> "command"
      "up" -> "command"
      "up_link" -> "command"
      "dl" -> "downlink"
      "down" -> "downlink"
      "downlinking" -> "downlink"
      "down_link" -> "downlink"
      "track" -> "tracking"
      "track_ing" -> "tracking"
      "tracking_pass" -> "tracking"
      "health" -> "health_check"
      "health_check" -> "health_check"
      "healthcheck" -> "health_check"
      "health_check_window" -> "health_check"
      value when value in ["command", "downlink", "tracking", "health_check"] -> value
      _unknown -> nil
    end
  end

  defp put_flattened_station_calendar_entry_id(context, activity, callbacks) do
    case first_stable_id(
           [
             Map.get(context, "station_calendar_entry_id"),
             get_in(activity, ["source_station_calendar_entry", "station_calendar_entry_id"]),
             get_in(activity, ["source_station_calendar_entry", "id"])
           ],
           callbacks
         ) do
      nil ->
        context

      station_calendar_entry_id ->
        Map.put(context, "station_calendar_entry_id", station_calendar_entry_id)
    end
  end

  defp first_stable_id(values, callbacks) do
    values
    |> Enum.find_value(fn value ->
      case stable_id_value(value, callbacks) do
        [id | _rest] -> id
        [] -> nil
      end
    end)
  end

  defp normalize_station_calendar_id_lists(context, callbacks) do
    Enum.reduce(
      [
        "station_calendar_overlap_entry_ids",
        "station_calendar_ambiguous_entry_ids",
        "station_calendar_reservation_ids"
      ],
      context,
      fn field, acc ->
        case normalize_id_list(
               Map.get(acc, field),
               [
                 "id",
                 "station_calendar_entry_id",
                 "station_reservation_id"
               ],
               callbacks
             ) do
          nil -> Map.delete(acc, field)
          ids -> Map.put(acc, field, ids)
        end
      end
    )
  end

  defp first_numeric_value(values, callbacks) do
    Enum.find_value(values, &numeric_value(&1, callbacks))
  end

  defp numeric_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :numeric_value), [value])

  defp encode_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :encode_value), [value])

  defp stable_id_value(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :stable_id_value), [value])

  defp normalize_id_list(value, map_keys, callbacks),
    do: apply(Keyword.fetch!(callbacks, :normalize_id_list), [value, map_keys])

  defp compact_map(value, callbacks),
    do: apply(Keyword.fetch!(callbacks, :compact_map), [value])
end
