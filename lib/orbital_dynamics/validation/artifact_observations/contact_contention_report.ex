defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactContentionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    conflict_groups = map_rows(artifact, "conflict_groups")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "input_contact_count" => Map.get(artifact, "input_contact_count"),
      "conflict_group_count" => Map.get(artifact, "conflict_group_count"),
      "row_derived_conflict_group_count" => length(conflict_groups),
      "conflict_group_row_count" => length(conflict_groups),
      "conflicted_contact_count" => Map.get(artifact, "conflicted_contact_count"),
      "row_derived_conflicted_contact_count" =>
        unique_list_value_count(conflict_groups, "contact_ids"),
      "group_contact_count_total" => sum_numeric(conflict_groups, "contact_count"),
      "row_derived_group_contact_count_total" => sum_numeric(conflict_groups, "contact_count"),
      "duplicate_contact_candidate_count" =>
        Map.get(artifact, "duplicate_contact_candidate_count"),
      "duplicate_contact_id_count" => Map.get(artifact, "duplicate_contact_id_count"),
      "review_required_group_count" =>
        count_rows_by_value(conflict_groups, "approval_status")
        |> Map.get("operator_review_required", 0),
      "row_derived_review_required_group_count" =>
        count_rows_by_value(conflict_groups, "approval_status")
        |> Map.get("operator_review_required", 0),
      "resource_scope_counts" => count_rows_by_value(conflict_groups, "resource_scope"),
      "required_operator_action_counts" =>
        count_rows_by_value(conflict_groups, "required_operator_action"),
      "conflict_group_ids_by_resource_scope" =>
        conflict_groups
        |> group_row_ids_by_value("resource_scope", "id")
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

  defp map_rows(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp unique_list_value_count(rows, key) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, key)))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
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

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
