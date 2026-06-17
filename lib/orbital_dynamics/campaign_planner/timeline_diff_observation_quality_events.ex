defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityEventPayload
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityFields

  def timeline_diff_changed_observation_quality_gap?(row, callbacks) do
    score = TimelineDiffObservationQualityFields.image_quality_score(row, callbacks)
    status = TimelineDiffObservationQualityFields.image_quality_status(row, callbacks)

    cloud_cover_fraction =
      TimelineDiffObservationQualityFields.cloud_cover_fraction(row, callbacks)

    blur_score = TimelineDiffObservationQualityFields.blur_score(row, callbacks)

    {factor, _source} =
      callback!(callbacks, :observation_quality_feedback_factor).(
        score,
        status,
        cloud_cover_fraction,
        blur_score
      )

    callback!(callbacks, :timeline_diff_changed_target_id).(row) not in [nil, ""] and
      factor < 1.0 and
      (is_number(score) or is_number(cloud_cover_fraction) or is_number(blur_score) or
         status not in [nil, ""])
  end

  def timeline_diff_changed_observation_quality_event(row, source_path, callbacks) do
    TimelineDiffObservationQualityEventPayload.build(row, source_path, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
