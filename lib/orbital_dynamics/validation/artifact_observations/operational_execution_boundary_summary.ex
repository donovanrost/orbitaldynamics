defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalExecutionBoundarySummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    operational_mode_gate = stringify_keys(Map.get(artifact, "operational_mode_gate") || %{})

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "readiness_level" => Map.get(artifact, "readiness_level"),
      "import_classification" => Map.get(artifact, "import_classification"),
      "status" => Map.get(artifact, "status"),
      "import_eligible" => Map.get(artifact, "import_eligible"),
      "handoff_only" => Map.get(artifact, "handoff_only"),
      "execution_allowed" => Map.get(artifact, "execution_allowed"),
      "cadence_write_allowed" => Map.get(artifact, "cadence_write_allowed"),
      "operator_authority_granted" => Map.get(artifact, "operator_authority_granted"),
      "execution_boundary" => Map.get(artifact, "execution_boundary"),
      "operational_mode_gate_id" => Map.get(operational_mode_gate, "id"),
      "operational_mode_gate_status" => Map.get(operational_mode_gate, "status"),
      "operational_mode_gate_classification" => Map.get(operational_mode_gate, "classification"),
      "gate_count" => Map.get(artifact, "gate_count"),
      "passed_gate_count" => Map.get(artifact, "passed_gate_count"),
      "review_gate_count" => Map.get(artifact, "review_gate_count"),
      "analysis_gate_count" => Map.get(artifact, "analysis_gate_count"),
      "blocked_gate_count" => Map.get(artifact, "blocked_gate_count"),
      "non_passed_gate_count" => Map.get(artifact, "non_passed_gate_count"),
      "non_passed_gate_keys" =>
        artifact
        |> list_values("non_passed_gate_ids")
        |> Enum.join("|"),
      "model_limit_count" => count(artifact, "model_limits"),
      "assumption_execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "cadence_write" => get_in(artifact, ["assumptions", "cadence_write"]),
      "command_execution" => get_in(artifact, ["assumptions", "command_execution"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"])
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
      _value -> []
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
