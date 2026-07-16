defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalQualityGateSchemaValidationSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    schema_validation_status_counts = Map.get(artifact, "schema_validation_status_counts") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_quality_gate_report_id" => Map.get(artifact, "source_quality_gate_report_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "schema_validation_row_count" => Map.get(artifact, "schema_validation_row_count"),
      "schema_validation_pass_count" => Map.get(artifact, "schema_validation_pass_count"),
      "row_derived_schema_validation_pass_count" =>
        Map.get(schema_validation_status_counts, "pass", 0),
      "schema_validation_fail_count" => Map.get(artifact, "schema_validation_fail_count"),
      "row_derived_schema_validation_fail_count" =>
        Map.get(schema_validation_status_counts, "fail", 0),
      "schema_validation_error_count" => Map.get(artifact, "schema_validation_error_count"),
      "schema_validation_warning_count" => Map.get(artifact, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        Map.get(artifact, "schema_validation_remediation_count"),
      "schema_validation_status_counts" => schema_validation_status_counts,
      "schema_validation_status_keys" =>
        artifact
        |> list_values("schema_validation_status_ids")
        |> Enum.join("|"),
      "schema_validation_import_blocked" => Map.get(artifact, "schema_validation_import_blocked"),
      "quality_gate_row_ids_by_status" =>
        Map.get(artifact, "quality_gate_row_ids_by_status") || %{},
      "quality_gate_ids_by_status" => Map.get(artifact, "quality_gate_ids_by_status") || %{},
      "blocked_quality_gate_row_keys" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> Enum.join("|"),
      "review_required_quality_gate_row_keys" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> Enum.join("|"),
      "failed_schema_validation_quality_gate_row_keys" =>
        artifact
        |> list_values("failed_schema_validation_quality_gate_row_ids")
        |> Enum.join("|"),
      "schema_validation_gate_keys" =>
        artifact
        |> list_values("schema_validation_gate_ids")
        |> Enum.join("|"),
      "row_derived_blocked_quality_gate_row_count" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> length(),
      "row_derived_failed_schema_validation_quality_gate_row_count" =>
        artifact
        |> list_values("failed_schema_validation_quality_gate_row_ids")
        |> length(),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"]),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
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
