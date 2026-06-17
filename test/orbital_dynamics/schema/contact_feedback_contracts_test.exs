defmodule OrbitalDynamics.Schema.ContactFeedbackContractsTest do
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

  test "validates checked-in timeline feedback report fixture" do
    report = read_json!("study_results/timeline_feedback_report_v1.json")

    planned_activities =
      report["rows"]
      |> Enum.map(& &1["planned_activity"])
      |> Enum.reject(&is_nil/1)

    realized_activities =
      report["rows"]
      |> Enum.map(& &1["realized_activity"])
      |> Enum.reject(&is_nil/1)

    generated_report =
      OrbitalDynamics.reconcile_timeline_feedback(planned_activities, realized_activities)

    assert generated_report == report

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "schema_contract" => "timeline_feedback_report.v1",
             "model" => "planned_vs_realized_activity_reconciliation",
             "planned_count" => 4,
             "realized_count" => 4,
             "row_count" => 4,
             "duplicate_realized_match_count" => 0,
             "duplicate_realized_feedback_count" => 0,
             "ambiguous_timeline_match_count" => 0,
             "ambiguous_timeline_feedback_count" => 0,
             "status_counts" => %{"matched" => 4},
             "feedback_kind_counts" => %{
               "command" => 1,
               "contact" => 1,
               "maneuver" => 1,
               "observation" => 1
             },
             "match_strategy_counts" => %{"planned_activity_id" => 4},
             "cadence_import_status_counts" => %{
               "missing" => 1,
               "not_applicable" => 2,
               "present" => 1
             },
             "planned_protection_decision_counts" => %{"preserve" => 4},
             "execution_uncertainty_declared_count" => 0,
             "execution_uncertainty_missing_count" => 1,
             "operational_feedback_excluded_count" => 1,
             "model_limits" => [
               "artifact_level_only",
               "no_schedule_mutation",
               "no_command_execution",
               "no_operator_authority_decision",
               "timing_deltas_require_declared_actual_times"
             ],
             "assumptions" => %{
               "boundary" => "report_only_no_schedule_mutation",
               "dependency_model" =>
                 "planned dependencies and exclusivity are checked inside the artifact when referenced rows are present; missing dependency checks are opt-in and schedules are not mutated",
               "identity_match" =>
                 "planned.id matches realized.planned_activity_id, realized.timeline_id, or realized.id; duplicate planned timeline identities are review-gated as ambiguous",
               "missing_dependency_validation" => "disabled",
               "timing_delta" => "actual time minus planned time when both are declared"
             }
           } = report

    assert %{
             "command_success_rate" => %{"cmd_repoint" => 0.88},
             "downlink_demand_mb" => %{"default" => 64.0},
             "maneuver_execution_uncertainty" => %{
               "burn_cleanup" => %{"execution_uncertainty_status" => "missing"}
             },
             "observation_success_rate" => %{"target_a" => 0.55}
           } = report["operational_feedback"]

    assert report["operational_feedback"]["maneuver_success_rate"]["burn_cleanup"] == 0.0

    assert %{
             "source_count" => 1,
             "input_keys" => [
               "command_success_rate",
               "downlink_demand_mb",
               "downlink_demand_sources",
               "maneuver_execution_uncertainty",
               "maneuver_success_rate",
               "observation_success_rate"
             ],
             "merge_order" => ["timeline_feedback_report.rows"],
             "sources" => [
               %{
                 "source" => "timeline_feedback_report.rows",
                 "source_report_contract" => "timeline_feedback_report.v1",
                 "source_report_count" => 1,
                 "source_report_row_count" => 4,
                 "realized_activity_count" => 4,
                 "source_report_status_counts" => %{"matched" => 4},
                 "source_feedback_kind_counts" => %{
                   "command" => 1,
                   "contact" => 1,
                   "maneuver" => 1,
                   "observation" => 1
                 },
                 "source_match_strategy_counts" => %{"planned_activity_id" => 4},
                 "source_cadence_import_status_counts" => %{
                   "missing" => 1,
                   "not_applicable" => 2,
                   "present" => 1
                 },
                 "source_planned_protection_decision_counts" => %{"preserve" => 4},
                 "source_execution_uncertainty_declared_count" => 0,
                 "source_execution_uncertainty_missing_count" => 1,
                 "source_operational_feedback_excluded_count" => 1,
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["operator_supplied"]
               }
             ]
           } = report["operational_feedback_provenance"]

    assert %{
             "realized_feedback|prepare_cadence_import|operator_review_required" => 1,
             "realized_feedback|record_realized_completion|not_required" => 1,
             "realized_feedback|review_contact_variance|operator_review_required" => 1,
             "realized_feedback|review_maneuver_exception|operator_review_required" => 1
           } = report["operator_review_package"]["review_queue_counts"]

    assert %{
             "cadence_import_status_counts" => %{
               "missing" => 1,
               "not_applicable" => 2,
               "present" => 1
             },
             "row_count" => 4
           } = report["cadence_import_manifest"]

    rows_by_activity_id = Map.new(report["rows"], &{&1["activity_id"], &1})

    assert %{
             "status" => "matched",
             "feedback_kind" => "maneuver",
             "match_strategy" => "planned_activity_id",
             "cadence_import_status" => "not_applicable",
             "planned_protection_decision" => "preserve",
             "planned_operator_action" => "review_activity_approval",
             "execution_uncertainty_status" => "missing",
             "maneuver_success" => false,
             "realized_activity_id" => "provider_burn_feedback_1"
           } = rows_by_activity_id["burn_cleanup"]

    assert %{
             "status" => "matched",
             "feedback_kind" => "command",
             "match_strategy" => "planned_activity_id",
             "cadence_import_status" => "missing",
             "planned_operator_action" => "prepare_cadence_import",
             "command_success" => true
           } = rows_by_activity_id["cmd_repoint"]

    assert rows_by_activity_id["cmd_repoint"]["start_delta_s"] == 1.0
    assert rows_by_activity_id["cmd_repoint"]["end_delta_s"] == -1.0

    assert %{
             "status" => "matched",
             "feedback_kind" => "contact",
             "match_strategy" => "planned_activity_id",
             "cadence_import_status" => "present",
             "contact_success" => false
           } = rows_by_activity_id["downlink_equator"]

    assert rows_by_activity_id["downlink_equator"]["start_delta_s"] == 2.0
    assert rows_by_activity_id["downlink_equator"]["end_delta_s"] == -10.0

    assert %{
             "status" => "matched",
             "feedback_kind" => "observation",
             "match_strategy" => "planned_activity_id",
             "cadence_import_status" => "not_applicable",
             "observation_success" => true,
             "realized_activity_id" => "provider_observation_feedback_1"
           } = rows_by_activity_id["obs_feedback"]
  end

  test "exports contact intent approval schemas" do
    assert {:ok, schema} = Schema.json_schema("contact_intent.v1")

    assert get_in(schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    requirement_schema = get_in(schema, ["properties", "approval_requirements", "items"])

    assert get_in(requirement_schema, ["properties", "schema_contract", "const"]) ==
             "approval_requirement.v1"

    assert get_in(requirement_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    assert get_in(schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "classification",
             "enum"
           ]) == ["auto_approvable", "operator_review_required", "blocked_by_policy"]
  end

  test "validates realized feedback row and snapshot contracts" do
    realized_activity = %{
      "schema_contract" => "realized_activity.v1",
      "id" => "dl_1",
      "planned_activity_id" => "downlink_equator",
      "timeline_id" =>
        "timeline:downlink:equator_prime:window:leo_1:ground_station_access:equator_prime:1",
      "status" => "partial",
      "type" => "downlink",
      "direction" => "downlink",
      "ground_station_id" => "equator_prime",
      "station" => %{"id" => "equator_prime"},
      "ground_station" => %{"station_id" => "equator_prime"},
      "target" => %{"id" => "target_a"},
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
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
      "collection_id" => "collection_alpha",
      "product_id" => "image_alpha_1",
      "product_ids" => ["image_alpha_1", "image_alpha_2"],
      "payload_id" => "payload_camera",
      "instrument_id" => "narrow_angle_camera",
      "data_volume_mb" => 80.0,
      "planned_data_volume_mb" => 80.0,
      "actual_data_volume_mb" => 60.0,
      "estimated_data_volume_mb" => 80.0,
      "estimated_storage_mb" => 80.0,
      "estimated_downlink_mb" => 72.0,
      "required_downlink_mb" => 72.0,
      "collection_ends_at_s" => 360.0,
      "planned_delivery_at_s" => 540.0,
      "actual_delivery_at_s" => 570.0,
      "max_latency_s" => 240.0,
      "planned_latency_s" => 180.0,
      "actual_latency_s" => 210.0,
      "planned_estimated_throughput_mb" => 72.0,
      "target_priority" => 4.0,
      "contact_result" => "dropped",
      "contact_success_factor" => 0.25,
      "contact_success_factor_source" => "provider_contact_quality",
      "command_success_factor" => 1.0,
      "command_success_factor_source" => "provider_command_acceptance",
      "observation_success" => false,
      "observation_result" => "clouded",
      "observation_success_factor" => 0.0,
      "observation_success_factor_source" => "provider_observation_result",
      "maneuver_success" => false,
      "maneuver_result" => "underburn",
      "maneuver_success_factor" => 0.4,
      "maneuver_success_factor_source" => "provider_maneuver_reconstruction",
      "feedback_weight" => 3.0,
      "feedback_weight_source" => "provider_sample_count",
      "delta_v_km_s" => [0.0, 0.008, 0.0],
      "actual_delta_v_km_s" => [0.0, 0.008, 0.0],
      "executed_delta_v_km_s" => [0.0, 0.008, 0.0],
      "delta_v_magnitude_km_s" => 0.008,
      "execution_uncertainty" => %{
        "timing_3sigma_s" => 5.0,
        "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
        "source" => "provider_execution_covariance"
      },
      "execution_uncertainty_status" => "declared",
      "timing_3sigma_s" => 5.0,
      "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
      "delta_v_3sigma_magnitude_km_s" => 0.001,
      "execution_uncertainty_source" => "provider_execution_covariance",
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
      "link_quality_status" => "low_margin",
      "actual_starts_at_s" => 100.0,
      "actual_ends_at_s" => 145.0,
      "actual_duration_s" => 45.0,
      "actual_throughput_mb" => 72.0,
      "actual_data_rate_mbps" => 12.8,
      "actual_downlink_rate_mb_s" => 1.6,
      "delivered_rate_mb_s" => 1.6,
      "contact_success" => false,
      "completed_fraction" => 0.75,
      "reason" => "station mask",
      "source" => %{"system" => "cadence_execution_feedback", "source_id" => "feedback-1"},
      "metadata" => %{"operator" => "alpha"}
    }

    realized_snapshot = %{
      "schema_contract" => "realized_state_snapshot.v1",
      "activities" => [realized_activity],
      "spacecraft_states" => [],
      "metadata" => %{"snapshot_id" => "ops-1"}
    }

    assert {:ok, %{"schema_contract" => "realized_activity.v1"}} =
             Schema.validate_artifact(realized_activity)

    assert {:ok, %{"schema_contract" => "realized_state_snapshot.v1"}} =
             Schema.validate_artifact(realized_snapshot)

    invalid_snapshot = put_in(realized_snapshot, ["activities", Access.at(0), "status"], "lost")

    assert {:error, report} = Schema.validate_artifact(invalid_snapshot)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.activities[0].status"))

    provider_snapshot =
      put_in(realized_snapshot, ["metadata"], %{
        "snapshot_id" => "ops-1",
        "provider" => "cadence",
        "adapter" => "cadence_feedback_adapter"
      })

    assert {:error, provider_snapshot_report} = Schema.validate_artifact(provider_snapshot)

    assert Enum.any?(
             provider_snapshot_report["errors"],
             &(&1["path"] == "$.metadata.trust_boundary" and
                 &1["message"] =~ "metadata requires trust_boundary")
           )

    invalid_spacecraft_snapshot =
      put_in(realized_snapshot, ["spacecraft_states"], [
        %{
          "spacecraft_id" => "sat 1",
          "mode" => "safe",
          "incompatible_activity_types" => ["downlink", 1]
        }
      ])

    assert {:error, spacecraft_report} = Schema.validate_artifact(invalid_spacecraft_snapshot)

    assert Enum.any?(
             spacecraft_report["errors"],
             &(&1["path"] == "$.spacecraft_states[0].scenario_id")
           )

    assert Enum.any?(
             spacecraft_report["errors"],
             &(&1["path"] == "$.spacecraft_states[0].spacecraft_id")
           )

    assert Enum.any?(
             spacecraft_report["errors"],
             &(&1["path"] == "$.spacecraft_states[0].incompatible_activity_types[1]")
           )

    invalid_limits =
      Map.put(realized_snapshot, "model_limits", ["provider_feedback_snapshot_only"])

    assert {:error, limits_report} = Schema.validate_artifact(invalid_limits)
    assert Enum.any?(limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_source_window =
      put_in(realized_activity, ["source_window_id"], "window id with spaces")

    assert {:error, source_window_report} = Schema.validate_artifact(invalid_source_window)
    assert Enum.any?(source_window_report["errors"], &(&1["path"] == "$.source_window_id"))

    invalid_timeline_id = put_in(realized_activity, ["timeline_id"], "timeline id with spaces")

    assert {:error, timeline_id_report} = Schema.validate_artifact(invalid_timeline_id)
    assert Enum.any?(timeline_id_report["errors"], &(&1["path"] == "$.timeline_id"))

    invalid_resource_id = put_in(realized_activity, ["resource_id"], "resource id with spaces")

    assert {:error, resource_id_report} = Schema.validate_artifact(invalid_resource_id)
    assert Enum.any?(resource_id_report["errors"], &(&1["path"] == "$.resource_id"))

    invalid_resource_provenance =
      put_in(realized_activity, ["resource_provenance"], "mission_database")

    assert {:error, resource_provenance_report} =
             Schema.validate_artifact(invalid_resource_provenance)

    assert Enum.any?(
             resource_provenance_report["errors"],
             &(&1["path"] == "$.resource_provenance")
           )

    invalid_suppressed_activity =
      put_in(realized_activity, ["suppressed_activity_types"], ["observe", 1])

    assert {:error, suppressed_activity_report} =
             Schema.validate_artifact(invalid_suppressed_activity)

    assert Enum.any?(
             suppressed_activity_report["errors"],
             &(&1["path"] == "$.suppressed_activity_types[1]")
           )

    invalid_collection_id =
      put_in(realized_activity, ["collection_id"], "collection id with spaces")

    assert {:error, collection_id_report} = Schema.validate_artifact(invalid_collection_id)
    assert Enum.any?(collection_id_report["errors"], &(&1["path"] == "$.collection_id"))

    invalid_product_id = put_in(realized_activity, ["product_id"], "product id with spaces")

    assert {:error, product_id_report} = Schema.validate_artifact(invalid_product_id)
    assert Enum.any?(product_id_report["errors"], &(&1["path"] == "$.product_id"))

    invalid_product_ids =
      put_in(realized_activity, ["product_ids"], ["image_alpha_1", "product id with spaces"])

    assert {:error, product_ids_report} = Schema.validate_artifact(invalid_product_ids)
    assert Enum.any?(product_ids_report["errors"], &(&1["path"] == "$.product_ids[1]"))

    invalid_payload_id = put_in(realized_activity, ["payload_id"], "payload id with spaces")

    assert {:error, payload_id_report} = Schema.validate_artifact(invalid_payload_id)
    assert Enum.any?(payload_id_report["errors"], &(&1["path"] == "$.payload_id"))

    invalid_instrument_id =
      put_in(realized_activity, ["instrument_id"], "instrument id with spaces")

    assert {:error, instrument_id_report} = Schema.validate_artifact(invalid_instrument_id)
    assert Enum.any?(instrument_id_report["errors"], &(&1["path"] == "$.instrument_id"))

    invalid_actual_data_volume =
      put_in(realized_activity, ["actual_data_volume_mb"], "sixty")

    assert {:error, actual_data_volume_report} =
             Schema.validate_artifact(invalid_actual_data_volume)

    assert Enum.any?(
             actual_data_volume_report["errors"],
             &(&1["path"] == "$.actual_data_volume_mb")
           )

    invalid_actual_latency = put_in(realized_activity, ["actual_latency_s"], "late")

    assert {:error, actual_latency_report} = Schema.validate_artifact(invalid_actual_latency)
    assert Enum.any?(actual_latency_report["errors"], &(&1["path"] == "$.actual_latency_s"))

    invalid_actual_rate = put_in(realized_activity, ["actual_data_rate_mbps"], "fast")

    assert {:error, actual_rate_report} = Schema.validate_artifact(invalid_actual_rate)
    assert Enum.any?(actual_rate_report["errors"], &(&1["path"] == "$.actual_data_rate_mbps"))

    invalid_actual_duration = put_in(realized_activity, ["actual_duration_s"], "long")

    assert {:error, actual_duration_report} = Schema.validate_artifact(invalid_actual_duration)
    assert Enum.any?(actual_duration_report["errors"], &(&1["path"] == "$.actual_duration_s"))

    Enum.each(
      [
        {"contact_success_factor", 1.5},
        {"command_success_factor", -0.1},
        {"observation_success_factor", 1.1},
        {"image_quality_score", 1.2},
        {"pointing_confidence", 1.2},
        {"attitude_confidence", -0.1},
        {"thermal_confidence", 1.1},
        {"battery_state_of_charge", 1.2},
        {"eclipse_overlap_fraction", 1.2},
        {"bit_error_rate", 1.2},
        {"packet_loss_rate", -0.1},
        {"frame_loss_rate", 1.1},
        {"cloud_cover_fraction", 1.2},
        {"blur_score", -0.2},
        {"maneuver_success_factor", -0.1}
      ],
      fn {field, value} ->
        invalid_probability_field = put_in(realized_activity, [field], value)

        assert {:error, probability_field_report} =
                 Schema.validate_artifact(invalid_probability_field)

        assert Enum.any?(
                 probability_field_report["errors"],
                 &(&1["path"] == "$.#{field}")
               )
      end
    )

    invalid_observation_success =
      put_in(realized_activity, ["observation_success"], "maybe")

    assert {:error, observation_success_report} =
             Schema.validate_artifact(invalid_observation_success)

    assert Enum.any?(
             observation_success_report["errors"],
             &(&1["path"] == "$.observation_success")
           )

    invalid_feedback_weight = put_in(realized_activity, ["feedback_weight"], "many")

    assert {:error, feedback_weight_report} = Schema.validate_artifact(invalid_feedback_weight)
    assert Enum.any?(feedback_weight_report["errors"], &(&1["path"] == "$.feedback_weight"))

    invalid_delta_v = put_in(realized_activity, ["delta_v_km_s"], [0.0, 0.008])

    assert {:error, delta_v_report} = Schema.validate_artifact(invalid_delta_v)
    assert Enum.any?(delta_v_report["errors"], &(&1["path"] == "$.delta_v_km_s"))

    invalid_uncertainty =
      put_in(realized_activity, ["execution_uncertainty"], "provider_covariance")

    assert {:error, uncertainty_report} = Schema.validate_artifact(invalid_uncertainty)

    assert Enum.any?(
             uncertainty_report["errors"],
             &(&1["path"] == "$.execution_uncertainty")
           )

    invalid_uncertainty_timing =
      put_in(realized_activity, ["execution_uncertainty"], %{"timing_3sigma_s" => "late"})

    assert {:error, uncertainty_timing_report} =
             Schema.validate_artifact(invalid_uncertainty_timing)

    assert Enum.any?(
             uncertainty_timing_report["errors"],
             &(&1["path"] == "$.execution_uncertainty.timing_3sigma_s")
           )

    invalid_delta_v_3sigma =
      put_in(realized_activity, ["delta_v_3sigma_km_s"], [0.0, "uncertain", 0.0])

    assert {:error, delta_v_3sigma_report} = Schema.validate_artifact(invalid_delta_v_3sigma)

    assert Enum.any?(
             delta_v_3sigma_report["errors"],
             &(&1["path"] == "$.delta_v_3sigma_km_s")
           )

    invalid_attitude_target =
      put_in(realized_activity, ["attitude_target_id"], "target id with spaces")

    assert {:error, attitude_target_report} = Schema.validate_artifact(invalid_attitude_target)
    assert Enum.any?(attitude_target_report["errors"], &(&1["path"] == "$.attitude_target_id"))

    invalid_pointing_target =
      put_in(realized_activity, ["pointing_target_id"], "target id with spaces")

    assert {:error, pointing_target_report} = Schema.validate_artifact(invalid_pointing_target)
    assert Enum.any?(pointing_target_report["errors"], &(&1["path"] == "$.pointing_target_id"))

    invalid_off_nadir = put_in(realized_activity, ["off_nadir_angle_deg"], "nadir")

    assert {:error, off_nadir_report} = Schema.validate_artifact(invalid_off_nadir)
    assert Enum.any?(off_nadir_report["errors"], &(&1["path"] == "$.off_nadir_angle_deg"))

    invalid_thermal_zone =
      put_in(realized_activity, ["thermal_zone_id"], "payload deck")

    assert {:error, thermal_zone_report} = Schema.validate_artifact(invalid_thermal_zone)
    assert Enum.any?(thermal_zone_report["errors"], &(&1["path"] == "$.thermal_zone_id"))

    invalid_temperature = put_in(realized_activity, ["actual_temperature_c"], "hot")

    assert {:error, temperature_report} = Schema.validate_artifact(invalid_temperature)
    assert Enum.any?(temperature_report["errors"], &(&1["path"] == "$.actual_temperature_c"))

    invalid_eclipse_overlap =
      put_in(realized_activity, ["eclipse_overlap_fraction"], "partial")

    assert {:error, eclipse_report} = Schema.validate_artifact(invalid_eclipse_overlap)
    assert Enum.any?(eclipse_report["errors"], &(&1["path"] == "$.eclipse_overlap_fraction"))

    invalid_lighting_confidence =
      put_in(realized_activity, ["lighting_confidence"], %{"label" => "sampled"})

    assert {:error, lighting_report} = Schema.validate_artifact(invalid_lighting_confidence)
    assert Enum.any?(lighting_report["errors"], &(&1["path"] == "$.lighting_confidence"))

    invalid_data_rate = put_in(realized_activity, ["data_rate_mbps"], "fast")

    assert {:error, data_rate_report} = Schema.validate_artifact(invalid_data_rate)
    assert Enum.any?(data_rate_report["errors"], &(&1["path"] == "$.data_rate_mbps"))

    invalid_carrier_lock = put_in(realized_activity, ["carrier_lock"], "lost")

    assert {:error, carrier_lock_report} = Schema.validate_artifact(invalid_carrier_lock)
    assert Enum.any?(carrier_lock_report["errors"], &(&1["path"] == "$.carrier_lock"))

    invalid_roll = put_in(realized_activity, ["roll_deg"], "nadir")

    assert {:error, roll_report} = Schema.validate_artifact(invalid_roll)
    assert Enum.any?(roll_report["errors"], &(&1["path"] == "$.roll_deg"))

    invalid_station_object =
      put_in(realized_activity, ["station", "id"], "station id with spaces")

    assert {:error, station_object_report} = Schema.validate_artifact(invalid_station_object)
    assert Enum.any?(station_object_report["errors"], &(&1["path"] == "$.station.id"))

    invalid_target_object = put_in(realized_activity, ["target"], "target_a")

    assert {:error, target_object_report} = Schema.validate_artifact(invalid_target_object)
    assert Enum.any?(target_object_report["errors"], &(&1["path"] == "$.target"))

    provider_missing_external_id =
      realized_activity
      |> Map.put("provider", "cadence")
      |> Map.put("trust_boundary", "operator_supplied")

    assert {:error, provider_missing_external_id_report} =
             Schema.validate_artifact(provider_missing_external_id)

    assert Enum.any?(
             provider_missing_external_id_report["errors"],
             &(&1["path"] == "$.external_id" and
                 &1["message"] =~ "required for provider realized feedback")
           )

    provider_missing_trust_boundary =
      realized_activity
      |> Map.put("provider", "cadence")
      |> Map.put("external_id", "cadence_feedback_1")

    assert {:error, provider_missing_trust_boundary_report} =
             Schema.validate_artifact(provider_missing_trust_boundary)

    assert Enum.any?(
             provider_missing_trust_boundary_report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] =~ "provider realized feedback requires trust_boundary")
           )

    provider_with_provenance_trust =
      provider_missing_trust_boundary
      |> Map.put("provenance", %{"trust_boundary" => "operator_supplied"})

    assert {:ok, %{"schema_contract" => "realized_activity.v1"}} =
             Schema.validate_artifact(provider_with_provenance_trust)
  end

  test "validates checked-in realized feedback examples" do
    realized_activity = read_json!("study_results/realized_activity_v1.json")
    realized_snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    assert {:ok, %{"schema_contract" => "realized_activity.v1"}} =
             Schema.validate_artifact(realized_activity)

    alias_realized_activity =
      realized_activity
      |> Map.delete("type")
      |> Map.put("activity_type", "downlink")

    assert {:ok, %{"schema_contract" => "realized_activity.v1"}} =
             Schema.validate_artifact(alias_realized_activity)

    invalid_alias_realized_activity =
      Map.put(alias_realized_activity, "activity_type", 42)

    assert {:error, alias_report} = Schema.validate_artifact(invalid_alias_realized_activity)
    assert Enum.any?(alias_report["errors"], &(&1["path"] == "$.activity_type"))

    assert %{
             "id" => "downlink_equator",
             "status" => "partial",
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
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
             "collection_id" => "collection_alpha",
             "product_id" => "image_alpha_1",
             "product_ids" => ["image_alpha_1", "image_alpha_2"],
             "payload_id" => "payload_camera",
             "instrument_id" => "narrow_angle_camera",
             "data_volume_mb" => 80.0,
             "planned_data_volume_mb" => 80.0,
             "actual_data_volume_mb" => 60.0,
             "estimated_data_volume_mb" => 80.0,
             "estimated_storage_mb" => 80.0,
             "estimated_downlink_mb" => 72.0,
             "required_downlink_mb" => 72.0,
             "collection_ends_at_s" => 360.0,
             "planned_delivery_at_s" => 540.0,
             "actual_delivery_at_s" => 570.0,
             "max_latency_s" => 240.0,
             "planned_latency_s" => 180.0,
             "actual_latency_s" => 210.0,
             "planned_estimated_throughput_mb" => 72.0,
             "target_priority" => 4.0,
             "contact_result" => "dropped",
             "contact_success_factor" => 0.25,
             "contact_success_factor_source" => "provider_contact_quality",
             "command_success_factor" => 1.0,
             "command_success_factor_source" => "provider_command_acceptance",
             "observation_success" => false,
             "observation_result" => "clouded",
             "observation_success_factor" => observation_success_factor,
             "observation_success_factor_source" => "provider_observation_result",
             "maneuver_success" => false,
             "maneuver_result" => "underburn",
             "maneuver_success_factor" => 0.4,
             "maneuver_success_factor_source" => "provider_maneuver_reconstruction",
             "feedback_weight" => 3.0,
             "feedback_weight_source" => "provider_sample_count",
             "delta_v_km_s" => realized_delta_v_km_s,
             "actual_delta_v_km_s" => actual_delta_v_km_s,
             "executed_delta_v_km_s" => executed_delta_v_km_s,
             "delta_v_magnitude_km_s" => 0.008,
             "execution_uncertainty" => execution_uncertainty,
             "execution_uncertainty_status" => "declared",
             "timing_3sigma_s" => 5.0,
             "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
             "delta_v_3sigma_magnitude_km_s" => 0.001,
             "execution_uncertainty_source" => "provider_execution_covariance",
             "pointing_mode" => "earth_track",
             "pointing_target_id" => "equator_prime",
             "boresight_axis" => "+Z",
             "off_nadir_angle_deg" => 4.5,
             "slew_angle_deg" => 1.0,
             "slew_rate_deg_s" => 0.1,
             "pointing_error_deg" => 0.04,
             "pointing_status" => "verified",
             "pointing_model" => "provider_feedback",
             "pointing_source" => "cadence_execution_feedback",
             "pointing_confidence" => 0.9,
             "attitude_mode" => "earth_track",
             "attitude_target_id" => "equator_prime",
             "roll_deg" => 0.25,
             "pitch_deg" => -0.1,
             "yaw_deg" => 0.5,
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
             "link_quality_status" => "low_margin",
             "actual_throughput_mb" => 72.0,
             "contact_success" => false
           } = realized_activity

    assert observation_success_factor == 0.0
    assert realized_delta_v_km_s == [0.0, 0.008, 0.0]
    assert actual_delta_v_km_s == [0.0, 0.008, 0.0]
    assert executed_delta_v_km_s == [0.0, 0.008, 0.0]

    assert execution_uncertainty == %{
             "timing_3sigma_s" => 5.0,
             "delta_v_3sigma_km_s" => [0.0, 0.001, 0.0],
             "source" => "provider_execution_covariance"
           }

    assert delta_v_3sigma_km_s == [0.0, 0.001, 0.0]

    invalid_completed_fraction = Map.put(realized_activity, "completed_fraction", 1.2)

    assert {:error, completed_fraction_report} =
             Schema.validate_artifact(invalid_completed_fraction)

    assert Enum.any?(
             completed_fraction_report["errors"],
             &(&1["path"] == "$.completed_fraction")
           )

    invalid_ingested_at = Map.put(realized_activity, "ingested_at", 123)

    assert {:error, ingested_at_report} = Schema.validate_artifact(invalid_ingested_at)
    assert Enum.any?(ingested_at_report["errors"], &(&1["path"] == "$.ingested_at"))

    assert {:ok, %{"schema_contract" => "realized_state_snapshot.v1"}} =
             Schema.validate_artifact(realized_snapshot)

    assert %{
             "activities" => [
               %{"id" => "cmd_repoint", "status" => "completed"},
               %{"id" => "downlink_equator", "status" => "partial"}
             ],
             "spacecraft_states" => [%{"scenario_id" => "leo_1"}],
             "metadata" => %{"feedback_boundary" => "artifact_only_no_schedule_mutation"}
           } = realized_snapshot
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
