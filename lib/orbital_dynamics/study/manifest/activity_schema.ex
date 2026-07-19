defmodule OrbitalDynamics.Study.Manifest.ActivitySchema do
  @moduledoc false

  alias OrbitalDynamics.MissionPlan.Activity

  def json_schema do
    object_property(
      %{
        "id" => string_property(),
        "type" => enum_property(activity_type_values()),
        "activity_type" => enum_property(activity_type_values()),
        "timeline_id" => string_property(),
        "scenario_id" => string_property(),
        "spacecraft_id" => string_property(),
        "satellite_id" => string_property(),
        "spacecraft" => spacecraft_identity_schema(),
        "satellite" => spacecraft_identity_schema(),
        "resource_id" => string_property(),
        "resource_source_quality" => string_property(),
        "resource_trust_boundary" => string_property(),
        "resource_trust_boundary_status" => string_property(),
        "resource_provenance" => object_property(),
        "resource_blocking_dimension" => string_property(),
        "fuel_margin" => number_property(),
        "power_margin" => number_property(),
        "storage_margin" => number_property(),
        "downlink_margin" => number_property(),
        "battery_capacity_wh" => number_property(),
        "battery_energy_used_wh" => number_property(),
        "battery_energy_generated_wh" => non_negative_number_property(),
        "battery_state_of_charge" => number_property(),
        "spacecraft_available" => boolean_property(),
        "payload_available" => boolean_property(),
        "antenna_available" => boolean_property(),
        "degraded" => boolean_property(),
        "mode" => string_property(),
        "incompatible_activity_types" => array_property(string_property()),
        "suppressed_activity_types" => array_property(string_property()),
        "collection_id" => string_property(),
        "product_id" => string_property(),
        "product_ids" => array_property(string_property()),
        "payload_id" => string_property(),
        "instrument_id" => string_property(),
        "target_priority" => number_property(),
        "target_priority_source" => string_property(),
        "target_priority_objective_ids" => array_property(string_property()),
        "target_priority_objective_type" => string_property(),
        "contact_success" => boolean_property(),
        "contact_result" => string_property(),
        "contact_success_factor" => number_property(),
        "contact_success_factor_source" => string_property(),
        "command_success" => boolean_property(),
        "command_result" => string_property(),
        "command_success_factor" => number_property(),
        "command_success_factor_source" => string_property(),
        "observation_success" => boolean_property(),
        "observation_result" => string_property(),
        "observation_success_factor" => number_property(),
        "observation_success_factor_source" => string_property(),
        "image_quality_score" => number_property(),
        "image_quality_status" => string_property(),
        "image_quality_source" => string_property(),
        "cloud_cover_fraction" => number_property(),
        "blur_score" => number_property(),
        "maneuver_success" => boolean_property(),
        "maneuver_result" => string_property(),
        "maneuver_success_factor" => number_property(),
        "maneuver_success_factor_source" => string_property(),
        "feedback_weight" => number_property(),
        "feedback_weight_source" => string_property(),
        "data_volume_mb" => number_property(),
        "planned_data_volume_mb" => number_property(),
        "actual_data_volume_mb" => number_property(),
        "estimated_data_volume_mb" => number_property(),
        "estimated_storage_mb" => number_property(),
        "estimated_downlink_mb" => number_property(),
        "required_downlink_mb" => number_property(),
        "collection_ends_at_s" => number_property(),
        "planned_delivery_at_s" => number_property(),
        "actual_delivery_at_s" => number_property(),
        "max_latency_s" => number_property(),
        "planned_latency_s" => number_property(),
        "actual_latency_s" => number_property(),
        "planned_estimated_throughput_mb" => number_property(),
        "actual_throughput_mb" => number_property(),
        "link_protocol" => string_property(),
        "frequency_band" => string_property(),
        "modulation" => string_property(),
        "coding_scheme" => string_property(),
        "polarization" => string_property(),
        "data_rate_mbps" => number_property(),
        "downlink_rate_mbps" => number_property(),
        "data_rate_mb_s" => number_property(),
        "downlink_rate_mb_s" => number_property(),
        "actual_data_rate_mbps" => number_property(),
        "actual_downlink_rate_mbps" => number_property(),
        "actual_data_rate_mb_s" => number_property(),
        "actual_downlink_rate_mb_s" => number_property(),
        "delivered_rate_mbps" => number_property(),
        "received_rate_mbps" => number_property(),
        "delivered_rate_mb_s" => number_property(),
        "received_rate_mb_s" => number_property(),
        "actual_duration_s" => number_property(),
        "actual_contact_duration_s" => number_property(),
        "contact_duration_s" => number_property(),
        "link_margin_db" => number_property(),
        "snr_db" => number_property(),
        "eb_no_db" => number_property(),
        "bit_error_rate" => number_property(),
        "packet_loss_rate" => number_property(),
        "frame_loss_rate" => number_property(),
        "carrier_lock" => boolean_property(),
        "symbol_lock" => boolean_property(),
        "link_quality_status" => string_property(),
        "pointing_mode" => string_property(),
        "pointing_target_id" => string_property(),
        "boresight_axis" => string_property(),
        "off_nadir_angle_deg" => number_property(),
        "slew_angle_deg" => number_property(),
        "slew_rate_deg_s" => number_property(),
        "pointing_error_deg" => number_property(),
        "pointing_status" => string_property(),
        "pointing_model" => string_property(),
        "pointing_source" => string_property(),
        "pointing_confidence" => number_property(),
        "attitude_mode" => string_property(),
        "attitude_target_id" => string_property(),
        "roll_deg" => number_property(),
        "pitch_deg" => number_property(),
        "yaw_deg" => number_property(),
        "attitude_error_deg" => number_property(),
        "attitude_status" => string_property(),
        "attitude_model" => string_property(),
        "attitude_source" => string_property(),
        "attitude_confidence" => number_property(),
        "thermal_zone_id" => string_property(),
        "temperature_c" => number_property(),
        "planned_temperature_c" => number_property(),
        "actual_temperature_c" => number_property(),
        "min_operating_temperature_c" => number_property(),
        "max_operating_temperature_c" => number_property(),
        "thermal_margin_c" => number_property(),
        "thermal_status" => string_property(),
        "thermal_model" => string_property(),
        "thermal_source" => string_property(),
        "thermal_confidence" => number_property(),
        "eclipse_overlap_fraction" => number_property(),
        "eclipse_overlap_s" => number_property(),
        "lighting_condition" => string_property(),
        "lighting_condition_detail" => string_property(),
        "lighting_condition_model" => string_property(),
        "lighting_detail_model" => string_property(),
        "lighting_confidence" => %{"type" => ["number", "string"]},
        "command_window_id" => string_property(),
        "command_window_type" => string_property(),
        "window_type" => string_property(),
        "command_window" => object_property(),
        "start_s" => number_property(),
        "end_s" => number_property(),
        "target_id" => string_property(),
        "target" => target_identity_schema(),
        "ground_station_id" => string_property(),
        "station_id" => string_property(),
        "station" => ground_station_identity_schema(),
        "ground_station" => ground_station_identity_schema(),
        "direction" => contact_direction_property(),
        "epoch_s" => number_property(),
        "delta_v_km_s" => vector3_schema(),
        "frame" => frame_schema(),
        "allow_overlap" => boolean_property(),
        "allow_overlap?" => boolean_property(),
        "status" => enum_property(activity_status_values()),
        "approval_status" => enum_property(activity_approval_status_values()),
        "locked" => boolean_property(),
        "dependencies" => array_property(string_property()),
        "dependency_activity_ids" => array_property(string_property()),
        "dependency_timeline_ids" => array_property(string_property()),
        "exclusive_with_activity_ids" => array_property(string_property()),
        "exclusive_with_timeline_ids" => array_property(string_property()),
        "exclusivity_group" => string_property(),
        "source_window_id" => string_property(),
        "source_window_type" => string_property(),
        "source_window" => object_property(),
        "cadence_import" => object_property(),
        "provenance" => object_property(),
        "metadata" => object_property()
      },
      ["id"]
    )
    |> Map.put("anyOf", [%{"required" => ["type"]}, %{"required" => ["activity_type"]}])
  end

  defp activity_type_values, do: capability_values(:activity_types)
  defp activity_status_values, do: capability_values(:activity_statuses)
  defp activity_approval_status_values, do: capability_values(:approval_statuses)

  defp capability_values(key) do
    Activity.capabilities()
    |> Map.fetch!(key)
    |> Enum.map(&Atom.to_string/1)
  end

  defp contact_direction_property do
    enum_property(activity_contact_direction_schema_values())
    |> Map.put(
      "description",
      "Canonical contact directions plus provider aliases accepted by the manifest loader."
    )
    |> Map.put("x-orbital-dynamics", %{
      "canonical_values" => activity_contact_direction_values(),
      "provider_aliases" =>
        Activity.capabilities().contact_direction_aliases
        |> Map.new(fn {alias, direction} -> {alias, Atom.to_string(direction)} end)
    })
  end

  defp activity_contact_direction_values, do: capability_values(:contact_directions)

  defp activity_contact_direction_schema_values do
    (activity_contact_direction_values() ++
       (Activity.capabilities().contact_direction_aliases |> Map.keys()) ++
       [
         "Down Link",
         "Health Check",
         "Health Check Window",
         "Track-ing",
         "Up Link",
         "up-link"
       ])
    |> Enum.uniq()
  end

  defp target_identity_schema do
    object_property(%{
      "id" => string_property(),
      "target_id" => string_property()
    })
  end

  defp ground_station_identity_schema do
    object_property(%{
      "id" => string_property(),
      "station_id" => string_property(),
      "ground_station_id" => string_property()
    })
  end

  defp spacecraft_identity_schema do
    object_property(%{
      "id" => string_property(),
      "spacecraft_id" => string_property(),
      "satellite_id" => string_property()
    })
  end

  defp vector3_schema do
    %{
      "type" => "array",
      "items" => number_property(),
      "minItems" => 3,
      "maxItems" => 3
    }
  end

  defp frame_schema, do: %{"type" => "string", "const" => "earth_inertial_j2000"}

  defp object_property(properties \\ %{}, required \\ []) do
    property = %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => properties
    }

    if required == [], do: property, else: Map.put(property, "required", required)
  end

  defp array_property(items), do: %{"type" => "array", "items" => items}
  defp string_property, do: %{"type" => "string"}
  defp number_property, do: %{"type" => "number"}
  defp non_negative_number_property, do: %{"type" => "number", "minimum" => 0.0}
  defp boolean_property, do: %{"type" => "boolean"}
  defp enum_property(values), do: %{"type" => "string", "enum" => Enum.sort(values)}
end
