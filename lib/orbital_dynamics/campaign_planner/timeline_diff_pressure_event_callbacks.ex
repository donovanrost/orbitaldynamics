defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffPressureEventCallbacks do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    FeedbackNumericValues,
    ManeuverReviewExecutionUncertainty,
    ObservationFeedbackEvents,
    OperationalFeedbackNormalization,
    ProviderResultValues,
    RealizedActivitySuccessValues,
    RepairRealizedState,
    ScalarValues,
    ScoreTermIdentifiers,
    ScoreTermPressureBranches,
    StrategyPolicyNormalization,
    TargetPriorityFeedbackEvents,
    TimelineDiffActivityFields,
    TimelineDiffCollectionLatencyEvents,
    TimelineDiffCommandFeedbackEvents,
    TimelineDiffContactFeedbackEvents,
    TimelineDiffDownlinkFeedbackEvents,
    TimelineDiffFieldValues,
    TimelineDiffLinkQualityEvents,
    TimelineDiffLinkQualityTelemetryFields,
    TimelineDiffManeuverFeedbackEvents,
    TimelineDiffObservationFeedbackEvents,
    TimelineDiffRemovedFeedbackEvents,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def callbacks do
    [
      operator_review_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      positive_number?: &ScalarValues.positive_number?/1,
      high_feedback_priority?: &TargetPriorityFeedbackEvents.high_priority?/2,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      unit_interval_number_or_nil: &FeedbackNumericValues.unit_interval_number_or_nil/1,
      observation_quality_feedback_factor: &ObservationFeedbackEvents.quality_factor/4,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      timeline_diff_first_string: &TimelineDiffFieldValues.first_string/2,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      timeline_diff_match_status: &TimelineDiffFieldValues.match_status/2,
      timeline_diff_first_stable_id: &TimelineDiffFieldValues.first_stable_id/2,
      timeline_diff_field_value: &TimelineDiffFieldValues.field_value/2,
      score_term_primary_target_id: &ScoreTermPressureBranches.primary_target_id/1,
      score_term_station_id: &ScoreTermIdentifiers.station_id/1,
      score_term_collection_id: &ScoreTermIdentifiers.collection_id/1,
      score_term_collection_ids: &ScoreTermIdentifiers.collection_ids/1,
      score_term_product_id: &ScoreTermIdentifiers.product_id/1,
      score_term_product_ids: &ScoreTermIdentifiers.product_ids/1,
      score_term_product_id_values: &ScoreTermIdentifiers.product_id_values/1,
      score_term_payload_id: &ScoreTermIdentifiers.payload_id/1,
      score_term_payload_ids: &ScoreTermIdentifiers.payload_ids/1,
      score_term_instrument_id: &ScoreTermIdentifiers.instrument_id/1,
      score_term_instrument_ids: &ScoreTermIdentifiers.instrument_ids/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      timeline_diff_source_activity_ids: &TimelineDiffActivityFields.source_activity_ids/1,
      timeline_diff_removed_pressure_row?: &TimelineDiffRemovedFeedbackEvents.pressure_row?/1,
      timeline_diff_removed_events: &TimelineDiffRemovedFeedbackEvents.events/2,
      timeline_diff_changed_downlink_pressure_row?:
        &TimelineDiffDownlinkFeedbackEvents.pressure_row?/1,
      timeline_diff_changed_downlink_event: &TimelineDiffDownlinkFeedbackEvents.event/2,
      timeline_diff_changed_contact_pressure_row?:
        &TimelineDiffContactFeedbackEvents.pressure_row?/1,
      timeline_diff_changed_contact_event: &TimelineDiffContactFeedbackEvents.event/2,
      timeline_diff_changed_observation_pressure_row?:
        &TimelineDiffObservationFeedbackEvents.pressure_row?/2,
      timeline_diff_changed_observation_events: &TimelineDiffObservationFeedbackEvents.events/3,
      timeline_diff_changed_command_pressure_row?:
        &TimelineDiffCommandFeedbackEvents.pressure_row?/1,
      timeline_diff_changed_command_event: &TimelineDiffCommandFeedbackEvents.event/2,
      timeline_diff_changed_maneuver_pressure_row?:
        &TimelineDiffManeuverFeedbackEvents.pressure_row?/1,
      timeline_diff_changed_maneuver_events: &TimelineDiffManeuverFeedbackEvents.events/2,
      timeline_diff_changed_collection_latency_pressure_row?:
        &TimelineDiffCollectionLatencyEvents.timeline_diff_changed_collection_latency_pressure_row?/1,
      timeline_diff_changed_collection_latency_events:
        &TimelineDiffCollectionLatencyEvents.timeline_diff_changed_collection_latency_events/2,
      timeline_diff_changed_observation?: &TimelineDiffObservationFeedbackEvents.observation?/1,
      timeline_diff_changed_downlink?: &TimelineDiffDownlinkFeedbackEvents.downlink?/1,
      timeline_diff_changed_contact?: &TimelineDiffContactFeedbackEvents.contact?/1,
      timeline_diff_changed_command?: &TimelineDiffCommandFeedbackEvents.command?/1,
      timeline_diff_changed_maneuver?: &TimelineDiffManeuverFeedbackEvents.maneuver?/1,
      timeline_diff_changed_contact_gap?: &TimelineDiffContactFeedbackEvents.gap?/1,
      timeline_diff_changed_link_quality_gap?:
        &TimelineDiffLinkQualityEvents.timeline_diff_changed_link_quality_gap?/1,
      timeline_diff_changed_command_gap?: &TimelineDiffCommandFeedbackEvents.gap?/1,
      timeline_diff_changed_target_id: &TimelineDiffObservationFeedbackEvents.target_id/1,
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_ground_station_id: &TimelineDiffActivityFields.ground_station_id/1,
      timeline_diff_changed_window_start_s: &TimelineDiffActivityFields.window_start_s/1,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_required_contacts: &TimelineDiffActivityFields.required_contacts/1,
      timeline_diff_changed_planned_contacts: &TimelineDiffActivityFields.planned_contacts/1,
      timeline_diff_changed_required_downlink_mb:
        &TimelineDiffDownlinkFeedbackEvents.required_mb/1,
      timeline_diff_changed_planned_downlink_mb: &TimelineDiffDownlinkFeedbackEvents.planned_mb/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_changed_observation_result: &TimelineDiffObservationFeedbackEvents.result/1,
      timeline_diff_changed_replacement_evidence:
        &TimelineDiffActivityFields.replacement_evidence/1,
      timeline_diff_changed_contact_result: &TimelineDiffContactFeedbackEvents.result/1,
      timeline_diff_changed_command_result: &TimelineDiffCommandFeedbackEvents.command_result/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_carrier_lock: &TimelineDiffLinkQualityTelemetryFields.carrier_lock/1,
      timeline_diff_changed_symbol_lock: &TimelineDiffLinkQualityTelemetryFields.symbol_lock/1,
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
      timeline_diff_changed_link_quality_status:
        &TimelineDiffLinkQualityTelemetryFields.link_quality_status/1,
      timeline_diff_first_boolean: &TimelineDiffFieldValues.first_boolean/2,
      timeline_diff_first_number: &TimelineDiffFieldValues.first_number/2,
      low_feedback_factor?: &FeedbackNumericValues.low_feedback_factor?/2,
      numeric_policy_value: &StrategyPolicyNormalization.numeric_value/3,
      clamp_unit_interval: &FeedbackNumericValues.clamp_unit_interval/1,
      actual_data_rate_contact_throughput_mb:
        &ContactThroughputFields.actual_data_rate_contact_throughput_mb/1,
      expected_contact_throughput_mb: &ContactThroughputFields.expected_contact_throughput_mb/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      normalize_resource_margin_aliases:
        &OperationalFeedbackNormalization.normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases:
        &OperationalFeedbackNormalization.normalize_resource_availability_aliases/1,
      put_default_if_present: &ValueEncoding.put_default_if_present/3,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      compact_map: &ValueEncoding.compact_map/1,
      provider_result_artifact_value: &ProviderResultValues.artifact_value/1,
      provider_result_artifact_string?: &ProviderResultValues.artifact_string?/1,
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      maneuver_review_execution_uncertainty_entry: &ManeuverReviewExecutionUncertainty.entry/1,
      realized_completion_statuses: &RepairRealizedState.completion_statuses/0,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end
end
