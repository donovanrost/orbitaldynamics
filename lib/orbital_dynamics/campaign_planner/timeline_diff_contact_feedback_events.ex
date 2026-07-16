defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffContactFeedbackEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    ScalarValues,
    TimelineDiffActivityFields,
    TimelineDiffLinkQualityTelemetryFields,
    TimelineDiffStatusTransitionFields
  }

  def pressure_row?(row), do: pressure_row?(row, default_callbacks())

  def pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and contact?(row) and gap?(row, callbacks)
  end

  def contact?(row) do
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

    type in ["downlink", "tracking"] or
      (type in ["planned_contact", "contact"] and
         direction not in ["command", "uplink", "health_check"])
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
      "type" => "contact_success_feedback",
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "contact_success_factor" => success_factor(row, callbacks),
      "contact_result" => result(row, callbacks),
      "realized_status" => callback!(callbacks, :timeline_diff_changed_realized_status).(row),
      "link_margin_db" => callback!(callbacks, :timeline_diff_changed_link_margin_db).(row),
      "snr_db" => callback!(callbacks, :timeline_diff_changed_snr_db).(row),
      "eb_no_db" => callback!(callbacks, :timeline_diff_changed_eb_no_db).(row),
      "bit_error_rate" => callback!(callbacks, :timeline_diff_changed_bit_error_rate).(row),
      "packet_loss_rate" => callback!(callbacks, :timeline_diff_changed_packet_loss_rate).(row),
      "frame_loss_rate" => callback!(callbacks, :timeline_diff_changed_frame_loss_rate).(row),
      "carrier_lock" => callback!(callbacks, :timeline_diff_changed_carrier_lock).(row),
      "symbol_lock" => callback!(callbacks, :timeline_diff_changed_symbol_lock).(row),
      "link_quality_status" =>
        callback!(callbacks, :timeline_diff_changed_link_quality_status).(row),
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
        "timeline_diff_changed_contact"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
  end

  def success_factor(row), do: success_factor(row, default_callbacks())

  def success_factor(row, callbacks) do
    [
      row["contact_success_factor"],
      row["replacement_contact_success_factor"],
      get_in(row, ["replacement_activity_context", "contact_success_factor"])
    ]
    |> Enum.map(&callback!(callbacks, :numeric_or_nil).(&1))
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        callback!(callbacks, :clamp_unit_interval).(value)

      _value ->
        row
        |> callback!(callbacks, :timeline_diff_changed_replacement_evidence).()
        |> callback!(callbacks, :contact_success_value).()
    end
  end

  def result(row), do: result(row, default_callbacks())

  def result(row, callbacks) do
    [
      row["replacement_contact_result"],
      get_in(row, ["replacement_activity_context", "contact_result"]),
      row["contact_result"],
      row["source_contact_result"],
      get_in(row, ["source_activity_context", "contact_result"])
    ]
    |> Enum.map(&callback!(callbacks, :provider_result_artifact_value).(&1))
    |> Enum.find(&callback!(callbacks, :provider_result_artifact_string?).(&1))
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_ground_station_id: &TimelineDiffActivityFields.ground_station_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_link_margin_db:
        &TimelineDiffLinkQualityTelemetryFields.link_margin_db/1,
      timeline_diff_changed_snr_db: &TimelineDiffLinkQualityTelemetryFields.snr_db/1,
      timeline_diff_changed_eb_no_db: &TimelineDiffLinkQualityTelemetryFields.eb_no_db/1,
      timeline_diff_changed_bit_error_rate:
        &TimelineDiffLinkQualityTelemetryFields.bit_error_rate/1,
      timeline_diff_changed_packet_loss_rate:
        &TimelineDiffLinkQualityTelemetryFields.packet_loss_rate/1,
      timeline_diff_changed_frame_loss_rate:
        &TimelineDiffLinkQualityTelemetryFields.frame_loss_rate/1,
      timeline_diff_changed_carrier_lock: &TimelineDiffLinkQualityTelemetryFields.carrier_lock/1,
      timeline_diff_changed_symbol_lock: &TimelineDiffLinkQualityTelemetryFields.symbol_lock/1,
      timeline_diff_changed_link_quality_status:
        &TimelineDiffLinkQualityTelemetryFields.link_quality_status/1,
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
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1
    ]
  end
end
