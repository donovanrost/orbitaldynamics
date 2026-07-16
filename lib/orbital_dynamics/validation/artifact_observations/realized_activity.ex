defmodule OrbitalDynamics.Validation.ArtifactObservations.RealizedActivity do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "type" => Map.get(artifact, "type"),
      "status" => Map.get(artifact, "status"),
      "planned_activity_id" => Map.get(artifact, "planned_activity_id"),
      "source_window_id" => Map.get(artifact, "source_window_id"),
      "timeline_id" => Map.get(artifact, "timeline_id"),
      "ground_station_id" => Map.get(artifact, "ground_station_id"),
      "direction" => Map.get(artifact, "direction"),
      "planned_data_volume_mb" => Map.get(artifact, "planned_data_volume_mb"),
      "actual_data_volume_mb" => Map.get(artifact, "actual_data_volume_mb"),
      "data_volume_shortfall_mb" =>
        numeric_delta(
          Map.get(artifact, "planned_data_volume_mb"),
          Map.get(artifact, "actual_data_volume_mb")
        ),
      "completed_fraction" => Map.get(artifact, "completed_fraction"),
      "contact_result" => Map.get(artifact, "contact_result"),
      "contact_success" => Map.get(artifact, "contact_success"),
      "execution_uncertainty_status" => Map.get(artifact, "execution_uncertainty_status"),
      "resource_trust_boundary_status" => Map.get(artifact, "resource_trust_boundary_status"),
      "adapter" => Map.get(artifact, "adapter"),
      "adapter_version" => Map.get(artifact, "adapter_version"),
      "trust_boundary" => Map.get(artifact, "trust_boundary"),
      "provenance_trust_boundary" => get_in(artifact, ["provenance", "trust_boundary"]),
      "product_count" => count(artifact, "product_ids")
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
