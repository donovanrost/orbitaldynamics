defmodule OrbitalDynamics.CampaignPlanner.StationFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{OperationalFeedbackSourceMetadata, ValueEncoding}

  def station_throughput(factors, station_ids, threshold, horizon_end_s, trust_boundary)
      when is_map(factors) do
    station_throughput(
      factors,
      station_ids,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def station_throughput(
        factors,
        station_ids,
        threshold,
        horizon_end_s,
        trust_boundary,
        callbacks
      )
      when is_map(factors) do
    factors
    |> low_station_events(
      station_ids,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks,
      &station_throughput_event/6
    )
    |> Enum.sort_by(&{Map.get(&1, "ground_station_id", ""), &1["station_throughput_factor"]})
  end

  def contact_success(factors, station_ids, threshold, horizon_end_s, trust_boundary)
      when is_map(factors) do
    contact_success(
      factors,
      station_ids,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def contact_success(factors, station_ids, threshold, horizon_end_s, trust_boundary, callbacks)
      when is_map(factors) do
    factors
    |> low_station_events(
      station_ids,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks,
      &contact_success_event/6
    )
    |> Enum.sort_by(&{Map.get(&1, "ground_station_id", ""), &1["contact_success_factor"]})
  end

  defp low_station_events(
         factors,
         station_ids,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks,
         event_fun
       ) do
    Enum.flat_map(factors, fn
      {"default", factor} ->
        if low_feedback_factor?(factor, threshold) do
          [event_fun.(nil, factor, "default", horizon_end_s, trust_boundary, callbacks)]
        else
          []
        end

      {station_id, factor} ->
        if station_id in station_ids and low_feedback_factor?(factor, threshold) do
          [event_fun.(station_id, factor, "station", horizon_end_s, trust_boundary, callbacks)]
        else
          []
        end
    end)
  end

  defp low_feedback_factor?(factor, threshold) when is_number(factor) and is_number(threshold),
    do: factor < threshold

  defp low_feedback_factor?(_factor, _threshold), do: false

  defp station_throughput_event(
         station_id,
         factor,
         source_scope,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "station_throughput_feedback",
      "station_throughput_factor" => factor |> max(0.0) |> min(1.0),
      "feedback_source" => "operational_feedback.station_throughput_factor",
      "feedback_scope" => source_scope,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "ground_station_id" => station_id,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "station_throughput_factor",
          station_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp contact_success_event(
         station_id,
         factor,
         source_scope,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "contact_success_feedback",
      "contact_success_factor" => factor |> max(0.0) |> min(1.0),
      "feedback_source" => "operational_feedback.contact_success_rate",
      "feedback_scope" => source_scope,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "ground_station_id" => station_id,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "contact_success_rate",
          station_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
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
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3
    ]
  end
end
