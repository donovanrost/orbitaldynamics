defmodule OrbitalDynamics.Validation.ArtifactObservations.QualityGateReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "report_id" => Map.get(artifact, "report_id"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "readiness_level" => Map.get(artifact, "readiness_level"),
      "import_classification" => Map.get(artifact, "import_classification"),
      "status" => Map.get(artifact, "status"),
      "gate_count" => Map.get(artifact, "gate_count"),
      "row_derived_gate_count" => length(rows),
      "passed_gate_count" => Map.get(artifact, "passed_gate_count"),
      "row_derived_passed_gate_count" => count_rows_matching(rows, "status", "passed"),
      "review_gate_count" => Map.get(artifact, "review_gate_count"),
      "row_derived_review_gate_count" => count_rows_matching(rows, "status", "review_required"),
      "analysis_gate_count" => Map.get(artifact, "analysis_gate_count"),
      "row_derived_analysis_gate_count" => count_rows_matching(rows, "status", "analysis_only"),
      "blocked_gate_count" => Map.get(artifact, "blocked_gate_count"),
      "row_derived_blocked_gate_count" => count_rows_matching(rows, "status", "blocked"),
      "row_count" => length(rows),
      "gate_status_counts" => Map.get(artifact, "gate_status_counts") || %{},
      "row_derived_gate_status_counts" => count_rows_by_value(rows, "status"),
      "gate_classification_counts" => Map.get(artifact, "gate_classification_counts") || %{},
      "row_derived_gate_classification_counts" => count_rows_by_value(rows, "classification"),
      "gate_ids_by_status" => Map.get(artifact, "gate_ids_by_status") || %{},
      "row_derived_gate_ids_by_status" =>
        rows
        |> group_row_ids_by_value("status", "gate_id")
        |> sort_grouped_values(),
      "gate_ids_by_classification" => Map.get(artifact, "gate_ids_by_classification") || %{},
      "row_derived_gate_ids_by_classification" =>
        rows
        |> group_row_ids_by_value("classification", "gate_id")
        |> sort_grouped_values(),
      "passed_gate_ids" => Map.get(artifact, "passed_gate_ids") || [],
      "review_required_gate_ids" => Map.get(artifact, "review_required_gate_ids") || [],
      "analysis_only_gate_ids" => Map.get(artifact, "analysis_only_gate_ids") || [],
      "blocked_gate_ids" => Map.get(artifact, "blocked_gate_ids") || [],
      "row_derived_ready_for_import_count" => sum_rows_numeric(rows, "ready_for_import_count"),
      "row_derived_manifest_review_required_count" =>
        sum_rows_numeric(rows, "manifest_review_required_count"),
      "row_derived_blocked_import_count" => sum_rows_numeric(rows, "blocked_import_count"),
      "row_derived_missing_import_count" => sum_rows_numeric(rows, "missing_import_count"),
      "row_derived_invalid_cadence_import_count" =>
        sum_rows_numeric(rows, "invalid_cadence_import_count"),
      "row_derived_current_freshness_count" => sum_rows_numeric(rows, "current_freshness_count"),
      "row_derived_stale_freshness_count" => sum_rows_numeric(rows, "stale_freshness_count"),
      "row_derived_unknown_freshness_count" => sum_rows_numeric(rows, "unknown_freshness_count"),
      "row_derived_freshness_status_counts" =>
        merge_row_count_maps(rows, "freshness_status_counts"),
      "row_derived_schema_validation_pass_count" =>
        sum_rows_numeric(rows, "schema_validation_pass_count"),
      "row_derived_schema_validation_fail_count" =>
        sum_rows_numeric(rows, "schema_validation_fail_count"),
      "row_derived_schema_validation_error_count" =>
        sum_rows_numeric(rows, "schema_validation_error_count"),
      "row_derived_schema_validation_warning_count" =>
        sum_rows_numeric(rows, "schema_validation_warning_count"),
      "row_derived_schema_validation_remediation_count" =>
        sum_rows_numeric(rows, "schema_validation_remediation_count"),
      "row_derived_schema_validation_status_counts" =>
        merge_row_count_maps(rows, "schema_validation_status_counts"),
      "row_derived_import_status_counts" => merge_row_count_maps(rows, "import_status_counts"),
      "row_derived_cadence_import_status_counts" =>
        merge_row_count_maps(rows, "cadence_import_status_counts"),
      "resource_availability_gate_count" =>
        count_rows_matching(rows, "gate_id", "resource_availability"),
      "row_derived_resource_availability_pressure_count" =>
        sum_rows_numeric(rows, "resource_availability_pressure_count"),
      "row_derived_resource_availability_reason_counts" =>
        merge_row_count_maps(rows, "resource_availability_reason_counts"),
      "row_derived_resource_availability_reason_keys" =>
        rows
        |> Enum.flat_map(&list_values(&1, "resource_availability_reason_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "row_derived_unavailable_resource_reason_keys" =>
        rows
        |> Enum.flat_map(&list_values(&1, "unavailable_resource_reason_ids"))
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "model_limit_count" => count(artifact, "model_limits"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"])
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

  defp sort_grouped_values(grouped_values) do
    Map.new(grouped_values, fn {key, values} -> {key, Enum.sort(values)} end)
  end

  defp count_rows_by_value(rows, key) do
    rows
    |> Enum.map(&(Map.get(&1, key) || "unknown"))
    |> Enum.frequencies()
    |> Map.new(fn {value, count} -> {to_string(value), count} end)
  end

  defp count_rows_matching(rows, key, value) do
    Enum.count(rows, &(Map.get(&1, key) == value))
  end

  defp sum_rows_numeric(rows, key) do
    rows
    |> Enum.map(&numeric_count(&1, key))
    |> Enum.sum()
  end

  defp numeric_count(report, field) when is_map(report) do
    case Map.get(report, field) do
      value when is_integer(value) and value >= 0 -> value
      value when is_float(value) and value >= 0 -> trunc(value)
      _value -> 0
    end
  end

  defp numeric_count(_report, _field), do: 0

  defp merge_row_count_maps(rows, key) do
    rows
    |> Enum.map(&Map.get(&1, key))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn
        {count_key, count_value}, acc when is_integer(count_value) and count_value >= 0 ->
          Map.update(acc, to_string(count_key), count_value, &(&1 + count_value))

        {_count_key, _count_value}, acc ->
          acc
      end)
    end)
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
