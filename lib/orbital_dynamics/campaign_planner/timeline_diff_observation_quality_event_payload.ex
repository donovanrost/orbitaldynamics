defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityEventPayload do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationQualityFields

  def build(row, source_path, callbacks) do
    score = TimelineDiffObservationQualityFields.image_quality_score(row, callbacks)
    status = TimelineDiffObservationQualityFields.image_quality_status(row, callbacks)

    cloud_cover_fraction =
      TimelineDiffObservationQualityFields.cloud_cover_fraction(row, callbacks)

    blur_score = TimelineDiffObservationQualityFields.blur_score(row, callbacks)

    {factor, factor_source} =
      callback!(callbacks, :observation_quality_feedback_factor).(
        score,
        status,
        cloud_cover_fraction,
        blur_score
      )

    %{
      "type" => "observation_success_feedback",
      "target_id" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "source_starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "source_ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "observation_success_factor" => factor,
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_ids" =>
        callback!(callbacks, :timeline_diff_changed_source_activity_ids).(row),
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "changed_fields" => row["changed_fields"],
      "required_operator_action" => row["required_operator_action"],
      "status_transition" => callback!(callbacks, :timeline_diff_changed_status_transition).(row),
      "transition_type" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(row, "transition_type"),
      "transition_category" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(row, "transition_category"),
      "transition_reason" => callback!(callbacks, :timeline_diff_changed_transition_reason).(row),
      "requires_operator_review" =>
        callback!(callbacks, :timeline_diff_changed_transition_field).(
          row,
          "requires_operator_review"
        ),
      "derivation_reasons" => [
        "timeline_diff_changed_activity",
        "timeline_diff_changed_observation_quality"
      ],
      "quality_factor_source" => factor_source,
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> put_optional_number("image_quality_score", score)
    |> put_optional_string("image_quality_status", status)
    |> put_optional_string(
      "image_quality_source",
      TimelineDiffObservationQualityFields.image_quality_source(row, callbacks)
    )
    |> put_optional_number("cloud_cover_fraction", cloud_cover_fraction)
    |> put_optional_number("blur_score", blur_score)
  end

  defp put_optional_number(map, _field, value) when not is_number(value), do: map
  defp put_optional_number(map, field, value), do: Map.put(map, field, value)

  defp put_optional_string(map, _field, value) when value in [nil, ""], do: map
  defp put_optional_string(map, field, value), do: Map.put(map, field, value)

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
