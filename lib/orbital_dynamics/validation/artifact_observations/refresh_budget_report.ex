defmodule OrbitalDynamics.Validation.ArtifactObservations.RefreshBudgetReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    kept_candidate_ids = list_values(artifact, "kept_candidate_ids")
    dropped_candidate_ids = list_values(artifact, "dropped_candidate_ids")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "input_candidate_count" => Map.get(artifact, "input_candidate_count"),
      "kept_candidate_count" => Map.get(artifact, "kept_candidate_count"),
      "dropped_candidate_count" => Map.get(artifact, "dropped_candidate_count"),
      "max_candidate_activities" => Map.get(artifact, "max_candidate_activities"),
      "kept_candidate_id_count" => length(kept_candidate_ids),
      "dropped_candidate_id_count" => length(dropped_candidate_ids),
      "first_kept_candidate_id" => List.first(kept_candidate_ids),
      "first_dropped_candidate_id" => List.first(dropped_candidate_ids),
      "budget_stage" => get_in(artifact, ["assumptions", "budget_stage"]),
      "optimizer_search_performed" =>
        get_in(artifact, ["assumptions", "optimizer_search_performed"]),
      "selection_policy" => get_in(artifact, ["assumptions", "selection_policy"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
