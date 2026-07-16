defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineIntegrityReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    row_issue_types =
      rows
      |> Enum.flat_map(&list_values(&1, "timeline_integrity_issue_types"))
      |> Enum.sort()

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "source" => Map.get(artifact, "source"),
      "activity_count" => Map.get(artifact, "activity_count"),
      "valid_activity_count" => Map.get(artifact, "valid_activity_count"),
      "invalid_activity_input_count" => Map.get(artifact, "invalid_activity_input_count"),
      "timeline_integrity_status" => Map.get(artifact, "timeline_integrity_status"),
      "timeline_integrity_review_count" => Map.get(artifact, "timeline_integrity_review_count"),
      "row_derived_timeline_integrity_review_count" => length(rows),
      "timeline_integrity_issue_count" => Map.get(artifact, "timeline_integrity_issue_count"),
      "row_derived_timeline_integrity_issue_count" => length(row_issue_types),
      "timeline_integrity_issue_type_keys" =>
        artifact
        |> list_values("timeline_integrity_issue_types")
        |> Enum.sort()
        |> Enum.join("|"),
      "timeline_integrity_issue_type_counts" =>
        Map.get(artifact, "timeline_integrity_issue_type_counts"),
      "row_derived_timeline_integrity_issue_type_counts" => list_value_counts(row_issue_types),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "operator_action_reason_counts" => Map.get(artifact, "operator_action_reason_counts"),
      "row_derived_operator_action_reason_counts" =>
        count_rows_by_value(rows, "operator_action_reason"),
      "dependency_issue_count" => Map.get(artifact, "dependency_issue_count"),
      "exclusivity_issue_count" => Map.get(artifact, "exclusivity_issue_count"),
      "review_activity_keys" =>
        artifact
        |> list_values("review_activity_ids")
        |> Enum.join("|"),
      "review_timeline_keys" =>
        artifact
        |> list_values("review_timeline_ids")
        |> Enum.join("|"),
      "dependency_review_activity_keys" =>
        artifact
        |> list_values("dependency_review_activity_ids")
        |> Enum.join("|"),
      "exclusivity_review_activity_keys" =>
        artifact
        |> list_values("exclusivity_review_activity_ids")
        |> Enum.join("|"),
      "missing_dependency_activity_keys" =>
        artifact
        |> list_values("missing_dependency_activity_ids")
        |> Enum.join("|"),
      "dependency_order_violation_activity_keys" =>
        artifact
        |> list_values("dependency_order_violation_activity_ids")
        |> Enum.join("|"),
      "exclusivity_violation_activity_keys" =>
        artifact
        |> list_values("exclusivity_violation_activity_ids")
        |> Enum.join("|"),
      "exclusivity_violation_timeline_keys" =>
        artifact
        |> list_values("exclusivity_violation_timeline_ids")
        |> Enum.join("|"),
      "review_activity_ids_by_issue_type" =>
        Map.get(artifact, "review_activity_ids_by_issue_type"),
      "row_derived_activity_ids_by_issue_type" =>
        rows
        |> integrity_row_ids_by_issue_type("activity_id")
        |> sort_grouped_values(),
      "review_timeline_ids_by_required_operator_action" =>
        Map.get(artifact, "review_timeline_ids_by_required_operator_action"),
      "row_derived_timeline_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "timeline_id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "missing_dependency_validation" =>
        get_in(artifact, ["assumptions", "missing_dependency_validation"]),
      "scope" => get_in(artifact, ["assumptions", "scope"]),
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

  defp integrity_row_ids_by_issue_type(rows, id_key) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> list_values("timeline_integrity_issue_types")
      |> Enum.map(fn issue_type -> {issue_type, Map.get(row, id_key)} end)
    end)
    |> Enum.group_by(fn {issue_type, _id} -> issue_type end, fn {_issue_type, id} -> id end)
    |> Map.new(fn {issue_type, ids} ->
      {to_string(issue_type), Enum.reject(ids, &is_nil/1)}
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

  defp list_value_counts(values) do
    values
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
