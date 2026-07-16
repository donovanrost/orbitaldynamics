defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCommandFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    ScalarValues,
    TimelineDiffActivityFields,
    TimelineDiffStatusTransitionFields
  }

  def pressure_row?(row), do: pressure_row?(row, default_callbacks())

  def pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and command?(row) and gap?(row, callbacks)
  end

  def command?(row) do
    type =
      row["replacement_activity_type"] || row["source_activity_type"] ||
        get_in(row, ["replacement_activity_context", "activity_type"]) ||
        get_in(row, ["replacement_activity_context", "type"]) ||
        get_in(row, ["source_activity_context", "activity_type"]) ||
        get_in(row, ["source_activity_context", "type"])

    direction =
      row["replacement_direction"] || row["source_direction"] ||
        get_in(row, ["replacement_activity_context", "direction"]) ||
        get_in(row, ["source_activity_context", "direction"])

    type in ["command", "health_check"] or
      (type in ["planned_contact", "contact"] and
         direction in ["command", "uplink", "health_check"])
  end

  def gap?(row), do: gap?(row, default_callbacks())

  def gap?(row, callbacks) do
    case success_factor(row, callbacks) do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  def event(row, source_path), do: event(row, source_path, default_callbacks())

  def event(row, source_path, callbacks) do
    %{
      "type" => "command_success_feedback",
      "activity_id" => row["source_activity_id"] || row["replacement_activity_id"],
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "command_success_factor" => success_factor(row, callbacks),
      "command_result" => command_result(row, callbacks),
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
        "timeline_diff_changed_command"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => row["source_activity_id"] || row["replacement_activity_id"],
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  def success_factor(row), do: success_factor(row, default_callbacks())

  def success_factor(row, callbacks) do
    [
      row["command_success_factor"],
      row["replacement_command_success_factor"],
      get_in(row, ["replacement_activity_context", "command_success_factor"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        callback!(callbacks, :clamp_unit_interval).(value)

      _value ->
        row
        |> callback!(callbacks, :timeline_diff_changed_replacement_evidence).()
        |> callback!(callbacks, :command_success_value).()
    end
  end

  def command_result(row), do: command_result(row, default_callbacks())

  def command_result(row, callbacks) do
    [
      row["replacement_command_result"],
      get_in(row, ["replacement_activity_context", "command_result"]),
      row["command_result"],
      row["source_command_result"],
      get_in(row, ["source_activity_context", "command_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      timeline_diff_changed_replacement_evidence:
        &TimelineDiffActivityFields.replacement_evidence/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1
    ]
  end
end
