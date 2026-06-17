defmodule OrbitalDynamics.CampaignPlanner.CandidateDiffReplacementAddition do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CandidateDiffMetadata
  alias OrbitalDynamics.CampaignPlanner.EventFeasibilityContext

  def build(replacement, event, candidate_diff) do
    replacement_id = event["replacement_candidate_id"]

    replacement
    |> put_repair_metadata(
      %{
        "action" => "strategic_addition",
        "reason" => "candidate_diff_replacement_inserted",
        "requires_approval" => true
      }
      |> CandidateDiffMetadata.put(candidate_diff)
    )
    |> put_in(
      ["feasibility"],
      %{
        "status" => "validated_candidate_diff_replacement",
        "replacement_candidate_id" => replacement_id,
        "invalidated_candidate_id" => event["invalidated_candidate_id"],
        "source_window_id" => event["source_window_id"],
        "replacement_source_window_id" => event["replacement_source_window_id"],
        "source_target_id" => event["source_target_id"],
        "source_target" => event["source_target"],
        "target_latitude_deg" => event["target_latitude_deg"],
        "target_longitude_deg" => event["target_longitude_deg"],
        "target_minimum_elevation_deg" => event["target_minimum_elevation_deg"],
        "target_priority" => event["target_priority"],
        "target_priority_source" => event["target_priority_source"],
        "target_priority_objective_ids" => event["target_priority_objective_ids"],
        "target_priority_objective_type" => event["target_priority_objective_type"],
        "changed_fields" => event["changed_fields"] || candidate_diff["changed_fields"],
        "candidate_diff_changed_fields" =>
          event["candidate_diff_changed_fields"] ||
            candidate_diff["candidate_diff_changed_fields"],
        "candidate_diff_changed_field_count" =>
          event["candidate_diff_changed_field_count"] ||
            candidate_diff["candidate_diff_changed_field_count"],
        "requires_approval" => true,
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "source_candidate_diff" => candidate_diff
      }
      |> Map.merge(EventFeasibilityContext.build(event))
      |> compact_map()
    )
  end

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
