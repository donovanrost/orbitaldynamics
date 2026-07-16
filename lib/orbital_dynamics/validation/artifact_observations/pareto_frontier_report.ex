defmodule OrbitalDynamics.Validation.ArtifactObservations.ParetoFrontierReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "alternative_count" => Map.get(artifact, "alternative_count"),
      "row_count" => length(rows),
      "frontier_count" => Map.get(artifact, "frontier_count"),
      "dominated_count" => Map.get(artifact, "dominated_count"),
      "objective_count" => Map.get(artifact, "objective_count"),
      "frontier_ids" => Map.get(artifact, "frontier_ids"),
      "dominated_ids" => Map.get(artifact, "dominated_ids"),
      "objective_directions" => Map.get(artifact, "objective_directions"),
      "frontier_status_counts" =>
        rows
        |> Enum.map(&(Map.get(&1, "frontier") == true))
        |> list_value_counts(),
      "objective_key_count_counts" =>
        rows
        |> Enum.map(&count(&1, "objective_keys"))
        |> list_value_counts(),
      "alternative_ids_by_frontier_status" => pareto_ids_by_frontier_status(rows),
      "missing_objective_policy" => get_in(artifact, ["assumptions", "missing_objective_policy"]),
      "search_performed" => get_in(artifact, ["assumptions", "search_performed"]),
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

  defp pareto_ids_by_frontier_status(rows) do
    rows
    |> Enum.group_by(
      fn row -> if Map.get(row, "frontier") == true, do: "true", else: "false" end,
      &Map.get(&1, "id")
    )
    |> Map.new(fn {status, ids} ->
      {status, ids |> Enum.reject(&is_nil/1) |> Enum.sort()}
    end)
  end

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

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
