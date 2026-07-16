defmodule OrbitalDynamics.Validation.ArtifactObservations.InvalidatedCandidate do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "type" => Map.get(artifact, "type"),
      "invalidated_reason" => Map.get(artifact, "invalidated_reason"),
      "replacement_candidate_id" => Map.get(artifact, "replacement_candidate_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "target_id" => Map.get(artifact, "target_id"),
      "target_priority" => Map.get(artifact, "target_priority"),
      "target_priority_objective_type" => Map.get(artifact, "target_priority_objective_type"),
      "changed_field_count" => count(artifact, "changed_fields"),
      "candidate_diff_changed_field_count" =>
        Map.get(artifact, "candidate_diff_changed_field_count"),
      "semantic_change_reason_count" => count(artifact, "semantic_change_reasons"),
      "semantic_change_detail_count" => count(artifact, "semantic_change_details"),
      "changed_field_order" =>
        artifact
        |> list_values("changed_fields")
        |> Enum.join("|"),
      "semantic_change_reason_order" =>
        artifact
        |> list_values("semantic_change_reasons")
        |> Enum.join("|"),
      "target_priority_objective_count" => count(artifact, "target_priority_objective_ids"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s"))
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

  defp numeric_delta(end_value, start_value)
       when is_number(end_value) and is_number(start_value) do
    end_value - start_value
  end

  defp numeric_delta(_end_value, _start_value), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
