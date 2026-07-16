defmodule OrbitalDynamics.Validation.ArtifactObservations.ValidationRecord do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "model" => Map.get(artifact, "model"),
      "implementation" => Map.get(artifact, "implementation"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "evidence_count" => count(artifact, "evidence"),
      "known_limit_count" => count(artifact, "known_limits"),
      "tolerance_count" => map_size(Map.get(artifact, "tolerances", %{})),
      "position_tolerance_km" => get_in(artifact, ["tolerances", "position_km"]),
      "velocity_tolerance_km_s" => get_in(artifact, ["tolerances", "velocity_km_s"]),
      "energy_relative_tolerance" => get_in(artifact, ["tolerances", "energy_relative"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
