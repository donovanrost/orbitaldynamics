defmodule OrbitalDynamics.Validation.ArtifactObservations.CandidateDiffReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    retained_candidates = map_rows(artifact, "retained_candidates")
    new_candidates = map_rows(artifact, "new_candidates")
    invalidated_candidates = map_rows(artifact, "invalidated_candidates")

    semantic_change_reasons =
      semantic_change_reasons(new_candidates, invalidated_candidates)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "prior_candidate_count" => Map.get(artifact, "prior_candidate_count"),
      "refreshed_candidate_count" => Map.get(artifact, "refreshed_candidate_count"),
      "retained_candidate_count" => Map.get(artifact, "retained_candidate_count"),
      "retained_candidate_row_count" => length(retained_candidates),
      "new_candidate_count" => Map.get(artifact, "new_candidate_count"),
      "new_candidate_row_count" => length(new_candidates),
      "invalidated_candidate_count" => Map.get(artifact, "invalidated_candidate_count"),
      "invalidated_candidate_row_count" => length(invalidated_candidates),
      "source_window_lineage_count" => count(artifact, "source_window_lineage"),
      "new_reason_counts" => count_rows_by_value(new_candidates, "diff_reason"),
      "invalidated_reason_counts" =>
        count_rows_by_value(invalidated_candidates, "invalidated_reason"),
      "semantic_change_reason_counts" => list_value_counts(semantic_change_reasons),
      "changed_field_counts" =>
        invalidated_candidates
        |> Enum.flat_map(&list_values(&1, "changed_fields"))
        |> list_value_counts(),
      "new_candidate_ids_by_reason" =>
        new_candidates
        |> group_row_ids_by_value("diff_reason", "id")
        |> sort_grouped_values(),
      "invalidated_candidate_ids_by_reason" =>
        invalidated_candidates
        |> group_row_ids_by_value("invalidated_reason", "id")
        |> sort_grouped_values(),
      "replacement_candidate_ids_by_invalidated_reason" =>
        invalidated_candidates
        |> group_row_ids_by_value("invalidated_reason", "replacement_candidate_id")
        |> sort_grouped_values(),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp group_row_ids_by_value(rows, value_key, id_key) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, value_key) || "unknown"),
      &Map.get(&1, id_key)
    )
    |> Map.new(fn {value, ids} ->
      {to_string(value), Enum.reject(ids, &is_nil/1)}
    end)
  end

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp semantic_change_reasons(new_candidates, invalidated_candidates) do
    (new_candidates ++ invalidated_candidates)
    |> Enum.flat_map(&list_values(&1, "semantic_change_reasons"))
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
