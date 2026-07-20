defmodule OrbitalDynamics.Schema.ContactFeedbackSchemaContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested realized-state and timeline-feedback row schemas" do
    assert {:ok, realized_schema} = Schema.json_schema("realized_state_snapshot.v1")

    activity_schema = get_in(realized_schema, ["properties", "activities", "items"])

    assert activity_schema["required"] == ["schema_contract", "id", "status"]

    assert get_in(activity_schema, ["properties", "schema_contract", "const"]) ==
             "realized_activity.v1"

    assert get_in(activity_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(activity_schema, ["properties", "status", "enum"]) == [
             "completed",
             "executed",
             "partial",
             "missed",
             "failed",
             "delayed",
             "canceled",
             "cancelled",
             "rejected"
           ]

    assert get_in(realized_schema, [
             "properties",
             "spacecraft_states",
             "items",
             "required"
           ]) == ["scenario_id"]

    assert get_in(realized_schema, [
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "scenario_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_schema, [
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "antenna_available",
             "type"
           ]) == "boolean"

    assert get_in(realized_schema, [
             "properties",
             "spacecraft_states",
             "items",
             "properties",
             "incompatible_activity_types",
             "items",
             "type"
           ]) == "string"

    metadata_schema = get_in(realized_schema, ["properties", "metadata"])

    assert get_in(metadata_schema, ["properties", "external_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(metadata_schema, [
             "allOf",
             Access.at(0),
             "then",
             "anyOf",
             Access.at(0),
             "required"
           ]) == ["trust_boundary"]

    assert get_in(realized_schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.CampaignPlanner.realized_state_snapshot_model_limits()

    realized_activity_schema =
      get_in(realized_schema, ["properties", "activities", "items", "properties"])

    assert get_in(realized_activity_schema, ["planned_activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_schema, ["timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert {:ok, realized_activity_contract_schema} = Schema.json_schema("realized_activity.v1")

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "planned_activity_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "resource_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, ["properties", "activity_type", "type"]) ==
             "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "battery_state_of_charge",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "battery_energy_generated_wh",
             "minimum"
           ]) == 0.0

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "payload_available",
             "type"
           ]) == "boolean"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "suppressed_activity_types",
             "items",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "collection_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "product_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_data_volume_mb",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_starts_at_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_ends_at_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_duration_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_data_rate_mbps",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_downlink_rate_mb_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "delivered_rate_mb_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_latency_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "contact_result",
             "type"
           ]) == "string"

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "image_quality_score",
        "eclipse_overlap_fraction",
        "bit_error_rate",
        "packet_loss_rate",
        "frame_loss_rate",
        "cloud_cover_fraction",
        "blur_score",
        "maneuver_success_factor",
        "battery_state_of_charge"
      ],
      fn field ->
        assert get_in(realized_activity_contract_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "observation_success",
             "type"
           ]) == "boolean"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "maneuver_success_factor_source",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "feedback_weight",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "completed_fraction",
             "maximum"
           ]) == 1.0

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "reason",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "delta_v_km_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "delta_v_km_s",
             "minItems"
           ]) == 3

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "execution_uncertainty",
             "type"
           ]) == "object"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "execution_uncertainty",
             "properties",
             "timing_3sigma_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "timing_3sigma_s",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "delta_v_3sigma_km_s",
             "maxItems"
           ]) == 3

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "attitude_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "pointing_target_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "off_nadir_angle_deg",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "pointing_confidence",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "thermal_zone_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "actual_temperature_c",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "thermal_confidence",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "lighting_condition",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "lighting_confidence",
             "type"
           ]) == ["number", "string"]

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "frequency_band",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "data_rate_mbps",
             "type"
           ]) == "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "carrier_lock",
             "type"
           ]) == "boolean"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "command_authority_status",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "required_authority",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "command_safety_status",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "command_authorized",
             "type"
           ]) == "boolean"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "command_safety_checked",
             "type"
           ]) == "boolean"

    assert get_in(realized_activity_contract_schema, ["properties", "roll_deg", "type"]) ==
             "number"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "attitude_confidence",
             "type"
           ]) == "number"

    Enum.each(["pointing_confidence", "attitude_confidence", "thermal_confidence"], fn field ->
      assert get_in(realized_activity_contract_schema, ["properties", field]) == %{
               "type" => "number",
               "minimum" => 0.0,
               "maximum" => 1.0
             }
    end)

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "received_at",
             "type"
           ]) == "string"

    assert get_in(realized_activity_contract_schema, [
             "properties",
             "ingested_at",
             "type"
           ]) == "string"

    assert {:ok, feedback_schema} = Schema.json_schema("timeline_feedback_report.v1")

    row_schema = get_in(feedback_schema, ["properties", "rows", "items"])

    assert get_in(feedback_schema, ["properties", "model", "const"]) ==
             "planned_vs_realized_activity_reconciliation"

    assert get_in(feedback_schema, [
             "properties",
             "status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.TimelineFeedback.capabilities().report_statuses

    assert get_in(feedback_schema, [
             "properties",
             "feedback_kind_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.TimelineFeedback.capabilities().feedback_kinds

    assert get_in(feedback_schema, [
             "properties",
             "match_strategy_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.TimelineFeedback.capabilities().match_strategies

    assert get_in(feedback_schema, [
             "properties",
             "cadence_import_status_counts",
             "propertyNames",
             "enum"
           ]) == OrbitalDynamics.TimelineFeedback.capabilities().cadence_import_statuses

    assert get_in(feedback_schema, [
             "properties",
             "planned_protection_decision_counts",
             "additionalProperties"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(feedback_schema, ["properties", "planned_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(feedback_schema, ["properties", "ambiguous_timeline_feedback_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(feedback_schema, ["properties", "model_limits", "const"]) ==
             timeline_feedback_report_model_limits()

    assert get_in(feedback_schema, [
             "properties",
             "operational_feedback",
             "properties",
             "cloud_cover_fraction",
             "additionalProperties",
             "maximum"
           ]) == 1.0

    assert get_in(feedback_schema, [
             "properties",
             "operational_feedback",
             "properties",
             "image_quality_source",
             "additionalProperties",
             "type"
           ]) == "string"

    provenance_schema = get_in(feedback_schema, ["properties", "operational_feedback_provenance"])
    provenance_source_schema = get_in(provenance_schema, ["properties", "sources", "items"])

    assert get_in(provenance_schema, ["properties", "model", "const"]) ==
             "timeline_feedback_report_rows_to_operational_feedback"

    assert get_in(provenance_schema, ["properties", "merge_order", "items", "type"]) == "string"
    assert get_in(provenance_schema, ["properties", "input_keys", "items", "type"]) == "string"

    assert get_in(provenance_schema, ["properties", "source_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(provenance_schema, ["properties", "explicit_request_override", "type"]) ==
             "boolean"

    assert get_in(provenance_source_schema, [
             "properties",
             "source_report_contract",
             "const"
           ]) == "timeline_feedback_report.v1"

    assert get_in(provenance_source_schema, ["properties", "source", "type"]) == "string"

    assert get_in(provenance_source_schema, ["properties", "input_keys", "items", "type"]) ==
             "string"

    assert get_in(provenance_source_schema, ["properties", "trust_boundary_status", "type"]) ==
             "string"

    assert get_in(provenance_source_schema, ["properties", "trust_boundaries", "items", "type"]) ==
             "string"

    assert get_in(provenance_source_schema, [
             "properties",
             "feedback_weight_sources",
             "items",
             "type"
           ]) == "string"

    for field <- [
          "source_report_count",
          "source_report_row_count",
          "realized_activity_count",
          "weighted_feedback_row_count",
          "source_operational_feedback_excluded_count"
        ] do
      assert get_in(provenance_source_schema, ["properties", field]) == %{
               "type" => "integer",
               "minimum" => 0
             }
    end

    for field <- [
          "source_report_status_counts",
          "source_feedback_kind_counts",
          "source_match_strategy_counts",
          "source_cadence_import_status_counts",
          "source_planned_protection_decision_counts",
          "source_realized_source_quality_counts"
        ] do
      assert get_in(provenance_source_schema, [
               "properties",
               field,
               "additionalProperties"
             ]) == %{"type" => "integer", "minimum" => 0}
    end

    assert get_in(provenance_source_schema, [
             "properties",
             "feedback_trust_boundaries",
             "additionalProperties",
             "items",
             "type"
           ]) == "string"

    assert row_schema["required"] == ["activity_id", "status"]

    assert get_in(row_schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "status", "enum"]) ==
             OrbitalDynamics.TimelineFeedback.capabilities().report_statuses

    assert get_in(row_schema, ["properties", "start_delta_s", "type"]) == "number"

    assert get_in(row_schema, ["properties", "match_strategy", "enum"]) ==
             OrbitalDynamics.TimelineFeedback.capabilities().match_strategies

    assert get_in(row_schema, ["properties", "feedback_kind", "enum"]) ==
             OrbitalDynamics.TimelineFeedback.capabilities().feedback_kinds

    assert get_in(row_schema, ["properties", "planned_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "realized_timeline_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "realized_activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    for field <- [
          "source_window_ids",
          "collection_ids",
          "product_ids",
          "payload_ids",
          "instrument_ids"
        ] do
      assert get_in(row_schema, [
               "properties",
               field,
               "items",
               "pattern"
             ]) == Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(row_schema, ["properties", "planned_estimated_throughput_mb", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "actual_throughput_mb", "type"]) == "number"

    assert get_in(row_schema, [
             "properties",
             "actual_data_rate_throughput_derivation",
             "properties",
             "rate_unit",
             "type"
           ]) == "string"

    assert get_in(row_schema, ["properties", "actual_data_volume_mb", "type"]) == "number"
    assert get_in(row_schema, ["properties", "throughput_delta_mb", "type"]) == "number"
    assert get_in(row_schema, ["properties", "contact_success", "type"]) == "boolean"
    assert get_in(row_schema, ["properties", "command_success", "type"]) == "boolean"
    assert get_in(row_schema, ["properties", "command_authority_status", "type"]) == "string"

    assert get_in(row_schema, ["properties", "realized_command_authority_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "required_authority", "type"]) == "string"
    assert get_in(row_schema, ["properties", "realized_required_authority", "type"]) == "string"
    assert get_in(row_schema, ["properties", "command_safety_status", "type"]) == "string"

    assert get_in(row_schema, ["properties", "realized_command_safety_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "command_authorized", "type"]) == "boolean"

    assert get_in(row_schema, ["properties", "realized_command_authorized", "type"]) ==
             "boolean"

    assert get_in(row_schema, ["properties", "command_safety_checked", "type"]) == "boolean"

    assert get_in(row_schema, ["properties", "realized_command_safety_checked", "type"]) ==
             "boolean"

    for field <- [
          "spacecraft_available",
          "planned_spacecraft_available",
          "realized_spacecraft_available",
          "payload_available",
          "planned_payload_available",
          "realized_payload_available",
          "antenna_available",
          "planned_antenna_available",
          "realized_antenna_available",
          "degraded",
          "planned_degraded",
          "realized_degraded"
        ] do
      assert get_in(row_schema, ["properties", field, "type"]) == "boolean"
    end

    for field <- [
          "spacecraft_available_match_status",
          "payload_available_match_status",
          "antenna_available_match_status",
          "degraded_match_status",
          "mode",
          "planned_mode",
          "realized_mode",
          "mode_match_status"
        ] do
      assert get_in(row_schema, ["properties", field, "type"]) == "string"
    end

    assert get_in(row_schema, [
             "properties",
             "source_activity_context",
             "properties",
             "command_safety_checked",
             "type"
           ]) == "boolean"

    Enum.each(
      [
        "contact_success_factor",
        "command_success_factor",
        "observation_success_factor",
        "maneuver_success_factor",
        "attitude_confidence",
        "battery_state_of_charge",
        "eclipse_overlap_fraction",
        "planned_eclipse_overlap_fraction",
        "realized_eclipse_overlap_fraction",
        "bit_error_rate",
        "planned_bit_error_rate",
        "realized_bit_error_rate",
        "packet_loss_rate",
        "planned_packet_loss_rate",
        "realized_packet_loss_rate",
        "frame_loss_rate",
        "planned_frame_loss_rate",
        "realized_frame_loss_rate",
        "image_quality_score",
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score",
        "image_quality_score",
        "planned_image_quality_score",
        "realized_image_quality_score"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    Enum.each(
      [
        "cloud_cover_fraction",
        "planned_cloud_cover_fraction",
        "realized_cloud_cover_fraction",
        "blur_score",
        "planned_blur_score",
        "realized_blur_score"
      ],
      fn field ->
        assert get_in(row_schema, ["properties", field]) == %{
                 "type" => "number",
                 "minimum" => 0.0,
                 "maximum" => 1.0
               }
      end
    )

    assert get_in(row_schema, ["properties", "station_calendar_entry_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "station_calendar_overlap_count", "minimum"]) == 0

    assert get_in(row_schema, [
             "properties",
             "station_calendar_overlap_entry_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "station_calendar_reservation_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "station_calendar_reservation_expires_at_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(row_schema, ["properties", "station_reservation_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "station_reservation_expires_at_s", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "dependency_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "exclusive_with_timeline_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "planned_delta_v_km_s", "items", "type"]) ==
             "number"

    assert get_in(row_schema, ["properties", "source_protection_decision", "type"]) ==
             "object"

    assert get_in(row_schema, ["properties", "timeline_identity", "type"]) == "object"

    assert get_in(row_schema, ["properties", "realized_activity", "properties", "status", "enum"]) ==
             [
               "completed",
               "executed",
               "partial",
               "missed",
               "failed",
               "delayed",
               "canceled",
               "cancelled",
               "rejected"
             ]

    feedback_report = read_json!("study_results/timeline_feedback_report_v1.json")

    invalid_model = Map.put(feedback_report, "model", "timeline_feedback_v0")

    assert {:error, invalid_model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"planned_vs_realized_activity_reconciliation\"")
           )

    stale_model_limits = Map.put(feedback_report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match timeline feedback report model limits")
           )

    invalid_feedback_counts =
      put_in(feedback_report, ["feedback_kind_counts", "maneuver"], 99)

    assert {:error, invalid_feedback_counts_report} =
             Schema.validate_artifact(invalid_feedback_counts)

    assert Enum.any?(
             invalid_feedback_counts_report["errors"],
             &(&1["path"] == "$.feedback_kind_counts")
           )

    invalid_negative_counts = put_in(feedback_report, ["status_counts", "matched"], -1)

    assert {:error, invalid_negative_counts_report} =
             Schema.validate_artifact(invalid_negative_counts)

    assert Enum.any?(
             invalid_negative_counts_report["errors"],
             &(&1["path"] == "$.status_counts.matched")
           )

    invalid_float_planned_count = Map.put(feedback_report, "planned_count", 1.0)

    assert {:error, invalid_float_planned_count_report} =
             Schema.validate_artifact(invalid_float_planned_count)

    assert Enum.any?(
             invalid_float_planned_count_report["errors"],
             &(&1["path"] == "$.planned_count")
           )

    invalid_negative_ambiguous_count =
      Map.put(feedback_report, "ambiguous_timeline_feedback_count", -1)

    assert {:error, invalid_negative_ambiguous_count_report} =
             Schema.validate_artifact(invalid_negative_ambiguous_count)

    assert Enum.any?(
             invalid_negative_ambiguous_count_report["errors"],
             &(&1["path"] == "$.ambiguous_timeline_feedback_count")
           )

    Enum.each(
      [
        {"contact_success_factor", 1.5},
        {"command_success_factor", -0.1},
        {"observation_success_factor", 1.1},
        {"maneuver_success_factor", -0.2},
        {"battery_state_of_charge", 1.2},
        {"eclipse_overlap_fraction", 1.2},
        {"planned_eclipse_overlap_fraction", -0.1},
        {"realized_eclipse_overlap_fraction", 1.1},
        {"bit_error_rate", 1.2},
        {"planned_packet_loss_rate", -0.1},
        {"realized_frame_loss_rate", 1.1},
        {"image_quality_score", 1.2},
        {"planned_image_quality_score", -0.1},
        {"realized_image_quality_score", 1.1}
      ],
      fn {field, value} ->
        invalid_success_factor =
          put_in(feedback_report, ["rows", Access.at(0), field], value)

        assert {:error, invalid_success_factor_report} =
                 Schema.validate_artifact(invalid_success_factor)

        assert Enum.any?(
                 invalid_success_factor_report["errors"],
                 &(&1["path"] == "$.rows[0].#{field}")
               )
      end
    )

    Enum.each(
      [
        {"cloud_cover_fraction", 1.5},
        {"planned_cloud_cover_fraction", -0.1},
        {"realized_cloud_cover_fraction", 1.1},
        {"blur_score", -0.2},
        {"planned_blur_score", 1.2},
        {"realized_blur_score", -0.3}
      ],
      fn {field, value} ->
        invalid_quality_fraction =
          put_in(feedback_report, ["rows", Access.at(0), field], value)

        assert {:error, invalid_quality_fraction_report} =
                 Schema.validate_artifact(invalid_quality_fraction)

        assert Enum.any?(
                 invalid_quality_fraction_report["errors"],
                 &(&1["path"] == "$.rows[0].#{field}")
               )
      end
    )

    Enum.each(
      [
        {"source_window_ids", ["window:valid", "bad source window"]},
        {"collection_ids", ["collection_alpha", "bad collection"]},
        {"product_ids", ["product_alpha", "bad product"]},
        {"payload_ids", ["payload_alpha", "bad payload"]},
        {"instrument_ids", ["instrument_alpha", "bad instrument"]}
      ],
      fn {field, value} ->
        invalid_identity_list =
          put_in(feedback_report, ["rows", Access.at(0), field], value)

        assert {:error, invalid_identity_list_report} =
                 Schema.validate_artifact(invalid_identity_list)

        assert Enum.any?(
                 invalid_identity_list_report["errors"],
                 &(&1["path"] == "$.rows[0].#{field}[1]")
               )
      end
    )
  end

  defp timeline_feedback_report_model_limits do
    OrbitalDynamics.TimelineFeedback.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
