defmodule OrbitalDynamics.Validation.ArtifactObservations.ResourceSummary do
  @moduledoc false

  def build(%{} = artifact) do
    artifact = stringify_keys(artifact)

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "spacecraft_id" => Map.get(artifact, "spacecraft_id"),
      "mode" => Map.get(artifact, "mode"),
      "fuel_margin" => Map.get(artifact, "fuel_margin"),
      "power_margin" => Map.get(artifact, "power_margin"),
      "battery_capacity_wh" => Map.get(artifact, "battery_capacity_wh"),
      "battery_energy_used_wh" => Map.get(artifact, "battery_energy_used_wh"),
      "battery_state_of_charge" => Map.get(artifact, "battery_state_of_charge"),
      "thermal_margin_c" => Map.get(artifact, "thermal_margin_c"),
      "storage_capacity_mb" => Map.get(artifact, "storage_capacity_mb"),
      "storage_used_mb" => Map.get(artifact, "storage_used_mb"),
      "storage_margin" => Map.get(artifact, "storage_margin"),
      "downlink_capacity_mb" => Map.get(artifact, "downlink_capacity_mb"),
      "downlink_margin" => Map.get(artifact, "downlink_margin"),
      "spacecraft_available" => Map.get(artifact, "spacecraft_available"),
      "payload_available" => Map.get(artifact, "payload_available"),
      "antenna_available" => Map.get(artifact, "antenna_available"),
      "degraded" => Map.get(artifact, "degraded"),
      "source_quality" => Map.get(artifact, "source_quality"),
      "trust_boundary" => Map.get(artifact, "trust_boundary"),
      "suppressed_activity_type_count" => count(artifact, "suppressed_activity_types"),
      "suppressed_activity_type_order" =>
        artifact
        |> list_values("suppressed_activity_types")
        |> Enum.join("|"),
      "incompatible_activity_type_count" => count(artifact, "incompatible_activity_types"),
      "incompatible_activity_type_order" =>
        artifact
        |> list_values("incompatible_activity_types")
        |> Enum.join("|"),
      "assumption_source" => get_in(artifact, ["assumptions", "source"]),
      "provenance_source" => get_in(artifact, ["provenance", "source"])
    }
  end

  defp count(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> length(values)
      _value -> 0
    end
  end

  defp list_values(map, key) do
    case Map.get(map, key) do
      values when is_list(values) -> values
      _values -> []
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
