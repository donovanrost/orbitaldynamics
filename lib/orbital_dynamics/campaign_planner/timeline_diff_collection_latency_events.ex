defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ScalarValues,
    ScoreTermIdentifiers,
    TimelineDiffActivityFields,
    TimelineDiffCollectionLatencyFields,
    TimelineDiffContactFeedbackEvents,
    TimelineDiffDownlinkFeedbackEvents,
    TimelineDiffFieldValues,
    TimelineDiffObservationFeedbackEvents,
    TimelineDiffStatusTransitionFields,
    ValueEncoding
  }

  def timeline_diff_changed_collection_latency_pressure_row?(row),
    do: timeline_diff_changed_collection_latency_pressure_row?(row, default_callbacks())

  def timeline_diff_changed_collection_latency_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      timeline_diff_changed_collection_latency_events(row, "timeline_diff", callbacks) != []
  end

  def timeline_diff_changed_collection_latency_events(row, source_path),
    do: timeline_diff_changed_collection_latency_events(row, source_path, default_callbacks())

  def timeline_diff_changed_collection_latency_events(row, source_path, callbacks) do
    if TimelineDiffCollectionLatencyFields.gap?(row, callbacks) and
         TimelineDiffCollectionLatencyFields.routed?(row, callbacks) do
      [timeline_diff_changed_collection_latency_event(row, source_path, callbacks)]
    else
      []
    end
  end

  defp timeline_diff_changed_collection_latency_event(row, source_path, callbacks) do
    evidence = TimelineDiffCollectionLatencyFields.evidence(row, callbacks)
    max_latency_s = TimelineDiffCollectionLatencyFields.max_s(row, callbacks)
    planned_latency_s = TimelineDiffCollectionLatencyFields.planned_s(row, callbacks)
    latency_gap_s = TimelineDiffCollectionLatencyFields.gap_s(row, callbacks)
    starts_at_s = TimelineDiffCollectionLatencyFields.window_start_s(row, callbacks)

    ends_at_s =
      TimelineDiffCollectionLatencyFields.deadline_s(row, callbacks) ||
        if(is_number(starts_at_s) and is_number(max_latency_s), do: starts_at_s + max_latency_s) ||
        callback!(callbacks, :timeline_diff_changed_window_end_s).(row)

    %{
      "type" => "downlink_completion_gap",
      "objective_id" => TimelineDiffCollectionLatencyFields.objective_id(row, callbacks),
      "objective_type" => "collection_latency",
      "latency_objective" => true,
      "target_id" =>
        callback!(callbacks, :timeline_diff_changed_target_id).(row) ||
          callback!(callbacks, :score_term_primary_target_id).(evidence),
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" =>
        callback!(callbacks, :timeline_diff_changed_ground_station_id).(row) ||
          callback!(callbacks, :score_term_station_id).(evidence),
      "collection_id" => callback!(callbacks, :score_term_collection_id).(evidence),
      "collection_ids" => callback!(callbacks, :score_term_collection_ids).(evidence),
      "product_id" => callback!(callbacks, :score_term_product_id).(evidence),
      "product_ids" => callback!(callbacks, :score_term_product_ids).(evidence),
      "payload_id" => callback!(callbacks, :score_term_payload_id).(evidence),
      "payload_ids" => callback!(callbacks, :score_term_payload_ids).(evidence),
      "instrument_id" => callback!(callbacks, :score_term_instrument_id).(evidence),
      "instrument_ids" => callback!(callbacks, :score_term_instrument_ids).(evidence),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "required_contacts" => callback!(callbacks, :timeline_diff_changed_required_contacts).(row),
      "planned_contacts" => callback!(callbacks, :timeline_diff_changed_planned_contacts).(row),
      "required_downlink_mb" =>
        callback!(callbacks, :timeline_diff_changed_required_downlink_mb).(row),
      "planned_downlink_mb" =>
        callback!(callbacks, :timeline_diff_changed_planned_downlink_mb).(row),
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "latency_gap_s" => latency_gap_s,
      "source_activity_id" =>
        TimelineDiffCollectionLatencyFields.source_activity_id(row, callbacks),
      "source_activity_ids" =>
        callback!(callbacks, :timeline_diff_changed_source_activity_ids).(row),
      "missed_downlink_activity_id" =>
        TimelineDiffCollectionLatencyFields.downlink_activity_id(row, callbacks),
      "missed_downlink_activity_ids" =>
        TimelineDiffCollectionLatencyFields.downlink_activity_ids(row, callbacks),
      "realized_status" => callback!(callbacks, :timeline_diff_changed_realized_status).(row),
      "contact_result" => callback!(callbacks, :timeline_diff_changed_contact_result).(row),
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
      "derivation_reasons" => TimelineDiffCollectionLatencyFields.reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" =>
        TimelineDiffCollectionLatencyFields.source_activity_id(row, callbacks) ||
          callback!(callbacks, :score_term_collection_id).(evidence) ||
          callback!(callbacks, :timeline_diff_changed_target_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      positive_number?: &ScalarValues.positive_number?/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      encode_value: &ValueEncoding.encode_value/1,
      compact_map: &ValueEncoding.compact_map/1,
      timeline_diff_first_number: &TimelineDiffFieldValues.first_number/2,
      timeline_diff_changed_window_end_s: &TimelineDiffActivityFields.window_end_s/1,
      timeline_diff_changed_target_id: &target_id/1,
      score_term_primary_target_id: &ScoreTermIdentifiers.primary_target_id/1,
      timeline_diff_changed_scenario_id: &TimelineDiffActivityFields.scenario_id/1,
      timeline_diff_changed_ground_station_id: &TimelineDiffActivityFields.ground_station_id/1,
      score_term_station_id: &ScoreTermIdentifiers.station_id/1,
      score_term_collection_id: &ScoreTermIdentifiers.collection_id/1,
      score_term_collection_ids: &ScoreTermIdentifiers.collection_ids/1,
      score_term_product_id: &ScoreTermIdentifiers.product_id/1,
      score_term_product_ids: &ScoreTermIdentifiers.product_ids/1,
      score_term_payload_id: &ScoreTermIdentifiers.payload_id/1,
      score_term_payload_ids: &ScoreTermIdentifiers.payload_ids/1,
      score_term_instrument_id: &ScoreTermIdentifiers.instrument_id/1,
      score_term_instrument_ids: &ScoreTermIdentifiers.instrument_ids/1,
      timeline_diff_changed_required_contacts: &TimelineDiffActivityFields.required_contacts/1,
      timeline_diff_changed_planned_contacts: &TimelineDiffActivityFields.planned_contacts/1,
      timeline_diff_changed_required_downlink_mb: &required_downlink_mb/1,
      timeline_diff_changed_planned_downlink_mb: &planned_downlink_mb/1,
      timeline_diff_changed_source_activity_ids:
        &TimelineDiffActivityFields.changed_source_activity_ids/1,
      timeline_diff_changed_realized_status:
        &TimelineDiffStatusTransitionFields.realized_status/1,
      timeline_diff_changed_contact_result: &TimelineDiffContactFeedbackEvents.result/1,
      timeline_diff_changed_status_transition:
        &TimelineDiffStatusTransitionFields.status_transition/1,
      timeline_diff_changed_transition_field:
        &TimelineDiffStatusTransitionFields.transition_field/2,
      timeline_diff_changed_transition_reason:
        &TimelineDiffStatusTransitionFields.transition_reason/1,
      timeline_diff_trust_boundary: &TimelineDiffActivityFields.trust_boundary/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2
    ]
  end

  defp target_id(row) do
    TimelineDiffObservationFeedbackEvents.target_id(row, default_callbacks())
  end

  defp required_downlink_mb(row) do
    TimelineDiffDownlinkFeedbackEvents.required_mb(row, default_callbacks())
  end

  defp planned_downlink_mb(row) do
    TimelineDiffDownlinkFeedbackEvents.planned_mb(row, default_callbacks())
  end
end
