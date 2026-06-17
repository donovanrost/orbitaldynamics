defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPriorityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPriorityFields

  def timeline_diff_changed_observation_target_priority_gap?(row, policy, callbacks) do
    target_id = callback!(callbacks, :timeline_diff_changed_target_id).(row)
    priority = TimelineDiffObservationPriorityFields.target_priority(row, callbacks)

    threshold =
      callback!(callbacks, :numeric_or_nil).(policy["target_priority_feedback_threshold"])

    callback!(callbacks, :stable_id_string?).(target_id) and
      callback!(callbacks, :high_feedback_priority?).(priority, threshold)
  end

  def timeline_diff_changed_observation_target_priority_event(row, source_path, callbacks) do
    target_id = callback!(callbacks, :timeline_diff_changed_target_id).(row)

    %{
      "type" => "target_priority_feedback",
      "target_id" => target_id,
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "priority" => TimelineDiffObservationPriorityFields.target_priority(row, callbacks),
      "latitude_deg" =>
        TimelineDiffObservationPriorityFields.target_number(row, "latitude_deg", callbacks),
      "longitude_deg" =>
        TimelineDiffObservationPriorityFields.target_number(row, "longitude_deg", callbacks),
      "minimum_elevation_deg" =>
        TimelineDiffObservationPriorityFields.target_number(
          row,
          "minimum_elevation_deg",
          callbacks
        ),
      "target_priority_source" =>
        TimelineDiffObservationPriorityFields.target_priority_source(row, callbacks),
      "target_priority_objective_ids" =>
        TimelineDiffObservationPriorityFields.target_priority_objective_ids(row, callbacks),
      "target_priority_objective_type" =>
        TimelineDiffObservationPriorityFields.target_priority_objective_type(row, callbacks),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
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
        "timeline_diff_changed_target_priority"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => target_id,
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
