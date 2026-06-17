defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingFields

  def timeline_diff_changed_observation_lighting_gap?(row, callbacks) do
    target_id = callback!(callbacks, :timeline_diff_changed_target_id).(row)

    callback!(callbacks, :stable_id_string?).(target_id) and
      TimelineDiffObservationLightingFields.observation_lighting_factor(row, callbacks) < 1.0 and
      TimelineDiffObservationLightingFields.observation_lighting_evidence?(row, callbacks)
  end

  def timeline_diff_changed_observation_lighting_event(row, source_path, callbacks) do
    %{
      "type" => "observation_success_feedback",
      "target_id" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "source_starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "source_ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "observation_success_factor" =>
        TimelineDiffObservationLightingFields.observation_lighting_factor(row, callbacks),
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
      "derivation_reasons" =>
        TimelineDiffObservationLightingFields.observation_lighting_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> put_optional_string(
      "lighting_condition_match_status",
      TimelineDiffObservationLightingFields.lighting_condition_match_status(row, callbacks)
    )
    |> put_optional_string(
      "planned_lighting_condition",
      TimelineDiffObservationLightingFields.planned_lighting_condition(row, callbacks)
    )
    |> put_optional_string(
      "realized_lighting_condition",
      TimelineDiffObservationLightingFields.realized_lighting_condition(row, callbacks)
    )
    |> put_optional_string(
      "lighting_condition_detail",
      TimelineDiffObservationLightingFields.lighting_condition_detail(row, callbacks)
    )
    |> put_optional_string(
      "lighting_condition_model",
      TimelineDiffObservationLightingFields.lighting_condition_model(row, callbacks)
    )
    |> put_optional_string(
      "lighting_detail_model",
      TimelineDiffObservationLightingFields.lighting_detail_model(row, callbacks)
    )
    |> put_optional_string(
      "lighting_confidence",
      TimelineDiffObservationLightingFields.lighting_confidence(row, callbacks)
    )
    |> put_optional_number(
      "eclipse_overlap_fraction",
      TimelineDiffObservationLightingFields.eclipse_overlap_fraction(row, callbacks)
    )
    |> put_optional_number(
      "eclipse_overlap_s",
      TimelineDiffObservationLightingFields.eclipse_overlap_s(row, callbacks)
    )
  end

  defp put_optional_number(map, _field, value) when not is_number(value), do: map
  defp put_optional_number(map, field, value), do: Map.put(map, field, value)

  defp put_optional_string(map, _field, value) when value in [nil, ""], do: map
  defp put_optional_string(map, field, value), do: Map.put(map, field, value)

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
