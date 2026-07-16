defmodule OrbitalDynamics.CampaignPlanner.CollectionLatencyBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CollectionLatencyGaps,
    CollectionLatencyMaps,
    CollectionLatencyObjectives,
    PriorActivityContext
  }

  def build(mission_state, prior_plan) do
    activities =
      prior_plan
      |> PriorActivityContext.activities()
      |> Enum.map(&CollectionLatencyMaps.stringify_keys/1)

    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(&CollectionLatencyMaps.stringify_keys/1)
    |> Enum.filter(&CollectionLatencyObjectives.objective?/1)
    |> Enum.flat_map(fn objective ->
      objective
      |> CollectionLatencyGaps.gaps(activities, mission_state, prior_plan)
      |> Enum.map(&branch/1)
    end)
  end

  defp branch(gap) do
    %{
      "id" => branch_id(gap),
      "label" => branch_label(gap),
      "events" => [gap],
      "metadata" => %{"derived_source" => "mission_state.objectives"}
    }
  end

  defp branch_id(%{"objective_id" => objective_id} = gap)
       when is_binary(objective_id) and objective_id != "" do
    "derived_collection_latency_#{objective_id}_#{gap["source_activity_id"]}"
  end

  defp branch_id(gap), do: "derived_collection_latency_#{gap["source_activity_id"]}"

  defp branch_label(%{"objective_id" => objective_id} = gap)
       when is_binary(objective_id) and objective_id != "" do
    "Derived collection latency #{objective_id} #{gap["source_activity_id"]}"
  end

  defp branch_label(gap), do: "Derived collection latency #{gap["source_activity_id"]}"
end
