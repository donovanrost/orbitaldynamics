defmodule OrbitalDynamics.Validation.ArtifactObservations.LinkCapacityReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "contact_count" => Map.get(artifact, "contact_count"),
      "row_derived_contact_count" => sum_numeric(rows, "contact_count"),
      "effective_contact_count" => Map.get(artifact, "effective_contact_count"),
      "row_derived_effective_contact_count" => sum_numeric(rows, "effective_contact_count"),
      "row_count" => length(rows),
      "selected_contact_count" => Map.get(artifact, "selected_contact_count"),
      "row_derived_selected_contact_count" => sum_numeric(rows, "selected_contact_count"),
      "ignored_contact_count" => Map.get(artifact, "ignored_contact_count"),
      "row_derived_ignored_contact_count" => sum_numeric(rows, "ignored_contact_count"),
      "ignored_selected_contact_count" => Map.get(artifact, "ignored_selected_contact_count"),
      "row_derived_ignored_selected_contact_count" =>
        sum_numeric(rows, "ignored_selected_contact_count"),
      "required_downlink_contact_count" => Map.get(artifact, "required_downlink_contact_count"),
      "row_derived_required_downlink_contact_count" =>
        sum_list_counts(rows, "required_downlink_contact_ids"),
      "actual_throughput_contact_count" => Map.get(artifact, "actual_throughput_contact_count"),
      "row_derived_actual_throughput_contact_count" =>
        sum_list_counts(rows, "actual_throughput_contact_ids"),
      "actual_completion_contact_count" => Map.get(artifact, "actual_completion_contact_count"),
      "row_derived_actual_completion_contact_count" =>
        sum_list_counts(rows, "actual_completion_contact_ids"),
      "unmatched_selected_contact_count" => Map.get(artifact, "unmatched_selected_contact_count"),
      "ambiguous_selected_contact_id_count" =>
        Map.get(artifact, "ambiguous_selected_contact_id_count"),
      "duplicate_contact_candidate_count" =>
        Map.get(artifact, "duplicate_contact_candidate_count"),
      "duplicate_contact_id_count" => Map.get(artifact, "duplicate_contact_id_count"),
      "capacity_adjusted_throughput_mb" => Map.get(artifact, "capacity_adjusted_throughput_mb"),
      "estimated_throughput_mb" => Map.get(artifact, "estimated_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        Map.get(artifact, "selected_capacity_adjusted_throughput_mb"),
      "selected_estimated_throughput_mb" => Map.get(artifact, "selected_estimated_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb" =>
        Map.get(artifact, "unused_capacity_adjusted_throughput_mb"),
      "selection_utilization_status" => Map.get(artifact, "selection_utilization_status"),
      "station_count" => link_capacity_station_count(rows),
      "stations_by_selection_utilization_status" =>
        rows
        |> group_row_ids_by_value("selection_utilization_status", "ground_station_id")
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

  defp link_capacity_station_count(rows) do
    rows
    |> Enum.map(&Map.get(&1, "ground_station_id"))
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp sum_numeric(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp sum_list_counts(rows, key) do
    rows
    |> Enum.map(&count(&1, key))
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
