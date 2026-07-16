defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencyDownlinks do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityIdentity
  alias OrbitalDynamics.CampaignPlanner.ActivityTiming
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyIdentity
  alias OrbitalDynamics.CampaignPlanner.CollectionLatencyMaps
  alias OrbitalDynamics.CampaignPlanner.DownlinkCompletionCandidates

  def next_latency_s(observation, downlinks, objective) do
    event = event(objective, observation)

    downlinks
    |> Enum.filter(&event_match?(&1, event))
    |> Enum.map(&(activity_start(&1) - activity_end(observation)))
    |> Enum.reject(&(&1 < 0.0))
    |> Enum.min(fn -> nil end)
  end

  def planned_downlinks(observation, downlinks, objective, max_latency_s) do
    event = event(objective, observation, max_latency_s)

    Enum.filter(downlinks, &event_match?(&1, event))
  end

  def event(objective, observation, max_latency_s \\ nil) do
    observation_end_s = activity_end(observation)

    CollectionLatencyMaps.compact_map(%{
      "scenario_id" => Map.get(objective, "scenario_id") || observation["scenario_id"],
      "ground_station_id" => ActivityIdentity.ground_station_id(objective),
      "starts_at_s" => observation_end_s,
      "ends_at_s" => if(is_number(max_latency_s), do: observation_end_s + max_latency_s),
      "collection_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "collection_id"),
      "product_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "product_id"),
      "product_ids" => CollectionLatencyIdentity.product_ids(objective, observation),
      "payload_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "payload_id"),
      "instrument_id" =>
        CollectionLatencyIdentity.identity_value(objective, observation, "instrument_id")
    })
  end

  def volume_gap?(planned_downlink_mb, required_downlink_mb)
      when is_number(required_downlink_mb) and required_downlink_mb > 0.0 do
    planned_downlink_mb < required_downlink_mb
  end

  def volume_gap?(_planned_downlink_mb, _required_downlink_mb), do: false

  def event_match?(downlink, event) do
    DownlinkCompletionCandidates.event_match?(
      downlink,
      event,
      downlink_completion_candidate_callbacks()
    )
  end

  defp downlink_completion_candidate_callbacks,
    do: [
      event_ground_station_id: &event_ground_station_id/1,
      activity_ground_station_id: &ActivityIdentity.ground_station_id/1,
      activity_start: &activity_start/1,
      activity_end: &activity_end/1
    ]

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             ActivityIdentity.ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp activity_start(activity),
    do: ActivityTiming.activity_start(activity, activity_timing_callbacks())

  defp activity_end(activity),
    do: ActivityTiming.activity_end(activity, activity_timing_callbacks())

  defp activity_timing_callbacks, do: [numeric_or_nil: &numeric_or_nil/1]

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

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
