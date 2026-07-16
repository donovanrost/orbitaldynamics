defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalTimelineReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "activity_count" => Map.get(artifact, "activity_count"),
      "row_count" => length(rows),
      "contact_count" => Map.get(artifact, "contact_count"),
      "command_count" => Map.get(artifact, "command_count"),
      "approved_count" => Map.get(artifact, "approved_count"),
      "executed_count" => Map.get(artifact, "executed_count"),
      "locked_count" => Map.get(artifact, "locked_count"),
      "terminal_exception_count" => Map.get(artifact, "terminal_exception_count"),
      "dependency_count" => Map.get(artifact, "dependency_count"),
      "dependency_issue_count" => Map.get(artifact, "dependency_issue_count"),
      "exclusivity_count" => Map.get(artifact, "exclusivity_count"),
      "exclusivity_issue_count" => Map.get(artifact, "exclusivity_issue_count"),
      "timeline_integrity_issue_count" => Map.get(artifact, "timeline_integrity_issue_count"),
      "timeline_integrity_review_count" => Map.get(artifact, "timeline_integrity_review_count"),
      "duplicate_timeline_identity_count" =>
        Map.get(artifact, "duplicate_timeline_identity_count"),
      "duplicate_timeline_identity_activity_count" =>
        Map.get(artifact, "duplicate_timeline_identity_activity_count"),
      "source_window_lineage_count" => Map.get(artifact, "source_window_lineage_count"),
      "operational_kind_counts" => Map.get(artifact, "operational_kind_counts"),
      "row_derived_operational_kind_counts" => count_rows_by_value(rows, "operational_kind"),
      "activity_status_counts" => Map.get(artifact, "activity_status_counts"),
      "row_derived_activity_status_counts" => count_rows_by_value(rows, "status"),
      "approval_status_counts" => Map.get(artifact, "approval_status_counts"),
      "row_derived_approval_status_counts" => count_rows_by_value(rows, "approval_status"),
      "cadence_import_status_counts" => Map.get(artifact, "cadence_import_status_counts"),
      "row_derived_cadence_import_status_counts" =>
        count_rows_by_value(rows, "cadence_import_status"),
      "required_operator_action_counts" => Map.get(artifact, "required_operator_action_counts"),
      "row_derived_required_operator_action_counts" =>
        count_rows_by_value(rows, "required_operator_action"),
      "timeline_integrity_issue_type_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "timeline_integrity_issue_types"))
        |> list_value_counts(),
      "row_derived_timeline_integrity_issue_type_counts" =>
        rows
        |> Enum.flat_map(&list_values(&1, "timeline_integrity_issue_types"))
        |> list_value_counts(),
      "timeline_row_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "row_derived_timeline_row_ids_by_required_operator_action" =>
        rows
        |> group_row_ids_by_value("required_operator_action", "id")
        |> sort_grouped_values(),
      "timeline_row_ids_by_integrity_status" =>
        rows
        |> operational_timeline_row_ids_by_integrity_status()
        |> sort_grouped_values(),
      "row_derived_timeline_row_ids_by_integrity_status" =>
        rows
        |> operational_timeline_row_ids_by_integrity_status()
        |> sort_grouped_values(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "missing_dependency_validation" =>
        get_in(artifact, ["assumptions", "missing_dependency_validation"]),
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

  defp operational_timeline_row_ids_by_integrity_status(rows) do
    rows
    |> Enum.group_by(
      &(Map.get(&1, "timeline_integrity_status") || "none"),
      &Map.get(&1, "id")
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
