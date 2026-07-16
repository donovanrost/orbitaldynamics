defmodule OrbitalDynamics.Validation.ArtifactObservations.ValidationCheck do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "field" => Map.get(artifact, "field"),
      "status" => Map.get(artifact, "status"),
      "expected" => Map.get(artifact, "expected"),
      "observed" => Map.get(artifact, "observed"),
      "tolerance" => Map.get(artifact, "tolerance"),
      "error" => Map.get(artifact, "error")
    }
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
