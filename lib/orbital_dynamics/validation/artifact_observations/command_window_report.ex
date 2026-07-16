defmodule OrbitalDynamics.Validation.ArtifactObservations.CommandWindowReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "window_count" => Map.get(artifact, "window_count"),
      "row_count" => length(rows),
      "command_count" => Map.get(artifact, "command_count"),
      "health_check_count" => Map.get(artifact, "health_check_count"),
      "tracking_count" => Map.get(artifact, "tracking_count"),
      "uplink_count" => Map.get(artifact, "uplink_count"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "source_window_lineage_count" => Map.get(artifact, "source_window_lineage_count"),
      "locked_window_count" => Enum.count(rows, &(Map.get(&1, "locked") == true)),
      "window_type_counts" => count_rows_by_value(rows, "window_type"),
      "row_derived_window_type_counts" => count_rows_by_value(rows, "window_type"),
      "required_operator_action_counts" => count_rows_by_value(rows, "required_operator_action"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "approval_status_counts" => count_rows_by_value(rows, "approval_status"),
      "row_derived_approval_status_counts" => count_rows_by_value(rows, "approval_status"),
      "cadence_import_status_counts" => count_rows_by_value(rows, "cadence_import_status"),
      "row_derived_cadence_import_status_counts" =>
        count_rows_by_value(rows, "cadence_import_status"),
      "window_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "row_derived_window_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "boundary"]),
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
