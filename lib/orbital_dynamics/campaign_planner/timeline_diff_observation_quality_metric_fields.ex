defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityMetricFields do
  @moduledoc false

  def image_quality_score(row, callbacks) do
    value =
      callback!(callbacks, :timeline_diff_first_number).(row, [
        "image_quality_score",
        "replacement_image_quality_score",
        "replacement_product_quality_score",
        "replacement_quality_score",
        ["replacement_activity_context", "image_quality_score"],
        ["replacement_activity_context", "product_quality_score"],
        ["replacement_activity_context", "quality_score"],
        ["replacement_activity_context", "quality", "image_quality_score"],
        ["replacement_activity_context", "quality", "product_quality_score"],
        ["replacement_activity_context", "quality", "score"],
        "source_image_quality_score",
        "source_product_quality_score",
        "source_quality_score",
        ["source_activity_context", "image_quality_score"],
        ["source_activity_context", "product_quality_score"],
        ["source_activity_context", "quality_score"],
        ["source_activity_context", "quality", "image_quality_score"],
        ["source_activity_context", "quality", "product_quality_score"],
        ["source_activity_context", "quality", "score"]
      ])

    callback!(callbacks, :unit_interval_number_or_nil).(value)
  end

  def cloud_cover_fraction(row, callbacks) do
    value =
      callback!(callbacks, :timeline_diff_first_number).(row, [
        "cloud_cover_fraction",
        "replacement_cloud_cover_fraction",
        "replacement_cloud_fraction",
        "replacement_cloud_cover",
        ["replacement_activity_context", "cloud_cover_fraction"],
        ["replacement_activity_context", "cloud_fraction"],
        ["replacement_activity_context", "cloud_cover"],
        ["replacement_activity_context", "quality", "cloud_cover_fraction"],
        ["replacement_activity_context", "quality", "cloud_fraction"],
        ["replacement_activity_context", "quality", "cloud_cover"],
        "source_cloud_cover_fraction",
        "source_cloud_fraction",
        "source_cloud_cover",
        ["source_activity_context", "cloud_cover_fraction"],
        ["source_activity_context", "cloud_fraction"],
        ["source_activity_context", "cloud_cover"],
        ["source_activity_context", "quality", "cloud_cover_fraction"],
        ["source_activity_context", "quality", "cloud_fraction"],
        ["source_activity_context", "quality", "cloud_cover"]
      ])

    callback!(callbacks, :unit_interval_number_or_nil).(value)
  end

  def blur_score(row, callbacks) do
    value =
      callback!(callbacks, :timeline_diff_first_number).(row, [
        "blur_score",
        "replacement_blur_score",
        "replacement_image_blur_score",
        "replacement_sharpness_loss_fraction",
        ["replacement_activity_context", "blur_score"],
        ["replacement_activity_context", "image_blur_score"],
        ["replacement_activity_context", "sharpness_loss_fraction"],
        ["replacement_activity_context", "quality", "blur_score"],
        ["replacement_activity_context", "quality", "image_blur_score"],
        ["replacement_activity_context", "quality", "sharpness_loss_fraction"],
        "source_blur_score",
        "source_image_blur_score",
        "source_sharpness_loss_fraction",
        ["source_activity_context", "blur_score"],
        ["source_activity_context", "image_blur_score"],
        ["source_activity_context", "sharpness_loss_fraction"],
        ["source_activity_context", "quality", "blur_score"],
        ["source_activity_context", "quality", "image_blur_score"],
        ["source_activity_context", "quality", "sharpness_loss_fraction"]
      ])

    callback!(callbacks, :unit_interval_number_or_nil).(value)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
