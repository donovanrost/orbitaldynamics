defmodule OrbitalDynamics.CampaignPlanner.StrategicAdditionActivityContext do
  @moduledoc false

  def build(activity) do
    %{
      "target_id" => activity["target_id"],
      "source_target_id" =>
        activity["source_target_id"] || get_in(activity, ["feasibility", "source_target_id"]),
      "source_target" =>
        activity["source_target"] || get_in(activity, ["feasibility", "source_target"]),
      "target_latitude_deg" =>
        activity["target_latitude_deg"] ||
          get_in(activity, ["feasibility", "target_latitude_deg"]),
      "target_longitude_deg" =>
        activity["target_longitude_deg"] ||
          get_in(activity, ["feasibility", "target_longitude_deg"]),
      "target_minimum_elevation_deg" =>
        activity["target_minimum_elevation_deg"] ||
          get_in(activity, ["feasibility", "target_minimum_elevation_deg"]),
      "ground_station_id" => activity["ground_station_id"],
      "scenario_id" => activity["scenario_id"],
      "starts_at_s" => activity["starts_at_s"],
      "ends_at_s" => activity["ends_at_s"],
      "duration_s" => activity["duration_s"],
      "source_window_id" => activity["source_window_id"],
      "source_window" => activity["source_window"],
      "score" => activity["score"],
      "score_terms" => activity["score_terms"],
      "target_priority" =>
        activity["target_priority"] || get_in(activity, ["feasibility", "target_priority"]),
      "target_priority_source" =>
        activity["target_priority_source"] ||
          get_in(activity, ["feasibility", "target_priority_source"]),
      "target_priority_objective_ids" =>
        activity["target_priority_objective_ids"] ||
          get_in(activity, ["feasibility", "target_priority_objective_ids"]),
      "target_priority_objective_type" =>
        activity["target_priority_objective_type"] ||
          get_in(activity, ["feasibility", "target_priority_objective_type"]),
      "changed_fields" =>
        get_in(activity, ["feasibility", "changed_fields"]) ||
          get_in(activity, ["repair", "candidate_diff", "changed_fields"]),
      "candidate_diff_changed_fields" =>
        get_in(activity, ["feasibility", "candidate_diff_changed_fields"]) ||
          get_in(activity, ["repair", "candidate_diff", "candidate_diff_changed_fields"]),
      "candidate_diff_changed_field_count" =>
        get_in(activity, ["feasibility", "candidate_diff_changed_field_count"]) ||
          get_in(activity, ["repair", "candidate_diff", "candidate_diff_changed_field_count"]),
      "observation_success_factor" => activity["observation_success_factor"],
      "observation_success_factor_source" => activity["observation_success_factor_source"],
      "contact_success_factor" => activity["contact_success_factor"],
      "contact_success_factor_source" => activity["contact_success_factor_source"],
      "estimated_throughput_mb" => activity["estimated_throughput_mb"],
      "direction" => activity["direction"],
      "feasibility_status" => get_in(activity, ["feasibility", "status"]),
      "source_event_type" => get_in(activity, ["feasibility", "source_event_type"]),
      "source_event_id" => get_in(activity, ["feasibility", "source_event_id"]),
      "source_branch_id" => get_in(activity, ["feasibility", "source_branch_id"]),
      "objective_id" => get_in(activity, ["feasibility", "objective_id"]),
      "objective_ids" => get_in(activity, ["feasibility", "objective_ids"]),
      "objective_type" => get_in(activity, ["feasibility", "objective_type"]),
      "target_ids" => get_in(activity, ["feasibility", "target_ids"]),
      "collection_id" => get_in(activity, ["feasibility", "collection_id"]),
      "collection_ids" => get_in(activity, ["feasibility", "collection_ids"]),
      "product_id" => get_in(activity, ["feasibility", "product_id"]),
      "product_ids" => get_in(activity, ["feasibility", "product_ids"]),
      "payload_id" => get_in(activity, ["feasibility", "payload_id"]),
      "payload_ids" => get_in(activity, ["feasibility", "payload_ids"]),
      "instrument_id" => get_in(activity, ["feasibility", "instrument_id"]),
      "instrument_ids" => get_in(activity, ["feasibility", "instrument_ids"]),
      "source_activity_id" => get_in(activity, ["feasibility", "source_activity_id"]),
      "source_activity_ids" => get_in(activity, ["feasibility", "source_activity_ids"]),
      "source_timeline_id" => get_in(activity, ["feasibility", "source_timeline_id"]),
      "feedback_source" => get_in(activity, ["feasibility", "feedback_source"]),
      "feedback_scope" => get_in(activity, ["feasibility", "feedback_scope"]),
      "trust_boundary" => get_in(activity, ["feasibility", "trust_boundary"]),
      "source_event_provenance" => get_in(activity, ["feasibility", "source_event_provenance"]),
      "derivation_reason" => get_in(activity, ["feasibility", "derivation_reason"]),
      "derivation_reasons" => get_in(activity, ["feasibility", "derivation_reasons"]),
      "repair_reason" => get_in(activity, ["repair", "reason"])
    }
    |> compact_map()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
