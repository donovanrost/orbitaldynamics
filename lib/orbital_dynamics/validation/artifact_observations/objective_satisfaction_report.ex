defmodule OrbitalDynamics.Validation.ArtifactObservations.ObjectiveSatisfactionReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "objective_count" => Map.get(artifact, "objective_count"),
      "row_count" => length(rows),
      "selected_count_total" => sum_numeric(rows, "selected_count"),
      "satisfied_count_total" => sum_numeric(rows, "satisfied_count"),
      "required_count_total" => sum_numeric(rows, "required_count"),
      "status_counts" => count_rows_by_value(rows, "status"),
      "objective_type_counts" => count_rows_by_value(rows, "objective"),
      "objective_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "id")
        |> sort_grouped_values(),
      "execution_status" => get_in(artifact, ["assumptions", "execution_status"]),
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
