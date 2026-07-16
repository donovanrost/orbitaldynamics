defmodule OrbitalDynamics.CampaignPlanner.ObservationQualityValues do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{FeedbackNumericValues, ScalarValues, ValueEncoding}

  def image_quality_score(activity), do: image_quality_score(activity, callbacks())

  def image_quality_score(activity, callbacks) do
    first_unit_interval_activity_value(activity, callbacks, [
      "image_quality_score",
      "product_quality_score",
      "quality_score",
      ["quality", "image_quality_score"],
      ["quality", "product_quality_score"],
      ["quality", "score"],
      ["metadata", "image_quality_score"],
      ["metadata", "product_quality_score"],
      ["metadata", "quality_score"]
    ])
  end

  def image_quality_status(activity), do: image_quality_status(activity, callbacks())

  def image_quality_status(activity, callbacks) do
    first_string_activity_value(activity, callbacks, [
      "image_quality_status",
      "product_quality_status",
      "quality_status",
      ["quality", "image_quality_status"],
      ["quality", "product_quality_status"],
      ["quality", "status"],
      ["metadata", "image_quality_status"],
      ["metadata", "product_quality_status"],
      ["metadata", "quality_status"]
    ])
  end

  def image_quality_source(activity), do: image_quality_source(activity, callbacks())

  def image_quality_source(activity, callbacks) do
    first_string_activity_value(activity, callbacks, [
      "image_quality_source",
      "product_quality_source",
      "quality_source",
      ["quality", "image_quality_source"],
      ["quality", "product_quality_source"],
      ["quality", "source"],
      ["metadata", "image_quality_source"],
      ["metadata", "product_quality_source"],
      ["metadata", "quality_source"]
    ])
  end

  def cloud_cover_fraction(activity), do: cloud_cover_fraction(activity, callbacks())

  def cloud_cover_fraction(activity, callbacks) do
    first_unit_interval_activity_value(activity, callbacks, [
      "cloud_cover_fraction",
      "cloud_fraction",
      "cloud_cover",
      ["quality", "cloud_cover_fraction"],
      ["quality", "cloud_fraction"],
      ["quality", "cloud_cover"],
      ["metadata", "cloud_cover_fraction"],
      ["metadata", "cloud_fraction"],
      ["metadata", "cloud_cover"]
    ])
  end

  def blur_score(activity), do: blur_score(activity, callbacks())

  def blur_score(activity, callbacks) do
    first_unit_interval_activity_value(activity, callbacks, [
      "blur_score",
      "image_blur_score",
      "sharpness_loss_fraction",
      ["quality", "blur_score"],
      ["quality", "image_blur_score"],
      ["quality", "sharpness_loss_fraction"],
      ["metadata", "blur_score"],
      ["metadata", "image_blur_score"],
      ["metadata", "sharpness_loss_fraction"]
    ])
  end

  defp callbacks do
    [
      unit_interval_number_or_nil:
        &FeedbackNumericValues.unit_interval_number_or_nil(&1, feedback_numeric_callbacks()),
      encode_value: &ValueEncoding.encode_value/1
    ]
  end

  defp feedback_numeric_callbacks,
    do: [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false

  defp first_unit_interval_activity_value(activity, callbacks, keys) do
    unit_interval_number_or_nil = Keyword.fetch!(callbacks, :unit_interval_number_or_nil)

    Enum.find_value(keys, fn key ->
      activity
      |> activity_value(key)
      |> unit_interval_number_or_nil.()
    end)
  end

  defp first_string_activity_value(activity, callbacks, keys) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    Enum.find_value(keys, fn key ->
      case activity |> activity_value(key) |> encode_value.() do
        value when is_binary(value) and value != "" -> value
        _value -> nil
      end
    end)
  end

  defp activity_value(activity, path) when is_list(path), do: get_in(activity, path)
  defp activity_value(activity, key), do: Map.get(activity, key)
end
