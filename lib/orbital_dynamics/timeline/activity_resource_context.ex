defmodule OrbitalDynamics.Timeline.ActivityResourceContext do
  @moduledoc false

  def build(activity) do
    %{
      "resource_id" => activity["resource_id"],
      "resource_source_quality" =>
        first_value(activity, ["resource_source_quality", "source_quality"]),
      "resource_trust_boundary" =>
        first_value(activity, ["resource_trust_boundary", "trust_boundary"]),
      "resource_trust_boundary_status" =>
        first_value(activity, ["resource_trust_boundary_status", "trust_boundary_status"]),
      "resource_provenance" => first_value(activity, ["resource_provenance", "provenance"]),
      "resource_blocking_dimension" => first_value(activity, ["resource_blocking_dimension"]),
      "fuel_margin" => first_number(activity, ["fuel_margin"]),
      "power_margin" => first_number(activity, ["power_margin"]),
      "storage_margin" => first_number(activity, ["storage_margin"]),
      "downlink_margin" => first_number(activity, ["downlink_margin"]),
      "battery_capacity_wh" => first_number(activity, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_number(activity, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" =>
        first_number(activity, [
          "battery_energy_generated_wh",
          "energy_generated_wh",
          "estimated_energy_generated_wh",
          "estimated_battery_energy_generated_wh",
          "planned_energy_generated_wh",
          ["metadata", "battery_energy_generated_wh"],
          ["metadata", "energy_generated_wh"],
          ["metadata", "estimated_energy_generated_wh"],
          ["metadata", "estimated_battery_energy_generated_wh"],
          ["metadata", "planned_energy_generated_wh"]
        ]),
      "battery_state_of_charge" => first_number(activity, ["battery_state_of_charge"]),
      "spacecraft_available" => first_boolean(activity, ["spacecraft_available"]),
      "payload_available" => first_boolean(activity, ["payload_available"]),
      "antenna_available" => first_boolean(activity, ["antenna_available"]),
      "degraded" => first_boolean(activity, ["degraded"]),
      "mode" => first_value(activity, ["mode"]),
      "incompatible_activity_types" => first_value(activity, ["incompatible_activity_types"]),
      "suppressed_activity_types" => first_value(activity, ["suppressed_activity_types"])
    }
    |> compact_map()
  end

  defp first_value(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_value(activity, keys)
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp first_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, keys)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
