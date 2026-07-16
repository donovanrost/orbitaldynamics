defmodule OrbitalDynamics.Schema.ResourceSummaryRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "resource_summary.v1" => %{
        "schema_contract" => "resource_summary.v1",
        "artifact_family" => "resource_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "spacecraft_id"
        ],
        "optional_fields" => [
          "mode",
          "fuel_margin",
          "power_margin",
          "battery_capacity_wh",
          "battery_energy_used_wh",
          "battery_energy_generated_wh",
          "battery_state_of_charge",
          "thermal_margin_c",
          "storage_capacity_mb",
          "storage_used_mb",
          "storage_margin",
          "downlink_capacity_mb",
          "downlink_margin",
          "spacecraft_available",
          "source_quality",
          "trust_boundary",
          "suppressed_activity_types",
          "incompatible_activity_types",
          "payload_available",
          "antenna_available",
          "degraded",
          "assumptions",
          "provenance"
        ],
        "nested_contracts" => []
      }
    }
  end
end
