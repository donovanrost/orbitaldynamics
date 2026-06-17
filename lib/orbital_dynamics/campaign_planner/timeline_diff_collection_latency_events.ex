defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyFields

  def timeline_diff_changed_collection_latency_pressure_row?(row, callbacks) do
    row["diff_status"] == "changed" and
      timeline_diff_changed_collection_latency_events(row, "timeline_diff", callbacks) != []
  end

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
end
