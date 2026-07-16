defmodule OrbitalDynamics.Validation.ArtifactObservations.ContactFilterReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    suppressed_candidates = map_rows(artifact, "suppressed_candidates")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "input_candidate_count" => Map.get(artifact, "input_candidate_count"),
      "kept_candidate_count" => Map.get(artifact, "kept_candidate_count"),
      "suppressed_candidate_count" => Map.get(artifact, "suppressed_candidate_count"),
      "row_derived_suppressed_candidate_count" => length(suppressed_candidates),
      "suppressed_candidate_row_count" => length(suppressed_candidates),
      "duplicate_suppressed_candidate_id_count" =>
        Map.get(artifact, "duplicate_suppressed_candidate_id_count"),
      "duplicate_suppressed_candidate_row_count" =>
        Map.get(artifact, "duplicate_suppressed_candidate_row_count"),
      "station_reservation_match_status_counts" =>
        Map.get(artifact, "station_reservation_match_status_counts") || %{},
      "suppressed_reason_counts" =>
        count_rows_by_value(suppressed_candidates, "suppressed_reason"),
      "suppressed_station_availability_counts" =>
        count_rows_by_value(suppressed_candidates, "station_availability"),
      "suppressed_candidate_ids_by_reason" =>
        suppressed_candidates
        |> group_row_ids_by_value("suppressed_reason", "id")
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
