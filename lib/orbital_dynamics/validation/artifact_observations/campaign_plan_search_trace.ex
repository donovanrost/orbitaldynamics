defmodule OrbitalDynamics.Validation.ArtifactObservations.CampaignPlanSearchTrace do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    id = Map.get(artifact, "id")
    plan_id = Map.get(artifact, "plan_id")
    search_result = map_value(artifact, "search_result")
    search_root = map_value(artifact, "search_root")
    alternatives = map_rows(search_result, "alternatives")
    selected_alternative = map_value(artifact, "selected_alternative")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => id,
      "plan_id" => plan_id,
      "identity_matches_plan_id" => identity_matches_plan_id?(id, plan_id),
      "status" => Map.get(artifact, "status"),
      "selection_contract" => Map.get(artifact, "selection_contract"),
      "selected_alternative_id" => Map.get(artifact, "selected_alternative_id"),
      "selected_activity_count" => Map.get(artifact, "selected_activity_count"),
      "selected_timeline_scenario_id" => Map.get(artifact, "selected_timeline_scenario_id"),
      "selected_timeline_score" => Map.get(artifact, "selected_timeline_score"),
      "selected_alternative_eligible" =>
        get_in(selected_alternative, ["candidate_feasibility", "eligible"]),
      "search_objective" => Map.get(search_result, "objective"),
      "alternative_count" => length(alternatives),
      "eligible_count" => Map.get(search_result, "eligible_count"),
      "infeasible_count" => Map.get(search_result, "infeasible_count"),
      "rejected_move_count" => count(search_result, "rejected_moves"),
      "source_evidence_registry_id" => get_in(search_root, ["source_evidence_registry", "id"]),
      "source_evidence_registry_entry_count" =>
        count(search_root, "source_evidence_registry_entries"),
      "source_candidate_evidence_count" => count(search_root, "source_candidate_evidence")
    }
  end

  defp identity_matches_plan_id?(id, plan_id)
       when is_binary(id) and is_binary(plan_id),
       do: id == "campaign_plan_search_trace:#{plan_id}"

  defp identity_matches_plan_id?(_id, _plan_id), do: false

  defp count(map, key), do: length(map_rows(map, key))

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp map_value(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
