defmodule OrbitalDynamics.CampaignPlanner.DownlinkCompletionCandidates do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    CollectionLatencyIdentity,
    DownlinkActivityNormalization,
    ScalarValues
  }

  def candidates(source_candidate_activities, event, request) do
    candidates(source_candidate_activities, event, request, callbacks())
  end

  def candidates(source_candidate_activities, event, request, callbacks) do
    normalize_downlink_activity = Keyword.fetch!(callbacks, :normalize_downlink_activity)
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)
    within_remaining_horizon? = Keyword.fetch!(callbacks, :within_remaining_horizon?)
    default_strategy_horizon = Keyword.fetch!(callbacks, :default_strategy_horizon)
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_id = Keyword.fetch!(callbacks, :activity_id)

    source_candidate_activities
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&normalize_downlink_activity.(&1))
    |> Enum.filter(&downlink_activity?.(&1))
    |> Enum.filter(
      &within_remaining_horizon?.(
        &1,
        request.remaining_horizon || default_strategy_horizon.(request)
      )
    )
    |> Enum.filter(&event_match?(&1, event, callbacks))
    |> Enum.sort_by(fn candidate ->
      {-candidate_score.(candidate), activity_start.(candidate), activity_id.(candidate)}
    end)
  end

  def event_match?(candidate, event) do
    event_match?(candidate, event, callbacks())
  end

  def event_match?(candidate, event, callbacks) do
    event_ground_station_id = Keyword.fetch!(callbacks, :event_ground_station_id)
    activity_ground_station_id = Keyword.fetch!(callbacks, :activity_ground_station_id)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_end = Keyword.fetch!(callbacks, :activity_end)
    station_id = event_ground_station_id.(event)
    scenario_id = Map.get(event, "scenario_id")
    starts_at_s = Map.get(event, "starts_at_s") || Map.get(event, "start_s")
    ends_at_s = Map.get(event, "ends_at_s") || Map.get(event, "end_s")
    window_selector? = event_window_selector?(event)

    (is_nil(station_id) or activity_ground_station_id.(candidate) == station_id) and
      (is_nil(scenario_id) or candidate["scenario_id"] == scenario_id) and
      (not window_selector? or not is_number(starts_at_s) or
         activity_start.(candidate) >= starts_at_s) and
      (not window_selector? or not is_number(ends_at_s) or activity_end.(candidate) <= ends_at_s) and
      identity_match?(candidate, event)
  end

  defp event_window_selector?(%{"feedback_scope" => "timeline_diff"}), do: false
  defp event_window_selector?(_event), do: true

  defp callbacks do
    [
      normalize_downlink_activity: &DownlinkActivityNormalization.normalize/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      within_remaining_horizon?: &ActivityTiming.within_remaining_horizon?/2,
      default_strategy_horizon: &default_strategy_horizon/1,
      candidate_score: &candidate_score/1,
      activity_start: &ActivityTiming.activity_start/1,
      activity_end: &ActivityTiming.activity_end/1,
      activity_id: &ActivityIdentity.activity_id/1,
      event_ground_station_id: &event_ground_station_id/1,
      activity_ground_station_id: &ActivityIdentity.ground_station_id/1
    ]
  end

  defp default_strategy_horizon(request) do
    ActivityTiming.remaining_horizon(
      request.prior_plan,
      request.remaining_horizon,
      request.current_epoch_s
    )
  end

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             DownlinkActivityNormalization.nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp identity_match?(candidate, event) do
    Enum.all?(
      [
        {CollectionLatencyIdentity.collection_keys(),
         CollectionLatencyIdentity.collection_keys()},
        {CollectionLatencyIdentity.payload_keys(), CollectionLatencyIdentity.payload_keys()},
        {CollectionLatencyIdentity.instrument_keys(),
         CollectionLatencyIdentity.instrument_keys()},
        {CollectionLatencyIdentity.product_keys(), CollectionLatencyIdentity.product_keys()}
      ],
      fn {event_keys, candidate_keys} ->
        event_values = CollectionLatencyIdentity.selector_values(event, event_keys)
        candidate_values = CollectionLatencyIdentity.selector_values(candidate, candidate_keys)

        event_values == [] or candidate_values == [] or
          Enum.any?(candidate_values, &(&1 in event_values))
      end
    )
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_struct{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
