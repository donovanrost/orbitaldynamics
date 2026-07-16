defmodule OrbitalDynamics.Validation.ArtifactObservations.PlannedActivity do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)
    timeline_identity = Map.get(artifact, "timeline_identity", %{})

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "scenario_id" => Map.get(artifact, "scenario_id"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "starts_at_s" => Map.get(artifact, "starts_at_s"),
      "ends_at_s" => Map.get(artifact, "ends_at_s"),
      "duration_s" =>
        numeric_delta(Map.get(artifact, "ends_at_s"), Map.get(artifact, "starts_at_s")),
      "ground_station_id" => Map.get(artifact, "ground_station_id"),
      "direction" => Map.get(artifact, "direction"),
      "mode" => Map.get(artifact, "mode"),
      "dependency_activity_count" => count(artifact, "dependency_activity_ids"),
      "exclusive_timeline_count" => count(artifact, "exclusive_with_timeline_ids"),
      "product_count" => count(artifact, "product_ids"),
      "suppressed_activity_type_count" => count(artifact, "suppressed_activity_types"),
      "timeline_identity_field_count" => map_size(timeline_identity),
      "timeline_identity_id" => Map.get(timeline_identity, "timeline_id"),
      "cadence_import_external_id" => get_in(artifact, ["cadence_import", "external_id"]),
      "resource_trust_boundary" => Map.get(artifact, "resource_trust_boundary"),
      "resource_trust_boundary_status" => Map.get(artifact, "resource_trust_boundary_status"),
      "resource_blocking_dimension" => Map.get(artifact, "resource_blocking_dimension"),
      "command_success_factor" => Map.get(artifact, "command_success_factor"),
      "maneuver_success_factor" => Map.get(artifact, "maneuver_success_factor"),
      "timing_3sigma_s" => get_in(artifact, ["execution_uncertainty", "timing_3sigma_s"]),
      "delta_v_3sigma_component_count" =>
        count(get_in(artifact, ["execution_uncertainty"]) || %{}, "delta_v_3sigma_km_s"),
      "degraded" => Map.get(artifact, "degraded"),
      "payload_available" => Map.get(artifact, "payload_available"),
      "spacecraft_available" => Map.get(artifact, "spacecraft_available")
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp numeric_delta(left, right) when is_number(left) and is_number(right), do: left - right
  defp numeric_delta(_left, _right), do: nil

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
