defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalQualityGateImportReadinessSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    freshness_status_counts = Map.get(artifact, "freshness_status_counts") || %{}
    import_status_counts = Map.get(artifact, "import_status_counts") || %{}
    cadence_import_status_counts = Map.get(artifact, "cadence_import_status_counts") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "source_quality_gate_report_id" => Map.get(artifact, "source_quality_gate_report_id"),
      "source_readiness_report_id" => Map.get(artifact, "source_readiness_report_id"),
      "import_readiness_row_count" => Map.get(artifact, "import_readiness_row_count"),
      "ready_for_import_count" => Map.get(artifact, "ready_for_import_count"),
      "row_derived_ready_for_import_count" =>
        Map.get(import_status_counts, "ready_for_import", 0),
      "manifest_review_required_count" => Map.get(artifact, "manifest_review_required_count"),
      "blocked_import_count" => Map.get(artifact, "blocked_import_count"),
      "missing_import_count" => Map.get(artifact, "missing_import_count"),
      "invalid_cadence_import_count" => Map.get(artifact, "invalid_cadence_import_count"),
      "current_freshness_count" => Map.get(artifact, "current_freshness_count"),
      "stale_freshness_count" => Map.get(artifact, "stale_freshness_count"),
      "row_derived_stale_freshness_count" => Map.get(freshness_status_counts, "stale", 0),
      "unknown_freshness_count" => Map.get(artifact, "unknown_freshness_count"),
      "freshness_status_counts" => freshness_status_counts,
      "freshness_status_keys" =>
        artifact
        |> list_values("freshness_status_ids")
        |> Enum.join("|"),
      "import_status_counts" => import_status_counts,
      "import_status_keys" =>
        artifact
        |> list_values("import_status_ids")
        |> Enum.join("|"),
      "cadence_import_status_counts" => cadence_import_status_counts,
      "cadence_import_status_keys" =>
        artifact
        |> list_values("cadence_import_status_ids")
        |> Enum.join("|"),
      "row_derived_cadence_import_present_count" =>
        Map.get(cadence_import_status_counts, "present", 0),
      "freshness_review_required" => Map.get(artifact, "freshness_review_required"),
      "import_preparation_required" => Map.get(artifact, "import_preparation_required"),
      "import_blocked" => Map.get(artifact, "import_blocked"),
      "quality_gate_row_ids_by_status" =>
        Map.get(artifact, "quality_gate_row_ids_by_status") || %{},
      "quality_gate_ids_by_status" => Map.get(artifact, "quality_gate_ids_by_status") || %{},
      "review_required_quality_gate_row_keys" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> Enum.join("|"),
      "blocked_quality_gate_row_keys" =>
        artifact
        |> list_values("blocked_quality_gate_row_ids")
        |> Enum.join("|"),
      "ready_quality_gate_row_keys" =>
        artifact
        |> list_values("ready_quality_gate_row_ids")
        |> Enum.join("|"),
      "analysis_only_quality_gate_row_keys" =>
        artifact
        |> list_values("analysis_only_quality_gate_row_ids")
        |> Enum.join("|"),
      "stale_or_unknown_freshness_quality_gate_row_keys" =>
        artifact
        |> list_values("stale_or_unknown_freshness_quality_gate_row_ids")
        |> Enum.join("|"),
      "import_preparation_quality_gate_row_keys" =>
        artifact
        |> list_values("import_preparation_quality_gate_row_ids")
        |> Enum.join("|"),
      "blocked_import_quality_gate_row_keys" =>
        artifact
        |> list_values("blocked_import_quality_gate_row_ids")
        |> Enum.join("|"),
      "import_readiness_gate_keys" =>
        artifact
        |> list_values("import_readiness_gate_ids")
        |> Enum.join("|"),
      "row_derived_review_required_quality_gate_row_count" =>
        artifact
        |> list_values("review_required_quality_gate_row_ids")
        |> length(),
      "row_derived_stale_or_unknown_freshness_quality_gate_row_count" =>
        artifact
        |> list_values("stale_or_unknown_freshness_quality_gate_row_ids")
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
