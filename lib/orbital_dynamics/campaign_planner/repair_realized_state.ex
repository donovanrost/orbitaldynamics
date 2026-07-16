defmodule OrbitalDynamics.CampaignPlanner.RepairRealizedState do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ModelLimits,
    OperationalFeedbackNormalization,
    RealizedActivity,
    ScalarValues,
    ValueEncoding
  }

  @realized_completion_statuses ~w(completed executed)
  @realized_preserved_executed_statuses @realized_completion_statuses ++ ~w(partial)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @realized_statuses @realized_preserved_executed_statuses ++
                       @realized_failure_statuses ++ ~w(delayed)
  @realized_feedback_match_statuses ~w(matched)
  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def completion_statuses, do: @realized_completion_statuses

  def normalize(realized_state) when is_list(realized_state) do
    normalize(%{"activities" => realized_state}, callbacks())
  end

  def normalize(realized_state), do: normalize(realized_state, callbacks())

  def normalize(realized_state, callbacks) when is_list(realized_state) do
    normalize(%{"activities" => realized_state}, callbacks)
  end

  def normalize(realized_state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    model_limits = Keyword.fetch!(callbacks, :model_limits)

    realized_state = stringify_keys.(realized_state || %{})

    activities =
      (Map.get(realized_state, "activities") || Map.get(realized_state, "realized_activities") ||
         [])
      |> Enum.map(&activity(&1, callbacks))
      |> Enum.sort_by(& &1["id"])

    {spacecraft_states, dropped_spacecraft_state_counts} =
      (Map.get(realized_state, "spacecraft_states") || Map.get(realized_state, "spacecraft") || [])
      |> spacecraft_states(callbacks)

    metadata =
      realized_state
      |> Map.get("metadata", %{})
      |> put_dropped_spacecraft_state_counts(dropped_spacecraft_state_counts, callbacks)

    model_limits =
      realized_state
      |> Map.get("model_limits", model_limits)
      |> normalize_string_list(model_limits)

    %{
      "schema_contract" => "realized_state_snapshot.v1",
      "activities" => activities,
      "spacecraft_states" => spacecraft_states,
      "metadata" => metadata,
      "model_limits" => model_limits
    }
  end

  def activities_by_id(realized_state) do
    realized_state
    |> Map.get("activities", [])
    |> Enum.group_by(fn activity -> activity["id"] end)
  end

  def activity_match(realized_by_id, activity_id) do
    case Map.get(realized_by_id, activity_id, []) do
      [] -> {:ok, nil}
      [realized] -> {:ok, realized}
      realized_rows -> {:ambiguous, realized_rows}
    end
  end

  def feedback_statuses(realized_rows) do
    realized_rows
    |> Enum.map(&Map.get(&1, "status"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def normalize_feedback_status(activity), do: normalize_feedback_status(activity, callbacks())

  def normalize_feedback_status(%{} = activity, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    activity = stringify_keys.(activity)

    status =
      activity
      |> Map.get("status")
      |> encode_value.()
      |> normalize_status_value()

    raw_realized_status =
      activity
      |> Map.get("realized_status")
      |> encode_value.()
      |> normalize_status_value()

    {status, feedback_status, realized_status} =
      activity_status(status, raw_realized_status, callbacks)

    activity
    |> put_if_present("status", status)
    |> put_if_present("feedback_status", feedback_status)
    |> put_if_present("realized_status", realized_status || raw_realized_status)
  end

  def normalize_feedback_status(activity, _callbacks), do: activity

  def normalize_status_value(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalize_status_value(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalize_status_value()
  end

  def normalize_status_value(status), do: status

  def spacecraft_states(states), do: spacecraft_states(states, callbacks())

  def spacecraft_states(states, callbacks) do
    states
    |> Enum.reduce({[], %{identityless: 0, invalid_identity: 0}}, fn state,
                                                                     {normalized, dropped_counts} ->
      case normalize_spacecraft_state(state, callbacks) do
        {:ok, normalized_state} ->
          {[normalized_state | normalized], dropped_counts}

        {:drop, reason} ->
          {normalized, Map.update!(dropped_counts, reason, &(&1 + 1))}
      end
    end)
    |> then(fn {normalized, dropped_counts} ->
      normalized =
        normalized
        |> Enum.reverse()
        |> Enum.sort_by(& &1["scenario_id"])

      {normalized, dropped_counts}
    end)
  end

  defp normalize_spacecraft_state(state, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    non_empty_string? = Keyword.fetch!(callbacks, :non_empty_string?)

    state = stringify_keys.(state || %{})
    state = spacecraft_state_booleans(state, callbacks)

    cond do
      stable_id_string?.(Map.get(state, "scenario_id")) ->
        {:ok, state}

      stable_id_string?.(Map.get(state, "id")) ->
        {:ok,
         state
         |> Map.put("scenario_id", Map.get(state, "id"))
         |> Map.delete("id")}

      non_empty_string?.(Map.get(state, "scenario_id")) or
          non_empty_string?.(Map.get(state, "id")) ->
        {:drop, :invalid_identity}

      true ->
        {:drop, :identityless}
    end
  end

  def spacecraft_state_booleans(state), do: spacecraft_state_booleans(state, callbacks())

  def spacecraft_state_booleans(state, callbacks) do
    Enum.reduce(
      [
        "degraded",
        "spacecraft_available",
        "spacecraft_availability",
        "payload_available",
        "antenna_available"
      ],
      state,
      fn key, acc ->
        case Map.fetch(acc, key) do
          {:ok, value} -> Map.put(acc, key, spacecraft_state_boolean_value(key, value, callbacks))
          :error -> acc
        end
      end
    )
  end

  defp spacecraft_state_boolean_value("degraded", value, callbacks) do
    json_boolean_value = Keyword.fetch!(callbacks, :json_boolean_value)

    case json_boolean_value.(value) do
      value when is_boolean(value) -> value
      _value -> value
    end
  end

  defp spacecraft_state_boolean_value(_availability_field, value, callbacks) do
    resource_availability_boolean_value =
      Keyword.fetch!(callbacks, :resource_availability_boolean_value)

    case resource_availability_boolean_value.(value) do
      value when is_boolean(value) -> value
      _value -> value
    end
  end

  defp put_dropped_spacecraft_state_counts(
         metadata,
         %{identityless: 0, invalid_identity: 0},
         _callbacks
       ),
       do: metadata

  defp put_dropped_spacecraft_state_counts(metadata, counts, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    metadata = stringify_keys.(metadata)

    metadata
    |> maybe_put_positive_count(
      "dropped_identityless_spacecraft_state_count",
      Map.fetch!(counts, :identityless)
    )
    |> maybe_put_positive_count(
      "dropped_invalid_spacecraft_state_count",
      Map.fetch!(counts, :invalid_identity)
    )
  end

  defp maybe_put_positive_count(metadata, _field, 0), do: metadata
  defp maybe_put_positive_count(metadata, field, count), do: Map.put(metadata, field, count)

  defp normalize_string_list(values, default) when is_list(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> case do
      [] -> default
      strings -> strings
    end
  end

  defp normalize_string_list(_values, default), do: default

  def activity(activity), do: activity(activity, callbacks())

  def activity(%RealizedActivity{} = activity, callbacks) do
    activity
    |> Map.from_struct()
    |> activity(callbacks)
  end

  def activity(activity, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    realized_statuses = Keyword.fetch!(callbacks, :realized_statuses)

    activity = stringify_keys.(activity)

    raw_status =
      activity
      |> Map.get("status")
      |> encode_value.()
      |> normalize_status_value()

    raw_realized_status =
      activity
      |> Map.get("realized_status")
      |> encode_value.()
      |> normalize_status_value()

    {status, feedback_status, realized_status} =
      activity_status(raw_status, raw_realized_status, callbacks)

    unless status in realized_statuses do
      raise ArgumentError, "unsupported realized activity status #{inspect(status)}"
    end

    %{
      "schema_contract" => "realized_activity.v1",
      "id" => encode_value.(Map.fetch!(activity, "id")),
      "status" => status,
      "actual_starts_at_s" =>
        Map.get(activity, "actual_starts_at_s") || Map.get(activity, "actual_start_s"),
      "actual_ends_at_s" =>
        Map.get(activity, "actual_ends_at_s") || Map.get(activity, "actual_end_s"),
      "completed_fraction" => Map.get(activity, "completed_fraction"),
      "reason" => Map.get(activity, "reason"),
      "feedback_status" => feedback_status,
      "realized_status" => realized_status,
      "metadata" => Map.get(activity, "metadata", %{})
    }
    |> Map.merge(activity_passthrough_context(activity, callbacks))
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp activity_passthrough_context(activity, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    activity
    |> Map.take([
      "type",
      "direction",
      "ground_station_id",
      "station_availability",
      "station_contention_status",
      "station_calendar_entry_id",
      "station_calendar_directions",
      "station_calendar_status",
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids",
      "station_calendar_overlap_availabilities",
      "station_calendar_trust_boundary_status",
      "station_reservation_id",
      "station_reserved_by",
      "station_reservation_status",
      "station_reservation_match_status",
      "trust_boundary",
      "provenance",
      "source_station_calendar_entry",
      "source_station_calendar_overlaps"
    ])
    |> compact_map.()
  end

  def activity_status(status, realized_status, callbacks) do
    feedback_match_statuses = Keyword.fetch!(callbacks, :feedback_match_statuses)
    realized_statuses = Keyword.fetch!(callbacks, :realized_statuses)

    if status in feedback_match_statuses and realized_status in realized_statuses do
      {realized_status, status, realized_status}
    else
      {status, nil, nil}
    end
  end

  defp callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      encode_value: &ValueEncoding.encode_value/1,
      compact_map: &ValueEncoding.compact_map/1,
      json_boolean_value: &ScalarValues.json_boolean_value/1,
      resource_availability_boolean_value: &resource_availability_boolean_value/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      non_empty_string?: &ScalarValues.non_empty_string?/1,
      model_limits: ModelLimits.realized_state_snapshot_model_limits(),
      realized_statuses: @realized_statuses,
      feedback_match_statuses: @realized_feedback_match_statuses
    ]

  defp resource_availability_boolean_value(value) do
    OperationalFeedbackNormalization.resource_availability_boolean_value(
      value,
      operational_feedback_normalization_callbacks()
    )
  end

  defp operational_feedback_normalization_callbacks,
    do: [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp put_if_present(map, _key, value) when value in [nil, "", [], %{}], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
