defmodule OrbitalDynamics.Validation.ArtifactObservations.OptimizerContract do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "optimizer" => Map.get(artifact, "optimizer"),
      "objective" => Map.get(artifact, "objective"),
      "selection_policy" => Map.get(artifact, "selection_policy"),
      "selected_activity_count" => Map.get(artifact, "selected_activity_count"),
      "candidate_count" => Map.get(artifact, "candidate_count"),
      "candidate_activity_id_count" => count(artifact, "candidate_activity_ids"),
      "ranked_scenario_count" => count(artifact, "ranked_scenario_ids"),
      "ranked_timeline_count" => Map.get(artifact, "ranked_timeline_count"),
      "constraint_count" => count_collection(artifact, "constraints"),
      "score_term_key_count" => count(artifact, "score_term_keys"),
      "deterministic_ordering_count" => count(artifact, "deterministic_ordering"),
      "known_limit_count" => count(artifact, "known_limits"),
      "preserved_lineage_field_count" => count(artifact, "preserved_lineage_fields"),
      "external_solver" => get_in(artifact, ["assumptions", "external_solver"]),
      "optimizer_family" => get_in(artifact, ["assumptions", "optimizer_family"]),
      "selection_scope" => get_in(artifact, ["assumptions", "selection_scope"]),
      "selected_activity_id_order" =>
        artifact
        |> list_values("selected_activity_ids")
        |> Enum.join("|"),
      "candidate_activity_id_order" =>
        artifact
        |> list_values("candidate_activity_ids")
        |> Enum.join("|")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
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
