defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    TimelineDiffActivityFields,
    TimelineDiffContactFeedbackEvents,
    TimelineDiffDownlinkFeedbackEvents,
    TimelineDiffFieldValues,
    TimelineDiffLinkQualityFields,
    TimelineDiffLinkQualityTelemetryFields,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def timeline_diff_changed_link_quality_pressure_row?(row),
    do: timeline_diff_changed_link_quality_pressure_row?(row, default_callbacks())

  def timeline_diff_changed_link_quality_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      (callback!(callbacks, :timeline_diff_changed_downlink?).(row) or
         callback!(callbacks, :timeline_diff_changed_contact?).(row)) and
      timeline_diff_changed_link_quality_gap?(row, callbacks) and
      not callback!(callbacks, :timeline_diff_changed_contact_gap?).(row)
  end

  def timeline_diff_changed_link_quality_events(row, source_path),
    do: timeline_diff_changed_link_quality_events(row, source_path, default_callbacks())

  def timeline_diff_changed_link_quality_events(row, source_path, callbacks) do
    if timeline_diff_changed_link_quality_gap?(row, callbacks) and
         not callback!(callbacks, :timeline_diff_changed_contact_gap?).(row) do
      [timeline_diff_changed_link_quality_event(row, source_path, callbacks)]
    else
      []
    end
  end

  def timeline_diff_changed_link_quality_gap?(row),
    do: timeline_diff_changed_link_quality_gap?(row, default_callbacks())

  def timeline_diff_changed_link_quality_gap?(row, callbacks) do
    TimelineDiffLinkQualityFields.link_quality_gap?(row, callbacks)
  end

  defp timeline_diff_changed_link_quality_event(row, source_path, callbacks) do
    %{
      "type" => "contact_success_feedback",
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "contact_success_factor" => 0.0,
      "contact_result" => callback!(callbacks, :timeline_diff_changed_contact_result).(row),
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
      "link_profile_mismatch_fields" =>
        TimelineDiffLinkQualityFields.link_profile_mismatch_fields(row, callbacks),
      "link_protocol" =>
        TimelineDiffLinkQualityFields.link_profile_value(row, "link_protocol", callbacks),
      "planned_link_protocol" =>
        TimelineDiffLinkQualityFields.planned_link_profile_value(row, "link_protocol", callbacks),
      "realized_link_protocol" =>
        TimelineDiffLinkQualityFields.realized_link_profile_value(row, "link_protocol", callbacks),
      "link_protocol_match_status" =>
        TimelineDiffLinkQualityFields.link_profile_match_status(row, "link_protocol", callbacks),
      "frequency_band" =>
        TimelineDiffLinkQualityFields.link_profile_value(row, "frequency_band", callbacks),
      "planned_frequency_band" =>
        TimelineDiffLinkQualityFields.planned_link_profile_value(row, "frequency_band", callbacks),
      "realized_frequency_band" =>
        TimelineDiffLinkQualityFields.realized_link_profile_value(
          row,
          "frequency_band",
          callbacks
        ),
      "frequency_band_match_status" =>
        TimelineDiffLinkQualityFields.link_profile_match_status(row, "frequency_band", callbacks),
      "modulation" =>
        TimelineDiffLinkQualityFields.link_profile_value(row, "modulation", callbacks),
      "planned_modulation" =>
        TimelineDiffLinkQualityFields.planned_link_profile_value(row, "modulation", callbacks),
      "realized_modulation" =>
        TimelineDiffLinkQualityFields.realized_link_profile_value(row, "modulation", callbacks),
      "modulation_match_status" =>
        TimelineDiffLinkQualityFields.link_profile_match_status(row, "modulation", callbacks),
      "coding_scheme" =>
        TimelineDiffLinkQualityFields.link_profile_value(row, "coding_scheme", callbacks),
      "planned_coding_scheme" =>
        TimelineDiffLinkQualityFields.planned_link_profile_value(row, "coding_scheme", callbacks),
      "realized_coding_scheme" =>
        TimelineDiffLinkQualityFields.realized_link_profile_value(row, "coding_scheme", callbacks),
      "coding_scheme_match_status" =>
        TimelineDiffLinkQualityFields.link_profile_match_status(row, "coding_scheme", callbacks),
      "polarization" =>
        TimelineDiffLinkQualityFields.link_profile_value(row, "polarization", callbacks),
      "planned_polarization" =>
        TimelineDiffLinkQualityFields.planned_link_profile_value(row, "polarization", callbacks),
      "realized_polarization" =>
        TimelineDiffLinkQualityFields.realized_link_profile_value(row, "polarization", callbacks),
      "polarization_match_status" =>
        TimelineDiffLinkQualityFields.link_profile_match_status(row, "polarization", callbacks),
      "data_rate_mbps" =>
        TimelineDiffLinkQualityFields.link_profile_data_rate_mbps(row, callbacks),
      "planned_data_rate_mbps" =>
        TimelineDiffLinkQualityFields.planned_data_rate_mbps(row, callbacks),
      "realized_data_rate_mbps" =>
        TimelineDiffLinkQualityFields.realized_data_rate_mbps(row, callbacks),
      "data_rate_delta_mbps" =>
        TimelineDiffLinkQualityFields.data_rate_delta_mbps(row, callbacks),
      "data_rate_match_status" =>
        TimelineDiffLinkQualityFields.data_rate_match_status(row, callbacks),
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
      "derivation_reasons" => TimelineDiffLinkQualityFields.link_quality_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      timeline_diff_changed_downlink?: &TimelineDiffDownlinkFeedbackEvents.downlink?/1,
      timeline_diff_changed_contact?: &TimelineDiffContactFeedbackEvents.contact?/1,
      timeline_diff_changed_contact_gap?: &TimelineDiffContactFeedbackEvents.gap?/1,
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_ground_station_id: &TimelineDiffActivityFields.ground_station_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_contact_result: &TimelineDiffContactFeedbackEvents.result/1,
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
      compact_map: &ValueEncoding.compact_map/1,
      timeline_diff_first_string: &TimelineDiffFieldValues.first_string/2,
      timeline_diff_match_status: &TimelineDiffFieldValues.match_status/2,
      timeline_diff_first_number: &TimelineDiffFieldValues.first_number/2
    ]
  end
end
