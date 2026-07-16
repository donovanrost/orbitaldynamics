defmodule OrbitalDynamics.Validation.ArtifactObservations.TimelineTransitionApplicationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    applications = map_rows(artifact, "applications")

    selected_integrity_applications =
      Enum.filter(
        applications,
        &(Map.get(&1, "selected_timeline_integrity_status") == "review_required")
      )

    selected_integrity_issue_types =
      applications
      |> Enum.flat_map(&list_values(&1, "selected_timeline_integrity_issue_types"))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_activity_count" => Map.get(artifact, "source_activity_count"),
      "replacement_activity_count" => Map.get(artifact, "replacement_activity_count"),
      "application_count" => length(applications),
      "selected_activity_count" => Map.get(artifact, "selected_activity_count"),
      "preserved_source_count" => Map.get(artifact, "preserved_source_count"),
      "recorded_replacement_count" => Map.get(artifact, "recorded_replacement_count"),
      "review_required_count" => Map.get(artifact, "review_required_count"),
      "withheld_review_count" => Map.get(artifact, "withheld_review_count"),
      "selected_timeline_integrity_issue_count" =>
        Map.get(artifact, "selected_timeline_integrity_issue_count"),
      "selected_timeline_integrity_review_count" =>
        Map.get(artifact, "selected_timeline_integrity_review_count"),
      "selected_timeline_integrity_issue_type_counts" =>
        artifact
        |> list_values("selected_timeline_integrity_issue_types")
        |> list_value_counts(),
      "row_derived_selected_timeline_integrity_issue_type_counts" =>
        list_value_counts(selected_integrity_issue_types),
      "row_derived_selected_required_operator_action_counts" =>
        count_rows_by_value(selected_integrity_applications, "required_operator_action"),
      "row_derived_selected_application_ids_by_required_operator_action" =>
        selected_integrity_applications
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "row_derived_selected_missing_dependency_activity_keys" =>
        applications
        |> Enum.flat_map(&list_values(&1, "selected_missing_dependency_activity_ids"))
        |> stable_id_keys(),
      "application_status_counts" => Map.get(artifact, "application_status_counts"),
      "row_derived_application_status_counts" =>
        count_rows_by_value(applications, "application_status"),
      "transition_decision_counts" => Map.get(artifact, "transition_decision_counts"),
      "row_derived_transition_decision_counts" =>
        count_rows_by_value(applications, "transition_decision"),
      "status_transition_counts" => Map.get(artifact, "status_transition_counts"),
      "row_derived_status_transition_counts" =>
        nested_row_value_counts(applications, ["status_transition", "transition_type"]),
      "status_transition_category_counts" =>
        Map.get(artifact, "status_transition_category_counts"),
      "row_derived_status_transition_category_counts" =>
        nested_row_value_counts(applications, ["status_transition", "transition_category"]),
      "approval_transition_counts" => Map.get(artifact, "approval_transition_counts"),
      "row_derived_approval_transition_counts" =>
        nested_row_value_counts(applications, ["approval_transition", "transition_type"]),
      "approval_transition_category_counts" =>
        Map.get(artifact, "approval_transition_category_counts"),
      "row_derived_approval_transition_category_counts" =>
        nested_row_value_counts(applications, ["approval_transition", "transition_category"]),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(applications, "required_operator_action"),
      "application_ids_by_status" =>
        applications
        |> group_row_ids_by_value("application_status", "id")
        |> sort_grouped_values(),
      "row_derived_application_ids_by_status" =>
        applications
        |> group_row_ids_by_value("application_status", "id")
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "review_gate" => get_in(artifact, ["assumptions", "review_gate"]),
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

  defp stable_id_keys(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.join("|")
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
