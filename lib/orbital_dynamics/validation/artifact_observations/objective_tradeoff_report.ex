defmodule OrbitalDynamics.Validation.ArtifactObservations.ObjectiveTradeoffReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    tradeoffs = map_rows(artifact, "tradeoffs")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "objective" => Map.get(artifact, "objective"),
      "ranking_count" => Map.get(artifact, "ranking_count"),
      "tradeoff_row_count" => length(tradeoffs),
      "score_term_key_count" => count(artifact, "score_term_keys"),
      "activity_count_total" => sum_numeric(tradeoffs, "activity_count"),
      "selected_observation_count_total" => sum_numeric(tradeoffs, "selected_observation_count"),
      "selected_contact_count_total" => sum_numeric(tradeoffs, "selected_contact_count"),
      "score_total" => sum_numeric(tradeoffs, "score"),
      "score_delta_from_selected_total" => sum_numeric(tradeoffs, "score_delta_from_selected"),
      "scenario_ids_by_rank" =>
        tradeoffs
        |> group_row_ids_by_value("rank", "scenario_id")
        |> sort_grouped_values(),
      "score_term_key_counts" =>
        artifact
        |> Map.get("score_term_keys")
        |> list_value_counts(),
      "selection_assumption" => get_in(artifact, ["assumptions", "selection"]),
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

  defp list_value_counts(values) when is_list(values) do
    values
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp list_value_counts(_values), do: %{}

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
