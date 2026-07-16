defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineLifecycleStateSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    review_rows = map_rows(artifact, "review_rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "planned_activity_count" => Map.get(artifact, "planned_activity_count"),
      "realized_activity_count" => Map.get(artifact, "realized_activity_count"),
      "row_count" => Map.get(artifact, "row_count"),
      "row_derived_row_count" => length(rows),
      "review_row_count" => count_collection(artifact, "review_rows"),
      "row_derived_review_row_count" => Enum.count(rows, &(&1["review_required"] == true)),
      "recordable_count" => Map.get(artifact, "recordable_count"),
      "row_derived_recordable_count" =>
        count_rows_matching(rows, "transition_decision", "record"),
      "preserved_count" => Map.get(artifact, "preserved_count"),
      "row_derived_preserved_count" => count_rows_matching(rows, "transition_decision", "none"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "row_derived_review_required_count" => Enum.count(rows, &(&1["review_required"] == true)),
      "duplicate_timeline_identity_count" =>
        Map.get(artifact, "duplicate_timeline_identity_count"),
      "row_derived_duplicate_timeline_identity_count" =>
        count_rows_matching(rows, "timeline_identity_collision", true),
      "invalid_activity_input_count" => Map.get(artifact, "invalid_activity_input_count"),
      "row_derived_invalid_activity_input_count" =>
        count_rows_matching(rows, "invalid_activity_input", true),
      "transition_decision_counts" => Map.get(artifact, "transition_decision_counts"),
      "row_derived_transition_decision_counts" => row_value_counts(rows, "transition_decision"),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        row_value_counts(rows, "required_operator_action"),
      "operator_action_reason_counts" => Map.get(artifact, "operator_action_reason_counts"),
      "row_derived_operator_action_reason_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "operator_action_reasons"))
        |> Enum.frequencies(),
      "import_action_counts" => Map.get(artifact, "import_action_counts"),
      "row_derived_import_action_counts" => row_value_counts(rows, "import_action"),
      "planned_status_category_counts" => Map.get(artifact, "planned_status_category_counts"),
      "row_derived_planned_status_category_counts" =>
        row_value_counts(rows, "planned_status_category"),
      "realized_status_category_counts" => Map.get(artifact, "realized_status_category_counts"),
      "row_derived_realized_status_category_counts" =>
        row_value_counts(rows, "realized_status_category"),
      "planned_approval_category_counts" => Map.get(artifact, "planned_approval_category_counts"),
      "row_derived_planned_approval_category_counts" =>
        row_value_counts(rows, "planned_approval_category"),
      "realized_approval_category_counts" =>
        Map.get(artifact, "realized_approval_category_counts"),
      "row_derived_realized_approval_category_counts" =>
        row_value_counts(rows, "realized_approval_category"),
      "status_transition_category_counts" =>
        Map.get(artifact, "status_transition_category_counts"),
      "row_derived_status_transition_category_counts" =>
        nested_row_value_counts(rows, ["status_transition", "transition_category"]),
      "approval_transition_category_counts" =>
        Map.get(artifact, "approval_transition_category_counts"),
      "row_derived_approval_transition_category_counts" =>
        nested_row_value_counts(rows, ["approval_transition", "transition_category"]),
      "recordable_timeline_keys" =>
        artifact
        |> list_values("recordable_timeline_ids")
        |> Enum.join("|"),
      "row_derived_recordable_timeline_keys" =>
        lifecycle_summary_timeline_keys(rows, &(&1["transition_decision"] == "record")),
      "preserved_timeline_keys" =>
        artifact
        |> list_values("preserved_timeline_ids")
        |> Enum.join("|"),
      "row_derived_preserved_timeline_keys" =>
        lifecycle_summary_timeline_keys(rows, &(&1["transition_decision"] == "none")),
      "review_timeline_keys" =>
        artifact
        |> list_values("review_timeline_ids")
        |> Enum.join("|"),
      "row_derived_review_timeline_keys" =>
        lifecycle_summary_timeline_keys(rows, &(&1["review_required"] == true)),
      "review_activity_keys" =>
        artifact
        |> list_values("review_activity_ids")
        |> Enum.join("|"),
      "row_derived_review_activity_keys" => lifecycle_summary_review_activity_keys(review_rows),
      "invalid_activity_input_keys" =>
        artifact
        |> list_values("invalid_activity_input_ids")
        |> Enum.join("|"),
      "review_timeline_ids_by_required_operator_action" =>
        Map.get(artifact, "review_timeline_ids_by_required_operator_action"),
      "row_derived_review_timeline_ids_by_required_operator_action" =>
        review_rows
        |> group_row_ids_by_value("required_operator_action", "timeline_id")
        |> sort_grouped_values(),
      "review_timeline_ids_by_operator_action_reason" =>
        Map.get(artifact, "review_timeline_ids_by_operator_action_reason"),
      "row_derived_review_timeline_ids_by_operator_action_reason" =>
        review_rows
        |> lifecycle_summary_timeline_ids_by_list_value("operator_action_reasons")
        |> sort_grouped_values(),
      "review_timeline_ids_by_approval_transition_category" =>
        Map.get(artifact, "review_timeline_ids_by_approval_transition_category"),
      "row_derived_review_timeline_ids_by_approval_transition_category" =>
        group_row_ids_by_nested_value(
          review_rows,
          ["approval_transition", "transition_category"],
          "timeline_id"
        ),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_import" => get_in(artifact, ["assumptions", "cadence_import"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"]),
      "identity_match" => get_in(artifact, ["assumptions", "identity_match"])
    }
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

  defp group_row_ids_by_nested_value(rows, value_path, id_key) do
    rows
    |> Enum.reject(&(get_in(&1, value_path) == nil))
    |> Enum.group_by(&get_in(&1, value_path), &Map.get(&1, id_key))
    |> Map.new(fn {value, ids} ->
      {to_string(value), ids |> Enum.reject(&is_nil/1) |> Enum.sort()}
    end)
  end

  defp lifecycle_summary_timeline_keys(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, "timeline_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp lifecycle_summary_review_activity_keys(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        Map.get(row, "activity_id"),
        Map.get(row, "planned_activity_id"),
        Map.get(row, "realized_activity_id")
      ] ++
        list_values(row, "planned_activity_ids") ++ list_values(row, "realized_activity_ids")
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
  end

  defp lifecycle_summary_timeline_ids_by_list_value(rows, value_key) do
    rows
    |> Enum.flat_map(fn row ->
      timeline_id = Map.get(row, "timeline_id")

      if is_binary(timeline_id) do
        row
        |> list_values(value_key)
        |> Enum.map(&{&1, timeline_id})
      else
        []
      end
    end)
    |> Enum.group_by(fn {value, _timeline_id} -> to_string(value) end, fn {_value, timeline_id} ->
      timeline_id
    end)
  end

  defp row_value_counts(rows, key) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
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

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
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
