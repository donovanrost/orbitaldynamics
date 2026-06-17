defmodule OrbitalDynamics.CampaignPlanner.CandidateDiffMetadata do
  @moduledoc false

  def put(metadata, nil), do: metadata

  def put(metadata, row) do
    Map.put(metadata, "candidate_diff", metadata(row))
  end

  def metadata(row) do
    %{
      "invalidated_candidate_id" => row["invalidated_candidate_id"] || row["id"],
      "invalidated_candidate_ids" => row["invalidated_candidate_ids"],
      "replacement_candidate_id" => row["replacement_candidate_id"],
      "invalidated_reason" => row["invalidated_reason"],
      "semantic_change_reasons" => Map.get(row, "semantic_change_reasons", []),
      "semantic_change_details" => Map.get(row, "semantic_change_details", []),
      "changed_fields" => Map.get(row, "changed_fields", []),
      "candidate_diff_changed_fields" => Map.get(row, "candidate_diff_changed_fields", []),
      "candidate_diff_changed_field_count" => row["candidate_diff_changed_field_count"],
      "source_target_id" => row["source_target_id"],
      "source_target" => row["source_target"],
      "target_latitude_deg" => row["target_latitude_deg"],
      "target_longitude_deg" => row["target_longitude_deg"],
      "target_minimum_elevation_deg" => row["target_minimum_elevation_deg"],
      "target_priority" => row["target_priority"],
      "target_priority_source" => row["target_priority_source"],
      "target_priority_objective_ids" => row["target_priority_objective_ids"],
      "target_priority_objective_type" => row["target_priority_objective_type"],
      "candidate_diff_match_status" => row["candidate_diff_match_status"],
      "candidate_diff_match_count" => row["candidate_diff_match_count"],
      "semantic_match_status" => row["semantic_match_status"],
      "semantic_match_candidate_count" => row["semantic_match_candidate_count"],
      "semantic_match_candidate_ids" => row["semantic_match_candidate_ids"],
      "candidate_budget_match_status" => row["candidate_budget_match_status"],
      "candidate_budget_match_count" => row["candidate_budget_match_count"],
      "budget_dropped_candidate_ids" => row["budget_dropped_candidate_ids"]
    }
    |> Map.merge(scoped_context(row))
    |> compact_map()
  end

  def scoped_context(row) do
    row
    |> Map.take(scoped_context_fields())
    |> compact_map()
  end

  def scoped_context_fields do
    [
      "target_id",
      "target_ids",
      "collection_id",
      "collection_ids",
      "product_id",
      "product_ids",
      "payload_id",
      "payload_ids",
      "instrument_id",
      "instrument_ids",
      "objective_id",
      "objective_ids",
      "objective_type",
      "objective_types",
      "objective_status",
      "objective_statuses",
      "source_objective_status",
      "source_objective_statuses",
      "latency_objective",
      "max_latency_s",
      "planned_latency_s",
      "required_contacts",
      "planned_contacts",
      "required_downlink_mb",
      "planned_downlink_mb",
      "contact_result",
      "contact_results",
      "realized_status",
      "realized_statuses",
      "source_activity_id",
      "source_activity_ids",
      "missed_downlink_activity_id",
      "missed_downlink_activity_ids",
      "feedback_source",
      "feedback_sources",
      "feedback_scope",
      "feedback_scopes",
      "trust_boundary",
      "trust_boundaries",
      "derivation_reasons",
      "candidate_downlink_mb",
      "downlink_completion_ratio",
      "selected_downlink_shortfall_mb",
      "downlink_requirement_status",
      "downlink_completion_source",
      "downlink_completion_sources"
    ]
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
