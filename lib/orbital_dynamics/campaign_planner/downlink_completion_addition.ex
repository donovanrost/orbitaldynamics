defmodule OrbitalDynamics.CampaignPlanner.DownlinkCompletionAddition do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CandidateDiffMetadata
  alias OrbitalDynamics.CampaignPlanner.EventFeasibilityContext

  def build(candidate, event, candidate_diff, throughput_context, candidate_downlink_mb) do
    feasibility =
      %{
        "status" => "validated_candidate_window",
        "ground_station_id" => candidate["ground_station_id"],
        "selected_scenario_id" => candidate["scenario_id"],
        "source_window" => Map.get(candidate, "source_window", %{"type" => "candidate_activity"}),
        "required_contacts" => event["required_contacts"],
        "planned_contacts" => event["planned_contacts"],
        "required_downlink_mb" => throughput_context["required_downlink_mb"],
        "planned_downlink_mb" => throughput_context["planned_downlink_mb"],
        "staged_downlink_mb" => throughput_context["staged_downlink_mb"],
        "candidate_downlink_mb" => candidate_downlink_mb,
        "requires_approval" => true
      }
      |> Map.merge(EventFeasibilityContext.build(event))
      |> compact_map()
      |> CandidateDiffMetadata.put(candidate_diff)

    put_repair_metadata(
      candidate,
      %{
        "action" => "strategic_addition",
        "reason" => addition_reason(event),
        "requires_approval" => true
      }
      |> CandidateDiffMetadata.put(candidate_diff)
    )
    |> put_in(["feasibility"], feasibility)
  end

  defp addition_reason(%{"objective_type" => "collection_latency"}),
    do: "collection_latency_downlink_candidate_inserted"

  defp addition_reason(%{"derivation_reasons" => reasons}) when is_list(reasons) do
    cond do
      "storage_margin_low" in reasons -> "storage_relief_downlink_candidate_inserted"
      "downlink_margin_low" in reasons -> "downlink_margin_candidate_inserted"
      true -> "downlink_completion_candidate_inserted"
    end
  end

  defp addition_reason(_event), do: "downlink_completion_candidate_inserted"

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
