defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineDiffSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    review_rows = map_rows(artifact, "review_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source" => Map.get(artifact, "source"),
      "source_activity_count" => Map.get(artifact, "source_activity_count"),
      "replacement_activity_count" => Map.get(artifact, "replacement_activity_count"),
      "row_count" => Map.get(artifact, "row_count"),
      "added_count" => Map.get(artifact, "added_count"),
      "removed_count" => Map.get(artifact, "removed_count"),
      "changed_count" => Map.get(artifact, "changed_count"),
      "unchanged_count" => Map.get(artifact, "unchanged_count"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "review_row_count" => length(review_rows),
      "diff_status_counts" => Map.get(artifact, "diff_status_counts"),
      "row_derived_diff_status_counts" => count_rows_by_value(review_rows, "diff_status"),
      "transition_decision_counts" => Map.get(artifact, "transition_decision_counts"),
      "row_derived_transition_decision_counts" =>
        count_rows_by_value(review_rows, "transition_decision"),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(review_rows, "required_operator_action"),
      "changed_field_counts" => Map.get(artifact, "changed_field_counts"),
      "row_derived_changed_field_counts" =>
        review_rows
        |> Enum.flat_map(&list_values(&1, "changed_fields"))
        |> list_value_counts(),
      "status_transition_category_counts" =>
        Map.get(artifact, "status_transition_category_counts"),
      "row_derived_status_transition_category_counts" =>
        nested_row_value_counts(review_rows, ["status_transition", "transition_category"]),
      "approval_transition_category_counts" =>
        Map.get(artifact, "approval_transition_category_counts"),
      "row_derived_approval_transition_category_counts" =>
        nested_row_value_counts(review_rows, ["approval_transition", "transition_category"]),
      "review_timeline_ids_by_required_operator_action" =>
        Map.get(artifact, "review_timeline_ids_by_required_operator_action"),
      "row_derived_review_timeline_ids_by_required_operator_action" =>
        review_rows
        |> group_row_ids_by_value("required_operator_action", "timeline_id")
        |> sort_grouped_values(),
      "review_timeline_keys" =>
        artifact
        |> list_values("review_timeline_ids")
        |> Enum.join("|"),
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
