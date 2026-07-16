defmodule OrbitalDynamics.Validation.ArtifactObservations.ConstraintReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "status" => Map.get(artifact, "status"),
      "constraint_count" => Map.get(artifact, "constraint_count"),
      "row_count" => Map.get(artifact, "row_count"),
      "constraint_row_count" => length(rows),
      "status_counts" =>
        Map.get(artifact, "status_counts") || count_rows_by_value(rows, "status"),
      "row_derived_status_counts" => count_rows_by_value(rows, "status"),
      "metric_counts" => count_rows_by_value(rows, "metric"),
      "row_derived_metric_counts" => count_rows_by_value(rows, "metric"),
      "operator_counts" => count_rows_by_value(rows, "operator"),
      "row_derived_operator_counts" => count_rows_by_value(rows, "operator"),
      "constraint_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "constraint_id")
        |> sort_grouped_values(),
      "row_derived_constraint_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "constraint_id")
        |> sort_grouped_values(),
      "constraint_model" => get_in(artifact, ["assumptions", "constraint_model"]),
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
