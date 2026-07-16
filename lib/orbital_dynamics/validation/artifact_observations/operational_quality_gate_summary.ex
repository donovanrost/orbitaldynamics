defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalQualityGateSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    rows = map_rows(artifact, "rows")
    non_passed_rows = Enum.reject(rows, &(&1["status"] == "passed"))

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_quality_gate_report_id" => Map.get(artifact, "source_quality_gate_report_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "readiness_level" => Map.get(artifact, "readiness_level"),
      "import_classification" => Map.get(artifact, "import_classification"),
      "status" => Map.get(artifact, "status"),
      "execution_allowed" => Map.get(artifact, "execution_allowed"),
      "cadence_write_allowed" => Map.get(artifact, "cadence_write_allowed"),
      "operator_authority_granted" => Map.get(artifact, "operator_authority_granted"),
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
      "non_passed_gate_count" => Map.get(artifact, "non_passed_gate_count"),
      "row_derived_non_passed_gate_count" => length(non_passed_rows),
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
      "non_passed_gate_keys" =>
        artifact
        |> list_values("non_passed_gate_ids")
        |> Enum.join("|"),
      "row_derived_non_passed_gate_keys" =>
        non_passed_rows
        |> Enum.map(& &1["gate_id"])
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "non_passed_quality_gate_row_keys" =>
        artifact
        |> list_values("non_passed_quality_gate_row_ids")
        |> Enum.sort()
        |> Enum.join("|"),
      "row_derived_non_passed_quality_gate_row_keys" =>
        non_passed_rows
        |> Enum.map(& &1["id"])
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "row_derived_non_passed_quality_gate_row_count" =>
        non_passed_rows
        |> Enum.map(& &1["id"])
        |> Enum.filter(&is_binary/1)
        |> length(),
      "model_limit_count" => count(artifact, "model_limits"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"])
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
