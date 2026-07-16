defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateDiffRow do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "diff_reason" => Map.get(artifact, "diff_reason"),
      "matched_prior_candidate_id" => Map.get(artifact, "matched_prior_candidate_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "changed_field_count" => count(artifact, "changed_fields"),
      "changed_field_order" =>
        artifact
        |> list_values("changed_fields")
        |> Enum.join("|"),
      "candidate_diff_changed_field_count" =>
        Map.get(artifact, "candidate_diff_changed_field_count"),
      "candidate_diff_changed_field_order" =>
        artifact
        |> list_values("candidate_diff_changed_fields")
        |> Enum.join("|"),
      "semantic_change_reason_count" => count(artifact, "semantic_change_reasons"),
      "semantic_change_reason_order" =>
        artifact
        |> list_values("semantic_change_reasons")
        |> Enum.join("|"),
      "semantic_change_detail_count" => count(artifact, "semantic_change_details"),
      "target_id" => Map.get(artifact, "target_id"),
      "source_target_id" => Map.get(artifact, "source_target_id"),
      "target_priority" => Map.get(artifact, "target_priority"),
      "target_priority_source" => Map.get(artifact, "target_priority_source"),
      "target_priority_objective_type" => Map.get(artifact, "target_priority_objective_type"),
      "target_priority_objective_count" => count(artifact, "target_priority_objective_ids")
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
