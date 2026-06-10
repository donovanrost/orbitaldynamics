defmodule OrbitalDynamics.Study.ManifestTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Propagators.{J2, TwoBodyNxCompiled}
  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Study.Manifest

  test "exports a structural JSON Schema for study manifests" do
    schema = Manifest.json_schema()

    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
    assert schema["$id"] =~ "study_manifest.v1.schema.json"
    assert schema["type"] == "object"
    assert schema["required"] == ["schema_version", "study_id", "outputs"]

    assert %{
             "schema_contract" => "study_manifest.v1",
             "executable_contract" => false,
             "executable_validator" =>
               "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2",
             "lint_error_codes" => lint_error_codes
           } = schema["x-orbital-dynamics"]

    assert "invalid_run_option" in lint_error_codes
    assert "missing_run_option" in lint_error_codes

    assert schema["properties"]["schema_version"]["const"] == 1
    assert "two_body" in schema["properties"]["propagator"]["enum"]
    assert "trajectories" in schema["properties"]["outputs"]["items"]["enum"]
    assert "ground_track_crossings" in schema["properties"]["outputs"]["items"]["enum"]

    assert schema["properties"]["ground_track_crossings"]["items"]["properties"]["crossing"][
             "enum"
           ] == ["latitude", "longitude"]

    assert schema["properties"]["ground_track_crossings"]["items"]["properties"][
             "rotation_rate_rad_s"
           ]["type"] == "number"

    assert schema["properties"]["ground_track_crossings"]["items"]["properties"][
             "earth_rotation_provider"
           ]["oneOf"]

    assert %{
             "required" => ["remaining_horizon"],
             "anyOf" => [
               %{"required" => ["accepted_planning_state"]},
               %{"required" => ["orbit_data"]},
               %{"required" => ["mission_state"]}
             ],
             "properties" => candidate_refresh_properties
           } = schema["properties"]["candidate_refresh"]

    assert candidate_refresh_properties["accepted_planning_state"]["required"] == [
             "schema_version",
             "artifact_type",
             "snapshot_id",
             "accepted_at",
             "spacecraft_states",
             "source",
             "quality",
             "provenance"
           ]

    orbit_data_state_estimate =
      candidate_refresh_properties["orbit_data"]["properties"]["state_estimates"]["items"]

    assert orbit_data_state_estimate["required"] == ["spacecraft_id", "source"]

    assert orbit_data_state_estimate["anyOf"] == [
             %{"required" => ["epoch"]},
             %{"required" => ["seconds_since_j2000"]}
           ]

    assert orbit_data_state_estimate["allOf"] == [
             %{
               "anyOf" => [
                 %{"required" => ["state_vector"]},
                 %{"required" => ["position_km", "velocity_km_s"]}
               ]
             }
           ]

    assert candidate_refresh_properties["resource_summaries"]["items"]["required"] == [
             "spacecraft_id"
           ]

    assert candidate_refresh_properties["candidate_limit_policy"]["properties"][
             "max_candidate_activities"
           ]["type"] == "integer"

    availability_schema =
      candidate_refresh_properties["ground_network"]["items"]["properties"]["availability"]

    assert %{"type" => "string", "enum" => availability_values} =
             Enum.find(availability_schema["oneOf"], &(&1["type"] == "string"))

    assert availability_values == [
             "available",
             "maintenance",
             "reduced_capacity",
             "reserved",
             "unavailable"
           ]

    assert %{"type" => "number"} =
             numeric_availability_schema =
             Enum.find(availability_schema["oneOf"], &(&1["type"] == "number"))

    assert numeric_availability_schema["minimum"] == 0.0
    assert numeric_availability_schema["maximum"] == 1.0

    assert candidate_refresh_properties["ground_network"]["items"]["properties"]["status"] == %{
             "type" => "string"
           }

    mission_plan_activity_properties =
      schema["properties"]["mission_plans"]["items"]["properties"]["activities"]["items"][
        "properties"
      ]

    assert schema["properties"]["mission_plans"]["items"]["properties"]["activities"]["items"][
             "required"
           ] == ["id"]

    assert schema["properties"]["mission_plans"]["items"]["properties"]["activities"]["items"][
             "anyOf"
           ] == [
             %{"required" => ["type"]},
             %{"required" => ["activity_type"]}
           ]

    assert mission_plan_activity_properties["station_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["target"]["properties"]["id"] == %{"type" => "string"}

    assert mission_plan_activity_properties["target"]["properties"]["target_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["station"]["properties"]["id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["station"]["properties"]["station_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["station"]["properties"]["ground_station_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["ground_station"]["properties"]["station_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["scenario_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["spacecraft_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["satellite_id"] == %{"type" => "string"}

    assert mission_plan_activity_properties["spacecraft"]["properties"]["id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["spacecraft"]["properties"]["spacecraft_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["spacecraft"]["properties"]["satellite_id"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["satellite"]["properties"]["id"] == %{
             "type" => "string"
           }

    assert Enum.sort(mission_plan_activity_properties["type"]["enum"]) ==
             OrbitalDynamics.MissionPlan.Activity.capabilities().activity_types
             |> Enum.map(&Atom.to_string/1)
             |> Enum.sort()

    assert Enum.sort(mission_plan_activity_properties["activity_type"]["enum"]) ==
             OrbitalDynamics.MissionPlan.Activity.capabilities().activity_types
             |> Enum.map(&Atom.to_string/1)
             |> Enum.sort()

    direction_enum = mission_plan_activity_properties["direction"]["enum"]

    assert Enum.all?(
             OrbitalDynamics.MissionPlan.Activity.capabilities().contact_directions,
             &(Atom.to_string(&1) in direction_enum)
           )

    assert "cmd" in direction_enum
    assert "Track-ing" in direction_enum
    assert "Health Check Window" in direction_enum
    assert "up-link" in direction_enum

    assert get_in(mission_plan_activity_properties, [
             "direction",
             "x-orbital-dynamics",
             "provider_aliases",
             "healthcheck"
           ]) == "health_check"

    assert "completed" in mission_plan_activity_properties["status"]["enum"]
    assert "partial" in mission_plan_activity_properties["status"]["enum"]
    assert "missed" in mission_plan_activity_properties["status"]["enum"]
    assert "failed" in mission_plan_activity_properties["status"]["enum"]
    assert "cancelled" in mission_plan_activity_properties["status"]["enum"]
    assert "blocked_by_policy" in mission_plan_activity_properties["status"]["enum"]

    assert "operator_review_required" in mission_plan_activity_properties["approval_status"][
             "enum"
           ]

    assert "blocked_by_policy" in mission_plan_activity_properties["approval_status"]["enum"]
    assert "not_evaluated" in mission_plan_activity_properties["approval_status"]["enum"]

    assert mission_plan_activity_properties["timeline_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["resource_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["resource_source_quality"] == %{"type" => "string"}
    assert mission_plan_activity_properties["resource_trust_boundary"] == %{"type" => "string"}

    assert mission_plan_activity_properties["resource_trust_boundary_status"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["resource_provenance"] == %{
             "type" => "object",
             "properties" => %{},
             "additionalProperties" => true
           }

    assert mission_plan_activity_properties["resource_blocking_dimension"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["fuel_margin"] == %{"type" => "number"}
    assert mission_plan_activity_properties["power_margin"] == %{"type" => "number"}
    assert mission_plan_activity_properties["storage_margin"] == %{"type" => "number"}
    assert mission_plan_activity_properties["downlink_margin"] == %{"type" => "number"}
    assert mission_plan_activity_properties["battery_capacity_wh"] == %{"type" => "number"}
    assert mission_plan_activity_properties["battery_energy_used_wh"] == %{"type" => "number"}

    assert mission_plan_activity_properties["battery_energy_generated_wh"] == %{
             "type" => "number",
             "minimum" => 0.0
           }

    assert mission_plan_activity_properties["battery_state_of_charge"] == %{"type" => "number"}
    assert mission_plan_activity_properties["spacecraft_available"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["payload_available"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["antenna_available"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["degraded"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["mode"] == %{"type" => "string"}

    assert mission_plan_activity_properties["incompatible_activity_types"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["suppressed_activity_types"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["collection_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["product_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["product_ids"]["items"] == %{"type" => "string"}
    assert mission_plan_activity_properties["payload_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["instrument_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["image_quality_score"] == %{"type" => "number"}
    assert mission_plan_activity_properties["image_quality_status"] == %{"type" => "string"}
    assert mission_plan_activity_properties["image_quality_source"] == %{"type" => "string"}
    assert mission_plan_activity_properties["cloud_cover_fraction"] == %{"type" => "number"}
    assert mission_plan_activity_properties["blur_score"] == %{"type" => "number"}
    assert mission_plan_activity_properties["data_volume_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["planned_data_volume_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_data_volume_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["estimated_data_volume_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["estimated_storage_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["estimated_downlink_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["required_downlink_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["collection_ends_at_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["planned_delivery_at_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_delivery_at_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["max_latency_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["planned_latency_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_latency_s"] == %{"type" => "number"}

    assert mission_plan_activity_properties["planned_estimated_throughput_mb"] == %{
             "type" => "number"
           }

    assert mission_plan_activity_properties["actual_throughput_mb"] == %{"type" => "number"}
    assert mission_plan_activity_properties["link_protocol"] == %{"type" => "string"}
    assert mission_plan_activity_properties["frequency_band"] == %{"type" => "string"}
    assert mission_plan_activity_properties["modulation"] == %{"type" => "string"}
    assert mission_plan_activity_properties["coding_scheme"] == %{"type" => "string"}
    assert mission_plan_activity_properties["polarization"] == %{"type" => "string"}
    assert mission_plan_activity_properties["data_rate_mbps"] == %{"type" => "number"}
    assert mission_plan_activity_properties["downlink_rate_mbps"] == %{"type" => "number"}
    assert mission_plan_activity_properties["data_rate_mb_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["downlink_rate_mb_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_data_rate_mbps"] == %{"type" => "number"}

    assert mission_plan_activity_properties["actual_downlink_rate_mbps"] == %{
             "type" => "number"
           }

    assert mission_plan_activity_properties["actual_data_rate_mb_s"] == %{"type" => "number"}

    assert mission_plan_activity_properties["actual_downlink_rate_mb_s"] == %{
             "type" => "number"
           }

    assert mission_plan_activity_properties["delivered_rate_mbps"] == %{"type" => "number"}
    assert mission_plan_activity_properties["received_rate_mbps"] == %{"type" => "number"}
    assert mission_plan_activity_properties["delivered_rate_mb_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["received_rate_mb_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_duration_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_contact_duration_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["contact_duration_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["link_margin_db"] == %{"type" => "number"}
    assert mission_plan_activity_properties["snr_db"] == %{"type" => "number"}
    assert mission_plan_activity_properties["eb_no_db"] == %{"type" => "number"}
    assert mission_plan_activity_properties["bit_error_rate"] == %{"type" => "number"}
    assert mission_plan_activity_properties["packet_loss_rate"] == %{"type" => "number"}
    assert mission_plan_activity_properties["frame_loss_rate"] == %{"type" => "number"}
    assert mission_plan_activity_properties["carrier_lock"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["symbol_lock"] == %{"type" => "boolean"}
    assert mission_plan_activity_properties["link_quality_status"] == %{"type" => "string"}
    assert mission_plan_activity_properties["pointing_mode"] == %{"type" => "string"}
    assert mission_plan_activity_properties["pointing_target_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["boresight_axis"] == %{"type" => "string"}
    assert mission_plan_activity_properties["off_nadir_angle_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["slew_angle_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["slew_rate_deg_s"] == %{"type" => "number"}
    assert mission_plan_activity_properties["pointing_error_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["pointing_status"] == %{"type" => "string"}
    assert mission_plan_activity_properties["pointing_model"] == %{"type" => "string"}
    assert mission_plan_activity_properties["pointing_source"] == %{"type" => "string"}
    assert mission_plan_activity_properties["pointing_confidence"] == %{"type" => "number"}
    assert mission_plan_activity_properties["attitude_mode"] == %{"type" => "string"}
    assert mission_plan_activity_properties["attitude_target_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["roll_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["pitch_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["yaw_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["attitude_error_deg"] == %{"type" => "number"}
    assert mission_plan_activity_properties["attitude_status"] == %{"type" => "string"}
    assert mission_plan_activity_properties["attitude_model"] == %{"type" => "string"}
    assert mission_plan_activity_properties["attitude_source"] == %{"type" => "string"}
    assert mission_plan_activity_properties["attitude_confidence"] == %{"type" => "number"}
    assert mission_plan_activity_properties["thermal_zone_id"] == %{"type" => "string"}
    assert mission_plan_activity_properties["temperature_c"] == %{"type" => "number"}
    assert mission_plan_activity_properties["planned_temperature_c"] == %{"type" => "number"}
    assert mission_plan_activity_properties["actual_temperature_c"] == %{"type" => "number"}

    assert mission_plan_activity_properties["min_operating_temperature_c"] == %{
             "type" => "number"
           }

    assert mission_plan_activity_properties["max_operating_temperature_c"] == %{
             "type" => "number"
           }

    assert mission_plan_activity_properties["thermal_margin_c"] == %{"type" => "number"}
    assert mission_plan_activity_properties["thermal_status"] == %{"type" => "string"}
    assert mission_plan_activity_properties["thermal_model"] == %{"type" => "string"}
    assert mission_plan_activity_properties["thermal_source"] == %{"type" => "string"}
    assert mission_plan_activity_properties["thermal_confidence"] == %{"type" => "number"}

    assert mission_plan_activity_properties["dependency_activity_ids"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["dependency_timeline_ids"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["exclusive_with_activity_ids"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["exclusive_with_timeline_ids"]["items"] == %{
             "type" => "string"
           }

    assert mission_plan_activity_properties["source_window_type"] == %{"type" => "string"}
    assert mission_plan_activity_properties["source_window"]["type"] == "object"
    assert mission_plan_activity_properties["cadence_import"]["type"] == "object"

    assert candidate_refresh_properties["operational_feedback"]["properties"][
             "realized_activities"
           ][
             "items"
           ]["properties"]["station_id"] == %{"type" => "string"}

    assert candidate_refresh_properties["mission_state"]["type"] == "object"

    realized_activity_properties =
      candidate_refresh_properties["operational_feedback"]["properties"][
        "realized_activities"
      ][
        "items"
      ]["properties"]

    assert realized_activity_properties["target"]["properties"]["id"] == %{"type" => "string"}

    assert realized_activity_properties["target"]["properties"]["target_id"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["station"]["properties"]["station_id"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["ground_station"]["properties"]["ground_station_id"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["spacecraft"]["properties"]["spacecraft_id"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["satellite"]["properties"]["satellite_id"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["resource_id"] == %{"type" => "string"}
    assert realized_activity_properties["resource_source_quality"] == %{"type" => "string"}
    assert realized_activity_properties["resource_trust_boundary"] == %{"type" => "string"}

    assert realized_activity_properties["resource_trust_boundary_status"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["resource_provenance"] == %{
             "type" => "object",
             "additionalProperties" => true,
             "properties" => %{}
           }

    assert realized_activity_properties["resource_blocking_dimension"] == %{"type" => "string"}
    assert realized_activity_properties["fuel_margin"] == %{"type" => "number"}
    assert realized_activity_properties["power_margin"] == %{"type" => "number"}
    assert realized_activity_properties["storage_margin"] == %{"type" => "number"}
    assert realized_activity_properties["downlink_margin"] == %{"type" => "number"}
    assert realized_activity_properties["battery_capacity_wh"] == %{"type" => "number"}
    assert realized_activity_properties["battery_energy_used_wh"] == %{"type" => "number"}

    assert realized_activity_properties["battery_energy_generated_wh"] == %{
             "type" => "number",
             "minimum" => 0.0
           }

    assert realized_activity_properties["battery_state_of_charge"] == %{"type" => "number"}
    assert realized_activity_properties["spacecraft_available"] == %{"type" => "boolean"}
    assert realized_activity_properties["payload_available"] == %{"type" => "boolean"}
    assert realized_activity_properties["antenna_available"] == %{"type" => "boolean"}
    assert realized_activity_properties["degraded"] == %{"type" => "boolean"}
    assert realized_activity_properties["mode"] == %{"type" => "string"}

    assert realized_activity_properties["incompatible_activity_types"]["items"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["suppressed_activity_types"]["items"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["collection_id"] == %{"type" => "string"}
    assert realized_activity_properties["product_id"] == %{"type" => "string"}
    assert realized_activity_properties["product_ids"]["items"] == %{"type" => "string"}
    assert realized_activity_properties["payload_id"] == %{"type" => "string"}
    assert realized_activity_properties["instrument_id"] == %{"type" => "string"}
    assert realized_activity_properties["actual_data_volume_mb"] == %{"type" => "number"}
    assert realized_activity_properties["estimated_downlink_mb"] == %{"type" => "number"}
    assert realized_activity_properties["required_downlink_mb"] == %{"type" => "number"}
    assert realized_activity_properties["actual_latency_s"] == %{"type" => "number"}
    assert realized_activity_properties["target_priority"] == %{"type" => "number"}
    assert realized_activity_properties["contact_result"] == %{"type" => "string"}
    assert realized_activity_properties["contact_success_factor"] == %{"type" => "number"}

    assert realized_activity_properties["contact_success_factor_source"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["command_result"] == %{"type" => "string"}
    assert realized_activity_properties["command_success_factor"] == %{"type" => "number"}

    assert realized_activity_properties["command_success_factor_source"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["observation_success"] == %{"type" => "boolean"}
    assert realized_activity_properties["observation_result"] == %{"type" => "string"}
    assert realized_activity_properties["observation_success_factor"] == %{"type" => "number"}

    assert realized_activity_properties["observation_success_factor_source"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["image_quality_score"] == %{"type" => "number"}
    assert realized_activity_properties["image_quality_status"] == %{"type" => "string"}
    assert realized_activity_properties["image_quality_source"] == %{"type" => "string"}
    assert realized_activity_properties["cloud_cover_fraction"] == %{"type" => "number"}
    assert realized_activity_properties["blur_score"] == %{"type" => "number"}

    assert realized_activity_properties["maneuver_success"] == %{"type" => "boolean"}
    assert realized_activity_properties["maneuver_result"] == %{"type" => "string"}
    assert realized_activity_properties["maneuver_success_factor"] == %{"type" => "number"}

    assert realized_activity_properties["maneuver_success_factor_source"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["feedback_weight"] == %{"type" => "number"}
    assert realized_activity_properties["feedback_weight_source"] == %{"type" => "string"}
    assert realized_activity_properties["delta_v_km_s"]["items"] == %{"type" => "number"}
    assert realized_activity_properties["delta_v_km_s"]["minItems"] == 3
    assert realized_activity_properties["actual_delta_v_km_s"]["maxItems"] == 3
    assert realized_activity_properties["executed_delta_v_km_s"]["minItems"] == 3
    assert realized_activity_properties["execution_uncertainty"]["type"] == "object"

    assert realized_activity_properties["maneuver_execution_uncertainty"]["type"] ==
             "object"

    assert realized_activity_properties["execution_uncertainty_status"] == %{
             "type" => "string"
           }

    assert realized_activity_properties["timing_3sigma_s"] == %{"type" => "number"}
    assert realized_activity_properties["delta_v_3sigma_km_s"]["minItems"] == 3

    assert realized_activity_properties["pointing_mode"] == %{"type" => "string"}
    assert realized_activity_properties["pointing_target_id"] == %{"type" => "string"}
    assert realized_activity_properties["boresight_axis"] == %{"type" => "string"}
    assert realized_activity_properties["off_nadir_angle_deg"] == %{"type" => "number"}
    assert realized_activity_properties["slew_angle_deg"] == %{"type" => "number"}
    assert realized_activity_properties["slew_rate_deg_s"] == %{"type" => "number"}
    assert realized_activity_properties["pointing_error_deg"] == %{"type" => "number"}
    assert realized_activity_properties["pointing_status"] == %{"type" => "string"}
    assert realized_activity_properties["pointing_model"] == %{"type" => "string"}
    assert realized_activity_properties["pointing_source"] == %{"type" => "string"}
    assert realized_activity_properties["pointing_confidence"] == %{"type" => "number"}
    assert realized_activity_properties["attitude_mode"] == %{"type" => "string"}
    assert realized_activity_properties["attitude_target_id"] == %{"type" => "string"}
    assert realized_activity_properties["roll_deg"] == %{"type" => "number"}
    assert realized_activity_properties["pitch_deg"] == %{"type" => "number"}
    assert realized_activity_properties["yaw_deg"] == %{"type" => "number"}
    assert realized_activity_properties["attitude_error_deg"] == %{"type" => "number"}
    assert realized_activity_properties["attitude_status"] == %{"type" => "string"}
    assert realized_activity_properties["attitude_model"] == %{"type" => "string"}
    assert realized_activity_properties["attitude_source"] == %{"type" => "string"}
    assert realized_activity_properties["attitude_confidence"] == %{"type" => "number"}
    assert realized_activity_properties["thermal_zone_id"] == %{"type" => "string"}
    assert realized_activity_properties["temperature_c"] == %{"type" => "number"}
    assert realized_activity_properties["planned_temperature_c"] == %{"type" => "number"}
    assert realized_activity_properties["actual_temperature_c"] == %{"type" => "number"}

    assert realized_activity_properties["min_operating_temperature_c"] == %{
             "type" => "number"
           }

    assert realized_activity_properties["max_operating_temperature_c"] == %{
             "type" => "number"
           }

    assert realized_activity_properties["thermal_margin_c"] == %{"type" => "number"}
    assert realized_activity_properties["thermal_status"] == %{"type" => "string"}
    assert realized_activity_properties["thermal_model"] == %{"type" => "string"}
    assert realized_activity_properties["thermal_source"] == %{"type" => "string"}
    assert realized_activity_properties["thermal_confidence"] == %{"type" => "number"}
    assert realized_activity_properties["eclipse_overlap_fraction"] == %{"type" => "number"}
    assert realized_activity_properties["eclipse_overlap_s"] == %{"type" => "number"}
    assert realized_activity_properties["lighting_condition"] == %{"type" => "string"}
    assert realized_activity_properties["lighting_condition_detail"] == %{"type" => "string"}
    assert realized_activity_properties["lighting_condition_model"] == %{"type" => "string"}
    assert realized_activity_properties["lighting_detail_model"] == %{"type" => "string"}

    assert realized_activity_properties["lighting_confidence"] == %{
             "type" => ["number", "string"]
           }

    assert realized_activity_properties["link_protocol"] == %{"type" => "string"}
    assert realized_activity_properties["frequency_band"] == %{"type" => "string"}
    assert realized_activity_properties["modulation"] == %{"type" => "string"}
    assert realized_activity_properties["coding_scheme"] == %{"type" => "string"}
    assert realized_activity_properties["polarization"] == %{"type" => "string"}
    assert realized_activity_properties["data_rate_mbps"] == %{"type" => "number"}
    assert realized_activity_properties["downlink_rate_mbps"] == %{"type" => "number"}
    assert realized_activity_properties["data_rate_mb_s"] == %{"type" => "number"}
    assert realized_activity_properties["downlink_rate_mb_s"] == %{"type" => "number"}
    assert realized_activity_properties["actual_data_rate_mbps"] == %{"type" => "number"}

    assert realized_activity_properties["actual_downlink_rate_mbps"] == %{
             "type" => "number"
           }

    assert realized_activity_properties["actual_data_rate_mb_s"] == %{"type" => "number"}

    assert realized_activity_properties["actual_downlink_rate_mb_s"] == %{
             "type" => "number"
           }

    assert realized_activity_properties["delivered_rate_mbps"] == %{"type" => "number"}
    assert realized_activity_properties["received_rate_mbps"] == %{"type" => "number"}
    assert realized_activity_properties["delivered_rate_mb_s"] == %{"type" => "number"}
    assert realized_activity_properties["received_rate_mb_s"] == %{"type" => "number"}
    assert realized_activity_properties["actual_duration_s"] == %{"type" => "number"}
    assert realized_activity_properties["actual_contact_duration_s"] == %{"type" => "number"}
    assert realized_activity_properties["contact_duration_s"] == %{"type" => "number"}
    assert realized_activity_properties["link_margin_db"] == %{"type" => "number"}
    assert realized_activity_properties["snr_db"] == %{"type" => "number"}
    assert realized_activity_properties["eb_no_db"] == %{"type" => "number"}
    assert realized_activity_properties["bit_error_rate"] == %{"type" => "number"}
    assert realized_activity_properties["packet_loss_rate"] == %{"type" => "number"}
    assert realized_activity_properties["frame_loss_rate"] == %{"type" => "number"}
    assert realized_activity_properties["carrier_lock"] == %{"type" => "boolean"}
    assert realized_activity_properties["symbol_lock"] == %{"type" => "boolean"}
    assert realized_activity_properties["link_quality_status"] == %{"type" => "string"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "station_id"
           ] == %{"type" => "string"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "activity_type"
           ] == %{"type" => "string"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "station"
           ]["properties"]["id"] == %{"type" => "string"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "ground_station"
           ]["properties"]["ground_station_id"] == %{"type" => "string"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "start_s"
           ] == %{"type" => "number"}

    assert candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
             "end_s"
           ] == %{"type" => "number"}

    prior_candidate_direction =
      candidate_refresh_properties["prior_candidate_activities"]["items"]["properties"][
        "direction"
      ]

    assert "health_check" in prior_candidate_direction["enum"]
    assert "healthcheck" in prior_candidate_direction["enum"]
    assert "Health Check Window" in prior_candidate_direction["enum"]

    assert get_in(prior_candidate_direction, [
             "x-orbital-dynamics",
             "provider_aliases",
             "cmd"
           ]) == "command"

    assert candidate_refresh_properties["ground_network"]["items"]["properties"]["station_id"] ==
             %{
               "type" => "string"
             }

    assert candidate_refresh_properties["ground_network"]["items"]["anyOf"] == [
             %{"required" => ["ground_station_id"]},
             %{"required" => ["station_id"]}
           ]

    operational_feedback_properties =
      candidate_refresh_properties["operational_feedback"]["properties"]

    assert candidate_refresh_properties["objectives"]["items"]["type"] == "object"

    assert candidate_refresh_properties["scoring_policy"]["properties"][
             "collection_latency_observation_weight"
           ] == %{"type" => "number"}

    assert operational_feedback_properties["trust_boundary"] == %{"type" => "string"}

    assert operational_feedback_properties["downlink_demand_mb"] == %{
             "type" => "object",
             "additionalProperties" => %{"type" => "number"},
             "properties" => %{}
           }

    assert operational_feedback_properties["station_throughput_factor"] ==
             operational_feedback_properties["downlink_demand_mb"]

    assert operational_feedback_properties["resource_margin_overrides"] == %{
             "type" => "object",
             "additionalProperties" => true,
             "properties" => %{}
           }

    campaign_ground_network =
      schema["properties"]["campaign"]["properties"]["ground_network"]["items"]

    assert campaign_ground_network["properties"]["station_id"] == %{"type" => "string"}
    assert campaign_ground_network["properties"]["reservation_id"] == %{"type" => "string"}
    assert campaign_ground_network["properties"]["reserved_by"] == %{"type" => "string"}
    assert campaign_ground_network["properties"]["reservation_status"] == %{"type" => "string"}

    assert campaign_ground_network["properties"]["provenance"] == %{
             "type" => "object",
             "additionalProperties" => true,
             "properties" => %{}
           }

    assert campaign_ground_network["anyOf"] == [
             %{"required" => ["ground_station_id"]},
             %{"required" => ["station_id"]}
           ]

    assert schema["x-orbital-dynamics"]["nested_contracts"] == [
             "accepted_planning_state.v1",
             "resource_summary.v1",
             "station_calendar_provider.v1"
           ]

    assert schema["x-orbital-dynamics"]["compatibility_policy"] == Schema.compatibility_policy()
    assert schema["x-orbital-dynamics"]["identity_policy"] == Schema.identity_policy()

    assert %{"required" => ["campaign"]} in schema["anyOf"]
    assert %{"required" => ["candidate_refresh"]} in schema["anyOf"]
  end

  test "checked-in study manifest JSON Schema matches the exporter" do
    assert File.exists?("schemas/study_manifest.v1.schema.json")

    assert "schemas/study_manifest.v1.schema.json"
           |> File.read!()
           |> :json.decode() == Manifest.json_schema()
  end

  test "builds JSON-serializable validation reports for manifest files" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_report_pass.json")
    invalid_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_report_fail.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(invalid_path)
    end)

    File.write!(manifest_path, :json.encode(circular_leo_manifest()) |> IO.iodata_to_binary())
    File.write!(invalid_path, ~s({"schema_version":1,"study_id":"missing_scenarios"}))

    assert %{
             "schema_contract" => "study_manifest_lint.v1",
             "schema_id" =>
               "https://orbital-dynamics.local/schemas/study_manifest_lint.v1.schema.json",
             "manifest_schema_contract" => "study_manifest.v1",
             "manifest_schema_id" =>
               "https://orbital-dynamics.local/schemas/study_manifest.v1.schema.json",
             "semantic_validator" =>
               "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2",
             "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
             "supported" => %{
               "lint_error_codes" => lint_error_codes,
               "outputs" => supported_outputs,
               "propagators" => supported_propagators
             },
             "status" => "pass",
             "study_id" => "leo_manifest",
             "scenario_count" => 2,
             "outputs" => ["trajectories", "access_windows", "eclipses"],
             "error_count" => 0,
             "warning_count" => 0,
             "errors" => []
           } = Manifest.validation_report(manifest_path)

    assert "ground_track_crossings" in supported_outputs
    assert "two_body_nx_compiled" in supported_propagators
    assert "invalid_run_option" in lint_error_codes
    assert "missing_run_option" in lint_error_codes

    assert %{
             "status" => "fail",
             "error_count" => 1,
             "warning_count" => 0,
             "schema_export_command" =>
               "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
             "errors" => [
               %{
                 "code" => "missing_field",
                 "path" => "$.scenarios",
                 "message" => "required field is missing: scenarios"
               }
             ]
           } = Manifest.validation_report(invalid_path)
  end

  test "manifest lint preflights configured Earth-rotation provider fit" do
    manifest_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_bad_provider_fit.json")

    on_exit(fn -> File.rm(manifest_path) end)

    source =
      circular_leo_manifest()
      |> Map.put("outputs", ["ground_track_crossings"])
      |> Map.put("ground_track_crossings", [
        %{
          "id" => "short_tabular_provider",
          "crossing" => "longitude",
          "longitude_deg" => 0.0,
          "frame" => "body_fixed",
          "earth_rotation_provider" => %{
            "provider" => "tabular_earth_orientation",
            "samples" => [
              %{"seconds_since_j2000" => 0.0, "earth_rotation_angle_rad" => 0.0},
              %{"seconds_since_j2000" => 300.0, "earth_rotation_angle_rad" => 0.021876345}
            ]
          }
        }
      ])

    File.write!(manifest_path, :json.encode(source) |> IO.iodata_to_binary())

    assert %{
             "status" => "fail",
             "study_id" => "leo_manifest",
             "outputs" => ["ground_track_crossings"],
             "supported" => %{"lint_error_codes" => lint_error_codes},
             "error_count" => 1,
             "warning_count" => 0,
             "errors" => [
               %{
                 "code" => "invalid_run_option",
                 "path" => "$.ground_track_crossings",
                 "message" => "run option has an invalid value: ground_track_crossings",
                 "details" => %{
                   "option" => "ground_track_crossings"
                 }
               }
             ]
           } = Manifest.validation_report(manifest_path)

    assert "invalid_run_option" in lint_error_codes
  end

  test "builds a runnable study from a circular LEO manifest" do
    source =
      Map.put(circular_leo_manifest(), "run_options", %{
        "max_concurrency" => 2,
        "task_supervisor_node" => "worker@127.0.0.1"
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert manifest.study.id == "leo_manifest"
    assert manifest.study.propagator == J2
    assert manifest.study.propagator_opts == [max_step_s: 10.0]
    assert manifest.study.outputs == [:trajectories, :access_windows, :eclipses]
    assert length(manifest.study.scenarios) == 2
    assert Enum.map(manifest.study.scenarios, & &1.id) == [:manifest_leo_1, :manifest_leo_2]
    assert Enum.map(manifest.ground_stations, & &1.id) == ["equator_prime", "equator_90e"]
    assert Keyword.fetch!(manifest.run_opts, :sun_direction) == {1.0, 0.0, 0.0}
    assert Keyword.fetch!(manifest.run_opts, :max_concurrency) == 2

    assert Keyword.fetch!(manifest.run_opts, :task_supervisor) ==
             {OrbitalDynamics.ScenarioSupervisor, :"worker@127.0.0.1"}
  end

  test "builds ground-track crossing study outputs from manifest config" do
    earth_rotation_samples = [
      %{"seconds_since_j2000" => 0.0, "earth_rotation_angle_rad" => 0.0},
      %{"seconds_since_j2000" => 3600.0, "earth_rotation_angle_rad" => 0.0}
    ]

    source =
      circular_leo_manifest()
      |> Map.put("outputs", ["ground_track_crossings"])
      |> Map.put("ground_track_crossings", [
        %{
          "id" => "prime_meridian",
          "crossing" => "longitude",
          "longitude_deg" => 0.0,
          "frame" => "body_fixed",
          "rotation_rate_rad_s" => 7.2921150e-5,
          "rotation_epoch_s" => 0.0,
          "rotation_angle_offset_rad" => 0.0
        },
        %{
          "id" => "tabular_prime_meridian",
          "crossing" => "longitude",
          "longitude_deg" => 0.0,
          "frame" => "body_fixed",
          "earth_rotation_provider" => %{
            "provider" => "tabular_earth_orientation",
            "source" => "manifest_declared_table",
            "samples" => earth_rotation_samples
          }
        }
      ])

    assert {:ok, manifest} = Manifest.from_map(source)

    assert manifest.study.outputs == [:ground_track_crossings]

    assert [constant_request, tabular_request] =
             Keyword.fetch!(manifest.run_opts, :ground_track_crossings)

    assert constant_request == %{
             id: "prime_meridian",
             crossing: :longitude,
             longitude_deg: 0.0,
             frame: :body_fixed,
             rotation_rate_rad_s: 7.2921150e-5,
             rotation_epoch_s: 0.0,
             rotation_angle_offset_rad: 0.0
           }

    assert %{
             id: "tabular_prime_meridian",
             crossing: :longitude,
             longitude_deg: tabular_longitude_deg,
             frame: :body_fixed,
             earth_rotation_provider:
               {OrbitalDynamics.Environment.TabularEarthOrientationProvider, provider_opts}
           } = tabular_request

    assert tabular_longitude_deg == 0.0

    assert Keyword.fetch!(provider_opts, :samples) == [
             %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
             %{seconds_since_j2000: 3600.0, earth_rotation_angle_rad: 0.0}
           ]

    assert Keyword.fetch!(provider_opts, :source) == "manifest_declared_table"

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set)

    assert [%{crossing: "longitude", frame: "body_fixed"} | _] =
             artifact.ground_track_crossings

    assert [%{assumptions: %{"rotation_epoch_s" => rotation_epoch_s}} | _] =
             artifact.ground_track_crossings

    assert rotation_epoch_s == 0.0

    assert Enum.any?(
             artifact.ground_track_crossings,
             &match?(
               %{
                 request_id: "tabular_prime_meridian",
                 assumptions: %{
                   "earth_rotation_provider_id" =>
                     "environment.provider.earth_orientation.tabular_rotation",
                   "earth_rotation_interpolation" => "linear_declared_rotation_sample"
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             artifact.assumptions["environment_models"],
             &(&1["id"] == "environment.earth_rotation.constant_rate")
           )
  end

  test "runs a manifest study and emits manifest assumptions in the artifact" do
    assert {:ok, manifest} = Manifest.from_map(circular_leo_manifest())
    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)

    artifact = Artifact.build(result_set)

    assert artifact.study_id == "leo_manifest"
    assert artifact.assumptions["outputs"] == ["trajectories", "access_windows", "eclipses"]
    assert artifact.assumptions["sun_direction"] == [1.0, 0.0, 0.0]
    assert artifact.assumptions["study_metadata"]["manifest_schema_version"] == 1
    assert length(artifact.trajectories) == 2
    assert length(artifact.access_windows) > 0
    assert length(artifact.eclipse_intervals) > 0
  end

  test "builds explicit Cartesian scenarios" do
    assert {:ok, manifest} = Manifest.from_map(explicit_scenario_manifest())

    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "explicit_leo_1"
    assert scenario.spacecraft.id == "sat_1"
    assert scenario.initial_state.position_km == {7000.0, 0.0, 0.0}
    assert scenario.initial_state.velocity_km_s == {0.0, 7.5, 0.0}
    assert scenario.duration_s == 120.0
    assert scenario.output_step_s == 60.0
    assert [maneuver] = scenario.maneuvers
    assert maneuver.id == "raise_apogee"
    assert maneuver.epoch.seconds_since_j2000 == 60.0
    assert maneuver.delta_v_km_s == {0.0, 0.01, 0.0}
  end

  test "builds mission plan scenarios and archives activity metadata" do
    assert {:ok, manifest} = Manifest.from_map(mission_plan_manifest())

    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "ops_plan"
    assert scenario.duration_s == 180.0
    assert scenario.output_step_s == 60.0

    assert [maneuver] = scenario.maneuvers
    assert maneuver.id == "raise_apogee"
    assert maneuver.epoch.seconds_since_j2000 == 60.0
    assert maneuver.delta_v_km_s == {0.0, 0.01, 0.0}

    assert get_in(scenario.metadata, [:mission_plan, :metadata]) == %{"objective" => "checkout"}

    assert [
             %{id: "initial_coast", type: :coast},
             %{id: "observe_target", type: :observe},
             %{id: "target_hold", type: :attitude},
             %{id: "downlink_pass", type: :downlink},
             %{id: "cmd_window", type: :command},
             %{id: "track_pass", type: :tracking},
             %{id: "health_poll", type: :health_check},
             %{id: "uplink_pass", type: :planned_contact}
           ] = get_in(scenario.metadata, [:mission_plan, :non_dynamics_activities])

    downlink_activity =
      scenario.metadata
      |> get_in([:mission_plan, :non_dynamics_activities])
      |> Enum.find(&(&1.id == "downlink_pass"))

    observe_activity =
      scenario.metadata
      |> get_in([:mission_plan, :non_dynamics_activities])
      |> Enum.find(&(&1.id == "observe_target"))

    attitude_activity =
      scenario.metadata
      |> get_in([:mission_plan, :non_dynamics_activities])
      |> Enum.find(&(&1.id == "target_hold"))

    assert observe_activity.pointing_mode == "target_track"
    assert observe_activity.pointing_target_id == "target_a"
    assert observe_activity.boresight_axis == "+Z"
    assert observe_activity.off_nadir_angle_deg == 12.5
    assert observe_activity.slew_angle_deg == 4.0
    assert observe_activity.slew_rate_deg_s == 0.2
    assert observe_activity.pointing_error_deg == 0.05
    assert observe_activity.pointing_status == "declared"
    assert observe_activity.pointing_model == "operator_supplied"
    assert observe_activity.pointing_source == "mission_database"
    assert observe_activity.pointing_confidence == 0.9
    assert observe_activity.attitude_mode == "target_track"
    assert observe_activity.attitude_target_id == "target_a"
    assert observe_activity.roll_deg == 1.0
    assert observe_activity.pitch_deg == -0.5
    assert observe_activity.yaw_deg == 2.0
    assert observe_activity.attitude_error_deg == 0.05
    assert observe_activity.attitude_status == "declared"
    assert observe_activity.attitude_model == "operator_supplied"
    assert observe_activity.attitude_source == "mission_database"
    assert observe_activity.attitude_confidence == 0.9
    assert observe_activity.thermal_zone_id == "payload_bus"
    assert observe_activity.temperature_c == 18.5
    assert observe_activity.planned_temperature_c == 19.0
    assert observe_activity.actual_temperature_c == 21.0
    assert observe_activity.min_operating_temperature_c == -5.0
    assert observe_activity.max_operating_temperature_c == 40.0
    assert observe_activity.thermal_margin_c == 19.0
    assert observe_activity.thermal_status == "nominal"
    assert observe_activity.thermal_model == "operator_supplied"
    assert observe_activity.thermal_source == "mission_database"
    assert observe_activity.thermal_confidence == 0.8
    assert observe_activity.image_quality_score == 0.84
    assert observe_activity.image_quality_status == "usable"
    assert observe_activity.image_quality_source == "provider_observation_review"
    assert observe_activity.cloud_cover_fraction == 0.18
    assert observe_activity.blur_score == 0.06
    assert attitude_activity.type == :attitude
    assert attitude_activity.pointing_mode == "target_track"
    assert attitude_activity.pointing_target_id == "target_a"
    assert attitude_activity.attitude_mode == "target_track"
    assert attitude_activity.attitude_target_id == "target_a"
    assert attitude_activity.attitude_error_deg == 0.08
    assert attitude_activity.attitude_confidence == 0.85

    assert downlink_activity.dependencies == ["observe_target"]
    assert downlink_activity.timeline_id == "timeline:downlink_pass"
    assert downlink_activity.scenario_id == "ops_plan"
    assert downlink_activity.spacecraft_id == "sat_1"
    assert downlink_activity.resource_id == "payload_bus"
    assert downlink_activity.resource_source_quality == "declared"
    assert downlink_activity.resource_trust_boundary == "operator_supplied"
    assert downlink_activity.resource_trust_boundary_status == "declared"
    assert downlink_activity.resource_provenance == %{"source" => "mission_database"}
    assert downlink_activity.resource_blocking_dimension == "power"
    assert downlink_activity.fuel_margin == 0.72
    assert downlink_activity.power_margin == 0.35
    assert downlink_activity.storage_margin == 0.42
    assert downlink_activity.downlink_margin == 0.51
    assert downlink_activity.battery_capacity_wh == 240.0
    assert downlink_activity.battery_energy_used_wh == 88.0
    assert downlink_activity.battery_energy_generated_wh == 45.0
    assert downlink_activity.battery_state_of_charge == 0.68
    assert downlink_activity.spacecraft_available == true
    assert downlink_activity.payload_available == false
    assert downlink_activity.antenna_available == true
    assert downlink_activity.degraded == true
    assert downlink_activity.mode == "payload_safe"
    assert downlink_activity.incompatible_activity_types == ["observe"]
    assert downlink_activity.suppressed_activity_types == ["downlink"]
    assert downlink_activity.collection_id == "collection_alpha"
    assert downlink_activity.product_id == "image_alpha_1"
    assert downlink_activity.product_ids == ["image_alpha_1", "image_alpha_2"]
    assert downlink_activity.payload_id == "camera_a"
    assert downlink_activity.instrument_id == "wide_field"
    assert downlink_activity.data_volume_mb == 120.0
    assert downlink_activity.planned_data_volume_mb == 120.0
    assert downlink_activity.actual_data_volume_mb == 90.0
    assert downlink_activity.estimated_data_volume_mb == 120.0
    assert downlink_activity.estimated_storage_mb == 120.0
    assert downlink_activity.estimated_downlink_mb == 118.0
    assert downlink_activity.required_downlink_mb == 100.0
    assert downlink_activity.collection_ends_at_s == 360.0
    assert downlink_activity.planned_delivery_at_s == 540.0
    assert downlink_activity.actual_delivery_at_s == 550.0
    assert downlink_activity.max_latency_s == 240.0
    assert downlink_activity.planned_latency_s == 180.0
    assert downlink_activity.actual_latency_s == 190.0
    assert downlink_activity.planned_estimated_throughput_mb == 118.0
    assert downlink_activity.actual_throughput_mb == 96.0
    assert downlink_activity.link_protocol == "space_packet"
    assert downlink_activity.frequency_band == "x_band"
    assert downlink_activity.modulation == "qpsk"
    assert downlink_activity.coding_scheme == "ldpc"
    assert downlink_activity.polarization == "rhcp"
    assert downlink_activity.data_rate_mbps == 8.0
    assert downlink_activity.downlink_rate_mbps == 7.5
    assert downlink_activity.data_rate_mb_s == 1.0
    assert downlink_activity.downlink_rate_mb_s == 0.9375
    assert downlink_activity.actual_data_rate_mbps == 6.0
    assert downlink_activity.actual_downlink_rate_mbps == 5.5
    assert downlink_activity.actual_data_rate_mb_s == 0.75
    assert downlink_activity.actual_downlink_rate_mb_s == 0.6875
    assert downlink_activity.delivered_rate_mbps == 5.0
    assert downlink_activity.received_rate_mbps == 4.5
    assert downlink_activity.delivered_rate_mb_s == 0.625
    assert downlink_activity.received_rate_mb_s == 0.5625
    assert downlink_activity.actual_duration_s == 28.0
    assert downlink_activity.actual_contact_duration_s == 27.0
    assert downlink_activity.contact_duration_s == 30.0
    assert downlink_activity.link_margin_db == 3.5
    assert downlink_activity.snr_db == 12.0
    assert downlink_activity.eb_no_db == 9.0
    assert downlink_activity.bit_error_rate == 1.0e-6
    assert downlink_activity.packet_loss_rate == 0.01
    assert downlink_activity.frame_loss_rate == 0.02
    assert downlink_activity.carrier_lock == true
    assert downlink_activity.symbol_lock == true
    assert downlink_activity.link_quality_status == "nominal"
    assert downlink_activity.dependency_activity_ids == ["observe_target"]
    assert downlink_activity.dependency_timeline_ids == ["timeline:observe_target"]
    assert downlink_activity.exclusive_with_activity_ids == ["cmd_window"]
    assert downlink_activity.exclusive_with_timeline_ids == ["timeline:cmd_window"]
    assert downlink_activity.source_window_type == "ground_station_access"

    assert downlink_activity.source_window == %{
             "id" => "window:leo_1:ground_station_access:dss_14:1",
             "type" => "ground_station_access",
             "provider" => "candidate_refresh.v1"
           }

    assert downlink_activity.cadence_import == %{
             "external_id" => "cadence:contact:downlink_pass",
             "activity_type" => "contact",
             "schema_contract" => "cadence_import_manifest.v1"
           }

    assert [plan_metadata] = manifest.study.metadata["mission_plans"]
    assert plan_metadata.id == "ops_plan"
    assert plan_metadata.activity_count == 9

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set)

    assert [
             %{
               "id" => "ops_plan",
               "metadata" => %{"objective" => "checkout"},
               "activity_count" => 9
             }
           ] = artifact.assumptions["study_metadata"]["mission_plans"]

    assert get_in(hd(artifact.trajectories), [
             :assumptions,
             "scenario_metadata",
             "mission_plan",
             "id"
           ]) == "ops_plan"
  end

  test "mission plan manifests accept activity_type aliases for activities" do
    source =
      update_in(mission_plan_manifest(), ["mission_plans", Access.at(0), "activities"], fn
        activities ->
          Enum.map(activities, fn
            %{"id" => "track_pass"} = activity ->
              activity
              |> Map.put("activity_type", Map.fetch!(activity, "type"))
              |> Map.delete("type")

            activity ->
              activity
          end)
      end)

    assert {:ok, manifest} = Manifest.from_map(source)
    scenario = hd(manifest.study.scenarios)

    assert %{id: "track_pass", type: :tracking} =
             scenario.metadata
             |> get_in([:mission_plan, :non_dynamics_activities])
             |> Enum.find(&(&1.id == "track_pass"))
  end

  test "rejects negative mission plan activity battery generation" do
    manifest =
      update_in(mission_plan_manifest(), ["mission_plans", Access.at(0), "activities"], fn
        activities ->
          Enum.map(activities, fn
            %{"id" => "downlink_pass"} = activity ->
              Map.put(activity, "battery_energy_generated_wh", -1.0)

            activity ->
              activity
          end)
      end)

    assert {:error,
            {:invalid_manifest,
             "battery_energy_generated_wh must be nil or a non-negative number"}} =
             Manifest.from_map(manifest)
  end

  test "rejects mission plan activity scope that conflicts with parent plan" do
    manifest =
      update_in(mission_plan_manifest(), ["mission_plans", Access.at(0), "activities"], fn
        activities ->
          Enum.map(activities, fn
            %{"id" => "downlink_pass"} = activity ->
              Map.put(activity, "spacecraft_id", "other_sat")

            activity ->
              activity
          end)
      end)

    assert {:error, {:invalid_field, "activities.spacecraft_id"}} = Manifest.from_map(manifest)
  end

  test "runs a LEO campaign manifest and emits a ranked plan artifact" do
    manifest_source =
      campaign_manifest()
      |> put_in(["campaign", "ground_network", Access.at(0), "status"], "available")

    assert {:ok, manifest} = Manifest.from_map(manifest_source)

    assert manifest.study.outputs == [
             :trajectories,
             :access_windows,
             :eclipses,
             :target_visibility
           ]

    assert Enum.map(manifest.study.scenarios, & &1.id) == ["leo_1", "leo_2"]
    assert Enum.map(manifest.targets, & &1.id) == ["target_a", "target_b"]
    assert Keyword.fetch!(manifest.run_opts, :targets) == manifest.targets

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "id" => "equator_maintenance",
               "status" => "available"
             }
           ] = manifest.study.metadata["campaign"]["ground_network"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "storage_capacity_mb" => 100.0,
               "storage_margin" => 0.8
             }
           ] = manifest.study.metadata["campaign"]["resource_summaries"]

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set, generated_at: ~U[2026-05-13 00:00:00Z])

    assert length(artifact.target_visibility_windows) > 0

    assert %{
             "schema_version" => 1,
             "planner" => "OrbitalDynamics.CampaignPlanner.V1",
             "activities" => activities,
             "proposed_contacts" => proposed_contacts,
             "contact_intents" => contact_intents,
             "station_calendar_report" => station_calendar_report,
             "resource_projection_report" => resource_projection_report,
             "candidate_activities" => candidates,
             "ranked_timelines" => [_best | _],
             "warnings" => warnings,
             "provenance" => provenance,
             "ranking_explanation" => ranking_explanation
           } = artifact.campaign_plan

    assert Enum.any?(candidates, &(&1["type"] == "observe"))
    assert Enum.any?(candidates, &(&1["type"] == "downlink"))
    assert Enum.all?(activities, &Map.has_key?(&1, "cadence_import"))
    assert proposed_contacts != []
    assert Enum.any?(contact_intents, &(&1["schema_contract"] == "contact_intent.v1"))
    assert station_calendar_report["calendar_entry_count"] == 1

    assert resource_projection_report["model"] ==
             "thin_campaign_selected_activity_resource_projection"

    assert [%{"spacecraft_id" => "leo_1"}] = resource_projection_report["projected_resources"]
    refute "no contact activities proposed" in warnings
    assert provenance["propagator"] == "Elixir.OrbitalDynamics.Propagators.TwoBody"
    assert ranking_explanation["objective"] =~ "maximize"
  end

  test "mission plan activities accept provider-shaped target station and spacecraft aliases" do
    source =
      update_in(mission_plan_manifest(), ["mission_plans", Access.at(0), "activities"], fn
        activities ->
          provider_activities =
            Enum.map(activities, fn
              %{"id" => "observe_target"} = activity ->
                activity
                |> Map.delete("target_id")
                |> Map.put("spacecraft", %{"id" => "sat_1"})
                |> Map.put("target", %{"id" => "target_a"})
                |> Map.put("target_priority", 4.5)
                |> Map.put("target_priority_source", "operator_objective")
                |> Map.put("target_priority_objective_ids", ["latency:collection_alpha"])
                |> Map.put("target_priority_objective_type", "collection_latency")
                |> Map.put("observation_success", true)
                |> Map.put("observation_result", "usable")
                |> Map.put("observation_success_factor", 0.8)
                |> Map.put("observation_success_factor_source", "image_quality_review")
                |> Map.put("feedback_weight", 0.7)
                |> Map.put("feedback_weight_source", "operator_weight")
                |> Map.put("eclipse_overlap_fraction", 0.25)
                |> Map.put("eclipse_overlap_s", 15.0)
                |> Map.put("lighting_condition", "partial_eclipse")
                |> Map.put("lighting_condition_detail", "mixed_lighting")
                |> Map.put("lighting_condition_model", "sampled_eclipse_overlap_tag")
                |> Map.put("lighting_detail_model", "sampled_eclipse_overlap_fraction_tag")
                |> Map.put("lighting_confidence", "bounded_by_sampled_eclipse_overlap")

              %{"id" => "downlink_pass"} = activity ->
                activity
                |> Map.delete("ground_station_id")
                |> Map.put("satellite", %{"satellite_id" => "sat_1"})
                |> Map.put("station", %{"id" => "dss_14"})

              %{"id" => "cmd_window"} = activity ->
                activity
                |> Map.delete("ground_station_id")
                |> Map.put("ground_station", %{"station_id" => "dss_14"})
                |> Map.put("direction", "cmd")
                |> Map.put("command_window", %{
                  "id" => "command_window:cmd_window",
                  "type" => "uplink_window",
                  "provider" => "cadence"
                })

              %{"id" => "track_pass"} = activity ->
                activity
                |> Map.delete("ground_station_id")
                |> Map.put("station", %{"ground_station_id" => "dss_14"})
                |> Map.put("direction", "Track-ing")

              %{"id" => "health_poll"} = activity ->
                activity
                |> Map.put("station", %{"id" => "dss_14"})
                |> Map.put("direction", "healthcheck")

              %{"id" => "uplink_pass"} = activity ->
                activity
                |> Map.delete("ground_station_id")
                |> Map.put("station_id", "dss_14")
                |> Map.put("direction", "up-link")

              activity ->
                activity
            end)

          provider_activities ++
            [
              %{
                "id" => "provider_health_window",
                "type" => "planned_contact",
                "start_s" => 179.0,
                "end_s" => 180.0,
                "station" => %{"id" => "dss_14"},
                "direction" => "Health Check Window"
              }
            ]
      end)

    assert {:ok, manifest} = Manifest.from_map(source)

    activities =
      get_in(manifest.study.scenarios, [
        Access.at(0),
        Access.key(:metadata),
        :mission_plan,
        :non_dynamics_activities
      ])

    assert Enum.find(activities, &(&1.id == "observe_target")).target_id == "target_a"
    assert Enum.find(activities, &(&1.id == "observe_target")).spacecraft_id == "sat_1"

    assert %{
             eclipse_overlap_fraction: 0.25,
             eclipse_overlap_s: 15.0,
             lighting_condition: "partial_eclipse",
             lighting_condition_detail: "mixed_lighting",
             lighting_condition_model: "sampled_eclipse_overlap_tag",
             lighting_detail_model: "sampled_eclipse_overlap_fraction_tag",
             lighting_confidence: "bounded_by_sampled_eclipse_overlap",
             target_priority: 4.5,
             target_priority_source: "operator_objective",
             target_priority_objective_ids: ["latency:collection_alpha"],
             target_priority_objective_type: "collection_latency",
             observation_success: true,
             observation_result: "usable",
             observation_success_factor: 0.8,
             observation_success_factor_source: "image_quality_review",
             feedback_weight: 0.7,
             feedback_weight_source: "operator_weight"
           } = Enum.find(activities, &(&1.id == "observe_target"))

    assert Enum.find(activities, &(&1.id == "downlink_pass")).ground_station_id == "dss_14"
    assert Enum.find(activities, &(&1.id == "downlink_pass")).spacecraft_id == "sat_1"

    assert %{
             ground_station_id: "dss_14",
             command_window_id: "command_window:cmd_window",
             command_window_type: "uplink_window",
             command_window: %{
               "id" => "command_window:cmd_window",
               "type" => "uplink_window",
               "provider" => "cadence"
             }
           } = Enum.find(activities, &(&1.id == "cmd_window"))

    assert Enum.find(activities, &(&1.id == "cmd_window")).direction == :command

    assert %{
             direction: :tracking,
             ground_station_id: "dss_14"
           } = Enum.find(activities, &(&1.id == "track_pass"))

    assert %{
             direction: :health_check,
             ground_station_id: "dss_14"
           } = Enum.find(activities, &(&1.id == "health_poll"))

    assert %{
             direction: :uplink,
             ground_station_id: "dss_14"
           } = Enum.find(activities, &(&1.id == "uplink_pass"))

    assert %{
             type: :health_check,
             direction: :health_check,
             ground_station_id: "dss_14"
           } = Enum.find(activities, &(&1.id == "provider_health_window"))

    mismatched_spacecraft =
      update_in(source, ["mission_plans", Access.at(0), "activities"], fn activities ->
        Enum.map(activities, fn
          %{"id" => "observe_target"} = activity ->
            Map.put(activity, "spacecraft", %{"id" => "sat_2"})

          activity ->
            activity
        end)
      end)

    assert {:error, {:invalid_field, "activities.spacecraft_id"}} =
             Manifest.from_map(mismatched_spacecraft)
  end

  test "mission plan manifests reject non-health-check direction on health-check activities" do
    source =
      update_in(mission_plan_manifest(), ["mission_plans", Access.at(0), "activities"], fn
        activities ->
          Enum.map(activities, fn
            %{"id" => "health_poll"} = activity ->
              Map.put(activity, "direction", "downlink")

            activity ->
              activity
          end)
      end)

    assert {:error, {:invalid_field, "activities.direction"}} = Manifest.from_map(source)
  end

  test "campaign manifests normalize station-id ground network aliases" do
    manifest =
      campaign_manifest()
      |> put_in(["campaign", "ground_network"], [
        %{
          "station_id" => "equator_prime",
          "id" => "equator_maintenance",
          "status" => "maintenance",
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0
        }
      ])

    assert {:ok, parsed} = Manifest.from_map(manifest)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "id" => "equator_maintenance",
               "status" => "maintenance"
             }
           ] = parsed.study.metadata["campaign"]["ground_network"]
  end

  test "campaign manifests preserve availability-only ground network entries" do
    manifest =
      campaign_manifest()
      |> put_in(["campaign", "ground_network"], [
        %{
          "station_id" => "equator_prime",
          "id" => "equator_maintenance",
          "availability" => "maintenance",
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0,
          "reservation_id" => "reservation_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "tentative",
          "provenance" => %{"source" => "operator_supplied"}
        },
        %{
          "station_id" => "deep_space_net",
          "id" => "dsn_numeric_capacity",
          "availability" => 0.5,
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0
        }
      ])

    assert {:ok, parsed} = Manifest.from_map(manifest)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "id" => "equator_maintenance",
               "status" => "maintenance",
               "availability" => "maintenance",
               "reservation_id" => "reservation_1",
               "reserved_by" => "ops_team_b",
               "reservation_status" => "tentative",
               "provenance" => %{"source" => "operator_supplied"}
             },
             %{
               "ground_station_id" => "deep_space_net",
               "id" => "dsn_numeric_capacity",
               "status" => "reduced_capacity",
               "availability" => "reduced_capacity",
               "capacity_fraction" => 0.5
             }
           ] = parsed.study.metadata["campaign"]["ground_network"]
  end

  test "rejects invalid campaign ground network calendar entries" do
    manifest =
      campaign_manifest()
      |> put_in(["campaign", "ground_network"], [
        %{"id" => "missing_station", "status" => "maintenance"}
      ])

    assert {:error, {:missing_field, "ground_station_id"}} = Manifest.from_map(manifest)

    manifest =
      campaign_manifest()
      |> put_in(["campaign", "ground_network"], [
        %{
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 120.0,
          "ends_at_s" => 60.0
        }
      ])

    assert {:error, {:invalid_field, "campaign.ground_network"}} = Manifest.from_map(manifest)

    manifest =
      campaign_manifest()
      |> put_in(["campaign", "ground_network"], [
        %{
          "ground_station_id" => "equator_prime",
          "availability" => 1.5
        }
      ])

    assert {:error, {:invalid_field, "availability"}} = Manifest.from_map(manifest)
  end

  test "runs candidate refresh manifests from accepted planning state snapshots" do
    assert {:ok, manifest} = Manifest.from_map(candidate_refresh_manifest())

    assert manifest.study.outputs == [
             :trajectories,
             :access_windows,
             :eclipses,
             :target_visibility
           ]

    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "leo_1"
    assert scenario.spacecraft.id == "sat_1"
    assert scenario.duration_s == 600.0
    assert scenario.output_step_s == 60.0
    assert get_in(scenario.metadata, [:candidate_refresh, :accepted_snapshot_id]) == "ops-state-1"
    assert Enum.map(manifest.targets, & &1.id) == ["target_a"]

    assert get_in(manifest.study.metadata, ["candidate_refresh", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.accepted_planning_state"],
             "targets" => ["candidate_refresh.targets"],
             "ground_stations" => ["ground_stations"]
           }

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z])

    assert %{
             "schema_contract" => "candidate_refresh.v1",
             "planner" => "OrbitalDynamics.CandidateRefresh.V1",
             "candidate_activities" => candidates,
             "contact_intents" => contact_intents,
             "resource_summaries" => resource_summaries,
             "contact_filter_report" => contact_filter_report,
             "candidate_diff_report" => candidate_diff_report,
             "freshness_report" => freshness_report,
             "invalidated_candidates" => invalidated
           } = artifact.candidate_refresh

    assert Enum.any?(candidates, &(&1["type"] in ["observe", "downlink"]))
    assert Enum.any?(contact_intents, &(&1["schema_contract"] == "contact_intent.v1"))
    assert contact_filter_report["suppressed_candidate_count"] == 0
    assert candidate_diff_report["schema_contract"] == "candidate_diff_report.v1"
    assert candidate_diff_report["invalidated_candidate_count"] == 1
    assert freshness_report["schema_contract"] == "freshness_report.v1"
    assert freshness_report["status"] == "current"
    assert freshness_report["allowed_state_quality_levels"] == ["planning_accepted"]

    downlink = Enum.find(candidates, &(&1["type"] == "downlink"))

    assert downlink["contact_success_factor"] == 0.8

    assert get_in(downlink, ["throughput_model", "confidence_source"]) ==
             "operational_feedback.contact_success_rate.station"

    assert artifact.candidate_refresh["resource_filter_report"]["policy"] == %{
             "min_observe_storage_margin" => 0.2,
             "min_downlink_margin" => 0.2
           }

    assert [%{"spacecraft_id" => "sat_1", "storage_margin" => 0.75}] = resource_summaries
    assert [%{"id" => "old_candidate"}] = invalidated

    assert get_in(artifact.candidate_refresh, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.accepted_planning_state"],
             "targets" => ["candidate_refresh.targets"],
             "ground_stations" => ["ground_stations"]
           }
  end

  test "candidate refresh manifests preserve typed source reports for refresh provenance" do
    feedback_report =
      OrbitalDynamics.TimelineFeedback.reconcile(
        [
          %{
            id: :manifest_dl,
            type: :downlink,
            ground_station_id: :equator_prime,
            direction: :downlink,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            required_downlink_mb: 360.0
          }
        ],
        [
          %{
            id: :manifest_dl,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0,
            trust_boundary: :manifest_timeline_review
          }
        ]
      )

    operational_timeline_report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "row_count" => 1,
      "provenance" => %{"trust_boundary" => "manifest_operational_timeline"},
      "rows" => [
        %{
          "id" => "timeline_row:manifest_contact",
          "activity_type" => "downlink",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "contact_success_factor" => 0.6
        }
      ]
    }

    source =
      candidate_refresh_manifest()
      |> update_in(["candidate_refresh"], fn refresh ->
        refresh
        |> Map.put("source_timeline_feedback_report", feedback_report)
        |> Map.put("source_operational_timeline_report", operational_timeline_report)
      end)

    assert {:ok, manifest} = Manifest.from_map(source)

    assert get_in(manifest.study.metadata, [
             "candidate_refresh",
             "source_timeline_feedback_report"
           ]) == feedback_report

    assert get_in(manifest.study.metadata, [
             "candidate_refresh",
             "source_operational_timeline_report"
           ]) == operational_timeline_report

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z])

    assert get_in(artifact.candidate_refresh, [
             "provenance",
             "operational_feedback",
             "derived_from_source_timeline_feedback_report"
           ])

    assert get_in(artifact.candidate_refresh, [
             "provenance",
             "operational_feedback",
             "source_timeline_feedback_report_paths"
           ]) == ["source_timeline_feedback_report"]

    assert get_in(artifact.candidate_refresh, [
             "provenance",
             "operational_feedback",
             "derived_from_source_operational_timeline_report"
           ])

    assert get_in(artifact.candidate_refresh, [
             "provenance",
             "operational_feedback",
             "source_operational_timeline_report_paths"
           ]) == ["source_operational_timeline_report"]
  end

  test "runs candidate refresh manifests from mission-state target and station fallbacks" do
    source =
      candidate_refresh_manifest()
      |> Map.delete("ground_stations")
      |> update_in(["candidate_refresh"], fn refresh ->
        refresh
        |> Map.delete("accepted_planning_state")
        |> Map.delete("targets")
        |> Map.put("mission_state", %{
          "snapshot_id" => "ops-mission-state",
          "captured_at" => "2026-05-14T00:00:00Z",
          "spacecraft_states" => [
            %{
              "spacecraft_id" => "sat_1",
              "scenario_id" => "leo_1",
              "dry_mass_kg" => 250.0,
              "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
              "frame" => "earth_inertial_j2000",
              "state_vector" => %{
                "position_km" => [7000.0, 0.0, 0.0],
                "velocity_km_s" => [0.0, 7.546053290107542, 0.0]
              }
            }
          ],
          "targets" => [
            %{
              "id" => "target_a",
              "latitude_deg" => 0.0,
              "longitude_deg" => 0.0,
              "minimum_elevation_deg" => 10.0,
              "priority" => 7.0
            }
          ],
          "ground_stations" => [
            %{
              "id" => "equator_prime",
              "latitude_deg" => 0.0,
              "longitude_deg" => 0.0,
              "minimum_elevation_deg" => 5.0
            }
          ]
        })
      end)

    assert {:ok, manifest} = Manifest.from_map(source)

    assert Enum.map(manifest.targets, & &1.id) == ["target_a"]
    assert Enum.map(manifest.ground_stations, & &1.id) == ["equator_prime"]
    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "leo_1"
    assert scenario.spacecraft.id == "sat_1"

    assert get_in(scenario.metadata, [:candidate_refresh, :accepted_snapshot_id]) ==
             "ops-mission-state"

    assert get_in(manifest.study.metadata, ["candidate_refresh", "mission_state", "targets"]) !=
             []

    assert get_in(manifest.study.metadata, [
             "candidate_refresh",
             "accepted_planning_state",
             "snapshot_id"
           ]) == "ops-mission-state"

    assert get_in(manifest.study.metadata, ["candidate_refresh", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.targets"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_stations"]
           }

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)

    artifact =
      Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z]).candidate_refresh

    assert %{
             "target_id" => "target_a",
             "target_priority" => 7.0
           } = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert Enum.any?(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert get_in(artifact, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.targets"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_stations"]
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "runs candidate refresh manifests from mission-state objective targets and ground-network geometry" do
    source =
      candidate_refresh_manifest()
      |> Map.put("ground_stations", [])
      |> update_in(["candidate_refresh"], fn refresh ->
        spacecraft_states = get_in(refresh, ["accepted_planning_state", "spacecraft_states"])

        refresh
        |> Map.delete("accepted_planning_state")
        |> Map.put("targets", [])
        |> Map.put("mission_state", %{
          "snapshot_id" => "ops-objective-mission-state",
          "captured_at" => "2026-05-14T00:00:00Z",
          "spacecraft_states" => spacecraft_states,
          "targets" => [],
          "objectives" => [
            %{
              "id" => "urgent:nested_target",
              "type" => "urgent_target",
              "spacecraft_id" => "sat_1",
              "priority" => 9.0,
              "target" => %{
                "id" => "target_a",
                "latitude_deg" => 0.0,
                "longitude_deg" => 0.0,
                "minimum_elevation_deg" => 10.0,
                "priority" => 4.0
              }
            }
          ],
          "ground_stations" => [],
          "ground_network" => [
            %{
              "station_id" => "equator_prime",
              "latitude_deg" => 0.0,
              "longitude_deg" => 0.0,
              "minimum_elevation_deg" => 5.0,
              "status" => "available"
            }
          ]
        })
      end)

    assert {:ok, manifest} = Manifest.from_map(source)

    assert Enum.map(manifest.targets, & &1.id) == ["target_a"]
    assert Enum.map(manifest.ground_stations, & &1.id) == ["equator_prime"]

    assert get_in(manifest.study.metadata, ["candidate_refresh", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.objectives"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
           }

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)

    artifact =
      Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z]).candidate_refresh

    assert %{
             "target_id" => "target_a",
             "target_priority" => 4.0,
             "target_priority_source" => "candidate_refresh.targets.priority",
             "observation_objective_ids" => ["urgent:nested_target"],
             "observation_objective_types" => ["urgent_target"]
           } = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert Enum.any?(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert get_in(artifact, ["provenance", "run_input_sources"]) == %{
             "accepted_planning_state" => ["candidate_refresh.mission_state.spacecraft_states"],
             "targets" => ["candidate_refresh.mission_state.objectives"],
             "ground_stations" => ["candidate_refresh.mission_state.ground_network"]
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate refresh manifest mission-state run-input fallbacks reject malformed inputs" do
    invalid_targets =
      candidate_refresh_manifest()
      |> update_in(["candidate_refresh"], fn refresh ->
        refresh
        |> Map.delete("targets")
        |> Map.put("mission_state", %{"targets" => "target_a"})
      end)

    assert {:error, {:invalid_field, "candidate_refresh.mission_state.targets"}} =
             Manifest.from_map(invalid_targets)

    invalid_stations =
      candidate_refresh_manifest()
      |> Map.delete("ground_stations")
      |> put_in(["candidate_refresh", "mission_state"], %{"ground_stations" => "station_a"})

    assert {:error, {:invalid_field, "candidate_refresh.mission_state.ground_stations"}} =
             Manifest.from_map(invalid_stations)

    invalid_spacecraft_states =
      candidate_refresh_manifest()
      |> update_in(["candidate_refresh"], fn refresh ->
        refresh
        |> Map.delete("accepted_planning_state")
        |> Map.put("mission_state", %{"spacecraft_states" => "sat_1"})
      end)

    assert {:error, {:invalid_field, "candidate_refresh.mission_state.spacecraft_states"}} =
             Manifest.from_map(invalid_spacecraft_states)
  end

  test "candidate refresh manifests preserve station-id prior contact candidates" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "prior_candidate_activities"], [
        %{
          "id" => "provider_prior_contact",
          "type" => "contact",
          "direction" => "downlink",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "provider-window-equator-prime-previous"
        }
      ])

    assert {:ok, manifest} = Manifest.from_map(source)

    assert [
             %{
               "id" => "provider_prior_contact",
               "type" => "contact",
               "direction" => "downlink",
               "station_id" => "equator_prime"
             }
           ] =
             get_in(manifest.study.metadata, ["candidate_refresh", "prior_candidate_activities"])
  end

  test "candidate refresh manifests preserve prior candidate provider direction aliases" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "prior_candidate_activities"], [
        %{
          "id" => "provider_prior_health_check",
          "direction" => "Health Check Window",
          "scenario_id" => "leo_1",
          "station" => %{"id" => "equator_prime"},
          "starts_at_s" => 300.0,
          "ends_at_s" => 420.0,
          "source_window_id" => "provider-window-health-check"
        }
      ])

    assert {:ok, manifest} = Manifest.from_map(source)

    assert [
             %{
               "id" => "provider_prior_health_check",
               "direction" => "Health Check Window",
               "station" => %{"id" => "equator_prime"}
             }
           ] =
             get_in(manifest.study.metadata, ["candidate_refresh", "prior_candidate_activities"])
  end

  test "candidate refresh manifests preserve provider-shaped realized feedback identities" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "operational_feedback"], %{
        "realized_activities" => [
          %{
            "id" => "provider_realized_observe",
            "planned_activity_id" => "old_candidate",
            "type" => "observe",
            "status" => "completed",
            "spacecraft" => %{"spacecraft_id" => "sat_1"},
            "target" => %{"id" => "target_a"},
            "resource_id" => "payload_power_bus",
            "resource_source_quality" => "declared",
            "resource_trust_boundary" => "operator_supplied",
            "resource_trust_boundary_status" => "declared",
            "resource_provenance" => %{"source" => "cadence_execution_feedback"},
            "resource_blocking_dimension" => "power",
            "fuel_margin" => 0.7,
            "power_margin" => 0.15,
            "storage_margin" => 0.05,
            "downlink_margin" => 0.6,
            "battery_capacity_wh" => 1200.0,
            "battery_energy_used_wh" => 900.0,
            "battery_state_of_charge" => 0.15,
            "spacecraft_available" => true,
            "payload_available" => false,
            "antenna_available" => false,
            "degraded" => true,
            "mode" => "reduced_power",
            "incompatible_activity_types" => ["downlink"],
            "suppressed_activity_types" => ["observe"],
            "pointing_mode" => "target_track",
            "pointing_target_id" => "target_a",
            "boresight_axis" => "+Z",
            "off_nadir_angle_deg" => 12.5,
            "slew_angle_deg" => 4.0,
            "slew_rate_deg_s" => 0.2,
            "pointing_error_deg" => 0.05,
            "pointing_status" => "verified",
            "pointing_model" => "provider_feedback",
            "pointing_source" => "cadence_execution_feedback",
            "pointing_confidence" => 0.9,
            "attitude_mode" => "target_track",
            "attitude_target_id" => "target_a",
            "roll_deg" => 1.5,
            "pitch_deg" => -2.0,
            "yaw_deg" => 0.25,
            "attitude_error_deg" => 0.08,
            "attitude_status" => "verified",
            "attitude_model" => "provider_feedback",
            "attitude_source" => "cadence_execution_feedback",
            "attitude_confidence" => 0.92,
            "thermal_zone_id" => "payload_deck",
            "temperature_c" => 42.0,
            "planned_temperature_c" => 18.0,
            "actual_temperature_c" => 42.0,
            "min_operating_temperature_c" => -5.0,
            "max_operating_temperature_c" => 45.0,
            "thermal_margin_c" => 3.0,
            "thermal_status" => "near_limit",
            "thermal_model" => "provider_feedback",
            "thermal_source" => "cadence_execution_feedback",
            "thermal_confidence" => 0.8,
            "eclipse_overlap_fraction" => 0.35,
            "eclipse_overlap_s" => 21.0,
            "lighting_condition" => "penumbra",
            "lighting_condition_detail" => "partial_eclipse",
            "lighting_condition_model" => "provider_lighting_replay",
            "lighting_detail_model" => "provider_lighting_replay",
            "lighting_confidence" => 0.72,
            "link_protocol" => "space_packet",
            "frequency_band" => "x_band",
            "modulation" => "qpsk",
            "coding_scheme" => "ldpc",
            "polarization" => "rhcp",
            "data_rate_mbps" => 8.0,
            "link_margin_db" => -1.5,
            "snr_db" => 2.0,
            "eb_no_db" => 0.5,
            "bit_error_rate" => 0.02,
            "packet_loss_rate" => 0.25,
            "frame_loss_rate" => 0.1,
            "carrier_lock" => false,
            "symbol_lock" => false,
            "link_quality_status" => "low_margin"
          },
          %{
            "id" => "provider_realized_contact",
            "planned_activity_id" => "old_downlink",
            "type" => "downlink",
            "status" => "partial",
            "satellite" => %{"satellite_id" => "sat_1"},
            "station" => %{"id" => "equator_prime"}
          }
        ]
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert %{
             "realized_activities" => [
               %{
                 "spacecraft" => %{"spacecraft_id" => "sat_1"},
                 "target" => %{"id" => "target_a"},
                 "resource_id" => "payload_power_bus",
                 "resource_source_quality" => "declared",
                 "resource_trust_boundary" => "operator_supplied",
                 "resource_trust_boundary_status" => "declared",
                 "resource_provenance" => %{"source" => "cadence_execution_feedback"},
                 "resource_blocking_dimension" => "power",
                 "fuel_margin" => 0.7,
                 "power_margin" => 0.15,
                 "storage_margin" => 0.05,
                 "downlink_margin" => 0.6,
                 "battery_capacity_wh" => 1200.0,
                 "battery_energy_used_wh" => 900.0,
                 "battery_state_of_charge" => 0.15,
                 "spacecraft_available" => true,
                 "payload_available" => false,
                 "antenna_available" => false,
                 "degraded" => true,
                 "mode" => "reduced_power",
                 "incompatible_activity_types" => ["downlink"],
                 "suppressed_activity_types" => ["observe"],
                 "pointing_mode" => "target_track",
                 "pointing_target_id" => "target_a",
                 "boresight_axis" => "+Z",
                 "off_nadir_angle_deg" => 12.5,
                 "slew_angle_deg" => 4.0,
                 "slew_rate_deg_s" => 0.2,
                 "pointing_error_deg" => 0.05,
                 "pointing_status" => "verified",
                 "pointing_model" => "provider_feedback",
                 "pointing_source" => "cadence_execution_feedback",
                 "pointing_confidence" => 0.9,
                 "attitude_mode" => "target_track",
                 "attitude_target_id" => "target_a",
                 "roll_deg" => 1.5,
                 "pitch_deg" => -2.0,
                 "yaw_deg" => 0.25,
                 "attitude_error_deg" => 0.08,
                 "attitude_status" => "verified",
                 "attitude_model" => "provider_feedback",
                 "attitude_source" => "cadence_execution_feedback",
                 "attitude_confidence" => 0.92,
                 "thermal_zone_id" => "payload_deck",
                 "temperature_c" => 42.0,
                 "planned_temperature_c" => 18.0,
                 "actual_temperature_c" => 42.0,
                 "min_operating_temperature_c" => -5.0,
                 "max_operating_temperature_c" => 45.0,
                 "thermal_margin_c" => 3.0,
                 "thermal_status" => "near_limit",
                 "thermal_model" => "provider_feedback",
                 "thermal_source" => "cadence_execution_feedback",
                 "thermal_confidence" => 0.8,
                 "eclipse_overlap_fraction" => 0.35,
                 "eclipse_overlap_s" => 21.0,
                 "lighting_condition" => "penumbra",
                 "lighting_condition_detail" => "partial_eclipse",
                 "lighting_condition_model" => "provider_lighting_replay",
                 "lighting_detail_model" => "provider_lighting_replay",
                 "lighting_confidence" => 0.72,
                 "link_protocol" => "space_packet",
                 "frequency_band" => "x_band",
                 "modulation" => "qpsk",
                 "coding_scheme" => "ldpc",
                 "polarization" => "rhcp",
                 "data_rate_mbps" => 8.0,
                 "link_margin_db" => -1.5,
                 "snr_db" => 2.0,
                 "eb_no_db" => 0.5,
                 "bit_error_rate" => 0.02,
                 "packet_loss_rate" => 0.25,
                 "frame_loss_rate" => 0.1,
                 "carrier_lock" => false,
                 "symbol_lock" => false,
                 "link_quality_status" => "low_margin"
               },
               %{
                 "satellite" => %{"satellite_id" => "sat_1"},
                 "station" => %{"id" => "equator_prime"}
               }
             ]
           } = get_in(manifest.study.metadata, ["candidate_refresh", "operational_feedback"])
  end

  test "candidate refresh manifests preserve objective lists for refresh scoring" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "objectives"], [
        %{
          "id" => "latency:collection_alpha",
          "type" => "collection_latency",
          "target_id" => "target_a",
          "spacecraft_id" => "sat_1",
          "collection_id" => "collection_alpha",
          "max_latency_s" => 900.0,
          "required_downlink_mb" => 180.0
        }
      ])
      |> put_in(
        ["candidate_refresh", "scoring_policy", "collection_latency_observation_weight"],
        35.0
      )

    assert {:ok, manifest} = Manifest.from_map(source)

    assert [
             %{
               "id" => "latency:collection_alpha",
               "type" => "collection_latency",
               "collection_id" => "collection_alpha"
             }
           ] = get_in(manifest.study.metadata, ["candidate_refresh", "objectives"])

    assert get_in(manifest.study.metadata, [
             "candidate_refresh",
             "scoring_policy",
             "collection_latency_observation_weight"
           ]) == 35.0
  end

  test "candidate refresh manifests preserve mission-state fallback snapshots" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "mission_state"], %{
        "objectives" => [
          %{
            "id" => "urgent:target_a",
            "type" => "urgent_target",
            "target_id" => "target_a",
            "spacecraft_id" => "sat_1",
            "priority" => 8.0
          }
        ],
        "operational_feedback" => %{
          "target_priority_overrides" => %{"target_a" => 6.0},
          "trust_boundary" => "cadence_mission_state"
        }
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert %{
             "objectives" => [
               %{
                 "id" => "urgent:target_a",
                 "type" => "urgent_target",
                 "priority" => 8.0
               }
             ],
             "operational_feedback" => %{
               "target_priority_overrides" => %{"target_a" => 6.0},
               "trust_boundary" => "cadence_mission_state"
             }
           } = get_in(manifest.study.metadata, ["candidate_refresh", "mission_state"])
  end

  test "candidate refresh manifests reject non-object mission-state fallback snapshots" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "mission_state"], ["not", "an", "object"])

    assert {:error, {:invalid_field, "candidate_refresh.mission_state"}} =
             Manifest.from_map(source)
  end

  test "candidate refresh manifests normalize ground-network availability inputs" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "ground_network"], [
        %{
          "station_id" => "equator_prime",
          "id" => "equator_maintenance",
          "availability" => "maintenance",
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0,
          "reservation_id" => "reservation_1",
          "reserved_by" => "ops_team_b",
          "reservation_status" => "reserved",
          "provenance" => %{"station_throughput_factor_source" => "operational_feedback"}
        },
        %{
          "station_id" => "deep_space_net",
          "id" => "dsn_numeric_capacity",
          "availability" => 0.5,
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0
        }
      ])

    assert {:ok, manifest} = Manifest.from_map(source)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "id" => "equator_maintenance",
               "status" => "maintenance",
               "availability" => "maintenance",
               "reservation_id" => "reservation_1",
               "reserved_by" => "ops_team_b",
               "reservation_status" => "reserved",
               "provenance" => %{"station_throughput_factor_source" => "operational_feedback"}
             },
             %{
               "ground_station_id" => "deep_space_net",
               "id" => "dsn_numeric_capacity",
               "status" => "reduced_capacity",
               "availability" => "reduced_capacity",
               "capacity_fraction" => 0.5
             }
           ] = get_in(manifest.study.metadata, ["candidate_refresh", "ground_network"])
  end

  test "rejects invalid candidate refresh ground-network entries" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "ground_network"], [
        %{"id" => "missing_station", "availability" => "maintenance"}
      ])

    assert {:error, {:missing_field, "ground_station_id"}} = Manifest.from_map(source)

    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "ground_network"], [
        %{
          "station_id" => "equator_prime",
          "availability" => 1.5
        }
      ])

    assert {:error, {:invalid_field, "availability"}} = Manifest.from_map(source)
  end

  test "passes candidate refresh limit policy through manifest metadata and artifacts" do
    source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh", "candidate_limit_policy"], %{
        "max_candidate_activities" => 1
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert get_in(manifest.study.metadata, ["candidate_refresh", "candidate_limit_policy"]) == %{
             "max_candidate_activities" => 1
           }

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z])

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "max_candidate_activities" => 1,
             "kept_candidate_count" => 1
           } = artifact.candidate_refresh["refresh_budget_report"]
  end

  test "runs candidate refresh manifests from simple orbit-data state estimates" do
    manifest_source =
      candidate_refresh_manifest()
      |> put_in(["candidate_refresh"], candidate_refresh_orbit_data_request())

    assert {:ok, manifest} = Manifest.from_map(manifest_source)

    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "leo_1"
    assert scenario.spacecraft.id == "sat_1"

    accepted_state =
      get_in(manifest.study.metadata, ["candidate_refresh", "accepted_planning_state"])

    assert accepted_state["snapshot_id"] == "ops-orbit-data-1"

    assert get_in(accepted_state, ["spacecraft_states", Access.at(0), "source", "system"]) ==
             "simple_json"

    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)
    artifact = Artifact.build(result_set, generated_at: ~U[2026-05-14 00:00:00Z])

    assert artifact.candidate_refresh["snapshot_id"] == "ops-orbit-data-1"

    assert Enum.any?(
             artifact.candidate_refresh["candidate_activities"],
             &(&1["type"] == "downlink")
           )
  end

  test "builds candidate refresh manifests from CCSDS OEM orbit-data wrappers" do
    manifest_source =
      candidate_refresh_manifest()
      |> put_in(
        ["candidate_refresh"],
        candidate_refresh_orbit_data_request()
        |> put_in(
          ["orbit_data"],
          %{
            "format" => "ccsds_oem_kvn",
            "content" => oem_kvn(),
            "sample" => "last",
            "snapshot_id" => "ops-oem-1",
            "quality" => %{"level" => "planning_accepted"},
            "provenance" => %{"created_by" => "manifest_test"}
          }
        )
        |> put_in(["model_assumptions", "accepted_state_adapter"], "orbit_data.ccsds_oem_kvn")
      )

    assert {:ok, manifest} = Manifest.from_map(manifest_source)

    assert [scenario] = manifest.study.scenarios
    assert scenario.id == "1998-067A"
    assert scenario.spacecraft.id == "1998-067A"

    accepted_state =
      get_in(manifest.study.metadata, ["candidate_refresh", "accepted_planning_state"])

    assert accepted_state["snapshot_id"] == "ops-oem-1"
    assert accepted_state["quality"] == %{"level" => "planning_accepted"}
    assert accepted_state["provenance"]["sample_index"] == 1

    assert get_in(accepted_state, [
             "spacecraft_states",
             Access.at(0),
             "metadata",
             "input_format"
           ]) == "ccsds_oem_kvn"
  end

  test "builds search scenarios from an impulsive burn grid" do
    assert {:ok, manifest} = Manifest.from_map(search_manifest())

    assert Enum.map(manifest.study.scenarios, & &1.id) == [
             "raise_apogee_1_1",
             "raise_apogee_1_2",
             "raise_apogee_2_1",
             "raise_apogee_2_2"
           ]

    assert [first | _] = manifest.study.scenarios
    assert [burn] = first.maneuvers
    assert burn.epoch.seconds_since_j2000 == 55.0
    assert burn.delta_v_km_s == {0.0, 0.005, 0.0}
    assert manifest.study.metadata["search"]["objective"] == "final_radius_km"
    assert manifest.study.metadata["search"]["objective_direction"] == "maximize"
    assert manifest.study.metadata["search"]["rank_limit"] == 3

    assert [
             %{
               "id" => "delta_v_budget",
               "metric" => "total_delta_v_km_s",
               "operator" => "<=",
               "value" => 0.008
             }
           ] = manifest.study.metadata["constraints"]
  end

  test "builds monte carlo scenarios from state vector dispersion" do
    assert {:ok, manifest} = Manifest.from_map(monte_carlo_manifest())
    assert {:ok, repeated_manifest} = Manifest.from_map(monte_carlo_manifest())

    assert Enum.map(manifest.study.scenarios, & &1.id) == [
             "dispersion_1",
             "dispersion_2",
             "dispersion_3"
           ]

    assert Enum.map(manifest.study.scenarios, & &1.initial_state) ==
             Enum.map(repeated_manifest.study.scenarios, & &1.initial_state)

    assert [first | _] = manifest.study.scenarios
    assert first.initial_state.position_km != {7000.0, 0.0, 0.0}
    assert first.maneuvers == []

    assert manifest.study.metadata["monte_carlo"] == %{
             "generator" => "state_vector_dispersion",
             "id_prefix" => "dispersion",
             "count" => 3,
             "seed" => 12_345,
             "position_sigma_km" => [0.1, 0.1, 0.05],
             "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
             "objective" => "final_radius_km",
             "objective_direction" => "maximize",
             "rank_limit" => 2
           }
  end

  test "parses batch-capable propagator backends" do
    source = Map.put(monte_carlo_manifest(), "propagator", "two_body_nx_compiled")

    assert {:ok, manifest} = Manifest.from_map(source)
    assert manifest.study.propagator == TwoBodyNxCompiled
  end

  test "parses adaptive two-body propagator options" do
    source =
      circular_leo_manifest()
      |> put_in(["propagator_opts"], %{
        "integration" => "adaptive_step",
        "max_step_s" => 120.0,
        "min_step_s" => 1.0,
        "adaptive_position_tolerance_km" => 1.0e-3,
        "adaptive_velocity_tolerance_km_s" => 1.0e-6
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert Map.new(manifest.study.propagator_opts) == %{
             integration: "adaptive_step",
             max_step_s: 120.0,
             min_step_s: 1.0,
             adaptive_position_tolerance_km: 1.0e-3,
             adaptive_velocity_tolerance_km_s: 1.0e-6
           }
  end

  test "runs manifest-backed adaptive two-body propagation" do
    source =
      circular_leo_manifest()
      |> Map.put("propagator", "two_body")
      |> Map.put("outputs", ["trajectories"])
      |> put_in(["propagator_opts"], %{
        "integration" => "adaptive_step",
        "max_step_s" => 120.0,
        "min_step_s" => 1.0,
        "adaptive_position_tolerance_km" => 1.0e-3,
        "adaptive_velocity_tolerance_km_s" => 1.0e-6
      })

    assert {:ok, manifest} = Manifest.from_map(source)
    assert {:ok, result_set} = OrbitalDynamics.run_study(manifest.study, manifest.run_opts)

    assert [
             %{
               trajectory: %{
                 assumptions: %{
                   numerical_method: :rk4_adaptive_step_doubling,
                   integration_mode: :adaptive_step,
                   adaptive_error_estimate: :step_doubling
                 }
               }
             }
             | _
           ] = result_set.trajectory_results
  end

  test "rejects unsupported manifest fields clearly" do
    bad_manifest = Map.put(circular_leo_manifest(), "propagator", "cowell")

    assert {:error, {:unsupported_propagator, "cowell"}} = Manifest.from_map(bad_manifest)

    bad_options =
      circular_leo_manifest()
      |> put_in(["propagator_opts"], %{"step" => 10.0})

    assert {:error, {:unsupported_option, "propagator_opts", "step"}} =
             Manifest.from_map(bad_options)
  end

  test "loads a manifest from JSON" do
    json = :json.encode(circular_leo_manifest()) |> IO.iodata_to_binary()

    assert {:ok, manifest} = Manifest.from_json(json)
    assert manifest.study.id == "leo_manifest"
  end

  test "parses distributed task supervisor nodes from run options" do
    source =
      circular_leo_manifest()
      |> put_in(["run_options"], %{
        "task_supervisor_nodes" => ["local", "worker@127.0.0.1"],
        "task_chunk_size" => 100
      })

    assert {:ok, manifest} = Manifest.from_map(source)

    assert Keyword.fetch!(manifest.run_opts, :task_supervisors) == [
             OrbitalDynamics.ScenarioSupervisor,
             {OrbitalDynamics.ScenarioSupervisor, :"worker@127.0.0.1"}
           ]

    assert Keyword.fetch!(manifest.run_opts, :task_chunk_size) == 100
  end

  defp circular_leo_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "leo_manifest",
      "central_body" => "earth",
      "propagator" => "j2",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories", "access_windows", "eclipses"],
      "sun_direction" => [1.0, 0.0, 0.0],
      "metadata" => %{"description" => "manifest test"},
      "scenarios" => [
        %{
          "generator" => "circular_leo",
          "count" => 2,
          "duration_s" => 3600.0,
          "output_step_s" => 60.0,
          "id_prefix" => "manifest_leo"
        }
      ],
      "ground_stations" => [
        %{
          "id" => "equator_prime",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 5.0
        },
        %{
          "id" => "equator_90e",
          "latitude_deg" => 0.0,
          "longitude_deg" => 90.0,
          "minimum_elevation_deg" => 5.0
        }
      ]
    }
  end

  defp candidate_refresh_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "candidate_refresh_demo",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories", "access_windows", "eclipses", "target_visibility"],
      "ground_stations" => [
        %{
          "id" => "equator_prime",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 5.0
        }
      ],
      "sun_direction" => [1.0, 0.0, 0.0],
      "candidate_refresh" => %{
        "accepted_planning_state" => %{
          "schema_version" => 1,
          "artifact_type" => "accepted_planning_state",
          "snapshot_id" => "ops-state-1",
          "accepted_at" => "2026-05-14T00:00:00Z",
          "spacecraft_states" => [
            %{
              "spacecraft_id" => "sat_1",
              "scenario_id" => "leo_1",
              "dry_mass_kg" => 250.0,
              "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
              "frame" => "earth_inertial_j2000",
              "state_vector" => %{
                "position_km" => [7000.0, 0.0, 0.0],
                "velocity_km_s" => [0.0, 7.546053290107542, 0.0]
              },
              "source" => %{"system" => "operator_import", "source_id" => "estimate-1"},
              "quality" => %{"level" => "accepted"},
              "provenance" => %{"trust_boundary" => "operator_supplied"}
            }
          ],
          "maneuver_execution_deltas" => [],
          "source" => %{"system" => "cadence_snapshot", "source_id" => "snapshot-1"},
          "quality" => %{"level" => "planning_accepted"},
          "provenance" => %{
            "created_by" => "manifest_test",
            "trust_boundary" => "operator_supplied"
          }
        },
        "current_epoch_s" => 0.0,
        "remaining_horizon" => %{
          "starts_at_s" => 0.0,
          "ends_at_s" => 600.0,
          "output_step_s" => 60.0
        },
        "targets" => [
          %{
            "id" => "target_a",
            "latitude_deg" => 0.0,
            "longitude_deg" => 0.0,
            "minimum_elevation_deg" => 10.0,
            "priority" => 2.0
          }
        ],
        "constraints" => %{"avoid_eclipse" => false, "min_activity_duration_s" => 60.0},
        "scoring_policy" => %{"contact_value_weight" => 0.2, "downlink_rate_mb_s" => 2.0},
        "operational_feedback" => %{
          "contact_success_rate" => %{"equator_prime" => 0.8}
        },
        "freshness_policy" => %{"allowed_state_quality_levels" => ["planning_accepted"]},
        "resource_filter_policy" => %{
          "min_observe_storage_margin" => 0.2,
          "min_downlink_margin" => 0.2
        },
        "model_assumptions" => %{"candidate_refresh_level" => "sampled_v1"},
        "ground_network" => [
          %{
            "ground_station_id" => "equator_prime",
            "status" => "available",
            "capacity_fraction" => 1.0
          }
        ],
        "resource_summaries" => [
          %{
            "spacecraft_id" => "sat_1",
            "fuel_margin" => 0.8,
            "power_margin" => 0.7,
            "storage_capacity_mb" => 1000.0,
            "storage_used_mb" => 250.0,
            "downlink_margin" => 0.6
          }
        ],
        "prior_candidate_activities" => [
          %{
            "id" => "old_candidate",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 900.0,
            "ends_at_s" => 960.0
          }
        ]
      }
    }
  end

  defp candidate_refresh_orbit_data_request do
    %{
      "orbit_data" => %{
        "snapshot_id" => "ops-orbit-data-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "source" => %{"system" => "simple_json", "source_id" => "orbit-data-batch-1"},
        "quality" => %{"level" => "planning_accepted"},
        "provenance" => %{"created_by" => "manifest_test"},
        "state_estimates" => [
          %{
            "spacecraft_id" => "sat_1",
            "scenario_id" => "leo_1",
            "dry_mass_kg" => 250.0,
            "seconds_since_j2000" => 0.0,
            "time_scale" => "tdb",
            "frame" => "earth_inertial_j2000",
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.546053290107542, 0.0],
            "source" => %{"system" => "simple_json", "source_id" => "estimate-1"},
            "quality" => %{"level" => "accepted"}
          }
        ]
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [
        %{
          "id" => "target_a",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 10.0,
          "priority" => 2.0
        }
      ],
      "constraints" => %{"avoid_eclipse" => false, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{"contact_value_weight" => 0.2, "downlink_rate_mb_s" => 2.0},
      "model_assumptions" => %{
        "candidate_refresh_level" => "sampled_v1",
        "accepted_state_adapter" => "orbit_data.simple_json"
      },
      "ground_network" => [
        %{
          "ground_station_id" => "equator_prime",
          "status" => "available",
          "capacity_fraction" => 1.0
        }
      ],
      "resource_summaries" => [],
      "prior_candidate_activities" => []
    }
  end

  defp oem_kvn do
    """
    CCSDS_OEM_VERS = 2.0
    CREATION_DATE = 2026-05-14T00:00:00Z
    ORIGINATOR = OrbitalDynamicsTest
    META_START
    OBJECT_NAME = ISS
    OBJECT_ID = 1998-067A
    CENTER_NAME = EARTH
    REF_FRAME = EME2000
    TIME_SYSTEM = UTC
    INTERPOLATION = LAGRANGE
    INTERPOLATION_DEGREE = 1
    META_STOP
    2000-01-01T12:02:00.000 7000 0 0 0 7.5 0
    2000-01-01T12:03:00.000 6990 450 0 -0.5 7.49 0
    """
  end

  defp explicit_scenario_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "explicit_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "scenarios" => [
        %{
          "id" => "explicit_leo_1",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "duration_s" => 120.0,
          "output_step_s" => 60.0,
          "maneuvers" => [
            %{
              "id" => "raise_apogee",
              "epoch" => %{
                "seconds_since_j2000" => 60.0,
                "scale" => "tdb"
              },
              "delta_v_km_s" => [0.0, 0.01, 0.0],
              "frame" => "earth_inertial_j2000"
            }
          ]
        }
      ]
    }
  end

  defp mission_plan_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "mission_plan_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "mission_plans" => [
        %{
          "id" => "ops_plan",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "horizon_s" => 180.0,
          "output_step_s" => 60.0,
          "metadata" => %{"objective" => "checkout"},
          "activities" => [
            %{
              "id" => "initial_coast",
              "type" => "coast",
              "start_s" => 0.0,
              "end_s" => 50.0
            },
            %{
              "id" => "raise_apogee",
              "type" => "impulsive_burn",
              "epoch_s" => 60.0,
              "delta_v_km_s" => [0.0, 0.01, 0.0]
            },
            %{
              "id" => "observe_target",
              "type" => "observe",
              "start_s" => 90.0,
              "end_s" => 120.0,
              "timeline_id" => "timeline:observe_target",
              "target_id" => "target_a",
              "pointing_mode" => "target_track",
              "pointing_target_id" => "target_a",
              "boresight_axis" => "+Z",
              "off_nadir_angle_deg" => 12.5,
              "slew_angle_deg" => 4.0,
              "slew_rate_deg_s" => 0.2,
              "pointing_error_deg" => 0.05,
              "pointing_status" => "declared",
              "pointing_model" => "operator_supplied",
              "pointing_source" => "mission_database",
              "pointing_confidence" => 0.9,
              "attitude_mode" => "target_track",
              "attitude_target_id" => "target_a",
              "roll_deg" => 1.0,
              "pitch_deg" => -0.5,
              "yaw_deg" => 2.0,
              "attitude_error_deg" => 0.05,
              "attitude_status" => "declared",
              "attitude_model" => "operator_supplied",
              "attitude_source" => "mission_database",
              "attitude_confidence" => 0.9,
              "thermal_zone_id" => "payload_bus",
              "temperature_c" => 18.5,
              "planned_temperature_c" => 19.0,
              "actual_temperature_c" => 21.0,
              "min_operating_temperature_c" => -5.0,
              "max_operating_temperature_c" => 40.0,
              "thermal_margin_c" => 19.0,
              "thermal_status" => "nominal",
              "thermal_model" => "operator_supplied",
              "thermal_source" => "mission_database",
              "thermal_confidence" => 0.8,
              "image_quality_score" => 0.84,
              "image_quality_status" => "usable",
              "image_quality_source" => "provider_observation_review",
              "cloud_cover_fraction" => 0.18,
              "blur_score" => 0.06,
              "metadata" => %{"mode" => "nadir"}
            },
            %{
              "id" => "target_hold",
              "type" => "attitude",
              "start_s" => 121.0,
              "end_s" => 129.0,
              "pointing_mode" => "target_track",
              "pointing_target_id" => "target_a",
              "pointing_error_deg" => 0.08,
              "pointing_status" => "declared",
              "pointing_model" => "operator_supplied",
              "pointing_source" => "mission_database",
              "pointing_confidence" => 0.85
            },
            %{
              "id" => "downlink_pass",
              "type" => "downlink",
              "start_s" => 130.0,
              "end_s" => 160.0,
              "ground_station_id" => "dss_14",
              "status" => "approved",
              "approval_status" => "approved",
              "locked" => true,
              "timeline_id" => "timeline:downlink_pass",
              "resource_id" => "payload_bus",
              "resource_source_quality" => "declared",
              "resource_trust_boundary" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "resource_provenance" => %{"source" => "mission_database"},
              "resource_blocking_dimension" => "power",
              "fuel_margin" => 0.72,
              "power_margin" => 0.35,
              "storage_margin" => 0.42,
              "downlink_margin" => 0.51,
              "battery_capacity_wh" => 240.0,
              "battery_energy_used_wh" => 88.0,
              "battery_energy_generated_wh" => 45.0,
              "battery_state_of_charge" => 0.68,
              "spacecraft_available" => true,
              "payload_available" => false,
              "antenna_available" => true,
              "degraded" => true,
              "mode" => "payload_safe",
              "incompatible_activity_types" => ["observe"],
              "suppressed_activity_types" => ["downlink"],
              "collection_id" => "collection_alpha",
              "product_id" => "image_alpha_1",
              "product_ids" => ["image_alpha_1", "image_alpha_2"],
              "payload_id" => "camera_a",
              "instrument_id" => "wide_field",
              "data_volume_mb" => 120.0,
              "planned_data_volume_mb" => 120.0,
              "actual_data_volume_mb" => 90.0,
              "estimated_data_volume_mb" => 120.0,
              "estimated_storage_mb" => 120.0,
              "estimated_downlink_mb" => 118.0,
              "required_downlink_mb" => 100.0,
              "collection_ends_at_s" => 360.0,
              "planned_delivery_at_s" => 540.0,
              "actual_delivery_at_s" => 550.0,
              "max_latency_s" => 240.0,
              "planned_latency_s" => 180.0,
              "actual_latency_s" => 190.0,
              "planned_estimated_throughput_mb" => 118.0,
              "actual_throughput_mb" => 96.0,
              "link_protocol" => "space_packet",
              "frequency_band" => "x_band",
              "modulation" => "qpsk",
              "coding_scheme" => "ldpc",
              "polarization" => "rhcp",
              "data_rate_mbps" => 8.0,
              "downlink_rate_mbps" => 7.5,
              "data_rate_mb_s" => 1.0,
              "downlink_rate_mb_s" => 0.9375,
              "actual_data_rate_mbps" => 6.0,
              "actual_downlink_rate_mbps" => 5.5,
              "actual_data_rate_mb_s" => 0.75,
              "actual_downlink_rate_mb_s" => 0.6875,
              "delivered_rate_mbps" => 5.0,
              "received_rate_mbps" => 4.5,
              "delivered_rate_mb_s" => 0.625,
              "received_rate_mb_s" => 0.5625,
              "actual_duration_s" => 28.0,
              "actual_contact_duration_s" => 27.0,
              "contact_duration_s" => 30.0,
              "link_margin_db" => 3.5,
              "snr_db" => 12.0,
              "eb_no_db" => 9.0,
              "bit_error_rate" => 1.0e-6,
              "packet_loss_rate" => 0.01,
              "frame_loss_rate" => 0.02,
              "carrier_lock" => true,
              "symbol_lock" => true,
              "link_quality_status" => "nominal",
              "dependencies" => ["observe_target"],
              "dependency_activity_ids" => ["observe_target"],
              "dependency_timeline_ids" => ["timeline:observe_target"],
              "exclusive_with_activity_ids" => ["cmd_window"],
              "exclusive_with_timeline_ids" => ["timeline:cmd_window"],
              "exclusivity_group" => "ground_station",
              "source_window_id" => "window:leo_1:ground_station_access:dss_14:1",
              "source_window_type" => "ground_station_access",
              "source_window" => %{
                "id" => "window:leo_1:ground_station_access:dss_14:1",
                "type" => "ground_station_access",
                "provider" => "candidate_refresh.v1"
              },
              "cadence_import" => %{
                "external_id" => "cadence:contact:downlink_pass",
                "activity_type" => "contact",
                "schema_contract" => "cadence_import_manifest.v1"
              },
              "provenance" => %{"source" => "operator_approval"}
            },
            %{
              "id" => "cmd_window",
              "type" => "command",
              "start_s" => 161.0,
              "end_s" => 165.0,
              "timeline_id" => "timeline:cmd_window",
              "ground_station_id" => "dss_14",
              "status" => "completed",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "track_pass",
              "type" => "tracking",
              "start_s" => 166.0,
              "end_s" => 170.0,
              "ground_station_id" => "dss_14"
            },
            %{
              "id" => "health_poll",
              "type" => "health_check",
              "start_s" => 171.0,
              "end_s" => 174.0
            },
            %{
              "id" => "uplink_pass",
              "type" => "planned_contact",
              "start_s" => 175.0,
              "end_s" => 179.0,
              "ground_station_id" => "dss_14",
              "direction" => "uplink"
            }
          ]
        }
      ]
    }
  end

  defp campaign_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "campaign_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories", "access_windows", "eclipses", "target_visibility"],
      "sun_direction" => [1.0, 0.0, 0.0],
      "campaign" => %{
        "planning_horizon" => %{
          "duration_s" => 120.0,
          "output_step_s" => 60.0
        },
        "spacecraft" => [
          %{
            "id" => "leo_1",
            "dry_mass_kg" => 250.0,
            "initial_state" => %{
              "position_km" => [7000.0, 0.0, 0.0],
              "velocity_km_s" => [0.0, 7.5, 0.0],
              "epoch" => %{"seconds_since_j2000" => 0.0, "scale" => "tdb"},
              "frame" => "earth_inertial_j2000"
            }
          },
          %{
            "id" => "leo_2",
            "dry_mass_kg" => 260.0,
            "initial_state" => %{
              "position_km" => [0.0, 7000.0, 0.0],
              "velocity_km_s" => [-7.5, 0.0, 0.0],
              "epoch" => %{"seconds_since_j2000" => 0.0, "scale" => "tdb"},
              "frame" => "earth_inertial_j2000"
            }
          }
        ],
        "targets" => [
          %{
            "id" => "target_a",
            "latitude_deg" => 0.0,
            "longitude_deg" => 0.0,
            "minimum_elevation_deg" => -90.0,
            "priority" => 0.1
          },
          %{
            "id" => "target_b",
            "latitude_deg" => 10.0,
            "longitude_deg" => 20.0,
            "minimum_elevation_deg" => -90.0,
            "priority" => 0.1
          }
        ],
        "constraints" => %{
          "min_activity_duration_s" => 1.0,
          "avoid_eclipse" => false,
          "max_timeline_activities" => 3
        },
        "scoring_policy" => %{
          "target_value_weight" => 0.01,
          "contact_value_weight" => 2.0,
          "eclipse_penalty_weight" => 0.0,
          "activity_count_penalty" => 0.0,
          "rank_limit" => 2
        },
        "ground_network" => [
          %{
            "id" => "equator_maintenance",
            "ground_station_id" => "equator_prime",
            "status" => "maintenance",
            "starts_at_s" => 0.0,
            "ends_at_s" => 120.0
          }
        ],
        "resource_summaries" => [
          %{
            "spacecraft_id" => "leo_1",
            "storage_capacity_mb" => 100.0,
            "storage_used_mb" => 20.0,
            "downlink_capacity_mb" => 500.0
          }
        ]
      },
      "ground_stations" => [
        %{
          "id" => "equator_prime",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => -90.0
        }
      ]
    }
  end

  defp search_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "search_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "constraints" => [
        %{
          "id" => "delta_v_budget",
          "metric" => "total_delta_v_km_s",
          "operator" => "<=",
          "value" => 0.008
        }
      ],
      "search" => %{
        "generator" => "impulsive_burn_grid",
        "id_prefix" => "raise_apogee",
        "objective" => "final_radius_km",
        "rank_limit" => 3,
        "burn_epoch_s" => [55.0, 60.0],
        "delta_v_km_s" => [[0.0, 0.005, 0.0], [0.0, 0.01, 0.0]],
        "base_scenario" => %{
          "id" => "base",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "duration_s" => 120.0,
          "output_step_s" => 60.0
        }
      }
    }
  end

  defp monte_carlo_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "monte_carlo_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "monte_carlo" => %{
        "generator" => "state_vector_dispersion",
        "id_prefix" => "dispersion",
        "seed" => 12_345,
        "count" => 3,
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
        "objective" => "final_radius_km",
        "rank_limit" => 2,
        "base_scenario" => %{
          "id" => "base",
          "spacecraft" => %{
            "id" => "sat_1",
            "dry_mass_kg" => 250.0
          },
          "initial_state" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0],
            "epoch" => %{
              "seconds_since_j2000" => 0.0,
              "scale" => "tdb"
            },
            "frame" => "earth_inertial_j2000"
          },
          "duration_s" => 120.0,
          "output_step_s" => 60.0
        }
      }
    }
  end
end
