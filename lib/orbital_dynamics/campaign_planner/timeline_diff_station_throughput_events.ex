defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffStationThroughputFields

  def timeline_diff_changed_station_throughput_pressure_row?(row, policy, callbacks) do
    row["diff_status"] == "changed" and
      (callback!(callbacks, :timeline_diff_changed_downlink?).(row) or
         callback!(callbacks, :timeline_diff_changed_contact?).(row)) and
      timeline_diff_changed_station_throughput_events(row, "timeline_diff", policy, callbacks) !=
        []
  end

  def timeline_diff_changed_station_throughput_events(row, source_path, policy, callbacks) do
    factor = TimelineDiffStationThroughputFields.factor(row, callbacks)
    threshold = TimelineDiffStationThroughputFields.threshold(row, policy, callbacks)

    if callback!(callbacks, :low_feedback_factor?).(factor, threshold) do
      [timeline_diff_changed_station_throughput_event(row, source_path, factor, callbacks)]
    else
      []
    end
  end

  defp timeline_diff_changed_station_throughput_event(row, source_path, factor, callbacks) do
    %{
      "type" => "station_throughput_feedback",
      "scenario_id" => callback!(callbacks, :timeline_diff_changed_scenario_id).(row),
      "ground_station_id" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "starts_at_s" => callback!(callbacks, :timeline_diff_changed_window_start_s).(row),
      "ends_at_s" => callback!(callbacks, :timeline_diff_changed_window_end_s).(row),
      "station_throughput_factor" => factor,
      "actual_throughput_mb" => TimelineDiffStationThroughputFields.actual_mb(row, callbacks),
      "estimated_throughput_mb" =>
        TimelineDiffStationThroughputFields.expected_mb(row, callbacks),
      "expected_throughput_mb" => TimelineDiffStationThroughputFields.expected_mb(row, callbacks),
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
        "timeline_diff_changed_station_throughput"
      ],
      "feedback_source" => source_path,
      "feedback_scope" => "timeline_diff",
      "feedback_key" => callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      "trust_boundary" => callback!(callbacks, :timeline_diff_trust_boundary).(row)
    }
    |> callback!(callbacks, :compact_map).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
