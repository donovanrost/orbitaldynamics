defmodule OrbitalDynamics.Validation.ArtifactObservations.AcceptedPlanningState do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    spacecraft_states = map_rows(artifact, "spacecraft_states")
    maneuver_deltas = map_rows(artifact, "maneuver_execution_deltas")
    first_state = List.first(spacecraft_states, %{})
    first_maneuver_delta = List.first(maneuver_deltas, %{})

    %{
      "schema_version" => Map.get(artifact, "schema_version"),
      "artifact_type" => Map.get(artifact, "artifact_type"),
      "snapshot_id" => Map.get(artifact, "snapshot_id"),
      "accepted_at" => Map.get(artifact, "accepted_at"),
      "quality_level" => get_in(artifact, ["quality", "level"]),
      "source_system" => get_in(artifact, ["source", "system"]),
      "provenance_adapter" => get_in(artifact, ["provenance", "adapter"]),
      "provenance_input_format" => get_in(artifact, ["provenance", "input_format"]),
      "provenance_trust_boundary" => get_in(artifact, ["provenance", "trust_boundary"]),
      "provenance_network_access" => get_in(artifact, ["provenance", "network_access"]),
      "provenance_state_estimate_count" =>
        get_in(artifact, ["provenance", "state_estimate_count"]),
      "spacecraft_state_count" => length(spacecraft_states),
      "maneuver_execution_delta_count" => length(maneuver_deltas),
      "spacecraft_id" => Map.get(first_state, "spacecraft_id"),
      "scenario_id" => Map.get(first_state, "scenario_id"),
      "state_quality_level" => get_in(first_state, ["quality", "level"]),
      "position_dimension" => count(get_in(first_state, ["state_vector"]) || %{}, "position_km"),
      "velocity_dimension" =>
        count(get_in(first_state, ["state_vector"]) || %{}, "velocity_km_s"),
      "position_sigma_dimension" =>
        count(get_in(first_state, ["quality"]) || %{}, "position_sigma_km"),
      "velocity_sigma_dimension" =>
        count(get_in(first_state, ["quality"]) || %{}, "velocity_sigma_km_s"),
      "maneuver_status" => Map.get(first_maneuver_delta, "status")
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
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
