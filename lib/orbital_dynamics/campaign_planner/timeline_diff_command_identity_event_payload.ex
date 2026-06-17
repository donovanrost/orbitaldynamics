defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCommandIdentityEventPayload do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffContactCommandIdentityFields

  def build(row, source_path, callbacks) do
    %{
      "type" => "command_success_feedback",
      "activity_id" => row["source_activity_id"] || row["replacement_activity_id"],
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "planned_ground_station_id" =>
        TimelineDiffContactCommandIdentityFields.planned_ground_station_id(row, callbacks),
      "realized_ground_station_id" =>
        TimelineDiffContactCommandIdentityFields.realized_ground_station_id(row, callbacks),
      "ground_station_match_status" =>
        TimelineDiffContactCommandIdentityFields.command_identity_match_status(
          row,
          "ground_station",
          callbacks
        ),
      "direction" => TimelineDiffContactCommandIdentityFields.contact_direction(row, callbacks),
      "planned_direction" =>
        TimelineDiffContactCommandIdentityFields.planned_contact_direction(row, callbacks),
      "realized_direction" =>
        TimelineDiffContactCommandIdentityFields.realized_contact_direction(row, callbacks),
      "direction_match_status" =>
        TimelineDiffContactCommandIdentityFields.command_identity_match_status(
          row,
          "direction",
          callbacks
        ),
      "source_window_id" =>
        TimelineDiffContactCommandIdentityFields.contact_source_window_id(row, callbacks),
      "planned_source_window_id" =>
        TimelineDiffContactCommandIdentityFields.planned_source_window_id(row, callbacks),
      "realized_source_window_id" =>
        TimelineDiffContactCommandIdentityFields.realized_source_window_id(row, callbacks),
      "source_window_match_status" =>
        TimelineDiffContactCommandIdentityFields.command_identity_match_status(
          row,
          "source_window",
          callbacks
        ),
      "command_identity_mismatch_fields" =>
        TimelineDiffContactCommandIdentityFields.command_identity_mismatch_fields(row, callbacks),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "command_success_factor" => 0.0,
      "command_result" => callback!(callbacks, :timeline_diff_changed_command_result).(row),
      "realized_status" => callback!(callbacks, :timeline_diff_changed_realized_status).(row),
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
        TimelineDiffContactCommandIdentityFields.command_identity_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => row["source_activity_id"] || row["replacement_activity_id"],
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
