defmodule OrbitalDynamics.CampaignPlanner.DownlinkDemandFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackSourceMetadata,
    ValueEncoding
  }

  def events(
        demands,
        demand_sources,
        station_ids,
        threshold_mb,
        horizon_end_s,
        trust_boundary
      )
      when is_map(demands) do
    events(
      demands,
      demand_sources,
      station_ids,
      threshold_mb,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def events(
        demands,
        demand_sources,
        station_ids,
        threshold_mb,
        horizon_end_s,
        trust_boundary,
        callbacks
      )
      when is_map(demands) do
    demands
    |> Enum.flat_map(fn
      {"default", required_downlink_mb} ->
        if downlink_demand_relevant?(required_downlink_mb, threshold_mb) do
          [
            event(
              nil,
              required_downlink_mb,
              "default",
              demand_sources_for(demand_sources, "default", callbacks),
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          ]
        else
          []
        end

      {station_id, required_downlink_mb} ->
        if station_id in station_ids and
             downlink_demand_relevant?(required_downlink_mb, threshold_mb) do
          [
            event(
              station_id,
              required_downlink_mb,
              "station",
              demand_sources_for(demand_sources, station_id, callbacks),
              horizon_end_s,
              trust_boundary,
              callbacks
            )
          ]
        else
          []
        end
    end)
    |> Enum.sort_by(&{Map.get(&1, "ground_station_id", ""), &1["required_downlink_mb"]})
  end

  defp demand_sources_for(%{} = demand_sources, key, callbacks) do
    encoded_key = encode_value(key, callbacks)

    Map.get(demand_sources, encoded_key, Map.get(demand_sources, key, []))
  end

  defp demand_sources_for(_demand_sources, _key, _callbacks), do: []

  defp source_list(sources, callbacks) do
    sources
    |> List.wrap()
    |> Enum.map(&encode_value(&1, callbacks))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      source_list -> source_list
    end
  end

  defp downlink_demand_relevant?(required_downlink_mb, threshold_mb)
       when is_number(required_downlink_mb) and is_number(threshold_mb),
       do: required_downlink_mb > threshold_mb

  defp downlink_demand_relevant?(required_downlink_mb, _threshold_mb)
       when is_number(required_downlink_mb),
       do: required_downlink_mb > 0.0

  defp downlink_demand_relevant?(_required_downlink_mb, _threshold_mb), do: false

  defp event(
         station_id,
         required_downlink_mb,
         source_scope,
         demand_sources,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "downlink_demand_feedback",
      "required_downlink_mb" => required_downlink_mb |> max(0.0),
      "feedback_source" => "operational_feedback.downlink_demand_mb",
      "feedback_scope" => source_scope,
      "downlink_demand_sources" => source_list(demand_sources, callbacks),
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "ground_station_id" => station_id,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "downlink_demand_mb",
          station_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp encode_value(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:encode_value)
    |> then(& &1.(value))
  end

  defp compact_map(map, callbacks) do
    callbacks
    |> Keyword.fetch!(:compact_map)
    |> then(& &1.(map))
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key, callbacks) do
    callbacks
    |> Keyword.fetch!(:feedback_event_trust_boundary)
    |> then(& &1.(trust_boundary, field, key))
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key) do
    OperationalFeedbackSourceMetadata.feedback_event_trust_boundary(
      trust_boundary,
      field,
      key,
      []
    )
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      encode_value: &ValueEncoding.encode_value/1,
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3
    ]
  end
end
