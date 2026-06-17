defmodule OrbitalDynamics.CampaignPlanner.EventFeasibilityContext do
  @moduledoc false

  def build(event) do
    %{
      "source_event_type" => event["type"],
      "source_event_id" => event["id"],
      "source_branch_id" => event["branch_id"],
      "source_activity_id" => event["source_activity_id"],
      "source_activity_ids" => event["source_activity_ids"],
      "source_window_id" => event["source_window_id"],
      "source_window_ids" => event["source_window_ids"],
      "source_timeline_id" => event["timeline_id"],
      "objective_id" => event["objective_id"],
      "objective_ids" => event["objective_ids"],
      "objective_type" => event["objective_type"],
      "target_id" => event["target_id"],
      "target_ids" => event["target_ids"],
      "collection_id" => event["collection_id"],
      "collection_ids" => event["collection_ids"],
      "product_id" => event["product_id"],
      "product_ids" => event["product_ids"],
      "payload_id" => event["payload_id"],
      "payload_ids" => event["payload_ids"],
      "instrument_id" => event["instrument_id"],
      "instrument_ids" => event["instrument_ids"],
      "contact_result" => event["contact_result"],
      "observation_result" => event["observation_result"],
      "command_result" => event["command_result"],
      "realized_status" => event["realized_status"],
      "status_transition" => event["status_transition"],
      "transition_type" => event["transition_type"],
      "transition_category" => event["transition_category"],
      "transition_reason" => event["transition_reason"],
      "requires_operator_review" => event["requires_operator_review"],
      "downlink_demand_sources" => event["downlink_demand_sources"],
      "downlink_completion_sources" => event["downlink_completion_sources"],
      "feedback_source" => event["feedback_source"],
      "feedback_scope" => event["feedback_scope"],
      "trust_boundary" =>
        event["trust_boundary"] || get_in(event, ["provenance", "trust_boundary"]),
      "source_event_provenance" => event["provenance"],
      "derivation_reason" => event["derivation_reason"],
      "derivation_reasons" => event["derivation_reasons"],
      "capacity_pack_group_id" => event["capacity_pack_group_id"],
      "capacity_pack_status" => event["capacity_pack_status"],
      "capacity_pack_capacity_fraction" => event["capacity_pack_capacity_fraction"],
      "capacity_pack_used_fraction" => event["capacity_pack_used_fraction"]
    }
    |> compact_map()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
