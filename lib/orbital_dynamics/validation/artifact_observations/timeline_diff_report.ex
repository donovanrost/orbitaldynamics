defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineDiffReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_activity_count" => Map.get(artifact, "source_activity_count"),
      "replacement_activity_count" => Map.get(artifact, "replacement_activity_count"),
      "row_count" => length(rows),
      "added_count" => Map.get(artifact, "added_count"),
      "changed_count" => Map.get(artifact, "changed_count"),
      "removed_count" => Map.get(artifact, "removed_count"),
      "unchanged_count" => Map.get(artifact, "unchanged_count"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "duplicate_timeline_identity_count" =>
        Map.get(artifact, "duplicate_timeline_identity_count"),
      "duplicate_source_timeline_identity_count" =>
        Map.get(artifact, "duplicate_source_timeline_identity_count"),
      "duplicate_replacement_timeline_identity_count" =>
        Map.get(artifact, "duplicate_replacement_timeline_identity_count"),
      "diff_status_counts" => Map.get(artifact, "diff_status_counts"),
      "row_derived_diff_status_counts" => count_rows_by_value(rows, "diff_status"),
      "approval_transition_counts" => Map.get(artifact, "approval_transition_counts"),
      "row_derived_approval_transition_counts" =>
        nested_row_value_counts(rows, ["approval_transition", "transition_type"]),
      "status_transition_counts" => Map.get(artifact, "status_transition_counts"),
      "row_derived_status_transition_counts" =>
        nested_row_value_counts(rows, ["status_transition", "transition_type"]),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "changed_field_counts" => Map.get(artifact, "changed_field_counts"),
      "row_derived_changed_field_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "changed_fields"))
        |> list_value_counts(),
      "row_ids_by_diff_status" =>
        rows
        |> group_row_ids_by_value("diff_status", "id")
        |> sort_grouped_values(),
      "row_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "row_derived_row_ids_by_diff_status" =>
        rows
        |> group_row_ids_by_value("diff_status", "id")
        |> sort_grouped_values(),
      "row_derived_row_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
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

  defp nested_row_value_counts(rows, path) when is_list(rows) and is_list(path) do
    rows
    |> Enum.map(&get_in(&1, path))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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
