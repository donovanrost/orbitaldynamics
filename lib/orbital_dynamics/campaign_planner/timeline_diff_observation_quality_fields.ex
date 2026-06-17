defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityMetricFields

  def image_quality_score(row, callbacks) do
    TimelineDiffObservationQualityMetricFields.image_quality_score(row, callbacks)
  end

  def cloud_cover_fraction(row, callbacks) do
    TimelineDiffObservationQualityMetricFields.cloud_cover_fraction(row, callbacks)
  end

  def blur_score(row, callbacks) do
    TimelineDiffObservationQualityMetricFields.blur_score(row, callbacks)
  end

  def image_quality_status(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "image_quality_status",
      "replacement_image_quality_status",
      "replacement_product_quality_status",
      "replacement_quality_status",
      ["replacement_activity_context", "image_quality_status"],
      ["replacement_activity_context", "product_quality_status"],
      ["replacement_activity_context", "quality_status"],
      ["replacement_activity_context", "quality", "status"],
      "source_image_quality_status",
      "source_product_quality_status",
      "source_quality_status",
      ["source_activity_context", "image_quality_status"],
      ["source_activity_context", "product_quality_status"],
      ["source_activity_context", "quality_status"],
      ["source_activity_context", "quality", "status"]
    ])
  end

  def image_quality_source(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "image_quality_source",
      "replacement_image_quality_source",
      "replacement_product_quality_source",
      "replacement_quality_source",
      ["replacement_activity_context", "image_quality_source"],
      ["replacement_activity_context", "product_quality_source"],
      ["replacement_activity_context", "quality_source"],
      ["replacement_activity_context", "quality", "source"],
      "source_image_quality_source",
      "source_product_quality_source",
      "source_quality_source",
      ["source_activity_context", "image_quality_source"],
      ["source_activity_context", "product_quality_source"],
      ["source_activity_context", "quality_source"],
      ["source_activity_context", "quality", "source"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
