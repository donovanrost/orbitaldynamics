defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineFeedbackReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "planned_count" => Map.get(artifact, "planned_count"),
      "realized_count" => Map.get(artifact, "realized_count"),
      "row_count" => length(rows),
      "operational_feedback_count" => count_collection(artifact, "operational_feedback"),
      "operational_feedback_excluded_count" =>
        Map.get(artifact, "operational_feedback_excluded_count"),
      "duplicate_realized_feedback_count" =>
        Map.get(artifact, "duplicate_realized_feedback_count"),
      "ambiguous_timeline_feedback_count" =>
        Map.get(artifact, "ambiguous_timeline_feedback_count"),
      "ambiguous_timeline_match_count" => Map.get(artifact, "ambiguous_timeline_match_count"),
      "duplicate_realized_match_count" => Map.get(artifact, "duplicate_realized_match_count"),
      "execution_uncertainty_declared_count" =>
        Map.get(artifact, "execution_uncertainty_declared_count"),
      "execution_uncertainty_missing_count" =>
        Map.get(artifact, "execution_uncertainty_missing_count"),
      "operator_review_count" => get_in(artifact, ["operator_review_package", "review_count"]),
      "cadence_import_manifest_row_count" =>
        get_in(artifact, ["cadence_import_manifest", "row_count"]),
      "status_counts" => Map.get(artifact, "status_counts"),
      "row_derived_status_counts" => count_rows_by_value(rows, "status"),
      "feedback_kind_counts" => Map.get(artifact, "feedback_kind_counts"),
      "row_derived_feedback_kind_counts" => count_rows_by_value(rows, "feedback_kind"),
      "match_strategy_counts" => Map.get(artifact, "match_strategy_counts"),
      "row_derived_match_strategy_counts" => count_rows_by_value(rows, "match_strategy"),
      "planned_protection_decision_counts" =>
        Map.get(artifact, "planned_protection_decision_counts"),
      "row_derived_planned_protection_decision_counts" =>
        count_rows_by_value(rows, "planned_protection_decision"),
      "cadence_import_status_counts" => Map.get(artifact, "cadence_import_status_counts"),
      "row_derived_cadence_import_status_counts" =>
        count_rows_by_value(rows, "cadence_import_status"),
      "realized_status_counts" => count_rows_by_value(rows, "realized_status"),
      "row_derived_realized_status_counts" => count_rows_by_value(rows, "realized_status"),
      "status_transition_category_counts" =>
        rows
        |> Enum.map(&get_in(&1, ["status_transition", "transition_category"]))
        |> list_value_counts(),
      "row_derived_status_transition_category_counts" =>
        nested_row_value_counts(rows, ["status_transition", "transition_category"]),
      "activity_ids_by_feedback_kind" =>
        rows
        |> group_row_ids_by_value("feedback_kind", "activity_id")
        |> sort_grouped_values(),
      "activity_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "activity_id")
        |> sort_grouped_values(),
      "row_derived_activity_ids_by_feedback_kind" =>
        rows
        |> group_row_ids_by_value("feedback_kind", "activity_id")
        |> sort_grouped_values(),
      "row_derived_activity_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "activity_id")
        |> sort_grouped_values(),
      "boundary" => get_in(artifact, ["assumptions", "boundary"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
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
