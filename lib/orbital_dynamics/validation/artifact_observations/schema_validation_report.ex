defmodule OrbitalDynamics.Validation.ArtifactObservations.SchemaValidationReport do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "model" => Map.get(artifact, "model"),
      "validation_mode" => Map.get(artifact, "validation_mode"),
      "artifact_path" => Map.get(artifact, "artifact_path"),
      "validated_contract" => Map.get(artifact, "validated_contract"),
      "validated_artifact_family" => Map.get(artifact, "validated_artifact_family"),
      "validated_schema_version" => Map.get(artifact, "validated_schema_version"),
      "status" => Map.get(artifact, "status"),
      "error_count" => Map.get(artifact, "error_count"),
      "warning_count" => Map.get(artifact, "warning_count"),
      "remediation_count" => Map.get(artifact, "remediation_count"),
      "error_row_count" => count(artifact, "errors"),
      "warning_row_count" => count(artifact, "warnings"),
      "remediation_row_count" => count(artifact, "remediation"),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
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
