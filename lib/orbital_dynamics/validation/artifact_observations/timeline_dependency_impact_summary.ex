defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineDependencyImpactSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "dependency_impact_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "source" => Map.get(artifact, "source"),
      "source_activity_count" => Map.get(artifact, "source_activity_count"),
      "replacement_activity_count" => Map.get(artifact, "replacement_activity_count"),
      "changed_source_activity_count" => Map.get(artifact, "changed_source_activity_count"),
      "changed_source_timeline_count" => Map.get(artifact, "changed_source_timeline_count"),
      "dependency_impact_status" => Map.get(artifact, "dependency_impact_status"),
      "dependent_activity_count" => Map.get(artifact, "dependent_activity_count"),
      "source_dependent_activity_count" => Map.get(artifact, "source_dependent_activity_count"),
      "replacement_dependent_activity_count" =>
        Map.get(artifact, "replacement_dependent_activity_count"),
      "impacted_source_activity_keys" =>
        artifact
        |> list_values("impacted_source_activity_ids")
        |> Enum.join("|"),
      "dependent_activity_keys" =>
        artifact
        |> list_values("dependent_activity_ids")
        |> Enum.join("|"),
      "impacted_dependency_activity_keys" =>
        artifact
        |> list_values("impacted_dependency_activity_ids")
        |> Enum.join("|"),
      "impacted_exclusive_with_activity_keys" =>
        artifact
        |> list_values("impacted_exclusive_with_activity_ids")
        |> Enum.join("|"),
      "dependency_impact_row_count" => length(rows),
      "row_derived_scope_counts" => count_rows_by_value(rows, "scope"),
      "row_derived_dependency_impact_status_counts" =>
        count_rows_by_value(rows, "dependency_impact_status"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "row_derived_operator_action_reason_counts" =>
        count_rows_by_value(rows, "operator_action_reason"),
      "row_derived_activity_type_counts" => count_rows_by_value(rows, "activity_type"),
      "row_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
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

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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
