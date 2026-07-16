defmodule OrbitalDynamics.Validation.ArtifactObservations.EnvironmentCapability do
  @moduledoc false

  def build_model(%{} = artifact) do
    artifact = stringify_keys(artifact)
    parameters = Map.get(artifact, "parameters") || %{}

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "category" => Map.get(artifact, "category"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "coordinate_frame" => Map.get(artifact, "coordinate_frame"),
      "interpolation" => Map.get(artifact, "interpolation"),
      "time_span" => Map.get(artifact, "time_span"),
      "supported_body_count" => count(artifact, "supported_bodies"),
      "network_access" => Map.get(artifact, "network_access"),
      "parameter_count" => count_collection(artifact, "parameters"),
      "sun_direction_dimension" => count(parameters, "sun_direction"),
      "sun_direction_order" =>
        parameters
        |> list_values("sun_direction")
        |> Enum.join("|"),
      "earth_rotation_rate_rad_s" => Map.get(parameters, "earth_rotation_rate_rad_s"),
      "geometry_model" => Map.get(parameters, "geometry_model"),
      "known_limit_count" => count(artifact, "known_limits")
    }
  end

  def build_provider(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "category" => Map.get(artifact, "category"),
      "model" => Map.get(artifact, "model"),
      "source" => Map.get(artifact, "source"),
      "validation_level" => Map.get(artifact, "validation_level"),
      "interpolation" => Map.get(artifact, "interpolation"),
      "coverage_policy" => get_in(artifact, ["coverage", "coverage_policy"]),
      "coverage_time_scale" => get_in(artifact, ["coverage", "time_scale"]),
      "output_count" => count(artifact, "outputs"),
      "supported_body_count" => count(artifact, "supported_bodies"),
      "network_access" => Map.get(artifact, "network_access"),
      "parameter_count" => count_collection(artifact, "parameters"),
      "known_limit_count" => count(artifact, "known_limits")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp count_collection(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      values when is_map(values) -> map_size(values)
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
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
