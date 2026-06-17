defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingFields

  def timeline_diff_changed_observation_pointing_gap?(row, callbacks) do
    target_id = TimelineDiffObservationPointingFields.feedback_target_id(row, callbacks)

    callback!(callbacks, :stable_id_string?).(target_id) and
      TimelineDiffObservationPointingFields.factor(row, callbacks) < 1.0
  end

  def timeline_diff_changed_observation_pointing_event(row, source_path, callbacks) do
    %{
      "type" => "observation_success_feedback",
      "target_id" => TimelineDiffObservationPointingFields.feedback_target_id(row, callbacks),
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "source_starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "source_ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "observation_success_factor" =>
        TimelineDiffObservationPointingFields.factor(row, callbacks),
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
      "derivation_reasons" => TimelineDiffObservationPointingFields.reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => TimelineDiffObservationPointingFields.feedback_target_id(row, callbacks),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> put_optional_string(
      "pointing_target_match_status",
      TimelineDiffObservationPointingFields.match_status(
        row,
        "pointing_target_match_status",
        callbacks
      )
    )
    |> put_optional_string(
      "pointing_mode_match_status",
      TimelineDiffObservationPointingFields.match_status(
        row,
        "pointing_mode_match_status",
        callbacks
      )
    )
    |> put_optional_string(
      "planned_pointing_target_id",
      TimelineDiffObservationPointingFields.planned_pointing_target_id(row, callbacks)
    )
    |> put_optional_string(
      "realized_pointing_target_id",
      TimelineDiffObservationPointingFields.realized_pointing_target_id(row, callbacks)
    )
    |> put_optional_string(
      "planned_pointing_mode",
      TimelineDiffObservationPointingFields.planned_pointing_mode(row, callbacks)
    )
    |> put_optional_string(
      "realized_pointing_mode",
      TimelineDiffObservationPointingFields.realized_pointing_mode(row, callbacks)
    )
    |> put_optional_string(
      "pointing_status",
      TimelineDiffObservationPointingFields.pointing_status(row, callbacks)
    )
    |> put_optional_number(
      "pointing_error_deg",
      TimelineDiffObservationPointingFields.pointing_error_deg(row, callbacks)
    )
    |> put_optional_string(
      "pointing_model",
      TimelineDiffObservationPointingFields.pointing_model(row, callbacks)
    )
    |> put_optional_string(
      "pointing_source",
      TimelineDiffObservationPointingFields.pointing_source(row, callbacks)
    )
    |> put_optional_string(
      "attitude_target_match_status",
      TimelineDiffObservationPointingFields.match_status(
        row,
        "attitude_target_match_status",
        callbacks
      )
    )
    |> put_optional_string(
      "attitude_mode_match_status",
      TimelineDiffObservationPointingFields.match_status(
        row,
        "attitude_mode_match_status",
        callbacks
      )
    )
    |> put_optional_string(
      "planned_attitude_target_id",
      TimelineDiffObservationPointingFields.planned_attitude_target_id(row, callbacks)
    )
    |> put_optional_string(
      "realized_attitude_target_id",
      TimelineDiffObservationPointingFields.realized_attitude_target_id(row, callbacks)
    )
    |> put_optional_string(
      "planned_attitude_mode",
      TimelineDiffObservationPointingFields.planned_attitude_mode(row, callbacks)
    )
    |> put_optional_string(
      "realized_attitude_mode",
      TimelineDiffObservationPointingFields.realized_attitude_mode(row, callbacks)
    )
    |> put_optional_string(
      "attitude_status",
      TimelineDiffObservationPointingFields.attitude_status(row, callbacks)
    )
    |> put_optional_number(
      "attitude_error_deg",
      TimelineDiffObservationPointingFields.attitude_error_deg(row, callbacks)
    )
    |> put_optional_string(
      "attitude_model",
      TimelineDiffObservationPointingFields.attitude_model(row, callbacks)
    )
    |> put_optional_string(
      "attitude_source",
      TimelineDiffObservationPointingFields.attitude_source(row, callbacks)
    )
  end

  defp put_optional_number(map, _field, value) when not is_number(value), do: map
  defp put_optional_number(map, field, value), do: Map.put(map, field, value)

  defp put_optional_string(map, _field, value) when value in [nil, ""], do: map
  defp put_optional_string(map, field, value), do: Map.put(map, field, value)

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
