defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineActivityState do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "state_status" => Map.get(artifact, "state_status"),
      "row_count" => Map.get(artifact, "row_count"),
      "row_derived_row_count" => length(rows),
      "review_required" => Map.get(artifact, "review_required"),
      "activity_id" => Map.get(artifact, "activity_id"),
      "timeline_id" => Map.get(artifact, "timeline_id"),
      "planned_timeline_id" => Map.get(artifact, "planned_timeline_id"),
      "realized_timeline_id" => Map.get(artifact, "realized_timeline_id"),
      "feedback_kind" => Map.get(artifact, "feedback_kind"),
      "match_strategy" => Map.get(artifact, "match_strategy"),
      "planned_status" => Map.get(artifact, "planned_status"),
      "realized_status" => Map.get(artifact, "realized_status"),
      "planned_protection_decision" => Map.get(artifact, "planned_protection_decision"),
      "planned_protection_category" => Map.get(artifact, "planned_protection_category"),
      "planned_protection_reason" => Map.get(artifact, "planned_protection_reason"),
      "status_transition_category" =>
        get_in(artifact, ["status_transition", "transition_category"]),
      "activity_keys" =>
        artifact
        |> list_values("activity_ids")
        |> Enum.join("|"),
      "review_activity_keys" =>
        artifact
        |> list_values("review_activity_ids")
        |> Enum.join("|"),
      "status_counts" => Map.get(artifact, "status_counts"),
      "row_derived_status_counts" => count_rows_by_value(rows, "status"),
      "feedback_kind_counts" => Map.get(artifact, "feedback_kind_counts"),
      "row_derived_feedback_kind_counts" => count_rows_by_value(rows, "feedback_kind"),
      "match_strategy_counts" => Map.get(artifact, "match_strategy_counts"),
      "row_derived_match_strategy_counts" => count_rows_by_value(rows, "match_strategy"),
      "cadence_import_status_counts" => Map.get(artifact, "cadence_import_status_counts"),
      "row_derived_cadence_import_status_counts" =>
        count_rows_by_value(rows, "cadence_import_status"),
      "planned_protection_decision_counts" =>
        Map.get(artifact, "planned_protection_decision_counts"),
      "row_derived_planned_protection_decision_counts" =>
        count_rows_by_value(rows, "planned_protection_decision"),
      "row_derived_status_transition_category_counts" =>
        nested_row_value_counts(rows, ["status_transition", "transition_category"]),
      "activity_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "activity_id")
        |> sort_grouped_values(),
      "row_derived_activity_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "activity_id")
        |> sort_grouped_values(),
      "row_derived_activity_ids_by_match_strategy" =>
        rows
        |> group_row_ids_by_value("match_strategy", "activity_id")
        |> sort_grouped_values(),
      "artifact_only" => get_in(artifact, ["assumptions", "artifact_only"]),
      "no_schedule_mutation" => get_in(artifact, ["assumptions", "no_schedule_mutation"]),
      "no_command_execution" => get_in(artifact, ["assumptions", "no_command_execution"]),
      "source" => get_in(artifact, ["assumptions", "source"]),
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
