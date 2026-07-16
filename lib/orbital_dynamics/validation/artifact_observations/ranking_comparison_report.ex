defmodule OrbitalDynamics.Validation.ArtifactObservations.RankingComparisonReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "objective" => Map.get(artifact, "objective"),
      "objective_direction" => Map.get(artifact, "objective_direction"),
      "left_count" => Map.get(artifact, "left_count"),
      "right_count" => Map.get(artifact, "right_count"),
      "matched_count" => Map.get(artifact, "matched_count"),
      "left_only_count" => Map.get(artifact, "left_only_count"),
      "right_only_count" => Map.get(artifact, "right_only_count"),
      "row_count" => Map.get(artifact, "row_count"),
      "derived_row_count" => length(rows),
      "status_counts" => count_rows_by_value(rows, "status"),
      "scenario_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "scenario_id")
        |> sort_grouped_values(),
      "rank_delta_total" => sum_numeric(rows, "rank_delta"),
      "value_delta_total" => sum_numeric(rows, "value_delta"),
      "winner_changed" => get_in(artifact, ["winner", "changed"]),
      "external_solver" => get_in(artifact, ["assumptions", "external_solver"]),
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
