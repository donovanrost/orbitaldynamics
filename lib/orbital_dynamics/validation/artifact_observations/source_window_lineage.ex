defmodule OrbitalDynamics.Validation.ArtifactObservations.SourceWindowLineage do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "candidate_activity_id" => Map.get(artifact, "candidate_activity_id"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "source_window_type" => Map.get(artifact, "source_window_type")
    }
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
