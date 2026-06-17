defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationOutcomeEvents do
  @moduledoc false

  def timeline_diff_changed_observation_gap?(row, callbacks) do
    case timeline_diff_changed_observation_success_factor(row, callbacks) do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  def timeline_diff_changed_observation_event(row, source_path, callbacks) do
    %{
      "type" => "urgent_target",
      "objective_type" => "target_revisit",
      "target_id" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "required_observations" => 1,
      "planned_observations" => 0,
      "observation_success_factor" =>
        timeline_diff_changed_observation_success_factor(row, callbacks),
      "observation_result" => timeline_diff_changed_observation_result(row, callbacks),
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
      "derivation_reasons" => [
        "timeline_diff_changed_activity",
        "timeline_diff_changed_observation"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  def timeline_diff_changed_observation_success_factor(row, callbacks) do
    [
      row["observation_success_factor"],
      row["replacement_observation_success_factor"],
      get_in(row, ["replacement_activity_context", "observation_success_factor"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        callback!(callbacks, :clamp_unit_interval).(value)

      _value ->
        row
        |> callback!(callbacks, :timeline_diff_changed_replacement_evidence).()
        |> callback!(callbacks, :observation_success_value).()
    end
  end

  def timeline_diff_changed_observation_result(row, callbacks) do
    [
      row["replacement_observation_result"],
      get_in(row, ["replacement_activity_context", "observation_result"]),
      row["observation_result"],
      row["source_observation_result"],
      get_in(row, ["source_activity_context", "observation_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
