defmodule OrbitalDynamics.CampaignPlanner.ObservationFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    OperationalFeedbackSourceMetadata,
    ScalarValues,
    ValueEncoding
  }

  def success(factors, target_ids, target_priorities, threshold, horizon_end_s, trust_boundary) do
    success(
      factors,
      target_ids,
      target_priorities,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def success(
        factors,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary,
        callbacks
      )
      when is_map(factors) do
    factors
    |> Enum.flat_map(fn
      {"default", factor} ->
        if low_feedback_factor?(factor, threshold) do
          Enum.map(
            target_ids,
            &success_event(
              &1,
              factor,
              "default",
              horizon_end_s,
              Map.get(target_priorities, &1),
              trust_boundary,
              callbacks
            )
          )
        else
          []
        end

      {target_id, factor} ->
        if target_id in target_ids and low_feedback_factor?(factor, threshold) do
          [
            success_event(
              target_id,
              factor,
              "target",
              horizon_end_s,
              Map.get(target_priorities, target_id),
              trust_boundary,
              callbacks
            )
          ]
        else
          []
        end
    end)
    |> Enum.sort_by(&{&1["target_id"], &1["observation_success_factor"]})
  end

  def quality(
        scores,
        statuses,
        sources,
        cloud_cover_fractions,
        blur_scores,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary
      ) do
    quality(
      scores,
      statuses,
      sources,
      cloud_cover_fractions,
      blur_scores,
      target_ids,
      target_priorities,
      threshold,
      horizon_end_s,
      trust_boundary,
      callbacks()
    )
  end

  def quality(
        scores,
        statuses,
        sources,
        cloud_cover_fractions,
        blur_scores,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary,
        callbacks
      )
      when is_map(scores) do
    statuses = if is_map(statuses), do: statuses, else: %{}
    sources = if is_map(sources), do: sources, else: %{}
    cloud_cover_fractions = if is_map(cloud_cover_fractions), do: cloud_cover_fractions, else: %{}
    blur_scores = if is_map(blur_scores), do: blur_scores, else: %{}

    [scores, statuses, cloud_cover_fractions, blur_scores]
    |> feedback_event_keys(callbacks)
    |> Enum.flat_map(fn
      "default" ->
        target_ids
        |> Enum.map(fn target_id ->
          quality_event(
            target_id,
            "default",
            horizon_end_s,
            Map.get(target_priorities, target_id),
            trust_boundary,
            scores,
            statuses,
            sources,
            cloud_cover_fractions,
            blur_scores,
            callbacks
          )
        end)
        |> Enum.filter(&low_feedback_factor?(&1["observation_success_factor"], threshold))

      target_id ->
        if target_id in target_ids do
          [
            quality_event(
              target_id,
              "target",
              horizon_end_s,
              Map.get(target_priorities, target_id),
              trust_boundary,
              scores,
              statuses,
              sources,
              cloud_cover_fractions,
              blur_scores,
              callbacks
            )
          ]
          |> Enum.filter(&low_feedback_factor?(&1["observation_success_factor"], threshold))
        else
          []
        end
    end)
    |> Enum.sort_by(&{&1["target_id"], &1["image_quality_score"]})
  end

  def quality_factor(score, status, cloud_cover_fraction, blur_score) do
    quality_factor(score, status, cloud_cover_fraction, blur_score, callbacks())
  end

  def quality_factor(score, status, cloud_cover_fraction, blur_score, callbacks) do
    [
      {"operational_feedback.image_quality_score", score},
      {"operational_feedback.image_quality_status",
       image_quality_status_feedback_factor(status, callbacks)},
      {"operational_feedback.cloud_cover_fraction",
       inverse_quality_factor(cloud_cover_fraction, callbacks)},
      {"operational_feedback.blur_score", inverse_quality_factor(blur_score, callbacks)}
    ]
    |> Enum.filter(fn {_source, value} -> is_number(value) end)
    |> Enum.min_by(fn {_source, value} -> value end, fn ->
      {"operational_feedback.image_quality_score", 1.0}
    end)
    |> then(fn {source, factor} -> {clamp_unit_interval(factor, callbacks), source} end)
  end

  defp feedback_event_keys(feedback_maps, callbacks) do
    feedback_maps
    |> Enum.flat_map(fn
      %{} = feedback_map -> Map.keys(feedback_map)
      _feedback_map -> []
    end)
    |> Enum.map(&encode_value(&1, callbacks))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp success_event(
         target_id,
         factor,
         source_scope,
         horizon_end_s,
         priority,
         trust_boundary,
         callbacks
       ) do
    %{
      "type" => "observation_success_feedback",
      "target_id" => target_id,
      "observation_success_factor" => factor |> max(0.0) |> min(1.0),
      "feedback_source" => "operational_feedback.observation_success_rate",
      "feedback_scope" => source_scope,
      "priority" => priority,
      "required_observations" => 1,
      "allow_placeholder" => false,
      "starts_at_s" => 0.0,
      "ends_at_s" => horizon_end_s,
      "trust_boundary" =>
        feedback_event_trust_boundary(
          trust_boundary,
          "observation_success_rate",
          target_id || "default",
          callbacks
        )
    }
    |> compact_map(callbacks)
  end

  defp quality_event(
         target_id,
         source_scope,
         horizon_end_s,
         priority,
         trust_boundary,
         scores,
         statuses,
         sources,
         cloud_cover_fractions,
         blur_scores,
         callbacks
       ) do
    score = feedback_event_number_value(scores, target_id)
    status = feedback_event_string_value(statuses, target_id, callbacks)
    cloud_cover_fraction = feedback_event_number_value(cloud_cover_fractions, target_id)
    blur_score = feedback_event_number_value(blur_scores, target_id)

    {factor, feedback_source} =
      quality_factor(score, status, cloud_cover_fraction, blur_score, callbacks)

    trust_boundary =
      feedback_event_trust_boundary(
        trust_boundary,
        operational_feedback_field_from_source(feedback_source, callbacks),
        target_id || "default",
        callbacks
      )

    target_id
    |> success_event(
      factor,
      source_scope,
      horizon_end_s,
      priority,
      trust_boundary,
      callbacks
    )
    |> Map.put("feedback_source", feedback_source)
    |> put_optional_number("image_quality_score", score)
    |> put_optional_string("image_quality_status", status)
    |> put_optional_string(
      "image_quality_source",
      feedback_event_string_value(sources, target_id, callbacks)
    )
    |> put_optional_number("cloud_cover_fraction", cloud_cover_fraction)
    |> put_optional_number("blur_score", blur_score)
  end

  defp image_quality_status_feedback_factor(status, callbacks) when is_binary(status) do
    case normalized_status_token(status, callbacks) do
      status
      when status in [
             "failed",
             "failure",
             "rejected",
             "unusable",
             "invalid",
             "missing",
             "not_usable",
             "no_image",
             "clouded_out"
           ] ->
        0.0

      status when status in ["poor", "degraded", "marginal", "partial"] ->
        0.5

      _status ->
        nil
    end
  end

  defp image_quality_status_feedback_factor(_status, _callbacks), do: nil

  defp inverse_quality_factor(value, callbacks) when is_number(value),
    do: 1.0 - clamp_unit_interval(value, callbacks)

  defp inverse_quality_factor(_value, _callbacks), do: nil

  defp feedback_event_number_value(values, target_id) do
    Enum.find_value([target_id, "default"], fn key ->
      case Map.get(values, key) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp feedback_event_string_value(values, target_id, callbacks) do
    Enum.find_value([target_id, "default"], fn key ->
      case encode_value(Map.get(values, key), callbacks) do
        value when is_binary(value) and value != "" -> value
        _value -> nil
      end
    end)
  end

  defp low_feedback_factor?(factor, threshold)
       when is_number(factor) and is_number(threshold),
       do: factor < threshold

  defp low_feedback_factor?(_factor, _threshold), do: false

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

  defp normalized_status_token(status, callbacks) do
    callbacks
    |> Keyword.fetch!(:normalized_status_token)
    |> then(& &1.(status))
  end

  defp operational_feedback_field_from_source(source, callbacks) do
    callbacks
    |> Keyword.fetch!(:operational_feedback_field_from_source)
    |> then(& &1.(source))
  end

  defp clamp_unit_interval(value, callbacks) do
    callbacks
    |> Keyword.fetch!(:clamp_unit_interval)
    |> then(& &1.(value))
  end

  defp callbacks do
    [
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      compact_map: &ValueEncoding.compact_map/1,
      encode_value: &ValueEncoding.encode_value/1,
      feedback_event_trust_boundary: &feedback_event_trust_boundary/3,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      operational_feedback_field_from_source:
        &OperationalFeedbackSourceMetadata.field_from_source/1
    ]
  end

  defp feedback_event_trust_boundary(trust_boundary, field, key) do
    OperationalFeedbackSourceMetadata.feedback_event_trust_boundary(
      trust_boundary,
      field,
      key,
      []
    )
  end

  defp put_optional_number(map, _field, value) when not is_number(value), do: map
  defp put_optional_number(map, field, value), do: Map.put(map, field, value)

  defp put_optional_string(map, _field, value) when value in [nil, ""], do: map
  defp put_optional_string(map, field, value), do: Map.put(map, field, value)
end
