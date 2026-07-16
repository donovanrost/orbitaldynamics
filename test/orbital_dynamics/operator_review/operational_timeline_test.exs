defmodule OrbitalDynamics.OperatorReview.OperationalTimelineTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "builds review package from operator-relevant operational timeline rows" do
    report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            "id" => "cmd_1",
            "timeline_id" => "timeline:cmd_1",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "status" => "planned",
            "approval_status" => "pending",
            "direction" => "command",
            "ground_station_id" => "dss_14",
            "source_window_id" => "cmd_window_1",
            "activity_template" => %{
              "schema_contract" => "activity_template.v1",
              "id" => "template:command:ops",
              "activity_type" => "command",
              "operational_hints" => %{
                "setup_duration_s" => 15.0,
                "cooldown_duration_s" => 5.0,
                "telemetry_confirmation_required" => true,
                "telemetry_confirmation_status" => "required"
              }
            },
            "dependencies" => ["health_1"],
            "dependency_timeline_ids" => ["timeline:health_1"],
            "exclusive_with_activity_ids" => ["command_chain"],
            "exclusive_with_timeline_ids" => ["timeline:command_chain"],
            "pointing_mode" => "target_track",
            "pointing_target_id" => "target_a",
            "boresight_axis" => "+Z",
            "off_nadir_angle_deg" => 12.0,
            "slew_angle_deg" => 4.0,
            "slew_rate_deg_s" => 0.2,
            "pointing_error_deg" => 0.05,
            "pointing_status" => "within_tolerance",
            "pointing_model" => "attitude_solver:v2",
            "pointing_source" => "mission_plan",
            "pointing_confidence" => 0.92,
            "attitude_mode" => "nadir_track",
            "attitude_target_id" => "target_a",
            "roll_deg" => 1.0,
            "pitch_deg" => -2.0,
            "yaw_deg" => 3.0,
            "attitude_error_deg" => 0.08,
            "attitude_status" => "stable",
            "attitude_model" => "attitude_solver:v2",
            "attitude_source" => "mission_plan",
            "attitude_confidence" => 0.91,
            "link_protocol" => "ccsds",
            "frequency_band" => "x_band",
            "modulation" => "qpsk",
            "coding_scheme" => "ldpc",
            "polarization" => "rhcp",
            "data_rate_mbps" => 12.0,
            "downlink_rate_mbps" => 10.0,
            "data_rate_mb_s" => 1.5,
            "downlink_rate_mb_s" => 1.25,
            "actual_data_rate_mbps" => 9.6,
            "actual_downlink_rate_mbps" => 9.2,
            "actual_data_rate_mb_s" => 1.2,
            "actual_downlink_rate_mb_s" => 1.15,
            "delivered_rate_mbps" => 9.0,
            "received_rate_mbps" => 8.8,
            "delivered_rate_mb_s" => 1.125,
            "received_rate_mb_s" => 1.1,
            "actual_duration_s" => 9.5,
            "actual_contact_duration_s" => 9.0,
            "contact_duration_s" => 10.0,
            "link_margin_db" => 4.5,
            "snr_db" => 12.0,
            "eb_no_db" => 8.5,
            "bit_error_rate" => 1.0e-6,
            "packet_loss_rate" => 0.01,
            "frame_loss_rate" => 0.02,
            "carrier_lock" => true,
            "symbol_lock" => true,
            "link_quality_status" => "nominal",
            "eclipse_overlap_fraction" => 0.4,
            "eclipse_overlap_s" => 24.0,
            "lighting_condition" => "partial_eclipse",
            "lighting_condition_detail" => "mixed_lighting",
            "lighting_condition_model" => "sampled_eclipse_overlap_tag",
            "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
            "lighting_confidence" => 0.82,
            "image_quality_score" => 0.87,
            "image_quality_status" => "usable",
            "image_quality_source" => "payload_processor",
            "cloud_cover_fraction" => 0.12,
            "blur_score" => 0.05,
            "feedback_weight" => 0.7,
            "feedback_weight_source" => "operator_tuning",
            "maneuver_success" => true,
            "maneuver_result" => ["completed", "within_tolerance"],
            "thermal_zone_id" => "payload_deck",
            "temperature_c" => 21.5,
            "planned_temperature_c" => 18.0,
            "actual_temperature_c" => 21.5,
            "temperature_delta_c" => 3.5,
            "min_operating_temperature_c" => -5.0,
            "max_operating_temperature_c" => 45.0,
            "thermal_margin_c" => 23.5,
            "thermal_status" => "warm",
            "thermal_model" => "thermal_model:v1",
            "thermal_source" => "mission_plan",
            "thermal_confidence" => 0.8,
            "cadence_import" => %{
              "external_id" => "cadence_cmd_1",
              "activity_type" => "command_window",
              "schema_contract" => "command_window.v1"
            }
          },
          %{
            "id" => "dl_1",
            "timeline_id" => "timeline:dl_1",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "starts_at_s" => 50.0,
            "ends_at_s" => 60.0,
            "status" => "planned",
            "approval_status" => "approved",
            "direction" => "downlink",
            "ground_station_id" => "dss_14"
          },
          %{
            "id" => "obs_1",
            "timeline_id" => "timeline:obs_1",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "starts_at_s" => 70.0,
            "ends_at_s" => 80.0,
            "status" => "planned",
            "approval_status" => "approved",
            "target_id" => "target_a"
          }
        ],
        source: "mission_plan.activities"
      )
      |> update_in(["rows", Access.at(0)], fn row ->
        row
        |> Map.put("contact_result", ["accepted", "DROPPED"])
        |> Map.put("command_result", [:accepted, :rejected])
        |> Map.update("activity_context", %{}, fn context ->
          Map.merge(context, %{
            "contact_result" => ["accepted", "DROPPED"],
            "command_result" => [:accepted, :rejected]
          })
        end)
      end)

    package = OperatorReview.from_operational_timeline_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "operational_timeline_report.v1",
             "source_artifact_id" => "mission_plan.activities",
             "review_count" => 2,
             "operational_timeline_count" => 2,
             "cadence_import_status_counts" => %{"missing" => 1, "present" => 1}
           } = package

    assert %{
             "review_type" => "operational_timeline_review",
             "source" => "operational_timeline_report.rows",
             "subject_id" => "timeline:cmd_1",
             "activity_id" => "cmd_1",
             "timeline_id" => "timeline:cmd_1",
             "operational_kind" => "command",
             "required_operator_action" => "review_command_contact",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "pending",
             "cadence_import_status" => "present",
             "cadence_import_type" => "command_window",
             "cadence_import_id" => "cadence_cmd_1",
             "cadence_import_contract" => "command_window.v1",
             "contact_result" => "accepted,DROPPED",
             "command_result" => "accepted,rejected",
             "dependency_activity_ids" => ["health_1"],
             "dependency_timeline_ids" => ["timeline:health_1"],
             "exclusive_with_activity_ids" => ["command_chain"],
             "exclusive_with_timeline_ids" => ["timeline:command_chain"],
             "pointing_mode" => "target_track",
             "pointing_target_id" => "target_a",
             "boresight_axis" => "+Z",
             "off_nadir_angle_deg" => 12.0,
             "slew_angle_deg" => 4.0,
             "slew_rate_deg_s" => 0.2,
             "pointing_error_deg" => 0.05,
             "pointing_status" => "within_tolerance",
             "pointing_model" => "attitude_solver:v2",
             "pointing_source" => "mission_plan",
             "pointing_confidence" => 0.92,
             "attitude_mode" => "nadir_track",
             "attitude_target_id" => "target_a",
             "roll_deg" => 1.0,
             "pitch_deg" => -2.0,
             "yaw_deg" => 3.0,
             "attitude_error_deg" => 0.08,
             "attitude_status" => "stable",
             "attitude_model" => "attitude_solver:v2",
             "attitude_source" => "mission_plan",
             "attitude_confidence" => 0.91,
             "setup_duration_s" => 15.0,
             "cooldown_duration_s" => 5.0,
             "telemetry_confirmation_required" => true,
             "telemetry_confirmation_status" => "required",
             "link_protocol" => "ccsds",
             "frequency_band" => "x_band",
             "modulation" => "qpsk",
             "coding_scheme" => "ldpc",
             "polarization" => "rhcp",
             "data_rate_mbps" => 12.0,
             "downlink_rate_mbps" => 10.0,
             "data_rate_mb_s" => 1.5,
             "downlink_rate_mb_s" => 1.25,
             "actual_data_rate_mbps" => 9.6,
             "actual_downlink_rate_mbps" => 9.2,
             "actual_data_rate_mb_s" => 1.2,
             "actual_downlink_rate_mb_s" => 1.15,
             "delivered_rate_mbps" => 9.0,
             "received_rate_mbps" => 8.8,
             "delivered_rate_mb_s" => 1.125,
             "received_rate_mb_s" => 1.1,
             "actual_duration_s" => 9.5,
             "actual_contact_duration_s" => 9.0,
             "contact_duration_s" => 10.0,
             "link_margin_db" => 4.5,
             "snr_db" => 12.0,
             "eb_no_db" => 8.5,
             "bit_error_rate" => 1.0e-6,
             "packet_loss_rate" => 0.01,
             "frame_loss_rate" => 0.02,
             "carrier_lock" => true,
             "symbol_lock" => true,
             "link_quality_status" => "nominal",
             "eclipse_overlap_fraction" => 0.4,
             "eclipse_overlap_s" => 24.0,
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mixed_lighting",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "lighting_confidence" => 0.82,
             "image_quality_score" => 0.87,
             "image_quality_status" => "usable",
             "image_quality_source" => "payload_processor",
             "cloud_cover_fraction" => 0.12,
             "blur_score" => 0.05,
             "feedback_weight" => 0.7,
             "feedback_weight_source" => "operator_tuning",
             "maneuver_success" => true,
             "maneuver_result" => "completed,within_tolerance",
             "thermal_zone_id" => "payload_deck",
             "temperature_c" => 21.5,
             "planned_temperature_c" => 18.0,
             "actual_temperature_c" => 21.5,
             "temperature_delta_c" => 3.5,
             "min_operating_temperature_c" => -5.0,
             "max_operating_temperature_c" => 45.0,
             "thermal_margin_c" => 23.5,
             "thermal_status" => "warm",
             "thermal_model" => "thermal_model:v1",
             "thermal_source" => "mission_plan",
             "thermal_confidence" => 0.8,
             "source_activity_context" => %{
               "contact_result" => "accepted,DROPPED",
               "command_result" => "accepted,rejected",
               "setup_duration_s" => 15.0,
               "cooldown_duration_s" => 5.0,
               "telemetry_confirmation_required" => true,
               "telemetry_confirmation_status" => "required",
               "lighting_condition" => "partial_eclipse",
               "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
               "lighting_confidence" => 0.82
             },
             "source_operational_timeline" => %{"activity_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "dl_1",
             "required_operator_action" => "prepare_cadence_import",
             "cadence_import_status" => "missing"
           } = Enum.find(package["rows"], &(&1["activity_id"] == "dl_1"))

    refute Enum.any?(package["rows"], &(&1["activity_id"] == "obs_1"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_operational_timeline =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "operational_timeline_review", "source_operational_timeline" => %{}} =
              row ->
            row
            |> put_in(["source_operational_timeline", "activity_id"], "stale_cmd")
            |> put_in(["source_operational_timeline", "timeline_id"], "timeline:stale_cmd")

          row ->
            row
        end)
      end)

    assert {:error, stale_source_operational_timeline_report} =
             Schema.validate_artifact(stale_source_operational_timeline)

    assert Enum.any?(
             stale_source_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.activity_id$/ and
                 &1["message"] == "must match source_operational_timeline.activity_id")
           )

    assert Enum.any?(
             stale_source_operational_timeline_report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.timeline_id$/ and
                 &1["message"] == "must match source_operational_timeline.timeline_id")
           )
  end

  test "normalizes map-valued provider results in operational timeline review rows" do
    report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            "id" => "cmd_provider_map",
            "timeline_id" => "timeline:cmd_provider_map",
            "type" => "command",
            "scenario_id" => "leo_1",
            "starts_at_s" => 30.0,
            "ends_at_s" => 40.0,
            "status" => "planned",
            "approval_status" => "pending",
            "direction" => "command",
            "ground_station_id" => "dss_14",
            "cadence_import" => %{
              "external_id" => "cadence_cmd_provider_map",
              "activity_type" => "command_window",
              "schema_contract" => "command_window.v1"
            }
          }
        ],
        source: "mission_plan.activities"
      )
      |> update_in(["rows", Access.at(0)], fn row ->
        row
        |> Map.put("contact_result", %{
          "outcome" => "accepted",
          "provider_status" => "NO-CONTACT"
        })
        |> Map.put("command_result", %{
          "status" => "rejected",
          "details" => %{"message" => "timed out"}
        })
        |> Map.update("activity_context", %{}, fn context ->
          Map.merge(context, %{
            "contact_result" => %{
              "outcome" => "accepted",
              "provider_status" => "NO-CONTACT"
            },
            "command_result" => %{
              "status" => "rejected",
              "details" => %{"message" => "timed out"}
            }
          })
        end)
      end)

    package = OperatorReview.from_operational_timeline_report(report)

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_provider_map",
             "contact_result" => "accepted,NO-CONTACT",
             "command_result" => "rejected,timed out",
             "source_activity_context" => %{
               "contact_result" => "accepted,NO-CONTACT",
               "command_result" => "rejected,timed out"
             }
           } = List.first(package["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "preserves malformed operational activity-context cadence import for review" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "source" => "bad_context",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline_cmd_1",
          "activity_type" => "command",
          "operational_kind" => "command",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "activity_context" => %{"cadence_import" => :bad_context}
        }
      ]
    }

    package = OperatorReview.from_operational_timeline_report(report)
    row = List.first(package["rows"])

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "cmd_1",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "invalid_cadence_import_reason" => "cadence_import_must_be_object",
             "source_cadence_import" => %{"invalid_import_shape" => "bad_context"},
             "source_activity_context" => %{
               "invalid_cadence_import" => true,
               "source_cadence_import" => %{"invalid_import_shape" => "bad_context"}
             }
           } = row

    refute Map.has_key?(row["source_activity_context"], "cadence_import")

    manifest = CadenceImport.from_operator_review_package(package)

    assert %{
             "import_status" => "review_required_before_import",
             "cadence_import_status" => "invalid",
             "invalid_cadence_import" => true,
             "source_cadence_import" => %{"invalid_import_shape" => "bad_context"}
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "normalizes unsupported operational cadence import statuses for review" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "source" => "custom_import_status",
      "rows" => [
        %{
          "activity_id" => "cmd_1",
          "timeline_id" => "timeline_cmd_1",
          "activity_type" => "command",
          "operational_kind" => "command",
          "required_operator_action" => "review_command_contact",
          "operator_action_reason" => "command_boundary_requires_review",
          "cadence_import_status" => "provider_custom",
          "has_cadence_import" => true,
          "source_cadence_import_status" => "source_custom",
          "source_has_cadence_import" => true,
          "replacement_cadence_import_status" => "replacement_custom",
          "replacement_has_cadence_import" => true
        }
      ]
    }

    package = OperatorReview.from_operational_timeline_report(report)
    row = List.first(package["rows"])

    assert row["cadence_import_status"] == "invalid"
    assert row["source_cadence_import_status"] == "invalid"
    assert row["replacement_cadence_import_status"] == "invalid"
    assert row["unsupported_cadence_import_status"] == "provider_custom"
    assert row["unsupported_source_cadence_import_status"] == "source_custom"
    assert row["unsupported_replacement_cadence_import_status"] == "replacement_custom"
    assert row["invalid_cadence_import"] == true
    assert row["invalid_cadence_import_reason"] == "unsupported_cadence_import_status"
    assert row["has_cadence_import"] == false
    assert row["source_has_cadence_import"] == false
    assert row["replacement_has_cadence_import"] == false
    assert package["cadence_import_status_counts"] == %{"invalid" => 1}
    assert package["source_cadence_import_status_counts"] == %{"invalid" => 1}
    assert package["replacement_cadence_import_status_counts"] == %{"invalid" => 1}

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end
end
