defmodule OrbitalDynamics.Timeline.ActivityObservationEvidenceContext do
  @moduledoc false

  def quality(activity) do
    %{
      "image_quality_score" =>
        first_number(activity, ["image_quality_score", "product_quality_score", "quality_score"]),
      "image_quality_status" =>
        first_scalar_string(activity, [
          "image_quality_status",
          "product_quality_status",
          "quality_status"
        ]),
      "image_quality_source" =>
        first_scalar_string(activity, [
          "image_quality_source",
          "product_quality_source",
          "quality_source"
        ]),
      "cloud_cover_fraction" =>
        first_number(activity, ["cloud_cover_fraction", "cloud_fraction", "cloud_cover"]),
      "blur_score" =>
        first_number(activity, ["blur_score", "image_blur_score", "sharpness_loss_fraction"])
    }
    |> compact_map()
  end

  def lighting(activity) do
    %{
      "eclipse_overlap_fraction" => first_number(activity, ["eclipse_overlap_fraction"]),
      "eclipse_overlap_s" => first_number(activity, ["eclipse_overlap_s"]),
      "lighting_condition" =>
        first_scalar_string(activity, ["lighting_condition", "lighting_status"]),
      "lighting_condition_detail" =>
        first_scalar_string(activity, ["lighting_condition_detail", "lighting_detail"]),
      "lighting_condition_model" =>
        first_scalar_string(activity, ["lighting_condition_model", "lighting_model"]),
      "lighting_detail_model" =>
        first_scalar_string(activity, ["lighting_detail_model", "lighting_detail_source"]),
      "lighting_confidence" =>
        first_number_or_scalar(activity, ["lighting_confidence", "lighting_confidence_label"])
    }
    |> compact_map()
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp first_number_or_scalar(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number_or_scalar(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
