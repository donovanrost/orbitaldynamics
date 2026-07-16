defmodule OrbitalDynamics.Validation.ArtifactObservations.RefreshedWindow do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "target_id" => Map.get(artifact, "target_id"),
      "starts_at_s" => Map.get(artifact, "starts_at_s"),
      "ends_at_s" => Map.get(artifact, "ends_at_s"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s")),
      "sample_count" => Map.get(artifact, "sample_count"),
      "target_priority" => Map.get(artifact, "target_priority"),
      "minimum_elevation_deg" => Map.get(artifact, "minimum_elevation_deg"),
      "max_elevation_deg" => Map.get(artifact, "max_elevation_deg"),
      "confidence" => get_in(artifact, ["assumptions", "confidence"]),
      "event_detector" => get_in(artifact, ["assumptions", "event_detector"]),
      "event_time_tolerance_s" => get_in(artifact, ["assumptions", "event_time_tolerance_s"]),
      "event_timing_policy" => get_in(artifact, ["assumptions", "event_timing_policy"]),
      "geometry_model" => get_in(artifact, ["assumptions", "geometry_model"]),
      "interpolation" => get_in(artifact, ["assumptions", "interpolation"]),
      "max_sample_step_s" => get_in(artifact, ["assumptions", "max_sample_step_s"]),
      "refraction" => get_in(artifact, ["assumptions", "refraction"]),
      "terrain_mask" => get_in(artifact, ["assumptions", "terrain_mask"])
    }
  end

  defp numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  defp numeric_delta(_left, _right), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
