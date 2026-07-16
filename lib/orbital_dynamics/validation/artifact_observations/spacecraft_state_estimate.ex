defmodule OrbitalDynamics.Validation.ArtifactObservations.SpacecraftStateEstimate do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    position = list_values(Map.get(artifact, "state_vector", %{}), "position_km")
    velocity = list_values(Map.get(artifact, "state_vector", %{}), "velocity_km_s")
    position_sigma = list_values(Map.get(artifact, "quality", %{}), "position_sigma_km")
    velocity_sigma = list_values(Map.get(artifact, "quality", %{}), "velocity_sigma_km_s")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "epoch_s" => get_in(artifact, ["epoch", "seconds_since_j2000"]),
      "time_scale" => get_in(artifact, ["epoch", "time_scale"]),
      "frame" => Map.get(artifact, "frame"),
      "source_system" => get_in(artifact, ["source", "system"]),
      "source_id" => get_in(artifact, ["source", "source_id"]),
      "trust_boundary" => get_in(artifact, ["provenance", "trust_boundary"]),
      "quality_level" => get_in(artifact, ["quality", "level"]),
      "position_component_count" => length(position),
      "velocity_component_count" => length(velocity),
      "position_sigma_component_count" => length(position_sigma),
      "velocity_sigma_component_count" => length(velocity_sigma),
      "position_x_km" => List.first(position),
      "velocity_y_km_s" => Enum.at(velocity, 1)
    }
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
