defmodule OrbitalDynamics.Validation.ArtifactObservations.OperationalImportEligibilitySummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    non_passed_gates = map_rows(artifact, "non_passed_gates")

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
      "gate_count" => Map.get(artifact, "gate_count"),
      "passed_gate_count" => Map.get(artifact, "passed_gate_count"),
      "review_gate_count" => Map.get(artifact, "review_gate_count"),
      "analysis_gate_count" => Map.get(artifact, "analysis_gate_count"),
      "blocked_gate_count" => Map.get(artifact, "blocked_gate_count"),
      "non_passed_gate_count" => Map.get(artifact, "non_passed_gate_count"),
      "row_derived_non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gate_keys" =>
        non_passed_gates
        |> Enum.map(& &1["id"])
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join("|"),
      "model_limit_count" => count(artifact, "model_limits"),
      "execution_boundary" => get_in(artifact, ["assumptions", "execution_boundary"]),
      "operator_authority" => get_in(artifact, ["assumptions", "operator_authority"]),
      "assumption_source" => get_in(artifact, ["assumptions", "source"])
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
