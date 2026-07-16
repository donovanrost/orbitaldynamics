defmodule OrbitalDynamics.CandidateRefresh.ObservationQuality do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common, only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.ObservationObjectives

  def success_factor(
        refresh,
        target_id,
        %{"observation_success_factor" => factor},
        operational_feedback,
        numeric_value
      )
      when is_number(factor) or is_binary(factor) do
    case numeric_value.(factor) do
      value when is_number(value) ->
        {1.0, value |> max(0.0) |> min(1.0),
         "operational_feedback.observation_success_rate.encoded"}

      _value ->
        success_factor(
          refresh,
          target_id,
          %{},
          operational_feedback,
          numeric_value
        )
    end
  end

  def success_factor(
        refresh,
        target_id,
        target,
        operational_feedback,
        numeric_value
      )
      when is_map(refresh) do
    if branch_event_derived_refresh?(refresh) do
      {1.0, 1.0, nil}
    else
      case success_factor_from_feedback(refresh, target_id, operational_feedback) do
        {1.0, 1.0, nil} -> success_factor_from_target_quality(target, numeric_value)
        factor -> factor
      end
    end
  end

  def quality_context(
        refresh,
        target_id,
        target,
        operational_feedback,
        numeric_value
      ) do
    target_id = encode_value(target_id)
    feedback = operational_feedback.(refresh)
    target = if is_map(target), do: target, else: %{}

    %{
      "image_quality_score" =>
        feedback_probability(feedback, "image_quality_score", target_id) ||
          first_probability(
            target,
            ["image_quality_score", "product_quality_score", "quality_score"],
            numeric_value
          ),
      "image_quality_status" =>
        feedback_string(feedback, "image_quality_status", target_id) ||
          first_string(target, ["image_quality_status", "quality_status"]),
      "image_quality_source" =>
        feedback_string(feedback, "image_quality_source", target_id) ||
          first_string(target, ["image_quality_source", "quality_source"]),
      "cloud_cover_fraction" =>
        feedback_probability(feedback, "cloud_cover_fraction", target_id) ||
          first_probability(
            target,
            ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"],
            numeric_value
          ),
      "blur_score" =>
        feedback_probability(feedback, "blur_score", target_id) ||
          first_probability(
            target,
            ["blur_score", "image_blur_score", "sharpness_loss_fraction"],
            numeric_value
          )
    }
    |> compact_map()
  end

  def target_metadata_context(%{} = target, numeric_value) do
    source_target = source_target_metadata(target, numeric_value)

    %{
      "source_target_id" => target_identity_value(target),
      "source_target" => source_target,
      "target_latitude_deg" =>
        target_metadata_number(target, ["latitude_deg", "lat_deg", "latitude"], numeric_value),
      "target_longitude_deg" =>
        target_metadata_number(target, ["longitude_deg", "lon_deg", "longitude"], numeric_value),
      "target_minimum_elevation_deg" =>
        target_metadata_number(
          target,
          ["minimum_elevation_deg", "min_elevation_deg", "minimum_elevation", "min_elevation"],
          numeric_value
        )
    }
    |> compact_map()
  end

  def target_metadata_context(_target, _numeric_value),
    do: %{}

  defp branch_event_derived_refresh?(refresh) do
    refresh
    |> Map.get("model_assumptions", %{})
    |> Map.get("candidate_refresh_level") == "branch_event_derived_v1"
  end

  defp success_factor_from_feedback(refresh, target_id, operational_feedback) do
    feedback = operational_feedback.(refresh)
    rates = Map.get(feedback, "observation_success_rate")
    image_quality_scores = Map.get(feedback, "image_quality_score")
    image_quality_statuses = Map.get(feedback, "image_quality_status")
    cloud_cover_fractions = Map.get(feedback, "cloud_cover_fraction")
    blur_scores = Map.get(feedback, "blur_score")
    target_id = encode_value(target_id)

    case rates do
      %{} ->
        cond do
          is_number(Map.get(rates, target_id)) ->
            factor = rates |> Map.get(target_id) |> max(0.0) |> min(1.0)
            {factor, factor, "operational_feedback.observation_success_rate.target"}

          is_number(Map.get(rates, "default")) ->
            factor = rates |> Map.get("default") |> max(0.0) |> min(1.0)
            {factor, factor, "operational_feedback.observation_success_rate.default"}

          true ->
            success_factor_from_quality_feedback(
              image_quality_scores,
              image_quality_statuses,
              cloud_cover_fractions,
              blur_scores,
              target_id
            )
        end

      _other ->
        success_factor_from_quality_feedback(
          image_quality_scores,
          image_quality_statuses,
          cloud_cover_fractions,
          blur_scores,
          target_id
        )
    end
  end

  defp success_factor_from_quality_feedback(
         scores,
         statuses,
         cloud_cover_fractions,
         blur_scores,
         target_id
       ) do
    case success_factor_from_image_quality(scores, target_id) do
      {1.0, 1.0, nil} ->
        case success_factor_from_image_quality_status(statuses, target_id) do
          {1.0, 1.0, nil} ->
            success_factor_from_cloud_or_blur(cloud_cover_fractions, blur_scores, target_id)

          factor ->
            factor
        end

      factor ->
        factor
    end
  end

  defp success_factor_from_image_quality(%{} = scores, target_id) do
    cond do
      is_number(Map.get(scores, target_id)) ->
        factor = scores |> Map.get(target_id) |> max(0.0) |> min(1.0)
        {factor, factor, "operational_feedback.image_quality_score.target"}

      is_number(Map.get(scores, "default")) ->
        factor = scores |> Map.get("default") |> max(0.0) |> min(1.0)
        {factor, factor, "operational_feedback.image_quality_score.default"}

      true ->
        {1.0, 1.0, nil}
    end
  end

  defp success_factor_from_image_quality(_scores, _target_id), do: {1.0, 1.0, nil}

  defp success_factor_from_image_quality_status(%{} = statuses, target_id) do
    cond do
      is_binary(Map.get(statuses, target_id)) ->
        image_quality_status_factor(Map.get(statuses, target_id), "target")

      is_binary(Map.get(statuses, "default")) ->
        image_quality_status_factor(Map.get(statuses, "default"), "default")

      true ->
        {1.0, 1.0, nil}
    end
  end

  defp success_factor_from_image_quality_status(_statuses, _target_id), do: {1.0, 1.0, nil}

  defp image_quality_status_factor(status, scope) when is_binary(status) do
    case normalized_quality_status_token(status) do
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
        {0.0, 0.0, "operational_feedback.image_quality_status.#{scope}"}

      status when status in ["poor", "degraded", "marginal", "partial"] ->
        {0.5, 0.5, "operational_feedback.image_quality_status.#{scope}"}

      _status ->
        {1.0, 1.0, nil}
    end
  end

  defp normalized_quality_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end

  defp success_factor_from_cloud_or_blur(cloud_cover_fractions, blur_scores, target_id) do
    [
      feedback_inverse_quality_factor(
        cloud_cover_fractions,
        target_id,
        "operational_feedback.cloud_cover_fraction"
      ),
      feedback_inverse_quality_factor(blur_scores, target_id, "operational_feedback.blur_score")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.min_by(fn {factor, _score, _source} -> factor end, fn -> nil end)
    |> case do
      {factor, score, source} -> {factor, score, source}
      nil -> {1.0, 1.0, nil}
    end
  end

  defp feedback_inverse_quality_factor(%{} = values, target_id, source) do
    cond do
      is_number(Map.get(values, target_id)) ->
        factor = values |> Map.get(target_id) |> inverse_quality_factor()
        {factor, factor, "#{source}.target"}

      is_number(Map.get(values, "default")) ->
        factor = values |> Map.get("default") |> inverse_quality_factor()
        {factor, factor, "#{source}.default"}

      true ->
        nil
    end
  end

  defp feedback_inverse_quality_factor(_values, _target_id, _source), do: nil

  defp inverse_quality_factor(value) when is_number(value),
    do: 1.0 - (value |> max(0.0) |> min(1.0))

  defp inverse_quality_factor(_value), do: nil

  defp success_factor_from_target_quality(%{} = target, numeric_value) do
    image_quality_score =
      first_probability(
        target,
        ["image_quality_score", "product_quality_score", "quality_score"],
        numeric_value
      )

    cloud_cover_fraction =
      first_probability(
        target,
        ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"],
        numeric_value
      )

    blur_score =
      first_probability(
        target,
        ["blur_score", "image_blur_score", "sharpness_loss_fraction"],
        numeric_value
      )

    cond do
      is_number(image_quality_score) ->
        {image_quality_score, image_quality_score, "target.image_quality_score"}

      is_number(cloud_cover_fraction) or is_number(blur_score) ->
        success_factor_from_target_cloud_or_blur(cloud_cover_fraction, blur_score)

      true ->
        {1.0, 1.0, nil}
    end
  end

  defp success_factor_from_target_quality(_target, _numeric_value), do: {1.0, 1.0, nil}

  defp success_factor_from_target_cloud_or_blur(cloud_cover_fraction, blur_score) do
    [
      {"target.cloud_cover_fraction", inverse_quality_factor(cloud_cover_fraction)},
      {"target.blur_score", inverse_quality_factor(blur_score)}
    ]
    |> Enum.filter(fn {_source, value} -> is_number(value) end)
    |> Enum.min_by(fn {_source, value} -> value end)
    |> then(fn {source, factor} -> {factor, factor, source} end)
  end

  defp feedback_probability(%{} = feedback, field, target_id) do
    case Map.get(feedback, field) do
      %{} = values ->
        Enum.find_value([target_id, "default"], fn key ->
          case Map.get(values, key) do
            value when is_number(value) -> value |> max(0.0) |> min(1.0)
            _value -> nil
          end
        end)

      _values ->
        nil
    end
  end

  defp feedback_probability(_feedback, _field, _target_id), do: nil

  defp feedback_string(%{} = feedback, field, target_id) do
    case Map.get(feedback, field) do
      %{} = values ->
        Enum.find_value([target_id, "default"], fn key ->
          case Map.get(values, key) do
            value when is_binary(value) and value != "" -> value
            _value -> nil
          end
        end)

      _values ->
        nil
    end
  end

  defp feedback_string(_feedback, _field, _target_id), do: nil

  defp first_probability(map, fields, numeric_value) do
    Enum.find_value(fields, fn field ->
      case numeric_value.(Map.get(map, field)) do
        value when is_number(value) -> value |> max(0.0) |> min(1.0)
        _value -> nil
      end
    end)
  end

  defp first_string(map, fields) do
    Enum.find_value(fields, fn field ->
      case encode_value(Map.get(map, field)) do
        value when is_binary(value) and value != "" -> value
        _value -> nil
      end
    end)
  end

  defp source_target_metadata(%{} = target, numeric_value) do
    %{
      "id" => target_identity_value(target),
      "latitude_deg" =>
        target_metadata_number(target, ["latitude_deg", "lat_deg", "latitude"], numeric_value),
      "longitude_deg" =>
        target_metadata_number(target, ["longitude_deg", "lon_deg", "longitude"], numeric_value),
      "minimum_elevation_deg" =>
        target_metadata_number(
          target,
          ["minimum_elevation_deg", "min_elevation_deg", "minimum_elevation", "min_elevation"],
          numeric_value
        ),
      "priority" =>
        target_metadata_number(target, ["priority", "target_priority"], numeric_value),
      "geometry_model" => first_string(target, ["geometry_model", "target_geometry_model"])
    }
    |> compact_map()
  end

  defp target_identity_value(%{} = target) do
    ObservationObjectives.target_identity_value(target, &encode_value/1)
  end

  defp target_metadata_number(map, fields, numeric_value) do
    Enum.find_value(fields, fn field ->
      case numeric_value.(Map.get(map, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
