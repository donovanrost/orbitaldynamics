defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationIdentityFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationProductIdentityPayloadFields

  def timeline_diff_changed_observation_product_identity_gap?(row, callbacks) do
    callback!(callbacks, :stable_id_string?).(
      TimelineDiffObservationIdentityFields.planned_observation_target_id(row, callbacks)
    ) and
      TimelineDiffObservationIdentityFields.observation_product_identity_mismatch_fields(
        row,
        callbacks
      ) != []
  end

  def timeline_diff_changed_observation_product_identity_event(row, source_path, callbacks) do
    planned_target_id =
      TimelineDiffObservationIdentityFields.planned_observation_target_id(row, callbacks)

    %{
      "type" => "observation_success_feedback",
      "target_id" => planned_target_id,
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "source_starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "source_ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "observation_success_factor" => 0.0,
      "observation_result" =>
        callback!(callbacks, :timeline_diff_changed_observation_result).(row),
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
        TimelineDiffObservationIdentityFields.observation_product_identity_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => planned_target_id,
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> Map.merge(TimelineDiffObservationProductIdentityPayloadFields.payload(row, callbacks))
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
