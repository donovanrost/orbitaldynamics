defmodule OrbitalDynamics.TimelineFeedbackTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.{Schema, Timeline, TimelineFeedback}

  test "declares feedback reconciliation capabilities" do
    assert %{
             artifact_contract: "timeline_feedback_report.v1",
             activity_state_artifact_contract: "timeline_activity_state.v1",
             validation_level: :artifact_contract,
             report_statuses: report_statuses,
             feedback_kinds: feedback_kinds,
             match_strategies: match_strategies,
             cadence_import_statuses: cadence_import_statuses,
             planned_protection_decisions: planned_protection_decisions,
             supported_realized_statuses: statuses,
             realized_completion_statuses: realized_completion_statuses,
             realized_failure_statuses: realized_failure_statuses,
             realized_feedback_match_statuses: realized_feedback_match_statuses,
             lifecycle_event_realized_statuses: lifecycle_event_realized_statuses,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             command_contact_directions: command_contact_directions,
             provider_result_map_value_keys: provider_result_map_value_keys,
             feedback_helpers: feedback_helpers,
             public_facades: public_facades,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = TimelineFeedback.capabilities()

    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths

    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths

    assert source_station_capacity_fraction_paths == station_capacity_fraction_paths
    assert source_station_capacity_percent_paths == station_capacity_percent_paths
    assert source_station_capacity_value_paths == station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "capacity_fraction"]} in source_station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_model", "station_capacity_percent"]} in source_station_capacity_value_paths

    assert command_contact_directions == ["command", "uplink"]

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert :reconcile in feedback_helpers
    assert :operational_feedback in feedback_helpers
    assert :activity_state in feedback_helpers
    assert :normalize_realized_activity in feedback_helpers
    assert :normalize_realized_activities in feedback_helpers
    assert :reconcile_timeline_feedback in public_facades
    assert :timeline_operational_feedback in public_facades
    assert :timeline_activity_state in public_facades
    assert :normalize_realized_timeline_activity in public_facades
    assert :normalize_realized_timeline_activities in public_facades

    assert report_statuses == ["matched", "planned_only", "realized_only"]
    assert "command" in feedback_kinds
    assert "contact" in feedback_kinds
    assert "observation" in feedback_kinds
    assert "maneuver" in feedback_kinds

    assert match_strategies == [
             "activity_id",
             "ambiguous_timeline_id",
             "planned_activity_id",
             "timeline_id",
             "unmatched_planned",
             "unmatched_realized"
           ]

    assert cadence_import_statuses == ["invalid", "missing", "not_applicable", "present"]
    assert planned_protection_decisions == ["mutable", "preserve", "review_change"]

    assert "completed" in statuses
    assert "executed" in statuses
    assert "partial" in statuses
    assert "cancelled" in statuses
    assert "rejected" in statuses

    assert realized_completion_statuses == ["completed", "executed"]
    assert realized_failure_statuses == ["missed", "failed", "canceled", "cancelled", "rejected"]
    assert realized_feedback_match_statuses == ["matched"]

    assert lifecycle_event_realized_statuses == %{
             "approve" => "approved",
             "reject" => "rejected",
             "lock" => "locked",
             "start_execution" => "executing",
             "record_execution" => "executed",
             "record_completion" => "completed",
             "record_partial" => "partial",
             "record_failure" => "failed",
             "record_miss" => "missed",
             "delay" => "delayed",
             "cancel" => "canceled"
           }

    assert :match_strategy in row_semantics
    assert :report_status in row_semantics
    assert :report_status_counts in row_semantics
    assert :feedback_kind_counts in row_semantics
    assert :match_strategy_counts in row_semantics
    assert :activity_state in row_semantics
    assert :activity_state_count_maps in row_semantics
    assert :normalized_realized_activity in row_semantics
    assert :normalized_realized_activity_list in row_semantics
    assert :duplicate_realized_match_count in row_semantics
    assert :duplicate_realized_feedback_count in row_semantics
    assert :ambiguous_timeline_match_count in row_semantics
    assert :ambiguous_timeline_feedback_count in row_semantics
    assert :command_contact_directions in row_semantics
    assert :cadence_import_identity in row_semantics
    assert :realized_provider_provenance in row_semantics
    assert :realized_source_quality in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :data_volume_delta_mb in row_semantics
    assert :downlink_demand_mb in row_semantics
    assert :resource_margin_overrides in row_semantics
    assert :resource_availability_overrides in row_semantics
    assert :feedback_status in row_semantics
    assert :execution_uncertainty_declared_count in row_semantics
    assert :execution_uncertainty_missing_count in row_semantics
    assert :realized_completion_statuses in row_semantics
    assert :realized_failure_statuses in row_semantics
    assert :realized_feedback_match_statuses in row_semantics
    assert :lifecycle_event_status_derivation in row_semantics
    assert :feedback_weight in row_semantics
    assert :product_identity in row_semantics
    assert :observation_quality_context in row_semantics
    assert :thermal_context in row_semantics
    assert :lighting_context in row_semantics
    assert :maneuver_success_factor in row_semantics
    assert :timeline_protection_evidence in row_semantics
    assert :timeline_integrity_review in row_semantics
    assert :normalized_provider_feedback_scalars in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :actual_data_rate_throughput_derivation in row_semantics
    assert :cadence_import_status in row_semantics
    assert :cadence_import_status_counts in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :derived_operational_feedback in row_semantics
    assert :operational_feedback_provenance in row_semantics
    assert :operational_feedback_source_counts in row_semantics
    assert :operational_feedback_input_keys in row_semantics
    assert :operational_feedback_realized_activity_count in row_semantics
    assert :operational_feedback_trust_boundary_status in row_semantics
    assert :operational_feedback_source_quality_counts in row_semantics
    assert :operational_feedback_exclusion in row_semantics
    assert :operational_feedback_excluded_count in row_semantics
    assert :invalid_activity_input_review in row_semantics
    assert :invalid_realized_feedback_unit_interval_review in row_semantics
    assert :planned_protection_decision in row_semantics
    assert :planned_protection_decision_counts in row_semantics
    assert :no_schedule_mutation in known_limits
    assert :no_command_execution in known_limits

    assert {:ok, feedback_schema} = Schema.json_schema("timeline_feedback_report.v1")

    row_properties = get_in(feedback_schema, ["properties", "rows", "items", "properties"])

    assert Enum.sort(row_properties["realized_status"]["enum"]) ==
             Enum.sort(["invalid" | statuses])

    assert get_in(row_properties, ["battery_capacity_wh", "type"]) == "number"
    assert get_in(row_properties, ["battery_energy_used_wh", "type"]) == "number"
    assert get_in(row_properties, ["battery_energy_generated_wh", "minimum"]) == 0.0
    assert get_in(row_properties, ["battery_state_of_charge", "type"]) == "number"
    assert get_in(row_properties, ["thermal_margin_c", "type"]) == "number"
    assert get_in(row_properties, ["eclipse_overlap_fraction", "type"]) == "number"
    assert get_in(row_properties, ["planned_eclipse_overlap_fraction", "type"]) == "number"
    assert get_in(row_properties, ["realized_eclipse_overlap_fraction", "type"]) == "number"
    assert get_in(row_properties, ["eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_properties, ["planned_eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_properties, ["realized_eclipse_overlap_s", "type"]) == "number"
    assert get_in(row_properties, ["lighting_condition", "type"]) == "string"
    assert get_in(row_properties, ["planned_lighting_condition", "type"]) == "string"
    assert get_in(row_properties, ["realized_lighting_condition", "type"]) == "string"
    assert get_in(row_properties, ["lighting_condition_match_status", "type"]) == "string"
    assert get_in(row_properties, ["lighting_condition_detail", "type"]) == "string"
    assert get_in(row_properties, ["lighting_condition_model", "type"]) == "string"
    assert get_in(row_properties, ["lighting_detail_model", "type"]) == "string"
    assert get_in(row_properties, ["lighting_confidence", "type"]) == ["number", "string"]

    assert get_in(row_properties, ["station_calendar_provider_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, ["station_calendar_provider_entry_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, ["source_activity_context", "type"]) == "object"
    assert get_in(row_properties, ["realized_activity_context", "type"]) == "object"

    assert get_in(row_properties, [
             "source_activity_context",
             "properties",
             "timeline_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_properties, [
             "realized_activity_context",
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(row_properties, [
             "realized_activity_context",
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(row_properties, [
             "realized_activity_context",
             "properties",
             "delta_v_km_s",
             "items",
             "type"
           ]) == "number"

    assert Enum.sort(get_in(row_properties, ["realized_statuses", "items", "enum"])) ==
             Enum.sort(["invalid" | statuses])

    assert {:ok, realized_schema} = Schema.json_schema("realized_activity.v1")

    assert Enum.sort(get_in(realized_schema, ["properties", "status", "enum"])) ==
             Enum.sort(statuses)

    assert Enum.sort(get_in(realized_schema, ["properties", "realized_status", "enum"])) ==
             Enum.sort(statuses)

    assert get_in(realized_schema, ["properties", "feedback_status", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "source_quality", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "quality", "type"]) == "string"
    stable_pattern = Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_schema, ["properties", "external_id", "pattern"]) == stable_pattern
    assert get_in(realized_schema, ["properties", "trust_boundary", "type"]) == "string"

    assert [
             %{
               "if" => %{"anyOf" => provider_context},
               "then" => %{"required" => ["external_id"], "anyOf" => trust_boundary_options}
             }
           ] = realized_schema["allOf"]

    assert %{"required" => ["provider"]} in provider_context
    assert %{"required" => ["adapter"]} in provider_context
    assert %{"required" => ["adapter_version"]} in provider_context
    assert %{"required" => ["external_id"]} in provider_context
    assert %{"required" => ["trust_boundary"]} in trust_boundary_options

    assert get_in(realized_schema, ["properties", "target", "properties", "id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "resource_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "battery_state_of_charge", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "payload_available", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "antenna_available", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "degraded", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "mode", "type"]) == "string"

    assert get_in(realized_schema, [
             "properties",
             "incompatible_activity_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(realized_schema, ["properties", "collection_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "product_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "product_ids", "items", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "payload_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "instrument_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "actual_data_volume_mb", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "estimated_downlink_mb", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "required_downlink_mb", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "actual_latency_s", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "target_priority", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "contact_result", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "contact_success_factor", "type"]) == "number"

    assert get_in(realized_schema, ["properties", "command_success_factor_source", "type"]) ==
             "string"

    assert get_in(realized_schema, ["properties", "observation_success", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "observation_result", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "maneuver_success", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "maneuver_success_factor", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "feedback_weight", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "delta_v_km_s", "minItems"]) == 3
    assert get_in(realized_schema, ["properties", "actual_delta_v_km_s", "maxItems"]) == 3
    assert get_in(realized_schema, ["properties", "execution_uncertainty", "type"]) == "object"
    assert get_in(realized_schema, ["properties", "timing_3sigma_s", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "delta_v_3sigma_km_s", "minItems"]) == 3

    assert get_in(
             realized_schema,
             ["properties", "station", "properties", "station_id", "pattern"]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             realized_schema,
             ["properties", "ground_station", "properties", "ground_station_id", "pattern"]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             realized_schema,
             ["properties", "spacecraft", "properties", "spacecraft_id", "pattern"]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(
             realized_schema,
             ["properties", "satellite", "properties", "satellite_id", "pattern"]
           ) == "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "attitude_target_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "pointing_target_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "pointing_mode", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "boresight_axis", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "off_nadir_angle_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "slew_angle_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "slew_rate_deg_s", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "pointing_error_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "pointing_status", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "pointing_model", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "pointing_source", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "pointing_confidence", "type"]) == "number"

    assert get_in(realized_schema, ["properties", "attitude_mode", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "roll_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "pitch_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "yaw_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "attitude_error_deg", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "attitude_status", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "attitude_model", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "attitude_source", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "attitude_confidence", "type"]) == "number"

    assert get_in(realized_schema, ["properties", "thermal_zone_id", "pattern"]) ==
             "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"

    assert get_in(realized_schema, ["properties", "temperature_c", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "planned_temperature_c", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "actual_temperature_c", "type"]) == "number"

    assert get_in(realized_schema, ["properties", "min_operating_temperature_c", "type"]) ==
             "number"

    assert get_in(realized_schema, ["properties", "max_operating_temperature_c", "type"]) ==
             "number"

    assert get_in(realized_schema, ["properties", "thermal_margin_c", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "thermal_status", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "thermal_model", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "thermal_source", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "thermal_confidence", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "eclipse_overlap_fraction", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "eclipse_overlap_s", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "lighting_condition", "type"]) == "string"

    assert get_in(realized_schema, ["properties", "lighting_condition_detail", "type"]) ==
             "string"

    assert get_in(realized_schema, ["properties", "lighting_condition_model", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "lighting_detail_model", "type"]) == "string"

    assert get_in(realized_schema, ["properties", "lighting_confidence", "type"]) == [
             "number",
             "string"
           ]

    assert get_in(realized_schema, ["properties", "link_protocol", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "frequency_band", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "modulation", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "coding_scheme", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "polarization", "type"]) == "string"
    assert get_in(realized_schema, ["properties", "data_rate_mbps", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "link_margin_db", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "snr_db", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "eb_no_db", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "bit_error_rate", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "packet_loss_rate", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "frame_loss_rate", "type"]) == "number"
    assert get_in(realized_schema, ["properties", "carrier_lock", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "symbol_lock", "type"]) == "boolean"
    assert get_in(realized_schema, ["properties", "link_quality_status", "type"]) == "string"
  end

  test "normalizes realized activity feedback rows through public helpers" do
    activity = %{
      id: :realized_obs_1,
      activity_type: :observe,
      planned_activity_id: :obs_1,
      status: :matched,
      realized_status: :completed,
      actual_data_rate_mb_s: 0.25,
      actual_duration_s: 50.0,
      target_id: :target_alpha,
      source_quality: :provider_report,
      trust_boundary: :ops_adapter
    }

    assert %{
             "id" => "realized_obs_1",
             "realized_activity_id" => "realized_obs_1",
             "planned_activity_id" => "obs_1",
             "status" => "completed",
             "feedback_status" => "matched",
             "type" => "observe",
             "target_id" => "target_alpha",
             "data_rate_mbps" => 2.0,
             "actual_throughput_mb" => 12.5,
             "actual_data_rate_throughput_derivation" => %{
               "derivation" => "actual_data_rate_times_duration",
               "rate_unit" => "MB/s",
               "actual_data_rate_mb_s" => 0.25,
               "duration_s" => 50.0,
               "actual_throughput_mb" => 12.5
             },
             "source_quality" => "provider_report",
             "trust_boundary" => "ops_adapter",
             "realized_activity_context" => %{
               "activity_id" => "obs_1",
               "realized_activity_id" => "realized_obs_1",
               "planned_activity_id" => "obs_1",
               "activity_type" => "observe",
               "status" => "completed",
               "feedback_status" => "matched",
               "target_id" => "target_alpha",
               "data_rate_mbps" => 2.0,
               "actual_throughput_mb" => 12.5,
               "actual_data_rate_throughput_derivation" => %{
                 "derivation" => "actual_data_rate_times_duration",
                 "rate_unit" => "MB/s",
                 "actual_data_rate_mb_s" => 0.25,
                 "duration_s" => 50.0,
                 "actual_throughput_mb" => 12.5
               },
               "source_quality" => "provider_report",
               "trust_boundary" => "ops_adapter"
             }
           } =
             normalized =
             TimelineFeedback.normalize_realized_activity(activity)

    assert OrbitalDynamics.normalize_realized_timeline_activity(activity) == normalized

    normalized_rows =
      TimelineFeedback.normalize_realized_activities([
        %{id: :missing_status, type: :observe},
        activity
      ])

    assert Enum.find(normalized_rows, &(&1["id"] == "realized_obs_1")) == normalized

    assert %{
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "missing_realized_status",
             "realized_activity_id" => "missing_status",
             "status" => "invalid"
           } = Enum.find(normalized_rows, &(&1["realized_activity_id"] == "missing_status"))

    assert OrbitalDynamics.normalize_realized_timeline_activities([activity]) == [normalized]

    assert_raise ArgumentError, ~r/realized activity must be a map/, fn ->
      TimelineFeedback.normalize_realized_activity(:not_a_map)
    end

    assert_raise ArgumentError, ~r/realized activities must be a list/, fn ->
      TimelineFeedback.normalize_realized_activities(:not_a_list)
    end
  end

  test "normalizes realized direction aliases through public helpers" do
    activity = %{
      id: :realized_cmd_alias,
      status: :completed,
      activity_type: :planned_contact,
      direction: :"s-band command",
      ground_station_id: :equator_prime,
      command_result: :accepted
    }

    assert %{
             "id" => "realized_cmd_alias",
             "type" => "planned_contact",
             "direction" => "command",
             "command_result" => "accepted",
             "realized_activity_context" => %{
               "activity_type" => "planned_contact",
               "direction" => "command"
             },
             "source_activity" => %{
               "activity_type" => "planned_contact",
               "direction" => "s-band command"
             }
           } =
             normalized =
             TimelineFeedback.normalize_realized_activity(activity)

    assert OrbitalDynamics.normalize_realized_timeline_activity(activity) == normalized
    assert normalized["direction"] == Timeline.normalize_contact_direction("s-band command")

    normalized_directions =
      [
        %{
          id: :realized_dl_alias,
          status: :completed,
          type: :planned_contact,
          direction: :dl,
          ground_station_id: :equator_prime,
          contact_success: true
        },
        %{
          id: :realized_tracking_alias,
          status: :completed,
          type: :planned_contact,
          direction: :"tracking-pass",
          ground_station_id: :dss_14,
          contact_success: true
        },
        %{
          id: :realized_unknown_alias,
          status: :completed,
          type: :planned_contact,
          direction: :"Ka-Band Special",
          ground_station_id: :atlas,
          contact_success: true
        }
      ]
      |> TimelineFeedback.normalize_realized_activities()
      |> Enum.sort_by(& &1["id"])
      |> Enum.map(&Map.take(&1, ["direction"]))

    assert normalized_directions == [
             %{"direction" => "downlink"},
             %{"direction" => "tracking"},
             %{"direction" => "ka_band_special"}
           ]
  end

  test "normalizes planned and realized activity state through public helper" do
    planned = %{
      id: :downlink_equator,
      type: :downlink,
      starts_at_s: 100.0,
      ends_at_s: 160.0,
      direction: :downlink,
      ground_station_id: :equator_prime,
      source_window_id: :"access:leo_1:equator_prime:1",
      estimated_throughput_mb: 120.0,
      required_downlink_mb: 120.0,
      cadence_import: %{activity_type: :contact_window}
    }

    realized = %{
      id: :downlink_equator,
      type: :downlink,
      status: :partial,
      actual_starts_at_s: 102.0,
      actual_ends_at_s: 150.0,
      actual_throughput_mb: 72.0,
      provider_id: "ksat",
      quality_level: "provider_declared",
      trust_boundary: "provider_adapter",
      reason: "provider reported reduced throughput"
    }

    assert %{
             "schema_contract" => "timeline_activity_state.v1",
             "model" => "artifact_only_timeline_activity_state",
             "validation_level" => "artifact_contract",
             "state_status" => "matched",
             "row_count" => 1,
             "status_counts" => %{"matched" => 1},
             "feedback_kind_counts" => %{"contact" => 1},
             "match_strategy_counts" => %{"activity_id" => 1},
             "cadence_import_status_counts" => %{"present" => 1},
             "planned_protection_decision_counts" => %{"preserve" => 1},
             "realized_provider_counts" => %{"ksat" => 1},
             "realized_source_quality_counts" => %{"provider_declared" => 1},
             "realized_trust_boundary_status" => "declared",
             "realized_trust_boundaries" => ["provider_adapter"],
             "activity_id" => "downlink_equator",
             "activity_ids" => ["downlink_equator"],
             "feedback_kind" => "contact",
             "match_strategy" => "activity_id",
             "planned_status" => "planned",
             "realized_status" => "partial",
             "status_transition" => %{
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "partial"
             },
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "planned_approval_status" => "not_evaluated",
             "realized_approval_status" => "not_evaluated",
             "planned_approval_category" => "review_required",
             "realized_approval_category" => "review_required",
             "planned_locked" => false,
             "realized_locked" => false,
             "planned_executed" => false,
             "realized_executed" => true,
             "planned_protection_decision" => "preserve",
             "planned_protection_category" => "executed",
             "realized_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed",
               "reason" => "activity_already_partial"
             },
             "review_required" => false,
             "review_activity_ids" => [],
             "source_activity_context" => %{
               "activity_id" => "downlink_equator",
               "source_window_id" => "access:leo_1:equator_prime:1"
             },
             "realized_activity_context" => %{
               "realized_activity_id" => "downlink_equator",
               "actual_throughput_mb" => 72.0,
               "provider" => "ksat",
               "source_quality" => "provider_declared",
               "trust_boundary" => "provider_adapter"
             },
             "assumptions" => %{
               "artifact_only" => true,
               "no_schedule_mutation" => true,
               "no_command_execution" => true
             },
             "model_limits" => model_limits,
             "rows" => [_row]
           } = state = TimelineFeedback.activity_state(planned, realized)

    assert "no_schedule_mutation" in model_limits
    assert "no_command_execution" in model_limits
    assert OrbitalDynamics.timeline_activity_state(planned, realized) == state

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(state)

    stale_status_counts = Map.put(state, "status_counts", %{"matched" => 2})

    assert {:error, stale_status_counts_validation} =
             Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             stale_status_counts_validation["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal row-derived status_counts")
           )
  end

  test "activity state carries lifecycle approval lock and executed evidence" do
    planned = %{
      "id" => "cmd_review",
      "type" => "command",
      "status" => "planned",
      "approval_status" => "approved",
      "locked" => true,
      "cadence_import" => %{
        "activity_type" => "command",
        "external_id" => "cmd_review"
      }
    }

    realized = %{
      "id" => "cmd_review",
      "type" => "command",
      "status" => "executed",
      "approval_status" => "operator_review_required"
    }

    state = TimelineFeedback.activity_state(planned, realized)
    lifecycle_state = Timeline.activity_lifecycle_state(planned, realized)

    lifecycle_fields = [
      "planned_approval_status",
      "realized_approval_status",
      "planned_status_category",
      "realized_status_category",
      "planned_approval_category",
      "realized_approval_category",
      "approval_transition",
      "planned_locked",
      "realized_locked",
      "planned_executed",
      "realized_executed",
      "realized_protection_decision"
    ]

    assert Map.take(state, lifecycle_fields) == Map.take(lifecycle_state, lifecycle_fields)

    assert %{
             "planned_approval_status" => "approved",
             "realized_approval_status" => "operator_review_required",
             "planned_status_category" => "planned",
             "realized_status_category" => "executed",
             "planned_approval_category" => "protected",
             "realized_approval_category" => "review_required",
             "planned_locked" => true,
             "planned_executed" => false,
             "realized_executed" => true,
             "approval_transition" => %{
               "transition_type" => "changed",
               "transition_category" => "approval_regressed",
               "requires_operator_review" => true
             },
             "realized_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed",
               "reason" => "activity_already_executed"
             }
           } = state

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(state)
  end

  test "activity state preserves unmatched planned and realized rows for review" do
    state =
      TimelineFeedback.activity_state(
        %{id: :planned_obs, type: :observe, target_id: :target_alpha},
        %{id: :provider_obs, type: :observe, status: :completed, target_id: :target_beta}
      )

    assert %{
             "schema_contract" => "timeline_activity_state.v1",
             "state_status" => "review_required",
             "row_count" => 2,
             "status_counts" => %{"planned_only" => 1, "realized_only" => 1},
             "feedback_kind_counts" => %{"observation" => 2},
             "match_strategy_counts" => %{
               "unmatched_planned" => 1,
               "unmatched_realized" => 1
             },
             "activity_ids" => ["planned_obs", "provider_obs"],
             "review_required" => true,
             "review_activity_ids" => ["planned_obs", "provider_obs"],
             "rows" => rows
           } = state

    assert Enum.map(rows, & &1["status"]) |> Enum.sort() == ["planned_only", "realized_only"]

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(state)

    assert_raise ArgumentError, ~r/planned or realized activity is required/, fn ->
      TimelineFeedback.activity_state(nil, nil)
    end

    assert_raise ArgumentError, ~r/planned activity must be a map or nil/, fn ->
      TimelineFeedback.activity_state(:not_a_map, %{id: :provider_obs, status: :completed})
    end
  end

  test "preserves invalid planned activity inputs for feedback review" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            ground_station_id: :equator_prime
          },
          %{
            id: :missing_type,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            target_id: :target_a
          },
          "not a planned activity"
        ],
        []
      )

    assert report["planned_count"] == 3
    assert report["row_count"] == 3
    assert report["status_counts"] == %{"planned_only" => 3}

    missing_id = Enum.find(report["rows"], &(&1["activity_id"] == "missing_activity_id:1"))
    missing_type = Enum.find(report["rows"], &(&1["activity_id"] == "missing_type"))
    invalid_shape = Enum.find(report["rows"], &(&1["activity_id"] == "invalid_activity_shape:3"))

    assert %{
             "status" => "planned_only",
             "planned_type" => "invalid_activity_input",
             "planned_starts_at_s" => 10.0,
             "planned_ends_at_s" => 20.0,
             "ground_station_id" => "equator_prime",
             "timeline_integrity_status" => "review_required",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "planned_activity" => %{"type" => "command"}
           } = missing_id

    assert %{
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_type",
             "target_id" => "target_a"
           } = missing_type

    assert %{
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_activity_shape",
             "planned_activity" => %{"raw_input" => "\"not a planned activity\""}
           } = invalid_shape

    review_row =
      Enum.find(
        get_in(report, ["operator_review_package", "rows"]),
        &(&1["activity_id"] == "missing_activity_id:1")
      )

    import_row =
      Enum.find(
        get_in(report, ["cadence_import_manifest", "rows"]),
        &(&1["activity_id"] == "missing_activity_id:1")
      )

    assert %{
             "required_operator_action" => "review_invalid_activity_input",
             "approval_status" => "operator_review_required",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_feedback" => %{"invalid_activity_input" => true}
           } = review_row

    assert %{
             "source_review_action" => "review_invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_feedback" => %{"invalid_activity_input" => true}
           } = import_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_reservation_ids =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_ids"], ["bad id"])

    assert {:error, invalid_reservation_ids_report} =
             Schema.validate_artifact(invalid_reservation_ids)

    assert Enum.any?(
             invalid_reservation_ids_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_ids[0]")
           )

    invalid_reservation_expirations =
      put_in(report, ["rows", Access.at(0), "station_calendar_reservation_expires_at_s"], [
        "soon"
      ])

    assert {:error, invalid_reservation_expirations_report} =
             Schema.validate_artifact(invalid_reservation_expirations)

    assert Enum.any?(
             invalid_reservation_expirations_report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_expires_at_s[0]")
           )

    invalid_reservation_expiration =
      put_in(report, ["rows", Access.at(0), "station_reservation_expires_at_s"], "soon")

    assert {:error, invalid_reservation_expiration_report} =
             Schema.validate_artifact(invalid_reservation_expiration)

    assert Enum.any?(
             invalid_reservation_expiration_report["errors"],
             &(&1["path"] == "$.rows[0].station_reservation_expires_at_s")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "accepts activity_type alias for realized feedback activity kind" do
    report =
      TimelineFeedback.reconcile([], [
        %{
          "schema_contract" => "realized_activity.v1",
          "id" => "downlink_equator",
          "planned_activity_id" => "downlink_equator",
          "status" => "partial",
          "activity_type" => "downlink",
          "direction" => "downlink",
          "ground_station_id" => "equator_prime",
          "actual_starts_at_s" => 102.0,
          "actual_ends_at_s" => 150.0,
          "actual_throughput_mb" => 72.0
        }
      ])

    assert [
             %{
               "activity_id" => "downlink_equator",
               "realized_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"},
               "realized_activity" => %{"activity_type" => "downlink"}
             }
           ] = report["rows"]

    assert [
             %{
               "activity_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"}
             }
           ] = report["operator_review_package"]["rows"]

    assert [
             %{
               "activity_type" => "downlink",
               "realized_activity_context" => %{"activity_type" => "downlink"}
             }
           ] = report["cadence_import_manifest"]["rows"]

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves malformed realized feedback inputs for review" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{status: :completed, actual_starts_at_s: 10.0, actual_ends_at_s: 20.0},
          "not realized feedback"
        ]
      )

    assert report["realized_count"] == 2
    assert report["row_count"] == 2
    assert report["status_counts"] == %{"realized_only" => 2}

    missing_id =
      Enum.find(
        report["rows"],
        &(&1["activity_id"] == "invalid_realized_feedback:missing_realized_feedback_id:1")
      )

    invalid_shape =
      Enum.find(
        report["rows"],
        &(&1["activity_id"] == "invalid_realized_feedback:invalid_realized_feedback_shape:2")
      )

    assert %{
             "status" => "realized_only",
             "realized_status" => "invalid",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "missing_realized_feedback_id",
             "realized_activity" => %{"status" => "completed"},
             "realized_activity_context" => %{
               "invalid_realized_feedback_input" => true,
               "invalid_realized_feedback_input_reason" => "missing_realized_feedback_id"
             }
           } = missing_id

    assert %{
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_shape",
             "realized_activity" => %{"raw_input" => "\"not realized feedback\""}
           } = invalid_shape

    review_row =
      Enum.find(
        get_in(report, ["operator_review_package", "rows"]),
        &(&1["activity_id"] == "invalid_realized_feedback:missing_realized_feedback_id:1")
      )

    import_row =
      Enum.find(
        get_in(report, ["cadence_import_manifest", "rows"]),
        &(&1["activity_id"] == "invalid_realized_feedback:missing_realized_feedback_id:1")
      )

    assert %{
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "approval_status" => "operator_review_required",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "missing_realized_feedback_id",
             "source_feedback" => %{"invalid_realized_feedback_input" => true}
           } = review_row

    assert %{
             "source_review_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "missing_realized_feedback_id",
             "source_feedback" => %{"invalid_realized_feedback_input" => true}
           } = import_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "rejects unknown realized status values in feedback artifacts" do
    report =
      TimelineFeedback.reconcile(
        [%{id: :dl_1, type: :downlink, starts_at_s: 10.0, ends_at_s: 20.0}],
        [%{id: :dl_1, status: :completed, type: :downlink}]
      )

    invalid_report = put_in(report, ["rows", Access.at(0), "realized_status"], "provider_custom")

    assert {:error, validation_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].realized_status" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "preserves malformed realized feedback ids while retaining planned match context" do
    report =
      TimelineFeedback.reconcile(
        [%{id: :cmd_1, type: :command, starts_at_s: 10.0, ends_at_s: 20.0}],
        [
          %{
            id: "provider bad id",
            planned_activity_id: :cmd_1,
            status: :completed,
            type: :command
          }
        ]
      )

    assert %{
             "realized_count" => 1,
             "row_count" => 1,
             "status_counts" => %{"matched" => 1}
           } = report

    assert %{
             "activity_id" => "cmd_1",
             "status" => "matched",
             "realized_status" => "invalid",
             "match_strategy" => "planned_activity_id",
             "realized_activity_id" => "invalid_realized_feedback:invalid_realized_feedback_id:1",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_id",
             "realized_activity" => %{
               "id" => "provider bad id",
               "planned_activity_id" => "cmd_1"
             }
           } = List.first(report["rows"])

    review_row = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "cmd_1",
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_id",
             "source_feedback" => %{"invalid_realized_feedback_input" => true}
           } = review_row

    import_row = List.first(report["cadence_import_manifest"]["rows"])

    assert %{
             "import_action" => "review_realized_feedback",
             "activity_id" => "cmd_1",
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_id"
           } = import_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves malformed provider-shaped realized identities for review" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :downlink_equator,
            type: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          },
          Activity.observe!(:obs_target_a, 50.0, 80.0, :target_a)
        ],
        [
          %{
            id: :provider_contact_1,
            planned_activity_id: :downlink_equator,
            status: :completed,
            type: :downlink,
            station: %{"id" => "bad station"},
            actual_throughput_mb: 80.0
          },
          %{
            id: :provider_obs_1,
            planned_activity_id: :obs_target_a,
            status: :completed,
            type: :observe,
            target: %{"id" => "bad target"},
            observation_result: :delivered
          }
        ]
      )

    assert report["status_counts"] == %{"matched" => 2}

    assert %{
             "activity_id" => "downlink_equator",
             "realized_status" => "invalid",
             "realized_activity_id" => "provider_contact_1",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_id",
             "realized_activity" => %{"station" => %{"id" => "bad station"}}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "obs_target_a",
             "realized_status" => "invalid",
             "realized_activity_id" => "provider_obs_1",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "invalid_realized_feedback_id",
             "realized_activity" => %{"target" => %{"id" => "bad target"}}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_target_a"))

    assert report["operational_feedback"]["station_throughput_factor"] == %{}
    assert report["operational_feedback"]["observation_success_rate"] == %{}

    assert Enum.all?(
             report["operator_review_package"]["rows"],
             &(&1["required_operator_action"] == "review_invalid_realized_feedback_input")
           )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves malformed realized cadence import context for review" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            id: :realized_bad_import,
            type: :downlink,
            status: :completed,
            cadence_import: :bad_import_context
          }
        ]
      )

    assert %{
             "status_counts" => %{"realized_only" => 1},
             "row_count" => 1
           } = report

    assert %{
             "activity_id" => "realized_bad_import",
             "status" => "realized_only",
             "realized_status" => "completed",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"},
             "realized_activity_context" => %{
               "invalid_cadence_import" => true,
               "invalid_cadence_import_reason" => "cadence_import_must_be_object",
               "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"}
             }
           } = List.first(report["rows"])

    review_row = List.first(get_in(report, ["operator_review_package", "rows"]))
    import_row = List.first(get_in(report, ["cadence_import_manifest", "rows"]))

    assert %{
             "required_operator_action" => "review_invalid_cadence_import",
             "approval_status" => "operator_review_required",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"},
             "source_feedback" => %{"invalid_cadence_import" => true}
           } = review_row

    assert %{
             "source_review_action" => "review_invalid_cadence_import",
             "import_status" => "review_required_before_import",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"},
             "source_feedback" => %{"invalid_cadence_import" => true}
           } = import_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "derives operational feedback for strategy refresh handoff" do
    planned = [
      %{
        id: :dl_1,
        type: :downlink,
        starts_at_s: 10.0,
        ends_at_s: 40.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        starts_at_s: 50.0,
        ends_at_s: 80.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0
      },
      Activity.command!(:cmd_repoint, 90.0, 100.0, ground_station_id: :equator_prime),
      Activity.observe!(:obs_partial, 120.0, 160.0, :target_a),
      Activity.observe!(:obs_provider_failed, 165.0, 175.0, :target_b),
      Activity.impulsive_burn!(:trim_burn, 180.0, {0.0, 0.01, 0.0})
    ]

    realized = [
      %{
        id: :dl_1,
        status: :completed,
        actual_throughput_mb: 50.0
      },
      %{
        id: :dl_2,
        status: :failed,
        actual_throughput_mb: 0.0,
        contact_success: false
      },
      %{
        id: :cmd_repoint,
        type: :command,
        status: :completed,
        command_result: :accepted
      },
      %{
        id: :obs_partial,
        type: :observe,
        status: :partial,
        completed_fraction: 0.25,
        target_priority: 4.0
      },
      %{
        id: :obs_provider_failed,
        type: :observe,
        status: :completed,
        observation_result: ["accepted", "failed"]
      },
      %{
        id: :trim_burn,
        type: :impulsive_burn,
        status: :delayed
      }
    ]

    report = TimelineFeedback.reconcile(planned, realized)

    assert report["operational_feedback"] ==
             TimelineFeedback.operational_feedback(report)

    assert report["operational_feedback"] ==
             OrbitalDynamics.timeline_operational_feedback(report)

    assert report["operational_feedback"] ==
             OrbitalDynamics.timeline_operational_feedback(%{rows: report["rows"]})

    assert report["operational_feedback"] == %{
             "contact_success_rate" => %{"equator_prime" => 0.5},
             "station_throughput_factor" => %{"equator_prime" => 0.25},
             "observation_success_rate" => %{"target_a" => 0.25, "target_b" => 0.0},
             "image_quality_score" => %{},
             "image_quality_status" => %{},
             "image_quality_source" => %{},
             "cloud_cover_fraction" => %{},
             "blur_score" => %{},
             "downlink_demand_mb" => %{},
             "downlink_demand_sources" => %{},
             "target_priority_overrides" => %{"target_a" => 4.0},
             "resource_margin_overrides" => %{},
             "resource_availability_overrides" => %{},
             "maneuver_success_rate" => %{"trim_burn" => 0.5},
             "maneuver_execution_uncertainty" => %{
               "trim_burn" => %{"execution_uncertainty_status" => "missing"}
             },
             "command_success_rate" => %{"cmd_repoint" => 1.0}
           }

    assert %{
             "observation_success" => false,
             "observation_result" => "accepted,failed"
           } =
             provider_failed_observation =
             Enum.find(report["rows"], &(&1["activity_id"] == "obs_provider_failed"))

    assert provider_failed_observation["observation_success_factor"] == 0.0

    assert %{
             "activity_id" => "obs_provider_failed",
             "observation_success" => false,
             "observation_result" => "accepted,failed",
             "observation_success_factor_source" => "realized_activity.observation_result"
           } =
             provider_failed_observation_review =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_provider_failed")
             )

    assert provider_failed_observation_review["observation_success_factor"] == 0.0

    assert %{
             "activity_id" => "obs_provider_failed",
             "observation_success" => false,
             "observation_result" => "accepted,failed",
             "observation_success_factor_source" => "realized_activity.observation_result"
           } =
             provider_failed_observation_import =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_provider_failed")
             )

    assert provider_failed_observation_import["observation_success_factor"] == 0.0

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives resource operational feedback from realized resource telemetry" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            id: :resource_snapshot_1,
            type: :resource_snapshot,
            status: :completed,
            spacecraft_id: :leo_1,
            storage_margin: 0.4,
            downlink_capacity_margin: 0.6,
            thermal_margin_c: 4.0,
            battery_capacity_wh: 1200.0,
            battery_energy_used_wh: 400.0,
            battery_energy_generated_wh: "45.5",
            battery_state_of_charge: 0.42,
            payload_available?: " TRUE ",
            spacecraft_available: " True ",
            incompatible_activity_types: [:observe],
            trust_boundary: :ops_telemetry
          },
          %{
            id: :resource_snapshot_2,
            type: :resource_snapshot,
            status: :completed,
            scenario_id: :leo_1,
            storage_margin: 0.05,
            thermal_margin_c: 1.5,
            battery_energy_used_wh: 900.0,
            estimated_energy_generated_wh: 70.0,
            battery_state_of_charge: 0.15,
            spacecraft_availability: " FALSE ",
            payload_available?: " False ",
            antenna_available: " false ",
            degraded: "1",
            incompatible_activity_types: [:downlink],
            trust_boundary: :ops_telemetry
          }
        ]
      )

    assert get_in(report, ["operational_feedback", "resource_margin_overrides"]) == %{
             "leo_1" => %{
               "battery_capacity_wh" => 1200.0,
               "battery_energy_used_wh" => 900.0,
               "battery_energy_generated_wh" => 70.0,
               "battery_state_of_charge" => 0.15,
               "downlink_margin" => 0.6,
               "power_margin" => 0.15,
               "storage_margin" => 0.05,
               "thermal_margin_c" => 1.5
             }
           }

    assert get_in(report, ["operational_feedback", "resource_availability_overrides"]) == %{
             "leo_1" => %{
               "antenna_available" => false,
               "degraded" => true,
               "incompatible_activity_types" => ["downlink", "observe"],
               "payload_available" => false,
               "spacecraft_availability" => false,
               "spacecraft_available" => false
             }
           }

    first_row = Enum.find(report["rows"], &(&1["activity_id"] == "resource_snapshot_1"))
    second_row = Enum.find(report["rows"], &(&1["activity_id"] == "resource_snapshot_2"))

    assert %{
             "spacecraft_id" => "leo_1",
             "storage_margin" => 0.4,
             "downlink_margin" => 0.6,
             "thermal_margin_c" => 4.0,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 400.0,
             "battery_energy_generated_wh" => 45.5,
             "battery_state_of_charge" => 0.42,
             "power_margin" => 0.42,
             "payload_available" => true,
             "spacecraft_available" => true,
             "incompatible_activity_types" => ["observe"],
             "realized_activity_context" => %{
               "spacecraft_id" => "leo_1",
               "storage_margin" => 0.4,
               "downlink_margin" => 0.6,
               "thermal_margin_c" => 4.0,
               "battery_capacity_wh" => 1200.0,
               "battery_energy_used_wh" => 400.0,
               "battery_energy_generated_wh" => 45.5,
               "battery_state_of_charge" => 0.42,
               "power_margin" => 0.42,
               "payload_available" => true,
               "spacecraft_available" => true,
               "incompatible_activity_types" => ["observe"]
             }
           } = first_row

    assert %{
             "storage_margin" => 0.05,
             "thermal_margin_c" => 1.5,
             "battery_energy_used_wh" => 900.0,
             "battery_energy_generated_wh" => 70.0,
             "battery_state_of_charge" => 0.15,
             "power_margin" => 0.15,
             "payload_available" => false,
             "antenna_available" => false,
             "degraded" => true,
             "spacecraft_available" => false,
             "incompatible_activity_types" => ["downlink"]
           } = second_row

    assert %{
             "spacecraft_id" => "leo_1",
             "storage_margin" => 0.4,
             "downlink_margin" => 0.6,
             "thermal_margin_c" => 4.0,
             "battery_capacity_wh" => 1200.0,
             "battery_energy_used_wh" => 400.0,
             "battery_energy_generated_wh" => 45.5,
             "battery_state_of_charge" => 0.42,
             "power_margin" => 0.42,
             "payload_available" => true,
             "spacecraft_available" => true,
             "incompatible_activity_types" => ["observe"]
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "resource_snapshot_1")
             )

    assert %{
             "storage_margin" => 0.05,
             "thermal_margin_c" => 1.5,
             "battery_energy_used_wh" => 900.0,
             "battery_energy_generated_wh" => 70.0,
             "battery_state_of_charge" => 0.15,
             "power_margin" => 0.15,
             "payload_available" => false,
             "antenna_available" => false,
             "degraded" => true,
             "spacecraft_available" => false,
             "incompatible_activity_types" => ["downlink"]
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "resource_snapshot_2")
             )

    assert %{
             "input_keys" => [
               "resource_availability_overrides",
               "resource_margin_overrides"
             ],
             "sources" => [
               %{
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_telemetry"],
                 "feedback_trust_boundaries" => %{
                   "resource_availability_overrides" => %{"leo_1" => ["ops_telemetry"]},
                   "resource_margin_overrides" => %{"leo_1" => ["ops_telemetry"]}
                 }
               }
             ]
           } = report["operational_feedback_provenance"]

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves command authority and safety evidence through realized feedback review and import rows" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "cmd_authority",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 100.0,
            "ends_at_s" => 120.0,
            "command_authority_status" => "authorized",
            "required_authority" => "payload_ops_lead",
            "command_safety_status" => "checked",
            "command_authorized" => "true",
            "command_safety_checked" => "yes"
          }
        ],
        [
          %{
            id: :cmd_authority_feedback,
            planned_activity_id: :cmd_authority,
            type: :command,
            status: :completed,
            command_authority_status: :operator_override,
            required_authority: :flight_director,
            command_safety_status: :rechecked,
            command_authorized: false,
            command_safety_checked: true
          }
        ]
      )

    assert %{
             "activity_id" => "cmd_authority",
             "command_authority_status" => "authorized",
             "planned_command_authority_status" => "authorized",
             "realized_command_authority_status" => "operator_override",
             "command_authority_status_match_status" => "mismatch",
             "required_authority" => "payload_ops_lead",
             "planned_required_authority" => "payload_ops_lead",
             "realized_required_authority" => "flight_director",
             "required_authority_match_status" => "mismatch",
             "command_safety_status" => "checked",
             "planned_command_safety_status" => "checked",
             "realized_command_safety_status" => "rechecked",
             "command_safety_status_match_status" => "mismatch",
             "command_authorized" => false,
             "planned_command_authorized" => true,
             "realized_command_authorized" => false,
             "command_authorized_match_status" => "mismatch",
             "command_safety_checked" => true,
             "planned_command_safety_checked" => true,
             "realized_command_safety_checked" => true,
             "command_safety_checked_match_status" => "matched",
             "source_activity_context" => %{
               "command_authority_status" => "authorized",
               "required_authority" => "payload_ops_lead",
               "command_safety_status" => "checked",
               "command_authorized" => true,
               "command_safety_checked" => true
             },
             "realized_activity_context" => %{
               "command_authority_status" => "operator_override",
               "required_authority" => "flight_director",
               "command_safety_status" => "rechecked",
               "command_authorized" => false,
               "command_safety_checked" => true
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_authority"))

    assert %{
             "activity_id" => "cmd_authority",
             "command_authority_status" => "authorized",
             "realized_command_authority_status" => "operator_override",
             "required_authority" => "payload_ops_lead",
             "realized_required_authority" => "flight_director",
             "command_safety_status" => "checked",
             "realized_command_safety_status" => "rechecked",
             "command_authorized" => false,
             "realized_command_authorized" => false,
             "command_safety_checked" => true,
             "source_activity_context" => %{
               "command_authority_status" => "authorized",
               "command_safety_status" => "checked"
             },
             "realized_activity_context" => %{
               "command_authority_status" => "operator_override",
               "command_safety_status" => "rechecked"
             }
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_authority")
             )

    assert %{
             "activity_id" => "cmd_authority",
             "command_authority_status" => "authorized",
             "realized_command_authority_status" => "operator_override",
             "required_authority" => "payload_ops_lead",
             "realized_required_authority" => "flight_director",
             "command_safety_status" => "checked",
             "realized_command_safety_status" => "rechecked",
             "command_authorized" => false,
             "realized_command_authorized" => false,
             "command_safety_checked" => true,
             "source_review_row" => %{
               "command_authority_status" => "authorized",
               "realized_command_authority_status" => "operator_override"
             }
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_authority")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves product identity and data volume evidence through review and import rows" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.observe!(:obs_product, 10.0, 20.0, :target_a,
            metadata: %{
              collection_id: :collection_alpha,
              product_id: :image_alpha_1,
              product_ids: [:image_alpha_1, :image_alpha_2],
              payload_id: :payload_camera,
              instrument_id: :narrow_angle_camera,
              pointing_mode: :target_track,
              pointing_target_id: :target_a,
              boresight_axis: "+Z",
              off_nadir_angle_deg: 11.0,
              pointing_model: :declared_observation_attitude,
              attitude_mode: :inertial_hold,
              attitude_target_id: :target_a,
              roll_deg: 1.0,
              pitch_deg: -0.5,
              yaw_deg: 2.0,
              attitude_model: :declared_euler_attitude,
              data_volume_mb: 80.0,
              estimated_storage_mb: 80.0,
              estimated_downlink_mb: 72.0,
              required_downlink_mb: 72.0,
              payload_available?: "false",
              antenna_available: "0",
              degraded: "yes"
            }
          )
        ],
        [
          %{
            id: :obs_product_feedback,
            planned_activity_id: :obs_product,
            type: :observe,
            status: :partial,
            collection_id: :collection_alpha,
            product_id: :image_alpha_1,
            product_ids: [:image_alpha_1],
            payload_id: :payload_camera,
            instrument_id: :narrow_angle_camera,
            pointing_mode: :target_track,
            pointing_target_id: :target_a,
            boresight_axis: "+Z",
            off_nadir_angle_deg: 12.5,
            pointing_error_deg: 0.2,
            pointing_status: :within_tolerance,
            pointing_source: :provider_attitude_feedback,
            attitude_mode: :inertial_hold,
            attitude_target_id: :target_a,
            roll_deg: 1.75,
            pitch_deg: -0.25,
            yaw_deg: 2.5,
            attitude_error_deg: 0.1,
            attitude_status: :within_tolerance,
            attitude_source: :provider_attitude_feedback,
            attitude_confidence: 0.9,
            actual_data_volume_mb: 60.0
          }
        ]
      )

    assert %{
             "activity_id" => "obs_product",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "payload_camera",
             "instrument_id" => "narrow_angle_camera",
             "pointing_target_id" => "target_a",
             "pointing_target_match_status" => "matched",
             "pointing_mode" => "target_track",
             "pointing_mode_match_status" => "matched",
             "planned_off_nadir_angle_deg" => 11.0,
             "realized_off_nadir_angle_deg" => 12.5,
             "off_nadir_angle_delta_deg" => 1.5,
             "pointing_error_deg" => 0.2,
             "pointing_status" => "within_tolerance",
             "pointing_source" => "provider_attitude_feedback",
             "attitude_target_id" => "target_a",
             "attitude_target_match_status" => "matched",
             "attitude_mode" => "inertial_hold",
             "attitude_mode_match_status" => "matched",
             "planned_roll_deg" => 1.0,
             "realized_roll_deg" => 1.75,
             "roll_delta_deg" => 0.75,
             "planned_pitch_deg" => -0.5,
             "realized_pitch_deg" => -0.25,
             "pitch_delta_deg" => 0.25,
             "planned_yaw_deg" => 2.0,
             "realized_yaw_deg" => 2.5,
             "yaw_delta_deg" => 0.5,
             "attitude_error_deg" => 0.1,
             "attitude_status" => "within_tolerance",
             "attitude_source" => "provider_attitude_feedback",
             "attitude_confidence" => 0.9,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "payload_available" => false,
             "antenna_available" => false,
             "degraded" => true,
             "source_activity_context" => %{
               "collection_id" => "collection_alpha",
               "product_id" => "image_alpha_1",
               "product_ids" => ["image_alpha_1", "image_alpha_2"],
               "payload_id" => "payload_camera",
               "instrument_id" => "narrow_angle_camera",
               "pointing_mode" => "target_track",
               "pointing_target_id" => "target_a",
               "boresight_axis" => "+Z",
               "off_nadir_angle_deg" => 11.0,
               "pointing_model" => "declared_observation_attitude",
               "attitude_mode" => "inertial_hold",
               "attitude_target_id" => "target_a",
               "roll_deg" => 1.0,
               "pitch_deg" => -0.5,
               "yaw_deg" => 2.0,
               "attitude_model" => "declared_euler_attitude",
               "data_volume_mb" => 80.0,
               "estimated_storage_mb" => 80.0,
               "estimated_downlink_mb" => 72.0,
               "required_downlink_mb" => 72.0,
               "payload_available" => false,
               "antenna_available" => false,
               "degraded" => true
             },
             "realized_activity_context" => %{
               "collection_id" => "collection_alpha",
               "product_id" => "image_alpha_1",
               "product_ids" => ["image_alpha_1"],
               "payload_id" => "payload_camera",
               "instrument_id" => "narrow_angle_camera",
               "pointing_mode" => "target_track",
               "pointing_target_id" => "target_a",
               "boresight_axis" => "+Z",
               "off_nadir_angle_deg" => 12.5,
               "pointing_error_deg" => 0.2,
               "pointing_status" => "within_tolerance",
               "pointing_source" => "provider_attitude_feedback",
               "attitude_mode" => "inertial_hold",
               "attitude_target_id" => "target_a",
               "roll_deg" => 1.75,
               "pitch_deg" => -0.25,
               "yaw_deg" => 2.5,
               "attitude_error_deg" => 0.1,
               "attitude_status" => "within_tolerance",
               "attitude_source" => "provider_attitude_feedback",
               "attitude_confidence" => 0.9,
               "actual_data_volume_mb" => 60.0
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_product"))

    assert report["operational_feedback"]["downlink_demand_mb"] == %{"default" => 60.0}

    assert %{
             "activity_id" => "obs_product",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "pointing_target_id" => "target_a",
             "off_nadir_angle_delta_deg" => 1.5,
             "attitude_target_id" => "target_a",
             "roll_delta_deg" => 0.75,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "payload_available" => false,
             "antenna_available" => false,
             "degraded" => true
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_product")
             )

    assert %{
             "activity_id" => "obs_product",
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "pointing_target_id" => "target_a",
             "off_nadir_angle_delta_deg" => 1.5,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "data_volume_delta_mb" => -20.0,
             "data_volume_completion_fraction" => 0.75,
             "payload_available" => false,
             "antenna_available" => false,
             "degraded" => true
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_product")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves thermal evidence through realized feedback review and import rows" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :payload_thermal_check,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 120.0,
            thermal_zone_id: :payload_deck,
            planned_temperature_c: "18.0",
            max_operating_temperature_c: "45.0",
            thermal_model: :declared_payload_thermal_budget
          }
        ],
        [
          %{
            id: :payload_thermal_feedback,
            planned_activity_id: :payload_thermal_check,
            type: :command,
            status: :completed,
            thermal_zone_id: :payload_deck,
            actual_temperature_c: "42.0",
            max_operating_temperature_c: "45.0",
            thermal_status: :near_limit,
            thermal_source: :provider_thermal_feedback,
            thermal_confidence: "0.8"
          }
        ]
      )

    assert %{
             "activity_id" => "payload_thermal_check",
             "thermal_zone_id" => "payload_deck",
             "planned_temperature_c" => 18.0,
             "actual_temperature_c" => 42.0,
             "temperature_delta_c" => 24.0,
             "thermal_margin_c" => 3.0,
             "thermal_status" => "near_limit",
             "thermal_source" => "provider_thermal_feedback",
             "thermal_confidence" => 0.8,
             "source_activity_context" => %{
               "thermal_zone_id" => "payload_deck",
               "planned_temperature_c" => 18.0,
               "max_operating_temperature_c" => 45.0,
               "thermal_margin_c" => 27.0,
               "thermal_model" => "declared_payload_thermal_budget"
             },
             "realized_activity_context" => %{
               "thermal_zone_id" => "payload_deck",
               "actual_temperature_c" => 42.0,
               "max_operating_temperature_c" => 45.0,
               "thermal_margin_c" => 3.0,
               "thermal_status" => "near_limit",
               "thermal_source" => "provider_thermal_feedback",
               "thermal_confidence" => 0.8
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "payload_thermal_check"))

    assert %{
             "source_activity_context" => %{
               "thermal_zone_id" => "payload_deck",
               "planned_temperature_c" => 18.0
             },
             "realized_activity_context" => %{
               "actual_temperature_c" => 42.0,
               "thermal_margin_c" => 3.0
             }
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "payload_thermal_check")
             )

    assert %{
             "source_activity_context" => %{
               "thermal_zone_id" => "payload_deck",
               "planned_temperature_c" => 18.0
             },
             "realized_activity_context" => %{
               "actual_temperature_c" => 42.0,
               "thermal_margin_c" => 3.0
             }
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "payload_thermal_check")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves lighting and eclipse evidence through realized feedback review and import rows" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :obs_lighting,
            type: :observe,
            target_id: :target_a,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            lighting_condition: :sunlit,
            lighting_condition_model: :declared_lighting_plan,
            eclipse_overlap_fraction: "0.0",
            eclipse_overlap_s: "0.0"
          }
        ],
        [
          %{
            id: :obs_lighting_feedback,
            planned_activity_id: :obs_lighting,
            type: :observe,
            target_id: :target_a,
            status: :completed,
            lighting_condition: :penumbra,
            lighting_condition_detail: :partial_eclipse,
            lighting_detail_model: :provider_lighting_replay,
            lighting_confidence: "0.72",
            eclipse_overlap_fraction: "0.35",
            eclipse_overlap_s: "21.0"
          }
        ]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_lighting"))

    assert row["eclipse_overlap_fraction"] == 0.35
    assert_in_delta row["planned_eclipse_overlap_fraction"], 0.0, 1.0e-12
    assert row["realized_eclipse_overlap_fraction"] == 0.35
    assert row["eclipse_overlap_s"] == 21.0
    assert_in_delta row["planned_eclipse_overlap_s"], 0.0, 1.0e-12
    assert row["realized_eclipse_overlap_s"] == 21.0
    assert row["lighting_condition"] == "sunlit"
    assert row["planned_lighting_condition"] == "sunlit"
    assert row["realized_lighting_condition"] == "penumbra"
    assert row["lighting_condition_match_status"] == "mismatch"
    assert row["lighting_condition_detail"] == "partial_eclipse"
    assert row["lighting_detail_model"] == "provider_lighting_replay"
    assert row["lighting_confidence"] == 0.72

    assert get_in(row, ["source_activity_context", "lighting_condition"]) == "sunlit"

    assert get_in(row, ["source_activity_context", "lighting_condition_model"]) ==
             "declared_lighting_plan"

    assert_in_delta get_in(row, ["source_activity_context", "eclipse_overlap_fraction"]),
                    0.0,
                    1.0e-12

    assert_in_delta get_in(row, ["source_activity_context", "eclipse_overlap_s"]), 0.0, 1.0e-12
    assert get_in(row, ["realized_activity_context", "lighting_condition"]) == "penumbra"

    assert get_in(row, ["realized_activity_context", "lighting_condition_detail"]) ==
             "partial_eclipse"

    assert get_in(row, ["realized_activity_context", "lighting_detail_model"]) ==
             "provider_lighting_replay"

    assert get_in(row, ["realized_activity_context", "lighting_confidence"]) == 0.72
    assert get_in(row, ["realized_activity_context", "eclipse_overlap_fraction"]) == 0.35
    assert get_in(row, ["realized_activity_context", "eclipse_overlap_s"]) == 21.0

    review_row =
      Enum.find(
        report["operator_review_package"]["rows"],
        &(&1["activity_id"] == "obs_lighting")
      )

    assert %{
             "activity_id" => "obs_lighting",
             "eclipse_overlap_fraction" => 0.35,
             "realized_eclipse_overlap_fraction" => 0.35,
             "lighting_condition" => "sunlit",
             "planned_lighting_condition" => "sunlit",
             "realized_lighting_condition" => "penumbra",
             "lighting_condition_match_status" => "mismatch",
             "lighting_detail_model" => "provider_lighting_replay",
             "lighting_confidence" => 0.72
           } = review_row

    assert_in_delta review_row["planned_eclipse_overlap_fraction"], 0.0, 1.0e-12

    import_row =
      Enum.find(
        report["cadence_import_manifest"]["rows"],
        &(&1["activity_id"] == "obs_lighting")
      )

    assert %{
             "activity_id" => "obs_lighting",
             "eclipse_overlap_fraction" => 0.35,
             "realized_eclipse_overlap_fraction" => 0.35,
             "lighting_condition" => "sunlit",
             "planned_lighting_condition" => "sunlit",
             "realized_lighting_condition" => "penumbra",
             "lighting_condition_match_status" => "mismatch",
             "lighting_detail_model" => "provider_lighting_replay",
             "lighting_confidence" => 0.72
           } = import_row

    assert_in_delta import_row["planned_eclipse_overlap_fraction"], 0.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves observation quality evidence through realized feedback review and import rows" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.observe!(:obs_quality, 100.0, 160.0, :target_a,
            product_id: :image_planned,
            image_quality_score: 0.82,
            image_quality_status: :usable,
            image_quality_source: :planner_quality_model,
            cloud_cover_fraction: 0.15,
            blur_score: 0.04
          )
        ],
        [
          %{
            "id" => "provider_observation:quality",
            "planned_activity_id" => "obs_quality",
            "type" => "observe",
            "target_id" => "target_a",
            "status" => "completed",
            "product_id" => "image_realized",
            "quality_score" => "0.67",
            "quality_status" => "marginal",
            "quality_source" => "provider_image_assessment",
            "cloud_cover" => "0.42",
            "sharpness_loss_fraction" => "0.21"
          }
        ]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_quality"))

    assert row["image_quality_score"] == 0.67
    assert row["planned_image_quality_score"] == 0.82
    assert row["realized_image_quality_score"] == 0.67
    assert_in_delta row["image_quality_score_delta"], -0.15, 1.0e-12
    assert row["image_quality_status"] == "marginal"
    assert row["planned_image_quality_status"] == "usable"
    assert row["realized_image_quality_status"] == "marginal"
    assert row["image_quality_status_match_status"] == "mismatch"
    assert row["image_quality_source"] == "provider_image_assessment"
    assert row["cloud_cover_fraction"] == 0.42
    assert row["planned_cloud_cover_fraction"] == 0.15
    assert row["realized_cloud_cover_fraction"] == 0.42
    assert_in_delta row["cloud_cover_fraction_delta"], 0.27, 1.0e-12
    assert row["blur_score"] == 0.21
    assert row["planned_blur_score"] == 0.04
    assert row["realized_blur_score"] == 0.21
    assert_in_delta row["blur_score_delta"], 0.17, 1.0e-12

    assert get_in(row, ["source_activity_context", "image_quality_status"]) == "usable"
    assert get_in(row, ["realized_activity_context", "image_quality_status"]) == "marginal"

    assert get_in(row, ["realized_activity_context", "image_quality_source"]) ==
             "provider_image_assessment"

    assert report["operational_feedback"]["observation_success_rate"] == %{
             "target_a" => 0.67
           }

    assert "observation_success_rate" in report["operational_feedback_provenance"]["input_keys"]

    review_row =
      Enum.find(
        report["operator_review_package"]["rows"],
        &(&1["activity_id"] == "obs_quality")
      )

    assert %{
             "activity_id" => "obs_quality",
             "image_quality_score" => 0.67,
             "planned_image_quality_score" => 0.82,
             "realized_image_quality_score" => 0.67,
             "image_quality_status" => "marginal",
             "image_quality_status_match_status" => "mismatch",
             "cloud_cover_fraction" => 0.42,
             "blur_score" => 0.21
           } = review_row

    import_row =
      Enum.find(
        report["cadence_import_manifest"]["rows"],
        &(&1["activity_id"] == "obs_quality")
      )

    assert %{
             "activity_id" => "obs_quality",
             "image_quality_score" => 0.67,
             "planned_image_quality_score" => 0.82,
             "realized_image_quality_score" => 0.67,
             "image_quality_status" => "marginal",
             "image_quality_status_match_status" => "mismatch",
             "cloud_cover_fraction" => 0.42,
             "blur_score" => 0.21
           } = import_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "review-gates observation feedback when pointing target differs from the plan" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :obs_pointing,
            type: :observe,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            target_id: :target_a,
            pointing_target_id: :target_a,
            observation_success_factor: 1.0
          }
        ],
        [
          %{
            id: :obs_pointing_feedback,
            planned_activity_id: :obs_pointing,
            type: :observe,
            status: :completed,
            target_id: :target_a,
            pointing_target_id: :target_b,
            observation_success_factor: 1.0
          }
        ]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_pointing"))

    assert %{
             "pointing_target_match_status" => "mismatch",
             "identity_match_status" => "mismatch",
             "identity_mismatch_fields" => ["pointing_target"],
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_identity_mismatch",
             "operational_feedback_exclusion_reason" => "target_identity_mismatch_review_required"
           } = row

    assert report["operational_feedback"]["observation_success_rate"] == %{}

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "weights operational feedback averages from provider confidence" do
    planned = [
      %{
        id: :dl_good,
        type: :downlink,
        starts_at_s: 10.0,
        ends_at_s: 40.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        required_downlink_mb: 100.0
      },
      %{
        id: :dl_bad,
        type: :downlink,
        starts_at_s: 50.0,
        ends_at_s: 80.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        required_downlink_mb: 100.0
      },
      %{
        id: :dl_zero_confidence,
        type: :downlink,
        starts_at_s: 90.0,
        ends_at_s: 120.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        required_downlink_mb: 100.0
      }
    ]

    realized = [
      %{
        id: :dl_good,
        status: :completed,
        actual_throughput_mb: 100.0,
        contact_success_factor: 1.0,
        feedback_weight: 1.0,
        feedback_weight_source: :provider_sample_count
      },
      %{
        id: :dl_bad,
        status: :completed,
        actual_throughput_mb: 0.0,
        contact_success_factor: 0.0,
        feedback_weight: 3.0,
        feedback_weight_source: :provider_sample_count,
        trust_boundary: :provider_feedback_archive
      },
      %{
        id: :dl_zero_confidence,
        status: :completed,
        actual_throughput_mb: 100.0,
        contact_success_factor: 1.0,
        feedback_weight: 0.0,
        feedback_weight_source: :zero_confidence_provider
      }
    ]

    report = TimelineFeedback.reconcile(planned, realized)

    assert report["operational_feedback"]["contact_success_rate"] == %{"equator_prime" => 0.25}

    assert report["operational_feedback"]["station_throughput_factor"] == %{
             "equator_prime" => 0.25
           }

    assert report["operational_feedback"]["downlink_demand_mb"] == %{
             "equator_prime" => 300.0
           }

    assert "timeline_feedback.contact.required_downlink_mb:dl_bad" in get_in(
             report,
             ["operational_feedback", "downlink_demand_sources", "equator_prime"]
           )

    assert %{
             "weighted_feedback_row_count" => 2,
             "feedback_weight_sources" => ["provider_sample_count"],
             "feedback_trust_boundaries" => %{
               "contact_success_rate" => %{"equator_prime" => ["provider_feedback_archive"]},
               "downlink_demand_mb" => %{"equator_prime" => ["provider_feedback_archive"]},
               "downlink_demand_sources" => %{
                 "equator_prime" => ["provider_feedback_archive"]
               },
               "station_throughput_factor" => %{
                 "equator_prime" => ["provider_feedback_archive"]
               }
             }
           } = hd(report["operational_feedback_provenance"]["sources"])

    assert %{
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "provider_sample_count"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_bad"))

    zero_confidence_row =
      Enum.find(report["rows"], &(&1["activity_id"] == "dl_zero_confidence"))

    assert zero_confidence_row["feedback_weight"] == 0.0
    assert zero_confidence_row["feedback_weight_source"] == "zero_confidence_provider"

    assert %{
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "provider_sample_count"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_bad")
             )

    assert %{
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "provider_sample_count"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "dl_bad")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "derives contact feedback throughput from actual data rate and duration" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_actual_rate,
            type: :downlink,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 120.0,
            required_downlink_mb: 120.0
          }
        ],
        [
          %{
            id: :dl_actual_rate,
            status: :partial,
            actual_data_rate_mbps: 8.0,
            actual_duration_s: 60.0
          }
        ]
      )

    row = hd(report["rows"])

    assert row["actual_throughput_mb"] == 60.0
    assert row["throughput_completion_fraction"] == 0.5

    assert row["actual_data_rate_throughput_derivation"] == %{
             "derivation" => "actual_data_rate_times_duration",
             "rate_unit" => "Mbps",
             "actual_data_rate_mbps" => 8.0,
             "actual_data_rate_mb_s" => 1.0,
             "duration_s" => 60.0,
             "actual_throughput_mb" => 60.0
           }

    assert row["realized_activity_context"]["actual_data_rate_throughput_derivation"] ==
             row["actual_data_rate_throughput_derivation"]

    assert report["operational_feedback"]["station_throughput_factor"] == %{
             "equator_prime" => 0.5
           }

    assert report["operational_feedback"]["downlink_demand_mb"] == %{
             "equator_prime" => 60.0
           }

    assert get_in(
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_actual_rate")
             ),
             ["actual_data_rate_throughput_derivation"]
           ) == row["actual_data_rate_throughput_derivation"]

    assert get_in(
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "dl_actual_rate")
             ),
             ["actual_data_rate_throughput_derivation"]
           ) == row["actual_data_rate_throughput_derivation"]

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves invalid provider feedback scalars for review without clamping them" do
    planned = [
      %{
        id: :dl_provider,
        type: :downlink,
        starts_at_s: 10.0,
        ends_at_s: 40.0,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      Activity.command!(:cmd_provider, 50.0, 70.0, ground_station_id: :equator_prime),
      Activity.observe!(:obs_provider, 80.0, 120.0, :target_a),
      Activity.impulsive_burn!(:burn_provider, 130.0, {0.0, 0.01, 0.0})
    ]

    realized = [
      %{
        id: :dl_provider,
        status: :completed,
        type: :downlink,
        actual_throughput_mb: 100.0,
        contact_success_factor: 1.4,
        completed_fraction: 1.2,
        capacity_pack_capacity_fraction: 1.3,
        feedback_weight: -3.0,
        feedback_weight_source: :provider_confidence
      },
      %{
        id: :cmd_provider,
        status: :completed,
        type: :command,
        command_success_factor: -0.25
      },
      %{
        id: :obs_provider,
        status: :completed,
        type: :observe,
        observation_success_factor: 2.5,
        completed_fraction: -0.5
      },
      %{
        id: :burn_provider,
        status: :completed,
        type: :impulsive_burn,
        maneuver_success_factor: -0.2
      }
    ]

    report = TimelineFeedback.reconcile(planned, realized)

    downlink_row = Enum.find(report["rows"], &(&1["activity_id"] == "dl_provider"))
    refute Map.has_key?(downlink_row, "contact_success_factor")
    refute Map.has_key?(downlink_row, "completed_fraction")
    refute Map.has_key?(downlink_row, "capacity_pack_capacity_fraction")
    refute Map.has_key?(downlink_row, "feedback_weight")
    refute Map.has_key?(downlink_row, "feedback_weight_source")
    assert downlink_row["operational_feedback_excluded"] == true
    assert downlink_row["operational_feedback_status"] == "review_only_invalid_feedback_weight"

    assert downlink_row["operational_feedback_exclusion_reason"] ==
             "feedback_weight_invalid_review_required"

    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider"))
    refute Map.has_key?(command_row, "command_success_factor")

    observation_row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_provider"))
    refute Map.has_key?(observation_row, "observation_success_factor")
    refute Map.has_key?(observation_row, "completed_fraction")

    maneuver_row = Enum.find(report["rows"], &(&1["activity_id"] == "burn_provider"))
    refute Map.has_key?(maneuver_row, "maneuver_success_factor")

    assert %{
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "realized_feedback_sections_invalid",
             "invalid_realized_feedback_sections" => downlink_invalid_sections
           } = downlink_row

    assert %{
             "field" => "contact_success_factor",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.4
           } in downlink_invalid_sections

    assert %{
             "field" => "completed_fraction",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.2
           } in downlink_invalid_sections

    assert %{
             "field" => "capacity_pack_capacity_fraction",
             "reason" => "entry_must_be_unit_interval_number",
             "invalid_feedback_shape" => 1.3
           } in downlink_invalid_sections

    assert %{
             "field" => "feedback_weight",
             "reason" => "entry_must_be_nonnegative_number",
             "invalid_feedback_shape" => -3.0
           } in downlink_invalid_sections

    assert %{
             "invalid_realized_feedback_sections" => ^downlink_invalid_sections
           } = downlink_row["realized_activity_context"]

    assert downlink_row["realized_activity_context"]["invalid_realized_feedback_input_reason"] ==
             "realized_feedback_sections_invalid"

    assert report["operational_feedback_excluded_count"] == 1
    assert get_in(report, ["operational_feedback", "contact_success_rate"]) == %{}

    assert get_in(report, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_provider" => 1.0
           }

    assert get_in(report, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 1.0
           }

    assert get_in(report, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_provider" => 1.0
           }

    assert %{
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "realized_feedback_sections_invalid",
             "source_feedback" => %{
               "invalid_realized_feedback_sections" => ^downlink_invalid_sections
             }
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_provider")
             )

    assert %{
             "source_review_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "realized_feedback_sections_invalid",
             "source_feedback" => %{
               "invalid_realized_feedback_sections" => ^downlink_invalid_sections
             }
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "dl_provider")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "derives station throughput from required downlink when planned throughput is absent" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_required,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 360.0
          }
        ],
        [
          %{
            id: :dl_required,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0
          }
        ]
      )

    row = List.first(report["rows"])

    assert %{
             "activity_id" => "dl_required",
             "actual_throughput_mb" => 120.0,
             "throughput_completion_fraction" => completion_fraction,
             "required_downlink_mb" => 360.0
           } = row

    refute Map.has_key?(row, "planned_estimated_throughput_mb")
    refute Map.has_key?(row, "throughput_delta_mb")

    assert_in_delta completion_fraction, 120.0 / 360.0, 1.0e-12

    assert report["operational_feedback"]["station_throughput_factor"] == %{
             "equator_prime" => 120.0 / 360.0
           }

    assert report["operational_feedback"]["downlink_demand_mb"] == %{
             "equator_prime" => 240.0
           }

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "grades partial contact and command feedback instead of binary failure" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_partial,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0,
            required_downlink_mb: 300.0
          },
          Activity.command!(:cmd_partial, 50.0, 60.0, ground_station_id: :equator_prime)
        ],
        [
          %{
            id: :dl_partial,
            type: :downlink,
            status: :partial,
            actual_throughput_mb: 120.0
          },
          %{
            id: :cmd_partial,
            type: :command,
            status: :partial,
            completed_fraction: 0.25
          }
        ]
      )

    contact_row = Enum.find(report["rows"], &(&1["activity_id"] == "dl_partial"))
    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_partial"))

    refute Map.has_key?(contact_row, "contact_success")
    refute Map.has_key?(command_row, "command_success")

    assert %{
             "throughput_completion_fraction" => contact_fraction,
             "realized_status" => "partial"
           } = contact_row

    assert_in_delta contact_fraction, 120.0 / 300.0, 1.0e-12

    assert %{
             "completed_fraction" => 0.25,
             "realized_status" => "partial"
           } = command_row

    assert report["operational_feedback"]["contact_success_rate"] == %{
             "equator_prime" => 120.0 / 300.0
           }

    assert report["operational_feedback"]["station_throughput_factor"] == %{
             "equator_prime" => 120.0 / 300.0
           }

    assert report["operational_feedback"]["command_success_rate"] == %{
             "cmd_partial" => 0.25
           }

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses completed-fraction factors for completed contact and command feedback" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :dl_completed_partial,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 40.0
          },
          Activity.command!(:cmd_completed_partial, 50.0, 60.0, ground_station_id: :equator_prime)
        ],
        [
          %{
            id: :dl_completed_partial,
            type: :downlink,
            status: :completed,
            completed_fraction: 0.4
          },
          %{
            id: :cmd_completed_partial,
            type: :command,
            status: :completed,
            completed_fraction: 0.25
          }
        ]
      )

    contact_row = Enum.find(report["rows"], &(&1["activity_id"] == "dl_completed_partial"))
    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_completed_partial"))

    assert %{
             "contact_success" => true,
             "contact_success_factor" => 0.4,
             "contact_success_factor_source" => "realized_activity.completed_fraction"
           } = contact_row

    assert %{
             "command_success" => true,
             "command_success_factor" => 0.25,
             "command_success_factor_source" => "realized_activity.completed_fraction"
           } = command_row

    assert report["operational_feedback"]["contact_success_rate"] == %{
             "equator_prime" => 0.4
           }

    assert report["operational_feedback"]["command_success_rate"] == %{
             "cmd_completed_partial" => 0.25
           }

    assert %{
             "activity_id" => "dl_completed_partial",
             "required_operator_action" => "review_contact_variance",
             "reason" => "realized contact completed with partial completion fraction",
             "contact_success_factor" => 0.4,
             "contact_success_factor_source" => "realized_activity.completed_fraction"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_completed_partial")
             )

    assert %{
             "activity_id" => "cmd_completed_partial",
             "required_operator_action" => "review_command_variance",
             "reason" => "realized command activity completed with partial completion fraction",
             "command_success_factor" => 0.25,
             "command_success_factor_source" => "realized_activity.completed_fraction"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_completed_partial")
             )

    assert %{
             "activity_id" => "cmd_completed_partial",
             "source_review_action" => "review_command_variance",
             "command_success_factor" => 0.25,
             "command_success_factor_source" => "realized_activity.completed_fraction"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_completed_partial")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reconciles realized feedback with planned timeline integrity review evidence" do
    planned = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 35.0,
        ends_at_s: 45.0,
        approval_status: :approved,
        dependencies: [:cmd_1]
      },
      %{
        id: :late_gate,
        type: :health_check,
        starts_at_s: 35.0,
        ends_at_s: 45.0,
        approval_status: :approved
      },
      %{
        id: :cmd_1,
        type: :command,
        starts_at_s: 30.0,
        ends_at_s: 40.0,
        ground_station_id: :dss_14,
        dependencies: [:health_gate, :late_gate, :missing_gate],
        exclusive_with: [:dl_conflict],
        cadence_import: %{
          activity_type: :command_window,
          external_id: :cmd_1,
          schema_contract: :"command_window.v1"
        }
      },
      %{
        id: :dl_conflict,
        type: :downlink,
        starts_at_s: 32.0,
        ends_at_s: 38.0,
        ground_station_id: :dss_14
      }
    ]

    realized = [
      %{id: :health_gate, status: :completed},
      %{id: :late_gate, status: :completed},
      %{id: :cmd_feedback, planned_activity_id: :cmd_1, status: :completed, type: :command},
      %{id: :dl_conflict, status: :completed, type: :downlink}
    ]

    report =
      TimelineFeedback.reconcile(planned, realized, validate_missing_dependencies?: true)

    assert OrbitalDynamics.reconcile_timeline_feedback(
             planned,
             realized,
             validate_missing_dependencies?: true
           ) == report

    assert get_in(report, ["assumptions", "missing_dependency_validation"]) == "enabled"

    assert %{
             "activity_id" => "cmd_1",
             "status" => "matched",
             "planned_operator_action" => "review_timeline_integrity",
             "superseded_planned_operator_action" => "review_command_contact",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_cycle_activity_ids" => ["health_gate"],
             "dependency_order_violation_activity_ids" => ["late_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "source_activity_context" => %{
               "dependency_activity_ids" => ["health_gate", "late_gate", "missing_gate"],
               "dependency_cycle_activity_ids" => ["health_gate"],
               "exclusive_with_activity_ids" => ["dl_conflict"]
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert %{
             "required_operator_action" => "review_timeline_integrity",
             "activity_id" => "cmd_1",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_cycle_activity_ids" => ["health_gate"],
             "dependency_order_violation_activity_ids" => ["late_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"]
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_1")
             )

    assert %{
             "source_review_action" => "review_timeline_integrity",
             "activity_id" => "cmd_1",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_cycle_activity_ids" => ["health_gate"],
             "dependency_order_violation_activity_ids" => ["late_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"]
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reconciles command and contact execution semantics" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:1",
            "estimated_throughput_mb" => 120.0,
            "required_downlink_mb" => 120.0,
            "cadence_import" => %{"activity_type" => "contact_window"}
          },
          %{
            "id" => "cmd_repoint",
            "type" => "command",
            "starts_at_s" => 180.0,
            "ends_at_s" => 200.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command",
            "approval_status" => "approved",
            "cadence_import" => %{
              "activity_type" => "command",
              "external_id" => "cadence_cmd_repoint",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "status" => "partial",
            "actual_starts_at_s" => 102.0,
            "actual_ends_at_s" => 150.0,
            "actual_throughput_mb" => 72.0,
            "reason" => "provider reported reduced throughput"
          },
          %{
            "id" => "cmd_repoint",
            "type" => "command",
            "status" => "completed",
            "actual_starts_at_s" => 181.0,
            "actual_ends_at_s" => 199.0,
            "command_result" => "accepted"
          }
        ]
      )

    assert "no_schedule_mutation" in report["model_limits"]
    assert "no_command_execution" in report["model_limits"]
    assert report["feedback_kind_counts"] == %{"command" => 1, "contact" => 1}
    assert report["match_strategy_counts"] == %{"activity_id" => 2}
    assert report["cadence_import_status_counts"] == %{"present" => 2}
    assert report["planned_protection_decision_counts"] == %{"preserve" => 2}

    assert %{
             "feedback_kind" => "contact",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "source_window_id" => "access:leo_1:equator_prime:1",
             "cadence_import_status" => "present",
             "planned_estimated_throughput_mb" => 120.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -48.0,
             "throughput_completion_fraction" => 0.6,
             "required_downlink_mb" => 120.0,
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "partial"
             },
             "planned_protection_decision" => "preserve",
             "planned_protection_category" => "executed",
             "planned_protection_reason" => "activity_already_partial",
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed",
               "reason" => "activity_already_partial"
             },
             "source_activity_context" => %{
               "activity_id" => "downlink_equator",
               "source_window_id" => "access:leo_1:equator_prime:1",
               "timeline_identity" => %{
                 "activity_id" => "downlink_equator",
                 "source_window_id" => "access:leo_1:equator_prime:1"
               }
             },
             "realized_activity_context" => %{
               "activity_id" => "downlink_equator",
               "realized_activity_id" => "downlink_equator",
               "status" => "partial",
               "actual_throughput_mb" => 72.0
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "feedback_kind" => "command",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "command_success" => true,
             "command_result" => "accepted"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_repoint"))

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_contact_variance",
             "feedback_kind" => "contact",
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -48.0,
             "required_downlink_mb" => 120.0,
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "partial"
             },
             "planned_protection_decision" => "preserve",
             "planned_protection_category" => "executed",
             "planned_protection_reason" => "activity_already_partial",
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed",
               "reason" => "activity_already_partial"
             },
             "source_activity_context" => %{
               "source_window_id" => "access:leo_1:equator_prime:1"
             },
             "realized_activity_context" => %{
               "realized_activity_id" => "downlink_equator",
               "actual_throughput_mb" => 72.0
             }
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "downlink_equator",
             "source_activity_context" => %{
               "source_window_id" => "access:leo_1:equator_prime:1"
             },
             "realized_activity_context" => %{
               "realized_activity_id" => "downlink_equator",
               "actual_throughput_mb" => 72.0
             },
             "required_downlink_mb" => 120.0,
             "status_transition" => %{
               "field" => "status",
               "transition_type" => "changed",
               "from" => "planned",
               "to" => "partial"
             },
             "planned_protection_decision" => "preserve",
             "planned_protection_category" => "executed",
             "planned_protection_reason" => "activity_already_partial",
             "source_protection_decision" => %{
               "protection_decision" => "preserve",
               "protection_category" => "executed",
               "reason" => "activity_already_partial"
             },
             "import_activity_context" => %{
               "realized_activity_id" => "downlink_equator",
               "actual_throughput_mb" => 72.0
             }
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    refute Map.has_key?(
             Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator")),
             "contact_success"
           )

    assert report["operational_feedback"]["downlink_demand_mb"] == %{"equator_prime" => 48.0}

    assert "timeline_feedback.contact.required_downlink_mb:downlink_equator" in get_in(
             report,
             ["operational_feedback", "downlink_demand_sources", "equator_prime"]
           )

    assert report["operational_feedback"]["contact_success_rate"] == %{
             "equator_prime" => 0.6
           }

    assert %{
             "activity_id" => "cmd_repoint",
             "required_operator_action" => "record_command_completion",
             "feedback_kind" => "command",
             "command_success" => true
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_repoint")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])
  end

  test "normalizes numeric string planned and realized feedback evidence" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_string_feedback",
            "type" => "downlink",
            "starts_at_s" => "100.0",
            "ends_at_s" => "160.0",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "estimated_throughput_mb" => "120.0",
            "required_downlink_mb" => "120.0"
          }
        ],
        [
          %{
            "id" => "downlink_string_feedback",
            "type" => "downlink",
            "status" => "partial",
            "actual_starts_at_s" => "102.0",
            "actual_ends_at_s" => "150.0",
            "actual_throughput_mb" => "72.0",
            "completed_fraction" => "0.5",
            "contact_success_factor" => "0.5",
            "fuel_margin" => "0.7",
            "delta_v_km_s" => ["0.0", "0.001", "0.0"],
            "execution_uncertainty" => %{
              "timing_3sigma_s" => "2.0",
              "delta_v_3sigma_km_s" => ["0.0", "0.0001", "0.0"],
              "source" => "provider"
            }
          }
        ]
      )

    row = List.first(report["rows"])

    assert Map.take(row, [
             "activity_id",
             "planned_starts_at_s",
             "planned_ends_at_s",
             "actual_starts_at_s",
             "actual_ends_at_s",
             "start_delta_s",
             "end_delta_s",
             "planned_estimated_throughput_mb",
             "actual_throughput_mb",
             "throughput_delta_mb",
             "throughput_completion_fraction",
             "completed_fraction",
             "contact_success_factor",
             "fuel_margin",
             "timing_3sigma_s"
           ]) == %{
             "activity_id" => "downlink_string_feedback",
             "planned_starts_at_s" => 100.0,
             "planned_ends_at_s" => 160.0,
             "actual_starts_at_s" => 102.0,
             "actual_ends_at_s" => 150.0,
             "start_delta_s" => 2.0,
             "end_delta_s" => -10.0,
             "planned_estimated_throughput_mb" => 120.0,
             "actual_throughput_mb" => 72.0,
             "throughput_delta_mb" => -48.0,
             "throughput_completion_fraction" => 0.6,
             "completed_fraction" => 0.5,
             "contact_success_factor" => 0.5,
             "fuel_margin" => 0.7,
             "timing_3sigma_s" => 2.0
           }

    assert row["realized_delta_v_km_s"] == [0.0, 0.001, 0.0]
    assert row["delta_v_3sigma_km_s"] == [0.0, 0.0001, 0.0]

    assert Map.take(row["realized_activity_context"], [
             "actual_starts_at_s",
             "actual_ends_at_s",
             "actual_throughput_mb",
             "completed_fraction",
             "contact_success_factor",
             "fuel_margin",
             "timing_3sigma_s"
           ]) == %{
             "actual_starts_at_s" => 102.0,
             "actual_ends_at_s" => 150.0,
             "actual_throughput_mb" => 72.0,
             "completed_fraction" => 0.5,
             "contact_success_factor" => 0.5,
             "fuel_margin" => 0.7,
             "timing_3sigma_s" => 2.0
           }

    assert row["realized_activity_context"]["delta_v_km_s"] == [0.0, 0.001, 0.0]

    assert row["realized_activity_context"]["execution_uncertainty"][
             "delta_v_3sigma_km_s"
           ] == [0.0, 0.0001, 0.0]

    assert row["realized_activity_context"]["execution_uncertainty"]["timing_3sigma_s"] == 2.0

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "operational feedback normalizes numeric-string row evidence" do
    feedback =
      TimelineFeedback.operational_feedback([
        %{
          "activity_id" => "dl_string",
          "feedback_kind" => "contact",
          "ground_station_id" => "equator_prime",
          "realized_status" => "partial",
          "required_downlink_mb" => "120.0",
          "actual_throughput_mb" => "72.0",
          "throughput_completion_fraction" => "0.6",
          "contact_success_factor" => "0.5",
          "feedback_weight" => "2.0"
        },
        %{
          "activity_id" => "obs_string",
          "feedback_kind" => "observation",
          "target_id" => "target_a",
          "realized_status" => "partial",
          "planned_data_volume_mb" => "80.0",
          "completed_fraction" => "0.5",
          "observation_success_factor" => "0.25",
          "target_priority" => "9.0"
        },
        %{
          "activity_id" => "resource_string",
          "feedback_kind" => "observation",
          "target_id" => "target_b",
          "spacecraft_id" => "leo_1",
          "fuel_margin" => "0.7",
          "payload_available" => "false"
        },
        %{
          "activity_id" => "burn_string",
          "feedback_kind" => "maneuver",
          "realized_status" => "partial",
          "maneuver_success_factor" => "0.4",
          "execution_uncertainty_status" => "declared",
          "timing_3sigma_s" => "12.0",
          "delta_v_3sigma_km_s" => ["0.0", "0.001", "0.0"],
          "delta_v_3sigma_magnitude_km_s" => "0.001",
          "execution_uncertainty_source" => "provider_covariance"
        },
        %{
          "activity_id" => "cmd_string",
          "feedback_kind" => "command",
          "realized_status" => "partial",
          "command_success_factor" => "0.3"
        }
      ])

    assert feedback["contact_success_rate"] == %{"equator_prime" => 0.5}
    assert feedback["station_throughput_factor"] == %{"equator_prime" => 0.6}
    assert feedback["observation_success_rate"] == %{"target_a" => 0.25}

    assert feedback["downlink_demand_mb"] == %{
             "default" => 40.0,
             "equator_prime" => 96.0
           }

    assert feedback["target_priority_overrides"] == %{"target_a" => 9.0}
    assert feedback["resource_margin_overrides"] == %{"leo_1" => %{"fuel_margin" => 0.7}}

    assert feedback["resource_availability_overrides"] == %{
             "leo_1" => %{"payload_available" => false}
           }

    assert feedback["maneuver_success_rate"] == %{"burn_string" => 0.4}
    assert feedback["command_success_rate"] == %{"cmd_string" => 0.3}

    assert feedback["maneuver_execution_uncertainty"] == %{
             "burn_string" => %{
               "execution_uncertainty_status" => "declared",
               "timing_3sigma_s" => 12.0,
               "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.001,
               "execution_uncertainty_source" => "provider_covariance"
             }
           }
  end

  test "operational feedback ignores non-stable direct row keys" do
    feedback =
      TimelineFeedback.operational_feedback([
        %{
          "activity_id" => "dl_bad",
          "feedback_kind" => "contact",
          "ground_station_id" => "bad station",
          "required_downlink_mb" => 120.0,
          "actual_throughput_mb" => 60.0,
          "contact_success_factor" => 0.5
        },
        %{
          "activity_id" => "obs_bad",
          "feedback_kind" => "observation",
          "target_id" => "bad target",
          "planned_data_volume_mb" => 50.0,
          "completed_fraction" => 0.5,
          "observation_success_factor" => 0.25,
          "target_priority" => 8.0
        },
        %{
          "activity_id" => "resource_bad",
          "feedback_kind" => "observation",
          "spacecraft_id" => "bad spacecraft",
          "fuel_margin" => 0.2,
          "payload_available" => false
        },
        %{
          "activity_id" => "bad burn",
          "feedback_kind" => "maneuver",
          "maneuver_success_factor" => 0.4,
          "execution_uncertainty_status" => "declared",
          "timing_3sigma_s" => 12.0
        },
        %{
          "activity_id" => "bad command",
          "feedback_kind" => "command",
          "command_success_factor" => 0.3
        },
        %{
          "activity_id" => "cmd_good",
          "feedback_kind" => "command",
          "command_success_factor" => 0.9
        }
      ])

    assert feedback["contact_success_rate"] == %{}
    assert feedback["station_throughput_factor"] == %{}
    assert feedback["observation_success_rate"] == %{}
    assert feedback["downlink_demand_mb"] == %{}
    assert feedback["target_priority_overrides"] == %{}
    assert feedback["resource_margin_overrides"] == %{}
    assert feedback["resource_availability_overrides"] == %{}
    assert feedback["maneuver_success_rate"] == %{}
    assert feedback["maneuver_execution_uncertainty"] == %{}
    assert feedback["command_success_rate"] == %{"cmd_good" => 0.9}
  end

  test "carries locked and approved protection evidence for failed realized feedback" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.command!(:cmd_repoint, 180.0, 200.0,
            ground_station_id: :equator_prime,
            approval_status: :approved,
            locked?: true
          )
        ],
        [
          %{
            "id" => "cmd_repoint",
            "type" => "command",
            "status" => "failed",
            "actual_starts_at_s" => 181.0,
            "actual_ends_at_s" => 199.0,
            "command_result" => "rejected"
          }
        ]
      )

    expected_protection = %{
      "protection_decision" => "review_change",
      "protection_category" => "locked_or_approved",
      "reason" => "realized_status_failed_requires_repair_review"
    }

    assert %{
             "activity_id" => "cmd_repoint",
             "planned_protection_decision" => "review_change",
             "planned_protection_category" => "locked_or_approved",
             "planned_protection_reason" => "realized_status_failed_requires_repair_review",
             "source_protection_decision" => source_protection
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_repoint"))

    assert Map.take(source_protection, Map.keys(expected_protection)) == expected_protection

    assert %{
             "activity_id" => "cmd_repoint",
             "planned_protection_decision" => "review_change",
             "planned_protection_category" => "locked_or_approved",
             "planned_protection_reason" => "realized_status_failed_requires_repair_review",
             "source_protection_decision" => source_review_protection
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_repoint")
             )

    assert Map.take(source_review_protection, Map.keys(expected_protection)) ==
             expected_protection

    assert %{
             "activity_id" => "cmd_repoint",
             "planned_protection_decision" => "review_change",
             "planned_protection_category" => "locked_or_approved",
             "planned_protection_reason" => "realized_status_failed_requires_repair_review",
             "source_protection_decision" => source_import_protection
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_repoint")
             )

    assert Map.take(source_import_protection, Map.keys(expected_protection)) ==
             expected_protection

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "review-gates completed contact feedback with planned realized identity mismatch" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:1",
            "estimated_throughput_mb" => 120.0,
            "cadence_import" => %{
              "activity_type" => "contact_window",
              "external_id" => "cadence_downlink_equator",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_contact:polar",
            "planned_activity_id" => "downlink_equator",
            "timeline_id" => "timeline:contact:leo_1:polar_prime:1",
            "type" => "downlink",
            "status" => "completed",
            "ground_station_id" => "polar_prime",
            "direction" => "uplink",
            "source_window_id" => "access:leo_1:polar_prime:1",
            "actual_throughput_mb" => 120.0
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "status" => "matched",
             "planned_direction" => "downlink",
             "realized_direction" => "uplink",
             "direction_match_status" => "mismatch",
             "planned_ground_station_id" => "equator_prime",
             "realized_ground_station_id" => "polar_prime",
             "ground_station_match_status" => "mismatch",
             "planned_source_window_id" => "access:leo_1:equator_prime:1",
             "realized_source_window_id" => "access:leo_1:polar_prime:1",
             "source_window_match_status" => "mismatch",
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_identity_mismatch",
             "operational_feedback_exclusion_reason" =>
               "contact_identity_mismatch_review_required"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert report["operational_feedback_excluded_count"] == 1

    assert report["operational_feedback"] == %{
             "contact_success_rate" => %{},
             "station_throughput_factor" => %{},
             "observation_success_rate" => %{},
             "image_quality_score" => %{},
             "image_quality_status" => %{},
             "image_quality_source" => %{},
             "cloud_cover_fraction" => %{},
             "blur_score" => %{},
             "downlink_demand_mb" => %{},
             "downlink_demand_sources" => %{},
             "target_priority_overrides" => %{},
             "resource_margin_overrides" => %{},
             "resource_availability_overrides" => %{},
             "maneuver_success_rate" => %{},
             "maneuver_execution_uncertainty" => %{},
             "command_success_rate" => %{}
           }

    assert get_in(
             report,
             [
               "operational_feedback_provenance",
               "sources",
               Access.at(0),
               "source_operational_feedback_excluded_count"
             ]
           ) == 1

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_contact_variance",
             "approval_status" => "operator_review_required",
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_identity_mismatch",
             "direction_match_status" => "mismatch",
             "ground_station_match_status" => "mismatch",
             "source_window_match_status" => "mismatch"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "downlink_equator",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_contact_variance",
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_identity_mismatch",
             "direction_match_status" => "mismatch",
             "ground_station_match_status" => "mismatch",
             "source_window_match_status" => "mismatch"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "normalizes megabyte-per-second link-rate aliases to megabits per second" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_link_rate_alias",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "downlink_rate_mb_s" => 1.0,
            "estimated_throughput_mb" => 60.0
          }
        ],
        [
          %{
            "id" => "provider_contact:link_rate_alias",
            "planned_activity_id" => "downlink_link_rate_alias",
            "type" => "downlink",
            "status" => "completed",
            "ground_station_id" => "equator_prime",
            "throughput_model" => %{"actual_data_rate_mb_s" => 0.5, "actual_duration_s" => 60.0}
          }
        ]
      )

    assert %{
             "planned_data_rate_mbps" => 8.0,
             "realized_data_rate_mbps" => 4.0,
             "data_rate_delta_mbps" => -4.0,
             "actual_throughput_mb" => 30.0,
             "actual_data_rate_throughput_derivation" => %{
               "derivation" => "actual_data_rate_times_duration",
               "rate_unit" => "MB/s",
               "actual_data_rate_mb_s" => 0.5,
               "duration_s" => 60.0,
               "actual_throughput_mb" => 30.0
             },
             "throughput_completion_fraction" => 0.5
           } = hd(report["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "review-gates completed contact feedback with planned realized link profile mismatch" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_link_profile",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:1",
            "frequency_band" => "x_band",
            "link_protocol" => "space_packet",
            "modulation" => "qpsk",
            "coding_scheme" => "ldpc",
            "polarization" => "rhcp",
            "data_rate_mbps" => 8.0,
            "estimated_throughput_mb" => 120.0,
            "cadence_import" => %{
              "activity_type" => "contact_window",
              "external_id" => "cadence_downlink_link_profile",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_contact:link_profile",
            "planned_activity_id" => "downlink_link_profile",
            "type" => "downlink",
            "status" => "completed",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:1",
            "frequency_band" => "s_band",
            "link_protocol" => "space_packet",
            "modulation" => "bpsk",
            "coding_scheme" => "convolutional",
            "polarization" => "lhcp",
            "data_rate_mbps" => 4.0,
            "actual_throughput_mb" => 120.0
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_link_profile",
             "status" => "matched",
             "planned_frequency_band" => "x_band",
             "realized_frequency_band" => "s_band",
             "frequency_band_match_status" => "mismatch",
             "planned_modulation" => "qpsk",
             "realized_modulation" => "bpsk",
             "modulation_match_status" => "mismatch",
             "planned_coding_scheme" => "ldpc",
             "realized_coding_scheme" => "convolutional",
             "coding_scheme_match_status" => "mismatch",
             "planned_polarization" => "rhcp",
             "realized_polarization" => "lhcp",
             "polarization_match_status" => "mismatch",
             "planned_data_rate_mbps" => 8.0,
             "realized_data_rate_mbps" => 4.0,
             "data_rate_delta_mbps" => -4.0,
             "identity_match_status" => "mismatch",
             "identity_mismatch_fields" => [
               "frequency_band",
               "modulation",
               "coding_scheme",
               "polarization"
             ],
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_identity_mismatch",
             "operational_feedback_exclusion_reason" =>
               "contact_identity_mismatch_review_required"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_link_profile"))

    assert report["operational_feedback_excluded_count"] == 1
    assert report["operational_feedback"]["station_throughput_factor"] == %{}

    assert %{
             "activity_id" => "downlink_link_profile",
             "required_operator_action" => "review_contact_variance",
             "frequency_band_match_status" => "mismatch",
             "modulation_match_status" => "mismatch",
             "coding_scheme_match_status" => "mismatch",
             "polarization_match_status" => "mismatch",
             "operational_feedback_excluded" => true
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_link_profile")
             )

    assert %{
             "activity_id" => "downlink_link_profile",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_contact_variance",
             "frequency_band_match_status" => "mismatch",
             "modulation_match_status" => "mismatch",
             "coding_scheme_match_status" => "mismatch",
             "polarization_match_status" => "mismatch",
             "operational_feedback_excluded" => true
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_link_profile")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "review-gates completed contact feedback with failed realized link quality" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_link_quality",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:2",
            "frequency_band" => "x_band",
            "modulation" => "qpsk",
            "data_rate_mbps" => 8.0,
            "link_margin_db" => 3.0,
            "carrier_lock" => true,
            "symbol_lock" => true,
            "estimated_throughput_mb" => 120.0,
            "cadence_import" => %{
              "activity_type" => "contact_window",
              "external_id" => "cadence_downlink_link_quality",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_contact:link_quality",
            "planned_activity_id" => "downlink_link_quality",
            "type" => "downlink",
            "status" => "completed",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "source_window_id" => "access:leo_1:equator_prime:2",
            "frequency_band" => "x_band",
            "modulation" => "qpsk",
            "data_rate_mbps" => 8.0,
            "link_margin_db" => -1.5,
            "snr_db" => 2.0,
            "eb_no_db" => 0.5,
            "bit_error_rate" => 0.02,
            "packet_loss_rate" => 0.25,
            "frame_loss_rate" => 0.1,
            "carrier_lock" => false,
            "symbol_lock" => false,
            "link_quality_status" => "Low Margin",
            "actual_throughput_mb" => 120.0
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_link_quality",
             "status" => "matched",
             "frequency_band_match_status" => "matched",
             "modulation_match_status" => "matched",
             "planned_link_margin_db" => 3.0,
             "realized_link_margin_db" => -1.5,
             "link_margin_delta_db" => -4.5,
             "realized_carrier_lock" => false,
             "realized_symbol_lock" => false,
             "realized_link_quality_status" => "Low Margin",
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_link_quality",
             "operational_feedback_exclusion_reason" => "contact_link_quality_review_required"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_link_quality"))

    assert report["operational_feedback_excluded_count"] == 1
    assert report["operational_feedback"]["contact_success_rate"] == %{}
    assert report["operational_feedback"]["station_throughput_factor"] == %{}

    assert %{
             "activity_id" => "downlink_link_quality",
             "required_operator_action" => "review_contact_variance",
             "operational_feedback_status" => "review_only_link_quality",
             "realized_link_margin_db" => -1.5,
             "realized_carrier_lock" => false,
             "realized_link_quality_status" => "Low Margin"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_link_quality")
             )

    assert %{
             "activity_id" => "downlink_link_quality",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_contact_variance",
             "operational_feedback_status" => "review_only_link_quality",
             "realized_link_margin_db" => -1.5,
             "realized_carrier_lock" => false,
             "realized_link_quality_status" => "Low Margin"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_link_quality")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "review-gates completed observation feedback with planned realized identity mismatch" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "obs_target_a",
            "type" => "observe",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "target_id" => "target_a",
            "resource_id" => "payload_power_bus_a",
            "collection_id" => "collection_alpha",
            "product_id" => "product_planned",
            "product_ids" => ["product_planned", "product_secondary"],
            "payload_id" => "payload_wac",
            "instrument_id" => "instrument_visible",
            "cadence_import" => %{
              "activity_type" => "observation",
              "external_id" => "cadence_obs_target_a",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_obs:target_b",
            "planned_activity_id" => "obs_target_a",
            "type" => "observe",
            "status" => "completed",
            "target_id" => "target_b",
            "resource_id" => "payload_power_bus_b",
            "collection_id" => "collection_beta",
            "product_id" => "product_realized",
            "product_ids" => ["product_realized"],
            "payload_id" => "payload_nac",
            "instrument_id" => "instrument_ir"
          }
        ]
      )

    assert %{
             "activity_id" => "obs_target_a",
             "status" => "matched",
             "planned_target_id" => "target_a",
             "realized_target_id" => "target_b",
             "target_match_status" => "mismatch",
             "planned_resource_id" => "payload_power_bus_a",
             "realized_resource_id" => "payload_power_bus_b",
             "resource_match_status" => "mismatch",
             "identity_match_status" => "mismatch",
             "identity_mismatch_fields" => [
               "target",
               "resource",
               "collection",
               "product",
               "product_ids",
               "payload",
               "instrument"
             ],
             "identity_mismatch_count" => 7,
             "planned_collection_id" => "collection_alpha",
             "realized_collection_id" => "collection_beta",
             "collection_match_status" => "mismatch",
             "planned_product_id" => "product_planned",
             "realized_product_id" => "product_realized",
             "product_match_status" => "mismatch",
             "planned_product_ids" => ["product_planned", "product_secondary"],
             "realized_product_ids" => ["product_realized"],
             "product_ids_match_status" => "mismatch",
             "planned_payload_id" => "payload_wac",
             "realized_payload_id" => "payload_nac",
             "payload_match_status" => "mismatch",
             "planned_instrument_id" => "instrument_visible",
             "realized_instrument_id" => "instrument_ir",
             "instrument_match_status" => "mismatch"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_target_a"))

    assert %{
             "activity_id" => "obs_target_a",
             "required_operator_action" => "review_realized_variance",
             "approval_status" => "operator_review_required",
             "target_match_status" => "mismatch",
             "resource_match_status" => "mismatch",
             "identity_match_status" => "mismatch",
             "identity_mismatch_fields" => [
               "target",
               "resource",
               "collection",
               "product",
               "product_ids",
               "payload",
               "instrument"
             ],
             "identity_mismatch_count" => 7,
             "product_match_status" => "mismatch",
             "payload_match_status" => "mismatch"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_target_a")
             )

    assert %{
             "activity_id" => "obs_target_a",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_realized_variance",
             "target_match_status" => "mismatch",
             "resource_match_status" => "mismatch",
             "identity_match_status" => "mismatch",
             "identity_mismatch_fields" => [
               "target",
               "resource",
               "collection",
               "product",
               "product_ids",
               "payload",
               "instrument"
             ],
             "identity_mismatch_count" => 7,
             "product_ids_match_status" => "mismatch"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_target_a")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "review-gates completed observation feedback with resource availability variance" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "obs_resource_variance",
            "type" => "observe",
            "status" => "planned",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "target_id" => "target_a",
            "spacecraft_available" => true,
            "payload_available" => true,
            "antenna_available" => true,
            "degraded" => false,
            "mode" => "nominal",
            "cadence_import" => %{
              "activity_type" => "observation",
              "external_id" => "cadence_obs_resource_variance",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_obs_resource_variance",
            "planned_activity_id" => "obs_resource_variance",
            "type" => "observe",
            "status" => "completed",
            "target_id" => "target_a",
            "spacecraft_available" => false,
            "payload_available" => false,
            "antenna_available" => false,
            "degraded" => true,
            "mode" => "safe"
          }
        ]
      )

    assert %{
             "activity_id" => "obs_resource_variance",
             "status" => "matched",
             "spacecraft_available" => false,
             "planned_spacecraft_available" => true,
             "realized_spacecraft_available" => false,
             "spacecraft_available_match_status" => "mismatch",
             "payload_available" => false,
             "planned_payload_available" => true,
             "realized_payload_available" => false,
             "payload_available_match_status" => "mismatch",
             "antenna_available" => false,
             "planned_antenna_available" => true,
             "realized_antenna_available" => false,
             "antenna_available_match_status" => "mismatch",
             "degraded" => true,
             "planned_degraded" => false,
             "realized_degraded" => true,
             "degraded_match_status" => "mismatch",
             "mode" => "safe",
             "planned_mode" => "nominal",
             "realized_mode" => "safe",
             "mode_match_status" => "mismatch",
             "operational_feedback_excluded" => true,
             "operational_feedback_status" => "review_only_resource_variance",
             "operational_feedback_exclusion_reason" =>
               "resource_availability_variance_review_required"
           } = row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_resource_variance"))

    refute Map.has_key?(row, "identity_match_status")
    refute Map.has_key?(row, "identity_mismatch_fields")
    assert report["operational_feedback_excluded_count"] == 1

    assert %{
             "activity_id" => "obs_resource_variance",
             "required_operator_action" => "review_realized_variance",
             "approval_status" => "operator_review_required",
             "spacecraft_available_match_status" => "mismatch",
             "payload_available_match_status" => "mismatch",
             "antenna_available_match_status" => "mismatch",
             "degraded_match_status" => "mismatch",
             "mode_match_status" => "mismatch",
             "planned_mode" => "nominal",
             "realized_mode" => "safe"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_resource_variance")
             )

    assert %{
             "activity_id" => "obs_resource_variance",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_realized_variance",
             "spacecraft_available_match_status" => "mismatch",
             "payload_available_match_status" => "mismatch",
             "antenna_available_match_status" => "mismatch",
             "degraded_match_status" => "mismatch",
             "mode_match_status" => "mismatch",
             "planned_mode" => "nominal",
             "realized_mode" => "safe"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_resource_variance")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "ignores malformed planned and realized product ids instead of creating phantom mismatches" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "obs_target_a",
            "type" => "observe",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "target_id" => "target_a",
            "product_id" => "product_planned",
            "product_ids" => [
              nil,
              false,
              "bad planned product id",
              %{"id" => nil},
              %{"product_id" => "bad nested planned product id"},
              %{"product_id" => "product_planned"},
              "product_secondary"
            ]
          }
        ],
        [
          %{
            "id" => "provider_obs:target_a",
            "planned_activity_id" => "obs_target_a",
            "type" => "observe",
            "status" => "completed",
            "target_id" => "target_a",
            "product_id" => "product_planned",
            "product_ids" => [
              nil,
              true,
              "bad realized product id",
              %{"product_id" => nil},
              %{"product_id" => "bad nested realized product id"},
              "product_planned",
              "product_secondary"
            ],
            "collection_id" => "bad realized collection id",
            "payload_id" => "bad realized payload id",
            "instrument_id" => "bad realized instrument id"
          }
        ]
      )

    assert %{
             "planned_product_ids" => ["product_planned", "product_secondary"],
             "realized_product_ids" => ["product_planned", "product_secondary"],
             "product_ids_match_status" => "matched"
           } = row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_target_a"))

    refute "nil" in row["planned_product_ids"]
    refute "false" in row["planned_product_ids"]
    refute "bad planned product id" in row["planned_product_ids"]
    refute "bad nested planned product id" in row["planned_product_ids"]
    refute "true" in row["realized_product_ids"]
    refute "bad realized product id" in row["realized_product_ids"]
    refute "bad nested realized product id" in row["realized_product_ids"]
    refute Map.has_key?(row, "collection_id")
    refute Map.has_key?(row, "payload_id")
    refute Map.has_key?(row, "instrument_id")

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves command and contact success factors through feedback review and import" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :downlink_feedback,
            type: :downlink,
            direction: :downlink,
            ground_station_id: :equator_prime,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            estimated_throughput_mb: 120.0,
            contact_success_factor: 0.42,
            contact_success_factor_source: :"operational_feedback.contact_success_rate.station",
            throughput_model: %{
              contact_success_factor: 0.42,
              confidence_source: :"operational_feedback.contact_success_rate.station"
            }
          },
          %{
            id: :cmd_feedback,
            type: :command,
            direction: :command,
            ground_station_id: :equator_prime,
            starts_at_s: 200.0,
            ends_at_s: 220.0,
            command_success_factor: 0.7,
            command_success_factor_source: :"planned.command_success_rate"
          },
          %{
            id: :obs_feedback,
            type: :observe,
            target_id: :target_a,
            starts_at_s: 300.0,
            ends_at_s: 360.0,
            observation_success_factor: 0.8,
            observation_success_factor_source:
              :"operational_feedback.observation_success_rate.target"
          }
        ],
        [
          %{
            id: :downlink_feedback,
            type: :downlink,
            status: :completed,
            actual_throughput_mb: 120.0
          },
          %{
            id: :provider_command_feedback,
            planned_activity_id: :cmd_feedback,
            type: :command,
            status: :completed,
            command_result: :accepted,
            command_success_factor: 0.35,
            command_success_factor_source: :"provider.command_success_rate"
          },
          %{
            id: :provider_observation_feedback,
            planned_activity_id: :obs_feedback,
            type: :observe,
            status: :completed,
            completed_fraction: 1.0,
            observation_success_factor: 0.55,
            observation_success_factor_source: :"provider.observation_success_rate"
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_feedback",
             "feedback_kind" => "contact",
             "contact_success" => true,
             "contact_success_factor" => 0.42,
             "contact_success_factor_source" =>
               "operational_feedback.contact_success_rate.station",
             "source_activity_context" => %{
               "contact_success_factor" => 0.42,
               "contact_success_factor_source" =>
                 "operational_feedback.contact_success_rate.station"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_feedback"))

    assert %{
             "activity_id" => "cmd_feedback",
             "feedback_kind" => "command",
             "command_success" => true,
             "command_success_factor" => 0.35,
             "command_success_factor_source" => "provider.command_success_rate",
             "realized_activity_context" => %{
               "command_success_factor" => 0.35,
               "command_success_factor_source" => "provider.command_success_rate"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_feedback"))

    assert %{
             "activity_id" => "obs_feedback",
             "feedback_kind" => "observation",
             "observation_success_factor" => 0.55,
             "observation_success_factor_source" => "provider.observation_success_rate",
             "source_activity_context" => %{
               "observation_success_factor" => 0.8,
               "observation_success_factor_source" =>
                 "operational_feedback.observation_success_rate.target"
             },
             "realized_activity_context" => %{
               "observation_success_factor" => 0.55,
               "observation_success_factor_source" => "provider.observation_success_rate"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_feedback"))

    assert %{
             "activity_id" => "downlink_feedback",
             "contact_success_factor" => 0.42,
             "contact_success_factor_source" =>
               "operational_feedback.contact_success_rate.station"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_feedback")
             )

    assert %{
             "activity_id" => "cmd_feedback",
             "command_success_factor" => 0.35,
             "command_success_factor_source" => "provider.command_success_rate"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_feedback")
             )

    assert %{
             "activity_id" => "obs_feedback",
             "observation_success_factor" => 0.55,
             "observation_success_factor_source" => "provider.observation_success_rate"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_feedback")
             )

    assert %{
             "activity_id" => "downlink_feedback",
             "contact_success_factor" => 0.42,
             "contact_success_factor_source" =>
               "operational_feedback.contact_success_rate.station"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_feedback")
             )

    assert %{
             "activity_id" => "cmd_feedback",
             "command_success_factor" => 0.35,
             "command_success_factor_source" => "provider.command_success_rate"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_feedback")
             )

    assert %{
             "activity_id" => "obs_feedback",
             "observation_success_factor" => 0.55,
             "observation_success_factor_source" => "provider.observation_success_rate"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_feedback")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "accepts executed cancelled and rejected realized provider statuses" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_executed",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "cadence_downlink_executed",
              "schema_contract" => "proposed_contact.v1"
            }
          },
          %{
            "id" => "downlink_cancelled",
            "type" => "downlink",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "approval_status" => "approved"
          },
          %{
            "id" => "cmd_rejected",
            "type" => "command",
            "starts_at_s" => 300.0,
            "ends_at_s" => 320.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command",
            "approval_status" => "approved"
          },
          %{
            "id" => "obs_executed",
            "type" => "observe",
            "starts_at_s" => 400.0,
            "ends_at_s" => 460.0,
            "target_id" => "target_a"
          },
          %{
            "id" => "obs_rejected",
            "type" => "observe",
            "starts_at_s" => 500.0,
            "ends_at_s" => 560.0,
            "target_id" => "target_b"
          }
        ],
        [
          %{
            "id" => "downlink_executed",
            "type" => "downlink",
            "status" => "executed"
          },
          %{
            "id" => "downlink_cancelled",
            "type" => "downlink",
            "status" => " Cancelled "
          },
          %{
            "id" => "cmd_rejected",
            "type" => "command",
            "status" => " REJECTED "
          },
          %{
            "id" => "obs_executed",
            "type" => "observe",
            "status" => "executed"
          },
          %{
            "id" => "obs_rejected",
            "type" => "observe",
            "status" => "rejected"
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_executed",
             "realized_status" => "executed",
             "contact_success" => true,
             "planned_protection_decision" => "preserve",
             "planned_protection_reason" => "activity_already_executed"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_executed"))

    assert %{
             "activity_id" => "downlink_cancelled",
             "realized_status" => "cancelled",
             "contact_success" => false,
             "planned_protection_decision" => "review_change",
             "planned_protection_reason" => "realized_status_cancelled_requires_repair_review"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_cancelled"))

    assert %{
             "activity_id" => "cmd_rejected",
             "realized_status" => "rejected",
             "command_success" => false,
             "planned_protection_decision" => "review_change",
             "planned_protection_reason" => "realized_status_rejected_requires_repair_review"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_rejected"))

    assert %{
             "activity_id" => "obs_executed",
             "realized_status" => "executed",
             "planned_protection_decision" => "preserve",
             "planned_protection_reason" => "activity_already_executed"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_executed"))

    assert %{
             "activity_id" => "obs_rejected",
             "realized_status" => "rejected",
             "planned_protection_decision" => "mutable",
             "planned_protection_reason" => "no_timeline_protection"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_rejected"))

    assert %{
             "activity_id" => "downlink_executed",
             "approval_status" => "not_required",
             "required_operator_action" => "record_contact_completion",
             "reason" => "realized contact executed"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_executed")
             )

    assert %{
             "activity_id" => "downlink_cancelled",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_contact_exception",
             "reason" => "realized contact ended with cancelled status"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_cancelled")
             )

    assert %{
             "activity_id" => "cmd_rejected",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_command_exception",
             "reason" => "realized command activity ended with rejected status"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_rejected")
             )

    assert %{
             "activity_id" => "obs_executed",
             "approval_status" => "not_required",
             "required_operator_action" => "record_realized_completion",
             "reason" => "realized activity executed"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_executed")
             )

    assert %{
             "activity_id" => "obs_rejected",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_realized_exception",
             "reason" => "realized activity ended with rejected status"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_rejected")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "matches realized feedback by planned activity id and timeline id" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "dependency_activity_ids" => ["cmd_prereq"],
            "dependency_timeline_ids" => ["timeline:cmd_prereq"],
            "exclusive_with_activity_ids" => ["dl_conflict"],
            "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "cadence_downlink_equator",
              "schema_contract" => "proposed_contact.v1"
            }
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
            "ground_station_id" => "equator_prime",
            "metadata" => %{"timeline_id" => "timeline:command:upload"}
          }
        ],
        [
          %{
            "id" => "provider_contact:123",
            "planned_activity_id" => "downlink_equator",
            "status" => "completed",
            "actual_starts_at_s" => 101.0,
            "actual_ends_at_s" => 161.0,
            "actual_throughput_mb" => 95.0
          },
          %{
            "id" => "provider_command:456",
            "timeline_id" => "timeline:command:upload",
            "type" => "command",
            "status" => "completed",
            "actual_starts_at_s" => 202.0,
            "actual_ends_at_s" => 219.0,
            "command_result" => "accepted"
          }
        ]
      )

    assert report["status_counts"] == %{"matched" => 2}

    assert %{
             "activity_id" => "downlink_equator",
             "realized_activity_id" => "provider_contact:123",
             "match_strategy" => "planned_activity_id",
             "status" => "matched",
             "timeline_identity" => %{
               "timeline_id" => "timeline:downlink:equator_prime:100.0",
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "subject_id" => "equator_prime"
             },
             "dependency_activity_ids" => ["cmd_prereq"],
             "dependency_timeline_ids" => ["timeline:cmd_prereq"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "cadence_import_status" => "present",
             "cadence_import_type" => "contact",
             "cadence_import_id" => "cadence_downlink_equator",
             "cadence_import_contract" => "proposed_contact.v1",
             "has_cadence_import" => true,
             "planned_activity" => %{
               "id" => "downlink_equator",
               "type" => "downlink",
               "ground_station_id" => "equator_prime"
             },
             "realized_activity" => %{
               "id" => "provider_contact:123",
               "planned_activity_id" => "downlink_equator",
               "actual_throughput_mb" => 95.0
             },
             "realized_activity_context" => %{
               "activity_id" => "downlink_equator",
               "planned_activity_id" => "downlink_equator",
               "matched_planned_activity_id" => "downlink_equator",
               "match_strategy" => "planned_activity_id",
               "realized_activity_id" => "provider_contact:123"
             },
             "contact_success" => true
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "cmd_upload",
             "planned_timeline_id" => "timeline:command:upload",
             "realized_timeline_id" => "timeline:command:upload",
             "realized_activity_id" => "provider_command:456",
             "match_strategy" => "timeline_id",
             "timeline_identity" => %{"timeline_id" => "timeline:command:upload"},
             "realized_activity_context" => %{
               "activity_id" => "provider_command:456",
               "matched_planned_activity_id" => "cmd_upload",
               "match_strategy" => "timeline_id",
               "realized_activity_id" => "provider_command:456",
               "timeline_id" => "timeline:command:upload",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:command:upload",
                 "activity_id" => "provider_command:456",
                 "activity_type" => "command"
               }
             },
             "realized_type" => "command",
             "status" => "matched",
             "command_success" => true
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_upload"))

    assert %{
             "activity_id" => "downlink_equator",
             "timeline_identity" => %{
               "timeline_id" => "timeline:downlink:equator_prime:100.0",
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "subject_id" => "equator_prime"
             },
             "dependency_activity_ids" => ["cmd_prereq"],
             "dependency_timeline_ids" => ["timeline:cmd_prereq"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "cadence_import_status" => "present",
             "cadence_import_type" => "contact",
             "cadence_import_id" => "cadence_downlink_equator",
             "cadence_import_contract" => "proposed_contact.v1",
             "has_cadence_import" => true
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "cmd_upload",
             "activity_type" => "command",
             "match_strategy" => "timeline_id",
             "planned_timeline_id" => "timeline:command:upload",
             "realized_timeline_id" => "timeline:command:upload",
             "realized_activity_id" => "provider_command:456",
             "timeline_identity" => %{"timeline_id" => "timeline:command:upload"},
             "planned_activity" => %{
               "id" => "cmd_upload",
               "metadata" => %{"timeline_id" => "timeline:command:upload"}
             },
             "realized_activity" => %{
               "id" => "provider_command:456",
               "timeline_id" => "timeline:command:upload"
             },
             "realized_activity_context" => %{
               "matched_planned_activity_id" => "cmd_upload",
               "match_strategy" => "timeline_id",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:command:upload",
                 "activity_id" => "provider_command:456"
               }
             },
             "realized_type" => "command"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_upload")
             )

    assert %{
             "activity_id" => "downlink_equator",
             "timeline_identity" => %{
               "timeline_id" => "timeline:downlink:equator_prime:100.0",
               "activity_id" => "downlink_equator",
               "activity_type" => "downlink",
               "subject_id" => "equator_prime"
             },
             "dependency_activity_ids" => ["cmd_prereq"],
             "dependency_timeline_ids" => ["timeline:cmd_prereq"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
             "cadence_import_status" => "present",
             "cadence_import_type" => "contact",
             "cadence_import_id" => "cadence_downlink_equator",
             "cadence_import_contract" => "proposed_contact.v1",
             "has_cadence_import" => true
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "cmd_upload",
             "activity_type" => "command",
             "match_strategy" => "timeline_id",
             "planned_timeline_id" => "timeline:command:upload",
             "realized_timeline_id" => "timeline:command:upload",
             "realized_activity_id" => "provider_command:456",
             "timeline_identity" => %{"timeline_id" => "timeline:command:upload"},
             "planned_activity" => %{
               "id" => "cmd_upload",
               "metadata" => %{"timeline_id" => "timeline:command:upload"}
             },
             "realized_activity" => %{
               "id" => "provider_command:456",
               "timeline_id" => "timeline:command:upload"
             },
             "realized_activity_context" => %{
               "matched_planned_activity_id" => "cmd_upload",
               "match_strategy" => "timeline_id"
             },
             "import_activity_context" => %{
               "matched_planned_activity_id" => "cmd_upload",
               "match_strategy" => "timeline_id",
               "timeline_identity" => %{
                 "timeline_id" => "timeline:command:upload",
                 "activity_id" => "provider_command:456"
               }
             },
             "realized_type" => "command"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_upload")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves provider realized activity id when feedback uses realized_activity_id" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :obs_1,
            type: :observe,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            target_id: :target_a
          }
        ],
        [
          %{
            realized_activity_id: :provider_obs_1,
            planned_activity_id: :obs_1,
            type: :observe,
            status: :completed,
            actual_starts_at_s: 10.5,
            actual_ends_at_s: 20.5,
            source: %{system: :cadence_realized_activity_import, source_id: :feedback_42},
            provider: :cadence,
            quality: :operator_verified,
            adapter: :cadence_feedback_adapter,
            adapter_version: "2026.05",
            external_id: :cadence_evt_42,
            schema_contract: :"realized_activity.v1",
            trust_boundary: :operator_supplied,
            received_at: "2026-05-14T00:05:00Z",
            ingested_at: "2026-05-14T00:05:02Z",
            provenance: %{
              adapter: :cadence_feedback_adapter,
              trust_boundary: :operator_supplied
            },
            metadata: %{batch_id: :feedback_batch_1}
          }
        ]
      )

    assert %{
             "activity_id" => "obs_1",
             "realized_activity_id" => "provider_obs_1",
             "match_strategy" => "planned_activity_id",
             "realized_source" => %{
               "system" => "cadence_realized_activity_import",
               "source_id" => "feedback_42"
             },
             "realized_provider" => "cadence",
             "realized_source_quality" => "operator_verified",
             "realized_adapter" => "cadence_feedback_adapter",
             "realized_adapter_version" => "2026.05",
             "realized_external_id" => "cadence_evt_42",
             "realized_schema_contract" => "realized_activity.v1",
             "realized_trust_boundary" => "operator_supplied",
             "realized_received_at" => "2026-05-14T00:05:00Z",
             "realized_ingested_at" => "2026-05-14T00:05:02Z",
             "realized_provenance" => %{
               "adapter" => "cadence_feedback_adapter",
               "trust_boundary" => "operator_supplied"
             },
             "realized_activity_context" => %{
               "activity_id" => "obs_1",
               "planned_activity_id" => "obs_1",
               "matched_planned_activity_id" => "obs_1",
               "match_strategy" => "planned_activity_id",
               "realized_activity_id" => "provider_obs_1",
               "source" => %{
                 "system" => "cadence_realized_activity_import",
                 "source_id" => "feedback_42"
               },
               "provider" => "cadence",
               "source_quality" => "operator_verified",
               "adapter" => "cadence_feedback_adapter",
               "adapter_version" => "2026.05",
               "external_id" => "cadence_evt_42",
               "schema_contract" => "realized_activity.v1",
               "trust_boundary" => "operator_supplied",
               "received_at" => "2026-05-14T00:05:00Z",
               "ingested_at" => "2026-05-14T00:05:02Z",
               "provenance" => %{
                 "adapter" => "cadence_feedback_adapter",
                 "trust_boundary" => "operator_supplied"
               },
               "metadata" => %{"batch_id" => "feedback_batch_1"}
             }
           } = List.first(report["rows"])

    assert %{
             "model" => "timeline_feedback_report_rows_to_operational_feedback",
             "merge_order" => ["timeline_feedback_report.rows"],
             "input_keys" => ["observation_success_rate"],
             "source_count" => 1,
             "explicit_request_override" => false,
             "sources" => [
               %{
                 "source" => "timeline_feedback_report.rows",
                 "source_report_contract" => "timeline_feedback_report.v1",
                 "source_report_count" => 1,
                 "source_report_row_count" => 1,
                 "source_report_status_counts" => %{"matched" => 1},
                 "source_feedback_kind_counts" => %{"observation" => 1},
                 "source_match_strategy_counts" => %{"planned_activity_id" => 1},
                 "source_cadence_import_status_counts" => %{"not_applicable" => 1},
                 "source_realized_source_quality_counts" => %{"operator_verified" => 1},
                 "source_planned_protection_decision_counts" => %{"preserve" => 1},
                 "input_keys" => ["observation_success_rate"],
                 "realized_activity_count" => 1,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["operator_supplied"]
               }
             ]
           } = report["operational_feedback_provenance"]

    assert %{
             "activity_id" => "obs_1",
             "realized_activity_id" => "provider_obs_1",
             "realized_provider" => "cadence",
             "realized_source_quality" => "operator_verified",
             "realized_adapter" => "cadence_feedback_adapter",
             "realized_external_id" => "cadence_evt_42",
             "realized_schema_contract" => "realized_activity.v1",
             "realized_trust_boundary" => "operator_supplied",
             "realized_activity_context" => %{
               "realized_activity_id" => "provider_obs_1",
               "provider" => "cadence",
               "source_quality" => "operator_verified",
               "adapter" => "cadence_feedback_adapter",
               "external_id" => "cadence_evt_42",
               "schema_contract" => "realized_activity.v1",
               "trust_boundary" => "operator_supplied"
             }
           } = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "obs_1",
             "realized_activity_id" => "provider_obs_1",
             "realized_provider" => "cadence",
             "realized_source_quality" => "operator_verified",
             "realized_adapter" => "cadence_feedback_adapter",
             "realized_external_id" => "cadence_evt_42",
             "realized_schema_contract" => "realized_activity.v1",
             "realized_trust_boundary" => "operator_supplied",
             "import_activity_context" => %{
               "realized_activity_id" => "provider_obs_1",
               "provider" => "cadence",
               "source_quality" => "operator_verified",
               "adapter" => "cadence_feedback_adapter",
               "external_id" => "cadence_evt_42",
               "schema_contract" => "realized_activity.v1",
               "trust_boundary" => "operator_supplied"
             }
           } = List.first(report["cadence_import_manifest"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves duplicate realized feedback matches for operator review" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "estimated_throughput_mb" => 120.0,
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "cadence_downlink_equator",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_contact:1",
            "planned_activity_id" => "downlink_equator",
            "type" => "downlink",
            "status" => "completed",
            "actual_throughput_mb" => 110.0
          },
          %{
            "id" => "provider_contact:2",
            "planned_activity_id" => "downlink_equator",
            "type" => "downlink",
            "status" => "partial",
            "actual_throughput_mb" => 64.0,
            "reason" => "provider emitted a second row"
          }
        ]
      )

    assert report["status_counts"] == %{"matched" => 1}
    assert report["duplicate_realized_match_count"] == 1
    assert report["duplicate_realized_feedback_count"] == 1

    assert %{
             "activity_id" => "downlink_equator",
             "status" => "matched",
             "match_strategy" => "planned_activity_id",
             "realized_match_count" => 2,
             "realized_activity_id" => "provider_contact:1",
             "realized_activity_ids" => ["provider_contact:1", "provider_contact:2"],
             "realized_statuses" => ["completed", "partial"],
             "realized_match_strategies" => ["planned_activity_id", "planned_activity_id"],
             "realized_activities" => [
               %{"id" => "provider_contact:1", "status" => "completed"},
               %{"id" => "provider_contact:2", "status" => "partial"}
             ]
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_duplicate_realized_feedback",
             "approval_status" => "operator_review_required",
             "reason" => "multiple realized feedback rows match the same planned activity",
             "realized_match_count" => 2,
             "realized_activity_ids" => ["provider_contact:1", "provider_contact:2"],
             "realized_activities" => [
               %{"id" => "provider_contact:1", "status" => "completed"},
               %{"id" => "provider_contact:2", "status" => "partial"}
             ]
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "downlink_equator",
             "import_status" => "review_required_before_import",
             "source_review_action" => "review_duplicate_realized_feedback",
             "realized_match_count" => 2,
             "realized_activity_ids" => ["provider_contact:1", "provider_contact:2"]
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "routes realized timeline feedback with duplicate planned timeline ids to ambiguity review" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :cmd_a,
            type: :command,
            starts_at_s: 100.0,
            ends_at_s: 120.0,
            ground_station_id: :equator_prime,
            metadata: %{timeline_id: :"timeline:command:duplicate"}
          },
          %{
            id: :cmd_b,
            type: :command,
            starts_at_s: 140.0,
            ends_at_s: 160.0,
            ground_station_id: :equator_prime,
            metadata: %{timeline_id: :"timeline:command:duplicate"}
          }
        ],
        [
          %{
            id: :provider_command_1,
            type: :command,
            timeline_id: :"timeline:command:duplicate",
            status: "completed",
            command_result: "accepted"
          }
        ]
      )

    assert report["status_counts"] == %{"planned_only" => 2, "realized_only" => 1}
    assert report["ambiguous_timeline_match_count"] == 1
    assert report["ambiguous_timeline_feedback_count"] == 2

    assert %{
             "activity_id" => "provider_command_1",
             "status" => "realized_only",
             "match_strategy" => "ambiguous_timeline_id",
             "ambiguous_planned_timeline_id" => "timeline:command:duplicate",
             "ambiguous_planned_match_count" => 2,
             "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"],
             "ambiguous_planned_activities" => [
               %{"id" => "cmd_a", "metadata" => %{"timeline_id" => "timeline:command:duplicate"}},
               %{"id" => "cmd_b", "metadata" => %{"timeline_id" => "timeline:command:duplicate"}}
             ],
             "realized_timeline_id" => "timeline:command:duplicate",
             "realized_activity_id" => "provider_command_1",
             "realized_activity_context" => %{
               "match_strategy" => "ambiguous_timeline_id",
               "ambiguous_planned_timeline_id" => "timeline:command:duplicate",
               "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"],
               "realized_activity_id" => "provider_command_1"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "provider_command_1"))

    assert %{
             "activity_id" => "provider_command_1",
             "required_operator_action" => "review_ambiguous_realized_feedback",
             "approval_status" => "operator_review_required",
             "match_strategy" => "ambiguous_timeline_id",
             "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"],
             "realized_activity_context" => %{
               "match_strategy" => "ambiguous_timeline_id",
               "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"]
             },
             "source_feedback" => %{
               "ambiguous_planned_match_count" => 2
             }
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "provider_command_1")
             )

    assert %{
             "activity_id" => "provider_command_1",
             "source_review_action" => "review_ambiguous_realized_feedback",
             "match_strategy" => "ambiguous_timeline_id",
             "ambiguous_planned_timeline_id" => "timeline:command:duplicate",
             "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"],
             "import_activity_context" => %{
               "match_strategy" => "ambiguous_timeline_id",
               "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"]
             },
             "source_feedback" => %{
               "ambiguous_planned_activity_ids" => ["cmd_a", "cmd_b"]
             }
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "provider_command_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "completed contact with throughput shortfall requires variance review" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "estimated_throughput_mb" => 120.0,
            "cadence_import" => %{
              "activity_type" => "contact",
              "external_id" => "cadence_downlink_equator",
              "schema_contract" => "proposed_contact.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_contact:short",
            "planned_activity_id" => "downlink_equator",
            "type" => "downlink",
            "status" => "completed",
            "actual_throughput_mb" => 72.0
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "realized_status" => "completed",
             "contact_success" => true,
             "planned_estimated_throughput_mb" => 120.0,
             "actual_throughput_mb" => 72.0,
             "throughput_completion_fraction" => 0.6
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_contact_variance",
             "approval_status" => "operator_review_required",
             "reason" => "realized contact completed below planned throughput",
             "throughput_completion_fraction" => 0.6
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "downlink_equator",
             "import_status" => "review_required_before_import",
             "source_review_action" => "review_contact_variance"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves explicit provider command and contact success flags over status defaults" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink"
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command",
            "cadence_import" => %{
              "activity_type" => "command",
              "external_id" => "cadence_cmd_upload",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "status" => "completed",
            "contact_success" => false,
            "reason" => "provider marked pass unusable"
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "status" => "completed",
            "command_success" => false,
            "command_result" => "rejected"
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "realized_status" => "completed",
             "contact_success" => false,
             "reason" => "provider marked pass unusable"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "cmd_upload",
             "realized_status" => "completed",
             "command_success" => false,
             "command_result" => "rejected"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_upload"))

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_contact_exception",
             "approval_status" => "operator_review_required",
             "contact_success" => false
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert %{
             "activity_id" => "cmd_upload",
             "required_operator_action" => "review_command_exception",
             "approval_status" => "operator_review_required",
             "command_success" => false
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_upload")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives failed contact success from provider contact result aliases" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink"
          }
        ],
        [
          %{
            "id" => "downlink_equator",
            "type" => "contact",
            "direction" => "downlink",
            "status" => "completed",
            "contact_result" => ["accepted", "dropped"]
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "realized_status" => "completed",
             "contact_result" => "accepted,dropped",
             "contact_success" => false,
             "realized_activity_context" => %{"contact_result" => "accepted,dropped"}
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert get_in(report, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert %{
             "activity_id" => "downlink_equator",
             "required_operator_action" => "review_contact_exception",
             "contact_success" => false
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "downlink_equator")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider result aliases before deriving contact and command success" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink"
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command"
          }
        ],
        [
          %{
            "id" => "downlink_equator",
            "type" => "contact",
            "direction" => "downlink",
            "status" => "completed",
            "contact_result" => ["accepted", " NO-CONTACT "]
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "status" => "completed",
            "command_result" => ["accepted", "timed-out"]
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "realized_status" => "completed",
             "contact_result" => "accepted,NO-CONTACT",
             "contact_success" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "cmd_upload",
             "realized_status" => "completed",
             "command_result" => "accepted,timed-out",
             "command_success" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_upload"))

    assert get_in(report, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert get_in(report, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_upload" => 0.0
           }

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider result maps before deriving operational feedback" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink"
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command"
          },
          Activity.observe!(:obs_provider_map, 260.0, 320.0, :target_a)
        ],
        [
          %{
            "id" => "downlink_equator",
            "type" => "contact",
            "direction" => "downlink",
            "status" => "completed",
            "contact_result" => %{
              "outcome" => "accepted",
              "provider_status" => "NO-CONTACT"
            }
          },
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "status" => "completed",
            "command_result" => %{
              "status" => "rejected",
              "details" => %{"message" => "timed out"}
            }
          },
          %{
            "id" => "obs_provider_map",
            "type" => "observe",
            "target_id" => "target_a",
            "status" => "completed",
            "observation_result" => %{
              "result" => ["delivered", %{"status" => "failed"}],
              "details" => %{"reason" => "clouded out"}
            }
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_equator",
             "contact_result" => "accepted,NO-CONTACT",
             "contact_success" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert %{
             "activity_id" => "cmd_upload",
             "command_result" => "rejected,timed out",
             "command_success" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_upload"))

    assert %{
             "activity_id" => "obs_provider_map",
             "observation_result" => "delivered,failed,clouded out",
             "observation_success" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_provider_map"))

    assert get_in(report, ["operational_feedback", "contact_success_rate"]) == %{
             "equator_prime" => 0.0
           }

    assert get_in(report, ["operational_feedback", "command_success_rate"]) == %{
             "cmd_upload" => 0.0
           }

    assert get_in(report, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.0
           }

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives failed command success from rejected provider command result" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "cmd_upload",
            "type" => "command",
            "starts_at_s" => 200.0,
            "ends_at_s" => 220.0,
            "ground_station_id" => "equator_prime",
            "direction" => "command",
            "cadence_import" => %{
              "activity_type" => "command",
              "external_id" => "cadence_cmd_upload",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_command:rejected",
            "planned_activity_id" => "cmd_upload",
            "type" => "command",
            "status" => "completed",
            "command_result" => "rejected"
          }
        ]
      )

    assert %{
             "activity_id" => "cmd_upload",
             "realized_status" => "completed",
             "command_success" => false,
             "command_result" => "rejected"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_upload"))

    assert %{
             "activity_id" => "cmd_upload",
             "required_operator_action" => "review_command_exception",
             "approval_status" => "operator_review_required",
             "command_success" => false,
             "command_result" => "rejected"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_upload")
             )

    assert %{
             "activity_id" => "cmd_upload",
             "import_status" => "review_required_before_import",
             "source_review_action" => "review_command_exception"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_upload")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes separator variants in realized statuses before feedback reconciliation" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "downlink_cancelled",
            "type" => "downlink",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "approval_status" => "approved"
          }
        ],
        [
          %{
            "id" => "downlink_cancelled",
            "type" => "downlink",
            "status" => " cancelled "
          }
        ]
      )

    assert %{
             "activity_id" => "downlink_cancelled",
             "realized_status" => "cancelled",
             "contact_success" => false,
             "planned_protection_reason" => "realized_status_cancelled_requires_repair_review"
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "completed observation with partial completion requires variance review" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.observe!(:obs_partial, 10.0, 30.0, :target_a, status: :approved)
        ],
        [
          %{
            "id" => "provider_observation:partial",
            "planned_activity_id" => "obs_partial",
            "type" => "observe",
            "status" => "completed",
            "completed_fraction" => 0.5
          }
        ]
      )

    feedback_row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_partial"))

    assert %{
             "activity_id" => "obs_partial",
             "feedback_kind" => "observation",
             "realized_status" => "completed",
             "completed_fraction" => 0.5,
             "observation_success_factor" => 0.5,
             "observation_success_factor_source" => "realized_activity.completed_fraction"
           } = feedback_row

    assert get_in(feedback_row, ["realized_activity_context", "observation_success_factor"]) ==
             0.5

    assert get_in(feedback_row, [
             "realized_activity_context",
             "observation_success_factor_source"
           ]) == "realized_activity.completed_fraction"

    assert %{
             "activity_id" => "obs_partial",
             "required_operator_action" => "review_realized_variance",
             "approval_status" => "operator_review_required",
             "reason" => "realized activity completed with partial completion fraction",
             "completed_fraction" => 0.5,
             "observation_success_factor" => 0.5,
             "observation_success_factor_source" => "realized_activity.completed_fraction"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_partial")
             )

    assert %{
             "activity_id" => "obs_partial",
             "import_status" => "review_required_before_import",
             "source_review_action" => "review_realized_variance",
             "observation_success_factor" => 0.5,
             "observation_success_factor_source" => "realized_activity.completed_fraction"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_partial")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves maneuver success factors in planned and realized feedback context" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "burn_cleanup",
            "type" => "impulsive_burn",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "execution_uncertainty" => %{
              "timing_3sigma_s" => 3.0,
              "delta_v_3sigma_km_s" => [0.0, 0.0005, 0.0],
              "source" => "preburn_covariance"
            },
            "maneuver_success_factor" => 0.9,
            "maneuver_success_factor_source" => "preburn_confidence_model"
          }
        ],
        [
          %{
            "id" => "provider_burn_cleanup",
            "planned_activity_id" => "burn_cleanup",
            "type" => "impulsive_burn",
            "status" => "completed",
            "actual_delta_v_km_s" => [0.0, 0.008, 0.0],
            "execution_uncertainty" => %{
              "timing_3sigma_s" => 5.0,
              "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
              "source" => "provider_execution_covariance"
            },
            "maneuver_success_factor" => 0.4,
            "maneuver_success_factor_source" => "provider_execution_feedback"
          }
        ]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "burn_cleanup"))

    assert report["execution_uncertainty_declared_count"] == 1
    assert report["execution_uncertainty_missing_count"] == 0

    assert %{
             "activity_id" => "burn_cleanup",
             "feedback_kind" => "maneuver",
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "provider_execution_feedback",
             "planned_delta_v_magnitude_km_s" => 0.01,
             "realized_delta_v_magnitude_km_s" => 0.008,
             "delta_v_match_status" => "mismatch",
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 5.0,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "source_activity_context" => %{
               "delta_v_magnitude_km_s" => 0.01,
               "execution_uncertainty_status" => "declared",
               "timing_3sigma_s" => 3.0,
               "execution_uncertainty_source" => "preburn_covariance",
               "maneuver_success_factor" => 0.9,
               "maneuver_success_factor_source" => "preburn_confidence_model"
             },
             "realized_activity_context" => %{
               "delta_v_magnitude_km_s" => 0.008,
               "execution_uncertainty_status" => "declared",
               "timing_3sigma_s" => 5.0,
               "execution_uncertainty_source" => "provider_execution_covariance",
               "maneuver_success_factor" => 0.4,
               "maneuver_success_factor_source" => "provider_execution_feedback"
             }
           } = row

    assert row["planned_delta_v_km_s"] == [0.0, 0.01, 0.0]
    assert row["realized_delta_v_km_s"] == [0.0, 0.008, 0.0]
    assert row["execution_uncertainty"]["source"] == "provider_execution_covariance"
    assert row["delta_v_3sigma_km_s"] == [0.0, 0.001, 0.0]
    assert_in_delta row["delta_v_3sigma_magnitude_km_s"], 0.001, 1.0e-12
    delta_v_delta = row["delta_v_delta_km_s"]
    assert Enum.at(delta_v_delta, 0) == 0.0
    assert Enum.at(delta_v_delta, 2) == 0.0
    assert get_in(row, ["source_activity_context", "delta_v_km_s"]) == [0.0, 0.01, 0.0]
    assert get_in(row, ["realized_activity_context", "delta_v_km_s"]) == [0.0, 0.008, 0.0]

    assert get_in(row, ["source_activity_context", "execution_uncertainty", "source"]) ==
             "preburn_covariance"

    assert get_in(row, ["source_activity_context", "delta_v_3sigma_km_s"]) ==
             [0.0, 0.0005, 0.0]

    assert get_in(row, ["realized_activity_context", "execution_uncertainty", "source"]) ==
             "provider_execution_covariance"

    assert get_in(row, ["realized_activity_context", "delta_v_3sigma_km_s"]) ==
             [0.0, 0.001, 0.0]

    assert_in_delta Enum.at(delta_v_delta, 1), -0.002, 1.0e-12
    assert_in_delta row["delta_v_magnitude_delta_km_s"], -0.002, 1.0e-12

    assert get_in(report, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_cleanup" => 0.4
           }

    assert get_in(report, ["operational_feedback", "maneuver_execution_uncertainty"]) == %{
             "burn_cleanup" => %{
               "execution_uncertainty_status" => "declared",
               "execution_uncertainty" => %{
                 "timing_3sigma_s" => 5.0,
                 "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
                 "source" => "provider_execution_covariance"
               },
               "timing_3sigma_s" => 5.0,
               "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
               "delta_v_3sigma_magnitude_km_s" => 0.001,
               "execution_uncertainty_source" => "provider_execution_covariance"
             }
           }

    review_row =
      Enum.find(
        report["operator_review_package"]["rows"],
        &(&1["activity_id"] == "burn_cleanup")
      )

    assert %{
             "activity_id" => "burn_cleanup",
             "required_operator_action" => "review_realized_variance",
             "approval_status" => "operator_review_required",
             "delta_v_match_status" => "mismatch",
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 5.0,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "provider_execution_feedback"
           } = review_row

    assert review_row["planned_delta_v_km_s"] == [0.0, 0.01, 0.0]
    assert review_row["realized_delta_v_km_s"] == [0.0, 0.008, 0.0]
    assert review_row["execution_uncertainty"]["source"] == "provider_execution_covariance"
    assert review_row["delta_v_3sigma_km_s"] == [0.0, 0.001, 0.0]

    import_row =
      Enum.find(
        report["cadence_import_manifest"]["rows"],
        &(&1["activity_id"] == "burn_cleanup")
      )

    assert %{
             "activity_id" => "burn_cleanup",
             "import_action" => "review_realized_feedback",
             "source_review_action" => "review_realized_variance",
             "delta_v_match_status" => "mismatch",
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 5.0,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "provider_execution_feedback"
           } = import_row

    assert import_row["planned_delta_v_km_s"] == [0.0, 0.01, 0.0]
    assert import_row["realized_delta_v_km_s"] == [0.0, 0.008, 0.0]
    assert import_row["execution_uncertainty"]["source"] == "provider_execution_covariance"
    assert import_row["delta_v_3sigma_km_s"] == [0.0, 0.001, 0.0]

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "derives maneuver success feedback from provider maneuver result aliases" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "burn_cleanup",
            "type" => "impulsive_burn",
            "starts_at_s" => 100.0,
            "ends_at_s" => 100.0,
            "delta_v_km_s" => [0.0, 0.01, 0.0],
            "maneuver_success_factor" => 0.9,
            "maneuver_success_factor_source" => "preburn_confidence_model"
          }
        ],
        [
          %{
            "id" => "provider_burn_cleanup",
            "planned_activity_id" => "burn_cleanup",
            "type" => "impulsive_burn",
            "status" => "completed",
            "maneuver_result" => ["accepted", "failed"]
          }
        ]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "burn_cleanup"))

    assert %{
             "activity_id" => "burn_cleanup",
             "feedback_kind" => "maneuver",
             "realized_status" => "completed",
             "maneuver_success" => false,
             "maneuver_result" => "accepted,failed",
             "realized_activity_context" => %{
               "maneuver_result" => "accepted,failed"
             }
           } = row

    assert get_in(report, ["operational_feedback", "maneuver_success_rate"]) == %{
             "burn_cleanup" => 0.0
           }

    assert %{
             "activity_id" => "burn_cleanup",
             "required_operator_action" => "review_maneuver_exception",
             "maneuver_success" => false,
             "maneuver_result" => "accepted,failed"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "burn_cleanup")
             )

    assert %{
             "activity_id" => "burn_cleanup",
             "import_action" => "review_realized_feedback",
             "maneuver_success" => false,
             "maneuver_result" => "accepted,failed"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "burn_cleanup")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "classifies realized-only command-directed contacts as command feedback" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            "id" => "provider_command_contact:1",
            "type" => "planned_contact",
            "direction" => "command",
            "ground_station_id" => "equator_prime",
            "status" => "completed",
            "actual_starts_at_s" => 200.0,
            "actual_ends_at_s" => 220.0,
            "command_result" => "accepted"
          }
        ]
      )

    assert %{
             "activity_id" => "provider_command_contact:1",
             "status" => "realized_only",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "command_success" => true,
             "command_result" => "accepted"
           } = List.first(report["rows"])

    refute Map.has_key?(List.first(report["rows"]), "realized_timeline_id")

    assert %{
             "activity_id" => "provider_command_contact:1",
             "required_operator_action" => "review_unplanned_realization",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "command_success" => true
           } = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "provider_command_contact:1",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "command_success" => true
           } = List.first(report["cadence_import_manifest"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies realized-only command direction aliases as command feedback" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            "id" => "provider_command_alias:1",
            "type" => "planned_contact",
            "direction" => "s-band command",
            "ground_station_id" => "equator_prime",
            "status" => "completed",
            "actual_starts_at_s" => 240.0,
            "actual_ends_at_s" => 260.0,
            "command_result" => "accepted"
          }
        ]
      )

    assert %{
             "activity_id" => "provider_command_alias:1",
             "status" => "realized_only",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "command_success" => true,
             "command_result" => "accepted",
             "realized_activity_context" => %{
               "direction" => "command"
             },
             "realized_activity" => %{
               "direction" => "s-band command"
             }
           } = List.first(report["rows"])

    refute Map.has_key?(List.first(report["rows"]), "contact_success")

    assert %{
             "activity_id" => "provider_command_alias:1",
             "required_operator_action" => "review_unplanned_realization",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "command",
             "command_success" => true
           } = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "provider_command_alias:1",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "command",
             "command_success" => true
           } = List.first(report["cadence_import_manifest"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies realized-only health-check direction aliases as health-check feedback" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            "id" => "provider_health_alias:1",
            "type" => "planned_contact",
            "direction" => "healthcheck",
            "ground_station_id" => "equator_prime",
            "status" => "completed",
            "actual_starts_at_s" => 260.0,
            "actual_ends_at_s" => 280.0,
            "completed_fraction" => 0.5
          }
        ]
      )

    assert %{
             "activity_id" => "provider_health_alias:1",
             "status" => "realized_only",
             "feedback_kind" => "health_check",
             "realized_type" => "planned_contact",
             "direction" => "health_check",
             "ground_station_id" => "equator_prime",
             "command_success" => true,
             "command_success_factor" => 0.5,
             "command_success_factor_source" => "realized_activity.completed_fraction",
             "realized_activity_context" => %{
               "direction" => "health_check",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "realized_activity.completed_fraction"
             },
             "realized_activity" => %{
               "direction" => "healthcheck"
             }
           } = List.first(report["rows"])

    refute Map.has_key?(List.first(report["rows"]), "contact_success")
    refute Map.has_key?(List.first(report["rows"]), "contact_success_factor")

    assert %{
             "activity_id" => "provider_health_alias:1",
             "required_operator_action" => "review_unplanned_realization",
             "activity_type" => "planned_contact",
             "feedback_kind" => "health_check",
             "realized_type" => "planned_contact",
             "direction" => "health_check",
             "command_success" => true,
             "command_success_factor" => 0.5,
             "command_success_factor_source" => "realized_activity.completed_fraction"
           } = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "provider_health_alias:1",
             "activity_type" => "planned_contact",
             "feedback_kind" => "health_check",
             "realized_type" => "planned_contact",
             "direction" => "health_check",
             "command_success" => true,
             "command_success_factor" => 0.5,
             "command_success_factor_source" => "realized_activity.completed_fraction"
           } = List.first(report["cadence_import_manifest"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies realized-only uplink contacts as command feedback" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            "id" => "provider_uplink_contact:1",
            "type" => "planned_contact",
            "direction" => "uplink",
            "ground_station_id" => "equator_prime",
            "status" => "completed",
            "actual_starts_at_s" => 240.0,
            "actual_ends_at_s" => 260.0,
            "command_result" => "accepted"
          }
        ]
      )

    assert %{
             "activity_id" => "provider_uplink_contact:1",
             "status" => "realized_only",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "uplink",
             "ground_station_id" => "equator_prime",
             "command_success" => true,
             "command_result" => "accepted"
           } = List.first(report["rows"])

    refute Map.has_key?(List.first(report["rows"]), "contact_success")

    assert %{
             "activity_id" => "provider_uplink_contact:1",
             "required_operator_action" => "review_unplanned_realization",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "uplink",
             "command_success" => true
           } = List.first(report["operator_review_package"]["rows"])

    assert %{
             "activity_id" => "provider_uplink_contact:1",
             "activity_type" => "planned_contact",
             "feedback_kind" => "command",
             "realized_type" => "planned_contact",
             "direction" => "uplink",
             "command_success" => true
           } = List.first(report["cadence_import_manifest"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes station-id realized provider contacts into canonical feedback rows" do
    report =
      TimelineFeedback.reconcile(
        [],
        [
          %{
            "id" => "provider_contact:station-alias",
            "timeline_id" => "provider:contact:equator_prime:1",
            "type" => "contact",
            "direction" => "downlink",
            "station_id" => "equator_prime",
            "status" => "completed",
            "actual_starts_at_s" => 200.0,
            "actual_ends_at_s" => 260.0,
            "actual_throughput_mb" => 120.0,
            "contact_success" => true
          }
        ]
      )

    assert %{
             "activity_id" => "provider_contact:station-alias",
             "status" => "realized_only",
             "feedback_kind" => "contact",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "contact_success" => true,
             "realized_activity_context" => %{
               "ground_station_id" => "equator_prime",
               "timeline_identity" => %{
                 "subject_id" => "equator_prime"
               }
             }
           } = List.first(report["rows"])

    assert %{
             "ground_station_id" => "equator_prime",
             "realized_activity" => %{"station_id" => "equator_prime"}
           } = List.first(report["operator_review_package"]["rows"])

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider-shaped realized target station and spacecraft objects into feedback rows" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            "id" => "obs_target_a",
            "type" => "observe",
            "starts_at_s" => 100.0,
            "ends_at_s" => 160.0,
            "target_id" => "target_a"
          },
          %{
            "id" => "downlink_equator",
            "type" => "downlink",
            "starts_at_s" => 200.0,
            "ends_at_s" => 260.0,
            "ground_station_id" => "equator_prime",
            "estimated_throughput_mb" => 100.0
          }
        ],
        [
          %{
            "id" => "provider_obs:target_a",
            "planned_activity_id" => "obs_target_a",
            "type" => "observe",
            "status" => "completed",
            "target" => %{"id" => "target_a"},
            "spacecraft" => %{"spacecraft_id" => "sat_1"},
            "observation_result" => "delivered"
          },
          %{
            "id" => "provider_contact:equator",
            "planned_activity_id" => "downlink_equator",
            "type" => "downlink",
            "status" => "completed",
            "station" => %{"id" => "equator_prime"},
            "satellite" => %{"satellite_id" => "sat_2"},
            "actual_throughput_mb" => 90.0,
            "contact_success" => true
          }
        ]
      )

    assert %{
             "activity_id" => "obs_target_a",
             "status" => "matched",
             "target_id" => "target_a",
             "spacecraft_id" => "sat_1",
             "realized_target_id" => "target_a",
             "target_match_status" => "matched",
             "observation_success" => true,
             "realized_activity_context" => %{
               "target_id" => "target_a",
               "spacecraft_id" => "sat_1"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_target_a"))

    assert %{
             "activity_id" => "downlink_equator",
             "status" => "matched",
             "ground_station_id" => "equator_prime",
             "spacecraft_id" => "sat_2",
             "realized_ground_station_id" => "equator_prime",
             "ground_station_match_status" => "matched",
             "contact_success" => true,
             "throughput_completion_fraction" => 0.9,
             "realized_activity_context" => %{
               "ground_station_id" => "equator_prime",
               "spacecraft_id" => "sat_2"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "downlink_equator"))

    assert report["operational_feedback"]["observation_success_rate"] == %{"target_a" => 1.0}

    assert report["operational_feedback"]["station_throughput_factor"] == %{
             "equator_prime" => 0.9
           }

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reconciles planned and realized activity rows" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.observe!(:obs_1, 10.0, 20.0, :target_a, status: :approved),
          %{"id" => "dl_1", "type" => "downlink", "starts_at_s" => 30.0, "ends_at_s" => 40.0}
        ],
        [
          %{
            "id" => "obs_1",
            "status" => "completed",
            "actual_starts_at_s" => 12.0,
            "actual_ends_at_s" => 21.0,
            "completed_fraction" => 1.0
          },
          %{"id" => "unplanned", "status" => "partial", "completed_fraction" => 0.5}
        ]
      )

    assert report["schema_contract"] == "timeline_feedback_report.v1"
    assert report["planned_count"] == 2
    assert report["realized_count"] == 2

    assert report["status_counts"] == %{
             "matched" => 1,
             "planned_only" => 1,
             "realized_only" => 1
           }

    assert %{
             "activity_id" => "obs_1",
             "status" => "matched",
             "planned_type" => "observe",
             "planned_status" => "approved",
             "realized_status" => "completed",
             "start_delta_s" => 2.0,
             "end_delta_s" => 1.0
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{"status" => "planned_only"} =
             Enum.find(report["rows"], &(&1["activity_id"] == "dl_1"))

    assert %{"status" => "realized_only"} =
             Enum.find(report["rows"], &(&1["activity_id"] == "unplanned"))

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "timeline_feedback_report.v1",
             "review_count" => 3,
             "realized_feedback_count" => 3
           } = report["operator_review_package"]

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "timeline_feedback_report.v1",
             "row_count" => 3,
             "ready_count" => 1,
             "review_required_count" => 1,
             "blocked_count" => 1,
             "missing_import_count" => 1
           } = report["cadence_import_manifest"]

    assert %{
             "activity_id" => "obs_1",
             "import_action" => "record_realized_feedback",
             "import_status" => "ready_for_import",
             "source_review_action" => "record_realized_completion"
           } =
             Enum.find(report["cadence_import_manifest"]["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_1",
             "review_type" => "realized_feedback",
             "approval_status" => "not_required",
             "required_operator_action" => "record_realized_completion",
             "start_delta_s" => 2.0,
             "end_delta_s" => 1.0
           } =
             Enum.find(report["operator_review_package"]["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "dl_1",
             "required_operator_action" => "review_missing_realization"
           } =
             Enum.find(report["operator_review_package"]["rows"], &(&1["activity_id"] == "dl_1"))

    assert %{
             "activity_id" => "unplanned",
             "required_operator_action" => "review_unplanned_realization"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "unplanned")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "routes completed feedback over timing variance threshold to review" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.observe!(:obs_late, 10.0, 20.0, :target_a, status: :approved)
        ],
        [
          %{
            "id" => "obs_late",
            "status" => "completed",
            "actual_starts_at_s" => 14.5,
            "actual_ends_at_s" => 23.0,
            "completed_fraction" => 1.0
          }
        ],
        timing_variance_threshold_s: 2.0
      )

    assert get_in(report, ["assumptions", "timing_variance_threshold_s"]) == 2.0

    assert %{
             "activity_id" => "obs_late",
             "start_delta_s" => 4.5,
             "end_delta_s" => 3.0,
             "max_timing_delta_s" => 4.5,
             "timing_variance_threshold_s" => 2.0,
             "timing_variance_status" => "exceeds_threshold"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_late"))

    assert %{
             "activity_id" => "obs_late",
             "required_operator_action" => "review_realized_variance",
             "reason" => "realized activity completed exceeded timing variance threshold",
             "max_timing_delta_s" => 4.5,
             "timing_variance_threshold_s" => 2.0,
             "timing_variance_status" => "exceeds_threshold"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_late")
             )

    assert %{
             "activity_id" => "obs_late",
             "import_action" => "review_realized_feedback",
             "import_status" => "review_required_before_import",
             "source_review_action" => "review_realized_variance",
             "max_timing_delta_s" => 4.5,
             "timing_variance_threshold_s" => 2.0,
             "timing_variance_status" => "exceeds_threshold"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_late")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "preserves unsupported realized statuses for review" do
    report =
      TimelineFeedback.reconcile(
        [%{"id" => "obs_1", "type" => "observe", "target_id" => "target_a"}],
        [%{"id" => "obs_1", "status" => " Not-Supported "}]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_1",
             "status" => "matched",
             "match_strategy" => "planned_activity_id",
             "realized_status" => "invalid",
             "realized_activity_id" => "obs_1",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
             "unsupported_realized_status" => "not_supported",
             "realized_activity" => %{"id" => "obs_1", "status" => " Not-Supported "}
           } = row

    assert get_in(row, ["realized_activity_context", "matched_planned_activity_id"]) == "obs_1"

    assert get_in(row, ["realized_activity_context", "unsupported_realized_status"]) ==
             "not_supported"

    assert %{
             "activity_id" => "obs_1",
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
             "unsupported_realized_status" => "not_supported",
             "reason" => "realized feedback input has unsupported status not_supported"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_1")
             )

    assert %{
             "activity_id" => "obs_1",
             "source_review_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
             "unsupported_realized_status" => "not_supported"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "obs_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "uses provider realized_status when feedback status is a match state" do
    report =
      TimelineFeedback.reconcile(
        [%{"id" => "obs_1", "type" => "observe", "target_id" => "target_a"}],
        [%{"id" => "obs_1", "status" => "matched", "realized_status" => "failed"}]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_1",
             "status" => "matched",
             "match_strategy" => "activity_id",
             "realized_status" => "failed",
             "realized_activity_id" => "obs_1",
             "status_transition" => %{
               "from" => "planned",
               "to" => "failed",
               "transition_type" => "changed"
             },
             "realized_activity_context" => %{
               "status" => "failed",
               "feedback_status" => "matched"
             },
             "realized_activity" => %{
               "id" => "obs_1",
               "status" => "matched",
               "realized_status" => "failed"
             }
           } = row

    refute Map.get(row, "invalid_realized_feedback_input")

    assert %{
             "activity_id" => "obs_1",
             "realized_status" => "failed",
             "feedback_status" => "matched",
             "required_operator_action" => "review_realized_exception",
             "reason" => "realized activity ended with failed status"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "derives realized status from lifecycle event feedback" do
    report =
      TimelineFeedback.reconcile(
        [
          %{"id" => "obs_1", "type" => "observe", "target_id" => "target_a"},
          %{
            "id" => "cmd_1",
            "type" => "command",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0
          }
        ],
        [
          %{"id" => "obs_1", "lifecycle_event" => "Record Completion"},
          %{"id" => "cmd_1", "status" => "matched", "lifecycle_event" => "record-failure"}
        ]
      )

    obs_row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))
    cmd_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert %{
             "activity_id" => "obs_1",
             "realized_status" => "completed",
             "status_transition" => %{
               "from" => "planned",
               "to" => "completed",
               "transition_category" => "execution_recorded"
             },
             "realized_activity" => %{
               "id" => "obs_1",
               "lifecycle_event" => "Record Completion"
             }
           } = obs_row

    assert %{
             "activity_id" => "cmd_1",
             "status" => "matched",
             "feedback_status" => "matched",
             "realized_status" => "failed",
             "status_transition" => %{
               "from" => "planned",
               "to" => "failed",
               "transition_category" => "terminal_exception_recorded"
             },
             "realized_activity_context" => %{
               "status" => "failed",
               "feedback_status" => "matched"
             }
           } = cmd_row

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "keeps non-terminal lifecycle feedback events reviewable" do
    report =
      TimelineFeedback.reconcile(
        [%{"id" => "cmd_1", "type" => "command"}],
        [%{"id" => "cmd_1", "lifecycle_event" => "start execution"}]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert %{
             "activity_id" => "cmd_1",
             "realized_status" => "invalid",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
             "unsupported_realized_status" => "executing"
           } = row

    assert %{
             "activity_id" => "cmd_1",
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "unsupported_realized_status" => "executing"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves missing realized statuses separately from unsupported statuses" do
    report =
      TimelineFeedback.reconcile(
        [%{"id" => "obs_1", "type" => "observe", "target_id" => "target_a"}],
        [%{"id" => "obs_1"}]
      )

    row = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "obs_1",
             "status" => "matched",
             "match_strategy" => "planned_activity_id",
             "realized_status" => "invalid",
             "realized_activity_id" => "obs_1",
             "invalid_realized_feedback_input" => true,
             "invalid_realized_feedback_input_reason" => "missing_realized_status",
             "realized_activity" => %{"id" => "obs_1"}
           } = row

    refute Map.has_key?(row, "unsupported_realized_status")
    assert get_in(row, ["realized_activity_context", "matched_planned_activity_id"]) == "obs_1"

    assert %{
             "activity_id" => "obs_1",
             "required_operator_action" => "review_invalid_realized_feedback_input",
             "invalid_realized_feedback_input_reason" => "missing_realized_status",
             "reason" => "realized feedback input is missing status"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "obs_1")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes atom realized statuses before feedback reconciliation" do
    report =
      TimelineFeedback.reconcile(
        [%{id: :obs_1, type: :observe, target_id: :target_a}],
        [%{id: :obs_1, status: :completed, actual_starts_at_s: 11.0, actual_ends_at_s: 19.0}]
      )

    assert %{
             "activity_id" => "obs_1",
             "status" => "matched",
             "realized_status" => "completed",
             "feedback_kind" => "observation"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves station-calendar context through feedback review and import rows" do
    station_context = %{
      "station_availability" => "reserved",
      "station_contention_status" => "reserved_overlap",
      "capacity_fraction" => 0.4,
      "capacity_fraction_min" => 0.4,
      "capacity_fraction_max" => 0.75,
      "station_calendar_entry_id" => "station_reserved",
      "station_calendar_provider_id" => "ground_partner_a",
      "station_calendar_provider_entry_id" => "partner_reserved_window",
      "station_calendar_directions" => ["downlink"],
      "station_calendar_status" => "reserved",
      "station_calendar_overlap_count" => 1,
      "station_calendar_overlap_entry_ids" => ["station_reserved"],
      "station_calendar_overlap_availabilities" => ["reserved"],
      "station_calendar_entry_ambiguous" => false,
      "station_calendar_reservation_overlap_count" => 1,
      "station_calendar_reservation_ids" => ["reservation_1"],
      "station_calendar_reservation_expires_at_s" => [240.0, 360.0, 420.0],
      "station_calendar_reserved_by" => ["mission_ops"],
      "station_calendar_reservation_statuses" => ["held"],
      "station_calendar_trust_boundary_status" => "declared",
      "source_station_calendar_entry" => %{
        "id" => "station_reserved",
        "availability" => "reserved",
        "reservation_expires_at_s" => "360.0",
        "capacity_pack_capacity_fraction" => "0.4",
        "capacity_model" => %{"station_capacity_percent" => "50"}
      },
      "source_station_calendar_overlaps" => [
        %{
          "id" => "station_reserved",
          "capacity_percent" => "75",
          "station_reservation_expires_at_s" => 420.0
        }
      ],
      "station_reservation_id" => "reservation_1",
      "station_reservation_expires_at_s" => 240.0,
      "station_reserved_by" => "mission_ops",
      "station_reservation_status" => "held",
      "station_reservation_match_status" => "matched"
    }

    planned =
      [
        Map.merge(
          %{
            "id" => "dl_station_calendar",
            "type" => "downlink",
            "status" => "approved",
            "starts_at_s" => 10.0,
            "ends_at_s" => 40.0,
            "ground_station_id" => "equator_prime",
            "direction" => "downlink"
          },
          station_context
        )
      ]

    realized =
      [
        Map.merge(
          %{
            "id" => "dl_station_calendar",
            "status" => "failed",
            "actual_starts_at_s" => 12.0,
            "actual_ends_at_s" => 20.0,
            "contact_result" => "reserved_station_blocked"
          },
          station_context
        )
      ]

    report = TimelineFeedback.reconcile(planned, realized)
    row = Enum.find(report["rows"], &(&1["activity_id"] == "dl_station_calendar"))

    assert Map.take(row, Map.keys(station_context)) == station_context
    assert Map.take(row["source_activity_context"], Map.keys(station_context)) == station_context

    assert Map.take(row["realized_activity_context"], Map.keys(station_context)) ==
             station_context

    review_row =
      Enum.find(
        report["operator_review_package"]["rows"],
        &(&1["activity_id"] == "dl_station_calendar")
      )

    assert Map.take(review_row, Map.keys(station_context)) == station_context
    assert Map.take(review_row["source_feedback"], Map.keys(station_context)) == station_context

    import_row =
      Enum.find(
        report["cadence_import_manifest"]["rows"],
        &(&1["activity_id"] == "dl_station_calendar")
      )

    assert Map.take(import_row, Map.keys(station_context)) == station_context
    assert Map.take(import_row["source_feedback"], Map.keys(station_context)) == station_context

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "completed contact feedback with missing Cadence import identity remains review-gated" do
    report =
      TimelineFeedback.reconcile(
        [
          Activity.downlink!(:dl_missing_import, 30.0, 40.0, :equator_prime, status: :approved),
          Activity.command!(:cmd_missing_import, 50.0, 60.0,
            status: :approved,
            ground_station_id: :equator_prime
          )
        ],
        [
          %{
            "id" => "dl_missing_import",
            "status" => "completed",
            "actual_starts_at_s" => 31.0,
            "actual_ends_at_s" => 39.0
          },
          %{
            "id" => "cmd_missing_import",
            "status" => "executed",
            "actual_starts_at_s" => 50.0,
            "actual_ends_at_s" => 58.0
          }
        ]
      )

    assert %{
             "activity_id" => "dl_missing_import",
             "status" => "matched",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_missing_import"))

    assert %{
             "activity_id" => "cmd_missing_import",
             "status" => "matched",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_missing_import"))

    assert %{
             "activity_id" => "dl_missing_import",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "prepare_cadence_import",
             "reason" =>
               "realized contact completed but planned contact is missing Cadence import identity"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_missing_import")
             )

    assert %{
             "activity_id" => "cmd_missing_import",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "prepare_cadence_import",
             "reason" =>
               "realized command activity executed but planned command is missing Cadence import identity"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_missing_import")
             )

    assert %{
             "activity_id" => "dl_missing_import",
             "import_action" => "review_realized_feedback",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_action" => "prepare_cadence_import",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "dl_missing_import")
             )

    assert %{
             "activity_id" => "cmd_missing_import",
             "import_action" => "review_realized_feedback",
             "import_status" => "blocked_missing_cadence_import",
             "source_review_action" => "prepare_cadence_import",
             "cadence_import_status" => "missing",
             "has_cadence_import" => false
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_missing_import")
             )

    assert report["cadence_import_manifest"]["missing_import_count"] == 2
    assert report["cadence_import_manifest"]["blocked_count"] == 2

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end

  test "completed feedback for blocked or rejected planned work stays review-gated" do
    report =
      TimelineFeedback.reconcile(
        [
          %{
            id: :cmd_blocked,
            type: :command,
            direction: :command,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            ground_station_id: :equator_prime,
            approval_status: :blocked_by_policy,
            cadence_import: %{activity_type: :command, external_id: :cmd_blocked}
          },
          %{
            id: :cmd_status_blocked,
            type: :command,
            direction: :command,
            scenario_id: :leo_1,
            starts_at_s: 21.0,
            ends_at_s: 29.0,
            ground_station_id: :equator_prime,
            status: :blocked_by_policy,
            approval_status: :approved,
            cadence_import: %{activity_type: :command, external_id: :cmd_status_blocked}
          },
          %{
            id: :dl_rejected,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :equator_prime,
            approval_status: :rejected,
            cadence_import: %{activity_type: :contact, external_id: :dl_rejected}
          }
        ],
        [
          %{
            id: :cmd_blocked,
            status: :executed,
            actual_starts_at_s: 10.0,
            actual_ends_at_s: 19.0
          },
          %{
            id: :cmd_status_blocked,
            status: :executed,
            actual_starts_at_s: 21.0,
            actual_ends_at_s: 28.0
          },
          %{
            id: :dl_rejected,
            status: :completed,
            actual_starts_at_s: 30.0,
            actual_ends_at_s: 39.0
          }
        ]
      )

    assert %{
             "activity_id" => "cmd_blocked",
             "status" => "matched",
             "planned_operator_action" => "resolve_blocked_activity",
             "realized_status" => "executed",
             "cadence_import_status" => "present"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_blocked"))

    assert %{
             "activity_id" => "cmd_status_blocked",
             "status" => "matched",
             "planned_operator_action" => "resolve_blocked_activity",
             "planned_operator_action_reason" => "activity_status_blocked_by_policy",
             "realized_status" => "executed",
             "cadence_import_status" => "present"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_status_blocked"))

    assert %{
             "activity_id" => "dl_rejected",
             "status" => "matched",
             "planned_operator_action" => "resolve_rejected_activity",
             "realized_status" => "completed",
             "cadence_import_status" => "present"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "dl_rejected"))

    assert %{
             "activity_id" => "cmd_blocked",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "resolve_blocked_activity",
             "reason" => "realized feedback arrived for policy-blocked planned activity"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_blocked")
             )

    assert %{
             "activity_id" => "cmd_status_blocked",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "resolve_blocked_activity",
             "planned_operator_action_reason" => "activity_status_blocked_by_policy",
             "reason" => "realized feedback arrived for status-blocked planned activity"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "cmd_status_blocked")
             )

    assert %{
             "activity_id" => "dl_rejected",
             "approval_status" => "operator_review_required",
             "required_operator_action" => "resolve_rejected_activity",
             "reason" => "realized feedback arrived for rejected planned activity"
           } =
             Enum.find(
               report["operator_review_package"]["rows"],
               &(&1["activity_id"] == "dl_rejected")
             )

    assert %{
             "activity_id" => "cmd_blocked",
             "import_action" => "review_realized_feedback",
             "import_status" => "review_required_before_import",
             "source_review_action" => "resolve_blocked_activity"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_blocked")
             )

    assert %{
             "activity_id" => "cmd_status_blocked",
             "import_action" => "review_realized_feedback",
             "import_status" => "review_required_before_import",
             "source_review_action" => "resolve_blocked_activity",
             "planned_operator_action_reason" => "activity_status_blocked_by_policy"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "cmd_status_blocked")
             )

    assert %{
             "activity_id" => "dl_rejected",
             "import_action" => "review_realized_feedback",
             "import_status" => "review_required_before_import",
             "source_review_action" => "resolve_rejected_activity"
           } =
             Enum.find(
               report["cadence_import_manifest"]["rows"],
               &(&1["activity_id"] == "dl_rejected")
             )

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(report["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(report["cadence_import_manifest"])
  end
end
