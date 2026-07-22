defmodule OrbitalDynamics.Schema.CadenceImportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "exports Cadence import resource projection evidence row schemas" do
    assert {:ok, schema} = Schema.json_schema("cadence_import_manifest.v1")

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    assert row_properties["station_reservation_expires_at_s"] == %{
             "anyOf" => [
               %{"type" => "number"},
               %{"type" => "array", "items" => %{"type" => "number"}}
             ]
           }

    source_review_row_properties =
      get_in(row_properties, ["source_review_row", "properties"])

    for properties <- [row_properties, source_review_row_properties] do
      assert get_in(properties, ["spacecraft_id", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      assert get_in(properties, ["first_resource_pressure_activity_id", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      assert get_in(properties, ["policy_bundle_id", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      assert get_in(properties, ["rule_id", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      assert get_in(properties, [
               "approval_requirements",
               "items",
               "properties",
               "schema_contract",
               "const"
             ]) ==
               "approval_requirement.v1"

      assert get_in(properties, [
               "approval_rule_matches",
               "items",
               "properties",
               "rule_id",
               "pattern"
             ]) ==
               Schema.identity_policy()["stable_id_pattern"]

      for field <- [
            "activity_count",
            "effective_activity_count",
            "ignored_activity_count",
            "observation_count",
            "downlink_count",
            "resource_flow_count"
          ] do
        assert get_in(properties, [field]) == %{"type" => "integer", "minimum" => 0}
      end

      assert get_in(properties, ["ignored_activity_ids", "items", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      for field <- [
            "projected_storage_margin",
            "projected_downlink_margin",
            "projected_storage_overflow_mb",
            "projected_downlink_shortfall_mb",
            "projected_battery_overuse_wh",
            "peak_storage_overflow_mb",
            "peak_downlink_shortfall_mb",
            "peak_unused_downlink_capacity_mb",
            "storage_limited_downlinked_mb",
            "unused_downlink_capacity_mb",
            "first_resource_pressure_starts_at_s",
            "fuel_margin",
            "power_margin",
            "sla_s"
          ] do
        assert get_in(properties, [field, "type"]) == "number"
      end

      for field <- [
            "source",
            "subject_id",
            "action",
            "required_operator_action",
            "reason",
            "approval_status",
            "review_queue",
            "review_queue_key",
            "resource_source_quality",
            "resource_trust_boundary_status",
            "first_resource_pressure_activity_type",
            "first_resource_pressure_kind",
            "requirement_type",
            "escalation_level",
            "escalation_queue",
            "escalation_role"
          ] do
        assert get_in(properties, [field, "type"]) == "string"
      end

      assert get_in(properties, ["warnings", "items", "type"]) == "string"
    end

    for field <- [
          "estimated_storage_produced_mb",
          "estimated_downlink_mb",
          "starting_storage_used_mb",
          "projected_storage_used_mb",
          "storage_capacity_mb",
          "starting_storage_margin",
          "downlink_capacity_mb",
          "starting_downlink_margin"
        ] do
      assert get_in(source_review_row_properties, [field, "type"]) == "number"
    end

    resource_projection_manifest =
      read_json!("study_results/cadence_import_resource_projection_battery_handoff_v1.json")

    invalid_row_pressure_activity =
      put_in(
        resource_projection_manifest,
        ["rows", Access.at(0), "first_resource_pressure_activity_id"],
        "bad id"
      )

    assert {:error, row_pressure_activity_report} =
             Schema.validate_artifact(invalid_row_pressure_activity)

    assert Enum.any?(
             row_pressure_activity_report["errors"],
             &(&1["path"] == "$.rows[0].first_resource_pressure_activity_id")
           )

    invalid_source_pressure_activity =
      put_in(
        resource_projection_manifest,
        ["rows", Access.at(0), "source_review_row", "first_resource_pressure_activity_id"],
        "bad id"
      )

    assert {:error, source_pressure_activity_report} =
             Schema.validate_artifact(invalid_source_pressure_activity)

    assert Enum.any?(
             source_pressure_activity_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.first_resource_pressure_activity_id")
           )
  end

  test "exports Cadence import resource pressure readiness row schemas" do
    capabilities = OrbitalDynamics.OperationalReadiness.capabilities()
    assert {:ok, schema} = Schema.json_schema("cadence_import_manifest.v1")

    row_properties = get_in(schema, ["properties", "rows", "items", "properties"])

    source_review_row_properties =
      get_in(row_properties, ["source_review_row", "properties"])

    for field <- [
          "ready_for_import_count",
          "manifest_review_required_count",
          "blocked_import_count",
          "missing_import_count",
          "invalid_cadence_import_count",
          "current_freshness_count",
          "stale_freshness_count",
          "unknown_freshness_count",
          "schema_validation_pass_count",
          "schema_validation_fail_count",
          "schema_validation_error_count",
          "schema_validation_warning_count",
          "schema_validation_remediation_count"
        ] do
      assert get_in(row_properties, [field]) == %{"type" => "integer", "minimum" => 0}
    end

    for field <- [
          "freshness_status_counts",
          "schema_validation_status_counts",
          "import_status_counts",
          "cadence_import_status_counts"
        ] do
      assert get_in(row_properties, [field, "additionalProperties", "type"]) == "integer"
      assert get_in(row_properties, [field, "additionalProperties", "minimum"]) == 0
    end

    for properties <- [row_properties, source_review_row_properties] do
      assert get_in(properties, ["readiness_level", "enum"]) == capabilities.readiness_levels

      assert get_in(properties, ["import_classification", "enum"]) ==
               capabilities.import_classifications

      assert get_in(properties, ["operational_readiness_status", "enum"]) ==
               capabilities.gate_statuses

      assert get_in(properties, ["cadence_import_status", "enum"]) ==
               OrbitalDynamics.CadenceImport.capability().cadence_import_statuses

      for field <- [
            "gate_count",
            "passed_gate_count",
            "review_gate_count",
            "analysis_gate_count",
            "blocked_gate_count"
          ] do
        assert get_in(properties, [field]) == %{"type" => "integer", "minimum" => 0}
      end

      assert get_in(properties, ["gates", "items", "properties", "id", "enum"]) ==
               capabilities.gates

      assert get_in(properties, ["evidence", "properties", "ready_for_import_count"]) == %{
               "type" => "integer",
               "minimum" => 0
             }

      assert get_in(properties, [
               "source_operational_readiness_gate",
               "properties",
               "classification",
               "enum"
             ]) ==
               capabilities.import_classifications
    end

    resource_pressure_manifest =
      read_json!("study_results/cadence_import_resource_pressure_v1.json")

    invalid_blocked_import_count =
      put_in(resource_pressure_manifest, ["rows", Access.at(0), "blocked_import_count"], "1")

    assert {:error, blocked_import_count_report} =
             Schema.validate_artifact(invalid_blocked_import_count)

    assert Enum.any?(
             blocked_import_count_report["errors"],
             &(&1["path"] == "$.rows[0].blocked_import_count")
           )
  end

  test "validates reduced-capacity pack policy fields on review and import rows" do
    report =
      "study_results/contact_allocation_capacity_pack_report_v1.json"
      |> read_json!()
      |> put_in(
        ["reduced_capacity_pack_groups", Access.at(0), "default_required_capacity_fraction"],
        0.25
      )

    package = OperatorReview.from_contact_allocation_report(report)

    review_index =
      Enum.find_index(
        package["rows"],
        &(&1["review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert is_integer(review_index)

    assert %{
             "default_required_capacity_fraction" => 0.25,
             "capacity_requirement_rows" => [
               %{"required_capacity_fraction" => 0.25}
               | _
             ]
           } = Enum.at(package["rows"], review_index)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_package =
      put_in(
        package,
        ["rows", Access.at(review_index), "default_required_capacity_fraction"],
        1.25
      )

    assert {:error, invalid_package_report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             invalid_package_report["errors"],
             &(&1["path"] == "$.rows[#{review_index}].default_required_capacity_fraction")
           )

    invalid_group_fraction =
      put_in(package, ["rows", Access.at(review_index), "used_capacity_fraction"], 1.25)

    assert {:error, invalid_group_fraction_report} =
             Schema.validate_artifact(invalid_group_fraction)

    assert Enum.any?(
             invalid_group_fraction_report["errors"],
             &(&1["path"] == "$.rows[#{review_index}].used_capacity_fraction")
           )

    invalid_requirement =
      put_in(
        package,
        [
          "rows",
          Access.at(review_index),
          "capacity_requirement_rows",
          Access.at(0),
          "required_capacity_fraction"
        ],
        1.25
      )

    assert {:error, invalid_requirement_report} = Schema.validate_artifact(invalid_requirement)

    assert Enum.any?(
             invalid_requirement_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{review_index}].capacity_requirement_rows[0].required_capacity_fraction")
           )

    manifest = CadenceImport.from_contact_allocation_report(report)

    import_index =
      Enum.find_index(
        manifest["rows"],
        &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
      )

    assert is_integer(import_index)

    assert %{
             "default_required_capacity_fraction" => 0.25,
             "source_review_row" => %{"default_required_capacity_fraction" => 0.25}
           } = Enum.at(manifest["rows"], import_index)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_manifest =
      put_in(
        manifest,
        ["rows", Access.at(import_index), "default_required_capacity_fraction"],
        1.25
      )

    assert {:error, invalid_manifest_report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             invalid_manifest_report["errors"],
             &(&1["path"] == "$.rows[#{import_index}].default_required_capacity_fraction")
           )

    invalid_source_review =
      put_in(
        manifest,
        [
          "rows",
          Access.at(import_index),
          "source_review_row",
          "default_required_capacity_fraction"
        ],
        1.25
      )

    assert {:error, invalid_source_review_report} =
             Schema.validate_artifact(invalid_source_review)

    assert Enum.any?(
             invalid_source_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{import_index}].source_review_row.default_required_capacity_fraction")
           )

    invalid_source_group_fraction =
      put_in(
        manifest,
        ["rows", Access.at(import_index), "source_review_row", "capacity_fraction"],
        1.25
      )

    assert {:error, invalid_source_group_fraction_report} =
             Schema.validate_artifact(invalid_source_group_fraction)

    assert Enum.any?(
             invalid_source_group_fraction_report["errors"],
             &(&1["path"] == "$.rows[#{import_index}].source_review_row.capacity_fraction")
           )
  end

  test "validates Cadence import source-window handoff rows" do
    manifest = read_json!("study_results/cadence_import_manifest_v1.json")

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_import_generated_energy =
      put_in(
        manifest,
        ["rows", Access.at(0), "import_activity_context"],
        %{"battery_energy_generated_wh" => -1.0}
      )

    assert {:error, invalid_import_generated_energy_report} =
             Schema.validate_artifact(invalid_import_generated_energy)

    assert Enum.any?(
             invalid_import_generated_energy_report["errors"],
             &(&1["path"] == "$.rows[0].import_activity_context.battery_energy_generated_wh")
           )

    invalid_source_review_analysis_mode =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"analysis_mode" => "execution"}
      )

    assert {:error, invalid_source_review_analysis_mode_report} =
             Schema.validate_artifact(invalid_source_review_analysis_mode)

    assert Enum.any?(
             invalid_source_review_analysis_mode_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.analysis_mode")
           )

    invalid_source_review_completion_fraction =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"completed_fraction" => 1.2, "throughput_completion_fraction" => -0.1}
      )

    assert {:error, invalid_source_review_completion_fraction_report} =
             Schema.validate_artifact(invalid_source_review_completion_fraction)

    assert Enum.any?(
             invalid_source_review_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.completed_fraction")
           )

    assert Enum.any?(
             invalid_source_review_completion_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.throughput_completion_fraction")
           )

    invalid_source_review_resource_variance =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"planned_spacecraft_available" => "not_boolean", "mode_match_status" => 42}
      )

    assert {:error, invalid_source_review_resource_variance_report} =
             Schema.validate_artifact(invalid_source_review_resource_variance)

    assert Enum.any?(
             invalid_source_review_resource_variance_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.planned_spacecraft_available")
           )

    assert Enum.any?(
             invalid_source_review_resource_variance_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.mode_match_status")
           )

    invalid_source_review_eclipse_overlap_fraction =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"eclipse_overlap_fraction" => 1.2, "realized_eclipse_overlap_fraction" => -0.1}
      )

    assert {:error, invalid_source_review_eclipse_overlap_fraction_report} =
             Schema.validate_artifact(invalid_source_review_eclipse_overlap_fraction)

    assert Enum.any?(
             invalid_source_review_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.eclipse_overlap_fraction")
           )

    assert Enum.any?(
             invalid_source_review_eclipse_overlap_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_eclipse_overlap_fraction")
           )

    invalid_source_review_eclipse_lighting_handoff =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{
          "realized_eclipse_overlap_s" => "long",
          "lighting_condition_detail" => 42,
          "lighting_confidence" => %{"label" => "high"}
        }
      )

    assert {:error, invalid_source_review_eclipse_lighting_handoff_report} =
             Schema.validate_artifact(invalid_source_review_eclipse_lighting_handoff)

    assert Enum.any?(
             invalid_source_review_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_eclipse_overlap_s")
           )

    assert Enum.any?(
             invalid_source_review_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.lighting_condition_detail")
           )

    assert Enum.any?(
             invalid_source_review_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.lighting_confidence")
           )

    invalid_source_review_image_quality_score =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"image_quality_score" => 1.2, "realized_image_quality_score" => -0.1}
      )

    assert {:error, invalid_source_review_image_quality_score_report} =
             Schema.validate_artifact(invalid_source_review_image_quality_score)

    assert Enum.any?(
             invalid_source_review_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.image_quality_score")
           )

    invalid_source_review_observation_quality_handoff =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{
          "image_quality_score_delta" => "worse",
          "cloud_cover_fraction_delta" => "cloudier",
          "image_quality_status_match_status" => 42,
          "image_quality_source" => 42
        }
      )

    assert {:error, invalid_source_review_observation_quality_handoff_report} =
             Schema.validate_artifact(invalid_source_review_observation_quality_handoff)

    assert Enum.any?(
             invalid_source_review_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.image_quality_score_delta")
           )

    assert Enum.any?(
             invalid_source_review_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.cloud_cover_fraction_delta")
           )

    assert Enum.any?(
             invalid_source_review_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.image_quality_status_match_status")
           )

    assert Enum.any?(
             invalid_source_review_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.image_quality_source")
           )

    invalid_source_review_feedback_maneuver_handoff =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{
          "feedback_weight" => -0.1,
          "feedback_weight_source" => 42,
          "maneuver_success" => "yes",
          "maneuver_result" => 42,
          "maneuver_success_factor" => 1.2,
          "maneuver_success_factor_source" => 42
        }
      )

    assert {:error, invalid_source_review_feedback_maneuver_handoff_report} =
             Schema.validate_artifact(invalid_source_review_feedback_maneuver_handoff)

    for field <- [
          "feedback_weight",
          "feedback_weight_source",
          "maneuver_success",
          "maneuver_result",
          "maneuver_success_factor",
          "maneuver_success_factor_source"
        ] do
      assert Enum.any?(
               invalid_source_review_feedback_maneuver_handoff_report["errors"],
               &(&1["path"] == "$.rows[0].source_review_row.#{field}")
             )
    end

    assert Enum.any?(
             invalid_source_review_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_image_quality_score")
           )

    invalid_source_review_link_error_rate =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"bit_error_rate" => 1.2, "realized_frame_loss_rate" => -0.1}
      )

    assert {:error, invalid_source_review_link_error_rate_report} =
             Schema.validate_artifact(invalid_source_review_link_error_rate)

    assert Enum.any?(
             invalid_source_review_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.bit_error_rate")
           )

    assert Enum.any?(
             invalid_source_review_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_frame_loss_rate")
           )

    invalid_source_review_link_handoff =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{
          "modulation" => 42,
          "realized_snr_db" => "weak",
          "planned_symbol_lock" => "locked"
        }
      )

    assert {:error, invalid_source_review_link_handoff_report} =
             Schema.validate_artifact(invalid_source_review_link_handoff)

    assert Enum.any?(
             invalid_source_review_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.modulation")
           )

    assert Enum.any?(
             invalid_source_review_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_snr_db")
           )

    assert Enum.any?(
             invalid_source_review_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.planned_symbol_lock")
           )

    invalid_source_review_attitude_confidence =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"attitude_confidence" => 1.2}
      )

    assert {:error, invalid_source_review_attitude_confidence_report} =
             Schema.validate_artifact(invalid_source_review_attitude_confidence)

    assert Enum.any?(
             invalid_source_review_attitude_confidence_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.attitude_confidence")
           )

    invalid_row_thermal_handoff =
      manifest
      |> put_in(["rows", Access.at(0), "thermal_zone_id"], "payload deck")
      |> put_in(["rows", Access.at(0), "thermal_confidence"], 1.2)

    assert {:error, invalid_row_thermal_handoff_report} =
             Schema.validate_artifact(invalid_row_thermal_handoff)

    assert Enum.any?(
             invalid_row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].thermal_zone_id")
           )

    assert Enum.any?(
             invalid_row_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].thermal_confidence")
           )

    invalid_source_review_thermal_handoff =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_review_row"],
        %{"thermal_zone_id" => "payload deck", "thermal_confidence" => 1.2}
      )

    assert {:error, invalid_source_review_thermal_handoff_report} =
             Schema.validate_artifact(invalid_source_review_thermal_handoff)

    assert Enum.any?(
             invalid_source_review_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.thermal_zone_id")
           )

    assert Enum.any?(
             invalid_source_review_thermal_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.thermal_confidence")
           )

    realized_feedback_manifest =
      OrbitalDynamics.TimelineFeedback.reconcile(
        [
          %{
            "id" => "obs_resource_variance_schema",
            "type" => "observe",
            "target_id" => "target_a",
            "spacecraft_available" => true,
            "cadence_import" => %{
              "activity_type" => "observation",
              "external_id" => "cadence_obs_resource_variance_schema",
              "schema_contract" => "planned_activity.v1"
            }
          }
        ],
        [
          %{
            "id" => "provider_obs_resource_variance_schema",
            "planned_activity_id" => "obs_resource_variance_schema",
            "type" => "observe",
            "status" => "completed",
            "target_id" => "target_a",
            "spacecraft_available" => false
          }
        ]
      )["cadence_import_manifest"]

    realized_feedback_index =
      Enum.find_index(
        realized_feedback_manifest["rows"],
        &(&1["source_review_type"] == "realized_feedback" and
            Map.has_key?(&1, "source_review_row"))
      )

    assert is_integer(realized_feedback_index)

    mismatched_source_review_resource_variance =
      realized_feedback_manifest
      |> put_in(
        [
          "rows",
          Access.at(realized_feedback_index),
          "source_review_row",
          "planned_spacecraft_available"
        ],
        true
      )
      |> put_in(
        ["rows", Access.at(realized_feedback_index), "planned_spacecraft_available"],
        false
      )

    assert {:error, mismatched_source_review_resource_variance_report} =
             Schema.validate_artifact(mismatched_source_review_resource_variance)

    assert Enum.any?(
             mismatched_source_review_resource_variance_report["errors"],
             &(&1["path"] ==
                 "$.rows[#{realized_feedback_index}].source_review_row.planned_spacecraft_available")
           )

    invalid_import_count =
      put_in(manifest, ["import_action_counts", "import_replacement_activity"], -1)

    assert {:error, invalid_import_count_report} =
             Schema.validate_artifact(invalid_import_count)

    assert Enum.any?(
             invalid_import_count_report["errors"],
             &(&1["path"] == "$.import_action_counts.import_replacement_activity")
           )

    for {field, key, counts} <- [
          {"calendar_entry_trust_boundary_status_counts", "declared", %{"declared" => -1}},
          {"station_reservation_match_status_counts", "overlap", %{"overlap" => -1}},
          {"station_reservation_expiration_status_counts", "declared", %{"declared" => -1}},
          {"resource_blocking_dimension_counts", "antenna", %{"antenna" => -1}},
          {"gate_status_counts", "review_required", %{"review_required" => -1}},
          {"gate_classification_counts", "review_only", %{"review_only" => -1}},
          {"required_capacity_fraction_source_counts", "capacity_model",
           %{"capacity_model" => -1}},
          {"provider_reservation_request_status_counts", "review_required",
           %{"review_required" => -1}},
          {"reduced_capacity_pack_status_counts", "capacity_limited",
           %{"capacity_limited" => -1}},
          {"station_pressure_contact_counts_by_ground_station_id", "gs", %{"gs" => -1}}
        ] do
      invalid_lifted_summary_counts = Map.put(manifest, field, counts)

      assert {:error, lifted_summary_counts_report} =
               Schema.validate_artifact(invalid_lifted_summary_counts)

      assert Enum.any?(
               lifted_summary_counts_report["errors"],
               &(&1["path"] == "$.#{field}.#{key}")
             )
    end

    invalid_resource_blocked_ids =
      Map.put(manifest, "resource_blocked_contact_ids_by_spacecraft_id", %{
        "sat_resource" => ["bad id"]
      })

    assert {:error, resource_blocked_ids_report} =
             Schema.validate_artifact(invalid_resource_blocked_ids)

    assert Enum.any?(
             resource_blocked_ids_report["errors"],
             &(&1["path"] == "$.resource_blocked_contact_ids_by_spacecraft_id.sat_resource[0]")
           )

    invalid_station_pressure_top_ids =
      Map.put(manifest, "station_pressure_contact_ids", ["bad id"])

    assert {:error, station_pressure_top_ids_report} =
             Schema.validate_artifact(invalid_station_pressure_top_ids)

    assert Enum.any?(
             station_pressure_top_ids_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids[0]")
           )

    cadence_schema = read_json!("schemas/cadence_import_manifest.v1.schema.json")

    assert get_in(cadence_schema, [
             "properties",
             "station_pressure_contact_ids",
             "uniqueItems"
           ]) == true

    assert get_in(cadence_schema, [
             "properties",
             "station_pressure_review_contact_ids",
             "uniqueItems"
           ]) == true

    valid_station_pressure_identity =
      Map.merge(manifest, %{
        "station_pressure_contact_count" => 2,
        "station_pressure_contact_ids" => ["contact_a", "contact_b"]
      })

    assert {:ok, _manifest} = Schema.validate_artifact(valid_station_pressure_identity)

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.station_pressure_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.station_pressure_contact_ids"},
          {2, ["contact_a"], "$.station_pressure_contact_count"}
        ] do
      invalid_identity =
        Map.merge(manifest, %{
          "station_pressure_contact_count" => contact_count,
          "station_pressure_contact_ids" => contact_ids
        })

      assert {:error, invalid_identity_report} = Schema.validate_artifact(invalid_identity)

      assert Enum.any?(invalid_identity_report["errors"], &(&1["path"] == error_path))
    end

    valid_station_pressure_review_identity =
      Map.merge(manifest, %{
        "station_pressure_review_contact_count" => 2,
        "station_pressure_review_contact_ids" => ["contact_a", "contact_b"]
      })

    assert {:ok, _manifest} = Schema.validate_artifact(valid_station_pressure_review_identity)

    explicit_empty_station_pressure_review_identity =
      Map.merge(manifest, %{
        "station_pressure_review_contact_count" => 0,
        "station_pressure_review_contact_ids" => []
      })

    assert {:ok, _manifest} =
             Schema.validate_artifact(explicit_empty_station_pressure_review_identity)

    assert {:ok, _manifest} =
             manifest
             |> Map.put("station_pressure_review_contact_count", 2)
             |> Schema.validate_artifact()

    for {contact_count, contact_ids, error_path} <- [
          {2, ["contact_b", "contact_a"], "$.station_pressure_review_contact_ids"},
          {1, ["contact_a", "contact_a"], "$.station_pressure_review_contact_ids"},
          {2, ["contact_a"], "$.station_pressure_review_contact_count"}
        ] do
      invalid_review_identity =
        Map.merge(manifest, %{
          "station_pressure_review_contact_count" => contact_count,
          "station_pressure_review_contact_ids" => contact_ids
        })

      assert {:error, invalid_review_identity_report} =
               Schema.validate_artifact(invalid_review_identity)

      assert Enum.any?(invalid_review_identity_report["errors"], &(&1["path"] == error_path))
    end

    grouped_station_pressure_fields = [
      {"station_pressure_contact_counts_by_ground_station_id",
       "station_pressure_contact_ids_by_ground_station_id", "gs_a"},
      {"station_pressure_contact_counts_by_availability",
       "station_pressure_contact_ids_by_availability", "reserved"},
      {"station_pressure_contact_counts_by_precedence_availability",
       "station_pressure_contact_ids_by_precedence_availability", "reserved"},
      {"station_pressure_contact_counts_by_precedence_rank",
       "station_pressure_contact_ids_by_precedence_rank", "1"},
      {"station_pressure_contact_counts_by_status", "station_pressure_contact_ids_by_status",
       "reservation_hold"}
    ]

    for {count_field, id_field, key} <- grouped_station_pressure_fields do
      assert get_in(cadence_schema, [
               "properties",
               id_field,
               "additionalProperties",
               "uniqueItems"
             ]) == true

      valid_group =
        manifest
        |> Map.put(count_field, %{key => 2})
        |> Map.put(id_field, %{key => ["contact_a", "contact_b"]})

      assert {:ok, _manifest} = Schema.validate_artifact(valid_group)

      for {count, contact_ids, error_path} <- [
            {2, ["contact_b", "contact_a"], "$.#{id_field}.#{key}"},
            {1, ["contact_a", "contact_a"], "$.#{id_field}.#{key}"},
            {1, ["contact_a", "contact_b"], "$.#{count_field}.#{key}"}
          ] do
        invalid_group =
          manifest
          |> Map.put(count_field, %{key => count})
          |> Map.put(id_field, %{key => contact_ids})

        assert {:error, invalid_group_report} = Schema.validate_artifact(invalid_group)
        assert Enum.any?(invalid_group_report["errors"], &(&1["path"] == error_path))
      end
    end

    flat_direction_field = "station_pressure_contact_ids_by_direction"
    nested_direction_field = "station_pressure_contact_ids_by_direction_and_ground_station_id"

    assert get_in(cadence_schema, [
             "properties",
             flat_direction_field,
             "additionalProperties",
             "uniqueItems"
           ]) == true

    assert get_in(cadence_schema, [
             "properties",
             nested_direction_field,
             "additionalProperties",
             "additionalProperties",
             "uniqueItems"
           ]) == true

    valid_direction_routes =
      manifest
      |> Map.put(flat_direction_field, %{"downlink" => ["contact_a", "contact_b"]})
      |> Map.put(nested_direction_field, %{"downlink" => %{"gs_a" => ["contact_b"]}})

    assert {:ok, _manifest} = Schema.validate_artifact(valid_direction_routes)

    nested_only_direction_route =
      Map.put(manifest, nested_direction_field, %{"downlink" => %{"gs_a" => ["contact_b"]}})

    assert {:ok, _manifest} = Schema.validate_artifact(nested_only_direction_route)

    routed_station_pressure_identity =
      Map.merge(manifest, %{
        "station_pressure_review_contact_count" => 1,
        "station_pressure_review_contact_ids" => ["contact_review"],
        "station_pressure_contact_counts_by_ground_station_id" => %{"gs_a" => 1},
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "gs_a" => ["contact_group"]
        },
        flat_direction_field => %{"downlink" => ["contact_nested"]},
        nested_direction_field => %{
          "downlink" => %{"gs_a" => ["contact_nested"]}
        }
      })

    assert {:ok, _manifest} = Schema.validate_artifact(routed_station_pressure_identity)

    valid_routed_top_identity =
      Map.merge(routed_station_pressure_identity, %{
        "station_pressure_contact_count" => 3,
        "station_pressure_contact_ids" => [
          "contact_group",
          "contact_nested",
          "contact_review"
        ]
      })

    assert {:ok, _manifest} = Schema.validate_artifact(valid_routed_top_identity)

    incomplete_routed_top_identity =
      Map.merge(routed_station_pressure_identity, %{
        "station_pressure_contact_count" => 1,
        "station_pressure_contact_ids" => ["contact_group"]
      })

    assert {:error, incomplete_routed_top_identity_report} =
             Schema.validate_artifact(incomplete_routed_top_identity)

    assert Enum.any?(
             incomplete_routed_top_identity_report["errors"],
             &(&1["path"] == "$.station_pressure_contact_ids")
           )

    for {flat_ids, nested_ids, error_path} <- [
          {["contact_b", "contact_a"], ["contact_b"], "$.#{flat_direction_field}.downlink"},
          {["contact_a", "contact_b"], ["contact_b", "contact_b"],
           "$.#{nested_direction_field}.downlink.gs_a"},
          {["contact_a"], ["contact_b"], "$.#{flat_direction_field}.downlink"}
        ] do
      invalid_routes =
        manifest
        |> Map.put(flat_direction_field, %{"downlink" => flat_ids})
        |> Map.put(nested_direction_field, %{"downlink" => %{"gs_a" => nested_ids}})

      assert {:error, invalid_routes_report} = Schema.validate_artifact(invalid_routes)
      assert Enum.any?(invalid_routes_report["errors"], &(&1["path"] == error_path))
    end

    invalid_station_pressure_ids =
      Map.put(manifest, "station_pressure_contact_ids_by_ground_station_id", %{
        "gs_capacity_pack" => ["bad id"]
      })

    assert {:error, station_pressure_ids_report} =
             Schema.validate_artifact(invalid_station_pressure_ids)

    assert Enum.any?(
             station_pressure_ids_report["errors"],
             &(&1["path"] ==
                 "$.station_pressure_contact_ids_by_ground_station_id.gs_capacity_pack[0]")
           )

    invalid_station_reservation_routing_ids =
      Map.put(manifest, "station_reservation_contact_ids_by_status", %{
        "confirmed" => ["bad id"]
      })

    assert {:error, station_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_station_reservation_routing_ids)

    assert Enum.any?(
             station_reservation_routing_ids_report["errors"],
             &(&1["path"] == "$.station_reservation_contact_ids_by_status.confirmed[0]")
           )

    invalid_quality_gate_count =
      Map.put(manifest, "blocked_gate_count", -1)

    assert {:error, quality_gate_count_report} =
             Schema.validate_artifact(invalid_quality_gate_count)

    assert Enum.any?(
             quality_gate_count_report["errors"],
             &(&1["path"] == "$.blocked_gate_count")
           )

    invalid_quality_gate_ids =
      Map.put(manifest, "blocked_gate_ids", ["bad id"])

    assert {:error, quality_gate_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_ids)

    assert Enum.any?(
             quality_gate_ids_report["errors"],
             &(&1["path"] == "$.blocked_gate_ids[0]")
           )

    invalid_quality_gate_routing_ids =
      Map.put(manifest, "gate_ids_by_classification", %{
        "blocked" => ["bad id"]
      })

    assert {:error, quality_gate_routing_ids_report} =
             Schema.validate_artifact(invalid_quality_gate_routing_ids)

    assert Enum.any?(
             quality_gate_routing_ids_report["errors"],
             &(&1["path"] == "$.gate_ids_by_classification.blocked[0]")
           )

    invalid_capacity_pack_group_ids =
      Map.put(manifest, "capacity_pack_group_ids", ["bad id"])

    assert {:error, capacity_pack_group_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids)

    assert Enum.any?(
             capacity_pack_group_ids_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids[0]")
           )

    invalid_capacity_pack_group_ids_by_status =
      Map.put(manifest, "capacity_pack_group_ids_by_status", %{
        "capacity_limited" => ["bad id"]
      })

    assert {:error, capacity_pack_group_ids_by_status_report} =
             Schema.validate_artifact(invalid_capacity_pack_group_ids_by_status)

    assert Enum.any?(
             capacity_pack_group_ids_by_status_report["errors"],
             &(&1["path"] == "$.capacity_pack_group_ids_by_status.capacity_limited[0]")
           )

    invalid_required_capacity_source_ids =
      Map.put(manifest, "required_capacity_fraction_contact_ids_by_source", %{
        "capacity_model" => ["bad id"]
      })

    assert {:error, required_capacity_source_ids_report} =
             Schema.validate_artifact(invalid_required_capacity_source_ids)

    assert Enum.any?(
             required_capacity_source_ids_report["errors"],
             &(&1["path"] ==
                 "$.required_capacity_fraction_contact_ids_by_source.capacity_model[0]")
           )

    invalid_provider_reservation_count =
      Map.put(manifest, "provider_reservation_review_contact_count", -1)

    assert {:error, provider_reservation_count_report} =
             Schema.validate_artifact(invalid_provider_reservation_count)

    assert Enum.any?(
             provider_reservation_count_report["errors"],
             &(&1["path"] == "$.provider_reservation_review_contact_count")
           )

    invalid_provider_reservation_ids =
      Map.put(manifest, "provider_reservation_review_contact_ids", ["bad id"])

    assert {:error, provider_reservation_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_ids)

    assert Enum.any?(
             provider_reservation_ids_report["errors"],
             &(&1["path"] == "$.provider_reservation_review_contact_ids[0]")
           )

    invalid_provider_reservation_routing_ids =
      Map.put(manifest, "provider_reservation_review_contact_ids_by_match_status", %{
        "overlap" => ["bad id"]
      })

    assert {:error, provider_reservation_routing_ids_report} =
             Schema.validate_artifact(invalid_provider_reservation_routing_ids)

    assert Enum.any?(
             provider_reservation_routing_ids_report["errors"],
             &(&1["path"] ==
                 "$.provider_reservation_review_contact_ids_by_match_status.overlap[0]")
           )

    invalid_capacity_pack_demand =
      Map.put(manifest, "capacity_pack_deferred_required_capacity_fraction", -1.0)

    assert {:error, capacity_pack_demand_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand)

    assert Enum.any?(
             capacity_pack_demand_report["errors"],
             &(&1["path"] == "$.capacity_pack_deferred_required_capacity_fraction")
           )

    invalid_capacity_pack_demand_map =
      Map.put(
        manifest,
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
        %{
          "gs_capacity_pack" => -1.0
        }
      )

    assert {:error, capacity_pack_demand_map_report} =
             Schema.validate_artifact(invalid_capacity_pack_demand_map)

    assert Enum.any?(
             capacity_pack_demand_map_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_deferred_required_capacity_fraction_by_ground_station_id.gs_capacity_pack")
           )

    invalid_capacity_pack_contact_ids =
      Map.put(manifest, "capacity_pack_contact_ids_by_status", %{
        "deferred_by_reduced_station_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_contact_ids)

    assert Enum.any?(
             capacity_pack_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_contact_ids_by_status.deferred_by_reduced_station_capacity_pack[0]")
           )

    invalid_capacity_pack_station_contact_ids =
      Map.put(manifest, "capacity_pack_deferred_contact_ids_by_ground_station_id", %{
        "gs_capacity_pack" => ["bad id"]
      })

    assert {:error, capacity_pack_station_contact_ids_report} =
             Schema.validate_artifact(invalid_capacity_pack_station_contact_ids)

    assert Enum.any?(
             capacity_pack_station_contact_ids_report["errors"],
             &(&1["path"] ==
                 "$.capacity_pack_deferred_contact_ids_by_ground_station_id.gs_capacity_pack[0]")
           )

    invalid_reduced_capacity_deferred_ids =
      Map.put(manifest, "reduced_capacity_deferred_contact_ids", ["bad id"])

    assert {:error, reduced_capacity_deferred_ids_report} =
             Schema.validate_artifact(invalid_reduced_capacity_deferred_ids)

    assert Enum.any?(
             reduced_capacity_deferred_ids_report["errors"],
             &(&1["path"] == "$.reduced_capacity_deferred_contact_ids[0]")
           )
  end

  test "validates Cadence import lineage and resource handoff rows" do
    manifest = read_json!("study_results/cadence_import_manifest_v1.json")

    invalid_scalar_count = Map.put(manifest, "ready_count", -1)

    assert {:error, invalid_scalar_count_report} =
             Schema.validate_artifact(invalid_scalar_count)

    assert Enum.any?(
             invalid_scalar_count_report["errors"],
             &(&1["path"] == "$.ready_count")
           )

    invalid_replacement_lineage =
      manifest
      |> put_in(["rows", Access.at(0), "replacement_candidate_id"], "replacement_candidate_1")
      |> put_in(["rows", Access.at(0), "replacement_source_window_id"], "replacement_window_1")
      |> put_in(["rows", Access.at(0), "replacement_source_window_lineage"], %{
        "candidate_activity_id" => "replacement candidate with spaces",
        "source_window_id" => "replacement_window_1",
        "source_window_type" => "downlink",
        "scenario_id" => "leo_1"
      })

    assert {:error, replacement_lineage_report} =
             Schema.validate_artifact(invalid_replacement_lineage)

    assert Enum.any?(
             replacement_lineage_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].replacement_source_window_lineage.candidate_activity_id")
           )

    invalid_source_delta =
      put_in(manifest, ["rows", Access.at(0), "source_delta"], %{
        "activity_id" => "activity with spaces",
        "activity_type" => "downlink",
        "status" => "changed",
        "repair_action" => "moved"
      })

    assert {:error, source_delta_report} = Schema.validate_artifact(invalid_source_delta)

    assert Enum.any?(
             source_delta_report["errors"],
             &(&1["path"] == "$.rows[0].source_delta.activity_id")
           )

    invalid_source_requirement =
      put_in(manifest, ["rows", Access.at(0), "source_requirement"], %{
        "activity_id" => "activity with spaces",
        "activity_type" => "downlink",
        "action" => "approve_contact",
        "reason" => "operator review"
      })

    assert {:error, source_requirement_report} =
             Schema.validate_artifact(invalid_source_requirement)

    assert Enum.any?(
             source_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].source_requirement.activity_id")
           )

    invalid_source_policy_decision =
      put_in(manifest, ["rows", Access.at(0), "source_policy_decision"], %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "maybe"
      })

    assert {:error, source_policy_decision_report} =
             Schema.validate_artifact(invalid_source_policy_decision)

    assert Enum.any?(
             source_policy_decision_report["errors"],
             &(&1["path"] == "$.rows[0].source_policy_decision.classification")
           )

    invalid_source_policy_escalation =
      put_in(manifest, ["rows", Access.at(0), "source_policy_escalation"], %{
        "rule_id" => "rule with spaces"
      })

    assert {:error, source_policy_escalation_report} =
             Schema.validate_artifact(invalid_source_policy_escalation)

    assert Enum.any?(
             source_policy_escalation_report["errors"],
             &(&1["path"] == "$.rows[0].source_policy_escalation.rule_id")
           )

    invalid_source_contact_suppression =
      put_in(manifest, ["rows", Access.at(0), "source_contact_suppression"], %{
        "id" => "contact suppression with spaces",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "suppressed_reason" => "ground_station_unavailable"
      })

    assert {:error, source_contact_suppression_report} =
             Schema.validate_artifact(invalid_source_contact_suppression)

    assert Enum.any?(
             source_contact_suppression_report["errors"],
             &(&1["path"] == "$.rows[0].source_contact_suppression.id")
           )

    invalid_source_link_capacity =
      put_in(manifest, ["rows", Access.at(0), "source_link_capacity"], %{
        "ground_station_id" => "station with spaces",
        "contact_count" => 1,
        "selected_contact_count" => 0,
        "estimated_throughput_mb" => 1.0,
        "selected_estimated_throughput_mb" => 0.0,
        "contact_ids" => ["contact_1"],
        "selected_contact_ids" => []
      })

    assert {:error, source_link_capacity_report} =
             Schema.validate_artifact(invalid_source_link_capacity)

    assert Enum.any?(
             source_link_capacity_report["errors"],
             &(&1["path"] == "$.rows[0].source_link_capacity.ground_station_id")
           )

    invalid_import_capacity_range =
      manifest
      |> put_in(["rows", Access.at(0), "capacity_fraction_min"], -0.1)
      |> put_in(["rows", Access.at(0), "capacity_fraction_max"], 1.2)

    assert {:error, import_capacity_range_report} =
             Schema.validate_artifact(invalid_import_capacity_range)

    assert Enum.any?(
             import_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_fraction_min")
           )

    assert Enum.any?(
             import_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].capacity_fraction_max")
           )

    invalid_source_resource_projection =
      put_in(manifest, ["rows", Access.at(0), "source_resource_projection"], %{
        "spacecraft_id" => "spacecraft with spaces",
        "activity_count" => 1,
        "observation_count" => 1,
        "downlink_count" => 0,
        "estimated_storage_produced_mb" => 0.0,
        "estimated_downlink_mb" => 0.0
      })

    assert {:error, source_resource_projection_report} =
             Schema.validate_artifact(invalid_source_resource_projection)

    assert Enum.any?(
             source_resource_projection_report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection.spacecraft_id")
           )

    invalid_resource_projection_battery_handoff =
      manifest
      |> put_in(["rows", Access.at(0), "total_battery_energy_consumed_wh"], "twenty")
      |> put_in(["rows", Access.at(0), "source_resource_projection"], %{
        "spacecraft_id" => "leo_1",
        "net_battery_energy_delta_wh" => "fifteen"
      })
      |> put_in(["rows", Access.at(0), "source_review_row"], %{
        "id" => "review_1",
        "review_type" => "resource_projection_review",
        "peak_battery_overuse_wh" => "four"
      })

    assert {:error, resource_projection_battery_handoff_report} =
             Schema.validate_artifact(invalid_resource_projection_battery_handoff)

    assert Enum.any?(
             resource_projection_battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].total_battery_energy_consumed_wh")
           )

    assert Enum.any?(
             resource_projection_battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection.net_battery_energy_delta_wh")
           )

    assert Enum.any?(
             resource_projection_battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.peak_battery_overuse_wh")
           )
  end

  test "validates Cadence import battery-flow handoff rows" do
    battery_handoff_manifest =
      read_json!("study_results/cadence_import_resource_projection_battery_handoff_v1.json")

    stale_source_review_battery_handoff =
      put_in(
        battery_handoff_manifest,
        ["rows", Access.at(0), "source_review_row", "net_battery_energy_delta_wh"],
        16.0
      )

    assert {:error, stale_source_review_battery_handoff_report} =
             Schema.validate_artifact(stale_source_review_battery_handoff)

    assert Enum.any?(
             stale_source_review_battery_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.net_battery_energy_delta_wh" and
                 &1["message"] == "must match net_battery_energy_delta_wh on Cadence import row")
           )

    operator_battery_handoff =
      read_json!("study_results/operator_review_resource_projection_battery_handoff_v1.json")

    stale_operator_source_flow =
      put_in(
        operator_battery_handoff,
        [
          "rows",
          Access.at(0),
          "source_resource_projection",
          "activity_resource_flow",
          Access.at(0),
          "battery_energy_consumed_wh"
        ],
        21.0
      )

    assert {:error, stale_operator_source_flow_report} =
             Schema.validate_artifact(stale_operator_source_flow)

    assert Enum.any?(
             stale_operator_source_flow_report["errors"],
             &(&1["path"] == "$.rows[0].total_battery_energy_consumed_wh" and
                 &1["message"] ==
                   "must equal source_resource_projection activity_resource_flow total_battery_energy_consumed_wh")
           )

    stale_cadence_source_flow =
      put_in(
        battery_handoff_manifest,
        [
          "rows",
          Access.at(0),
          "source_resource_projection",
          "activity_resource_flow",
          Access.at(1),
          "battery_energy_generated_wh"
        ],
        9.0
      )

    assert {:error, stale_cadence_source_flow_report} =
             Schema.validate_artifact(stale_cadence_source_flow)

    assert Enum.any?(
             stale_cadence_source_flow_report["errors"],
             &(&1["path"] == "$.rows[0].total_battery_energy_generated_wh")
           )

    stale_nested_source_aggregate =
      put_in(
        battery_handoff_manifest,
        ["rows", Access.at(0), "source_resource_projection", "total_battery_energy_consumed_wh"],
        22.0
      )

    assert {:error, stale_nested_source_aggregate_report} =
             Schema.validate_artifact(stale_nested_source_aggregate)

    assert Enum.any?(
             stale_nested_source_aggregate_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_resource_projection.total_battery_energy_consumed_wh" and
                 &1["message"] ==
                   "must equal activity_resource_flow total_battery_energy_consumed_wh")
           )

    stale_cadence_source_review_flow =
      put_in(
        battery_handoff_manifest,
        [
          "rows",
          Access.at(0),
          "source_review_row",
          "source_resource_projection",
          "activity_resource_flow",
          Access.at(1),
          "battery_energy_delta_wh"
        ],
        -4.0
      )

    assert {:error, stale_cadence_source_review_flow_report} =
             Schema.validate_artifact(stale_cadence_source_review_flow)

    assert Enum.any?(
             stale_cadence_source_review_flow_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.net_battery_energy_delta_wh")
           )
  end

  test "validates Cadence import embedded source-report handoff rows" do
    manifest = read_json!("study_results/cadence_import_manifest_v1.json")

    source_timeline_diff_row =
      read_json!("study_results/operator_review_package_v1.json")
      |> Map.fetch!("rows")
      |> Enum.find(&(&1["review_type"] == "timeline_diff_review"))
      |> Map.fetch!("source_timeline_diff")

    manifest_with_timeline_diff_source =
      put_in(manifest, ["rows", Access.at(0), "source_timeline_diff"], source_timeline_diff_row)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_timeline_diff_source)

    invalid_source_timeline_diff =
      put_in(
        manifest_with_timeline_diff_source,
        ["rows", Access.at(0), "source_timeline_diff", "timeline_id"],
        "timeline with spaces"
      )

    assert {:error, source_timeline_diff_report} =
             Schema.validate_artifact(invalid_source_timeline_diff)

    assert Enum.any?(
             source_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].source_timeline_diff.timeline_id")
           )

    command_window_row =
      read_json!("study_results/command_window_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    manifest_with_command_window_source =
      put_in(manifest, ["rows", Access.at(0), "source_command_window"], command_window_row)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_command_window_source)

    invalid_source_command_window =
      put_in(
        manifest_with_command_window_source,
        ["rows", Access.at(0), "source_command_window", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_command_window_report} =
             Schema.validate_artifact(invalid_source_command_window)

    assert Enum.any?(
             source_command_window_report["errors"],
             &(&1["path"] == "$.rows[0].source_command_window.ground_station_id")
           )

    maneuver_review_row =
      read_json!("study_results/maneuver_review_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    manifest_with_maneuver_review_source =
      put_in(manifest, ["rows", Access.at(0), "source_maneuver_review"], maneuver_review_row)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_maneuver_review_source)

    invalid_source_maneuver_review =
      put_in(
        manifest_with_maneuver_review_source,
        ["rows", Access.at(0), "source_maneuver_review", "maneuver_id"],
        "maneuver with spaces"
      )

    assert {:error, source_maneuver_review_report} =
             Schema.validate_artifact(invalid_source_maneuver_review)

    assert Enum.any?(
             source_maneuver_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_maneuver_review.maneuver_id")
           )

    ranking_comparison_row =
      read_json!("study_results/ranking_comparison_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    manifest_with_ranking_comparison_source =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_ranking_comparison"],
        ranking_comparison_row
      )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_ranking_comparison_source)

    invalid_source_ranking_comparison =
      put_in(
        manifest_with_ranking_comparison_source,
        ["rows", Access.at(0), "source_ranking_comparison", "scenario_id"],
        "scenario with spaces"
      )

    assert {:error, source_ranking_comparison_report} =
             Schema.validate_artifact(invalid_source_ranking_comparison)

    assert Enum.any?(
             source_ranking_comparison_report["errors"],
             &(&1["path"] == "$.rows[0].source_ranking_comparison.scenario_id")
           )

    contention_group =
      read_json!("study_results/contact_contention_report_v1.json")
      |> Map.fetch!("conflict_groups")
      |> List.first()

    manifest_with_contention_group_source =
      put_in(manifest, ["rows", Access.at(0), "source_contention_group"], contention_group)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_contention_group_source)

    invalid_source_contention_group =
      put_in(
        manifest_with_contention_group_source,
        ["rows", Access.at(0), "source_contention_group", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_contention_group_report} =
             Schema.validate_artifact(invalid_source_contention_group)

    assert Enum.any?(
             source_contention_group_report["errors"],
             &(&1["path"] == "$.rows[0].source_contention_group.ground_station_id")
           )

    station_calendar_contact =
      read_json!("study_results/station_calendar_report_v1.json")
      |> Map.fetch!("affected_contacts")
      |> List.first()

    manifest_with_station_calendar_source =
      put_in(
        manifest,
        ["rows", Access.at(0), "source_station_calendar_review"],
        station_calendar_contact
      )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_station_calendar_source)

    invalid_source_station_calendar_review =
      put_in(
        manifest_with_station_calendar_source,
        ["rows", Access.at(0), "source_station_calendar_review", "ground_station_id"],
        "station with spaces"
      )

    assert {:error, source_station_calendar_review_report} =
             Schema.validate_artifact(invalid_source_station_calendar_review)

    assert Enum.any?(
             source_station_calendar_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_review.ground_station_id")
           )

    source_feedback_row =
      read_json!("study_results/operator_review_package_v1.json")
      |> Map.fetch!("rows")
      |> Enum.find(&(&1["review_type"] == "realized_feedback"))
      |> Map.fetch!("source_feedback")

    manifest_with_feedback_source =
      put_in(manifest, ["rows", Access.at(0), "source_feedback"], source_feedback_row)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest_with_feedback_source)

    invalid_source_feedback =
      put_in(
        manifest_with_feedback_source,
        ["rows", Access.at(0), "source_feedback", "activity_id"],
        "activity with spaces"
      )

    assert {:error, source_feedback_report} = Schema.validate_artifact(invalid_source_feedback)

    assert Enum.any?(
             source_feedback_report["errors"],
             &(&1["path"] == "$.rows[0].source_feedback.activity_id")
           )

    invalid_source_feedback_factor =
      put_in(
        manifest_with_feedback_source,
        ["rows", Access.at(0), "source_feedback", "command_success_factor"],
        -0.1
      )

    assert {:error, source_feedback_factor_report} =
             Schema.validate_artifact(invalid_source_feedback_factor)

    assert Enum.any?(
             source_feedback_factor_report["errors"],
             &(&1["path"] == "$.rows[0].source_feedback.command_success_factor")
           )

    invalid_source_feedback_quality =
      put_in(
        manifest_with_feedback_source,
        ["rows", Access.at(0), "source_feedback", "cloud_cover_fraction"],
        1.2
      )

    assert {:error, source_feedback_quality_report} =
             Schema.validate_artifact(invalid_source_feedback_quality)

    assert Enum.any?(
             source_feedback_quality_report["errors"],
             &(&1["path"] == "$.rows[0].source_feedback.cloud_cover_fraction")
           )

    invalid_row_quality_fraction =
      put_in(manifest_with_feedback_source, ["rows", Access.at(0), "blur_score"], -0.1)

    assert {:error, row_quality_fraction_report} =
             Schema.validate_artifact(invalid_row_quality_fraction)

    assert Enum.any?(
             row_quality_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].blur_score")
           )

    invalid_row_image_quality_score =
      put_in(manifest_with_feedback_source, ["rows", Access.at(0), "image_quality_score"], 1.2)

    assert {:error, row_image_quality_score_report} =
             Schema.validate_artifact(invalid_row_image_quality_score)

    assert Enum.any?(
             row_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[0].image_quality_score")
           )

    invalid_row_observation_quality_handoff =
      manifest_with_feedback_source
      |> put_in(["rows", Access.at(0), "image_quality_score_delta"], "worse")
      |> put_in(["rows", Access.at(0), "blur_score_delta"], "blurrier")
      |> put_in(["rows", Access.at(0), "realized_image_quality_status"], 42)
      |> put_in(["rows", Access.at(0), "image_quality_source"], 42)

    assert {:error, row_observation_quality_handoff_report} =
             Schema.validate_artifact(invalid_row_observation_quality_handoff)

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].image_quality_score_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].blur_score_delta")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].realized_image_quality_status")
           )

    assert Enum.any?(
             row_observation_quality_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].image_quality_source")
           )

    invalid_row_feedback_maneuver_handoff =
      manifest_with_feedback_source
      |> put_in(["rows", Access.at(0), "feedback_weight"], -0.1)
      |> put_in(["rows", Access.at(0), "feedback_weight_source"], 42)
      |> put_in(["rows", Access.at(0), "maneuver_success"], "yes")
      |> put_in(["rows", Access.at(0), "maneuver_result"], 42)
      |> put_in(["rows", Access.at(0), "maneuver_success_factor"], 1.2)
      |> put_in(["rows", Access.at(0), "maneuver_success_factor_source"], 42)

    assert {:error, row_feedback_maneuver_handoff_report} =
             Schema.validate_artifact(invalid_row_feedback_maneuver_handoff)

    for field <- [
          "feedback_weight",
          "feedback_weight_source",
          "maneuver_success",
          "maneuver_result",
          "maneuver_success_factor",
          "maneuver_success_factor_source"
        ] do
      assert Enum.any?(
               row_feedback_maneuver_handoff_report["errors"],
               &(&1["path"] == "$.rows[0].#{field}")
             )
    end

    invalid_row_eclipse_lighting_handoff =
      manifest_with_feedback_source
      |> put_in(["rows", Access.at(0), "planned_eclipse_overlap_s"], "long")
      |> put_in(["rows", Access.at(0), "realized_lighting_condition"], 42)
      |> put_in(["rows", Access.at(0), "lighting_confidence"], %{"label" => "high"})

    assert {:error, row_eclipse_lighting_handoff_report} =
             Schema.validate_artifact(invalid_row_eclipse_lighting_handoff)

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].planned_eclipse_overlap_s")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].realized_lighting_condition")
           )

    assert Enum.any?(
             row_eclipse_lighting_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].lighting_confidence")
           )

    invalid_row_link_error_rate =
      put_in(manifest_with_feedback_source, ["rows", Access.at(0), "packet_loss_rate"], 1.2)

    assert {:error, row_link_error_rate_report} =
             Schema.validate_artifact(invalid_row_link_error_rate)

    assert Enum.any?(
             row_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[0].packet_loss_rate")
           )

    invalid_row_link_handoff =
      manifest_with_feedback_source
      |> put_in(["rows", Access.at(0), "link_protocol"], 42)
      |> put_in(["rows", Access.at(0), "data_rate_delta_mbps"], "slow")
      |> put_in(["rows", Access.at(0), "carrier_lock"], "locked")

    assert {:error, row_link_handoff_report} =
             Schema.validate_artifact(invalid_row_link_handoff)

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].link_protocol")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].data_rate_delta_mbps")
           )

    assert Enum.any?(
             row_link_handoff_report["errors"],
             &(&1["path"] == "$.rows[0].carrier_lock")
           )
  end

  test "validates Cadence import nested review-copy handoff rows" do
    manifest = read_json!("study_results/cadence_import_manifest_v1.json")

    source_timeline_diff_row =
      read_json!("study_results/operator_review_package_v1.json")
      |> Map.fetch!("rows")
      |> Enum.find(&(&1["review_type"] == "timeline_diff_review"))
      |> Map.fetch!("source_timeline_diff")

    command_window_row =
      read_json!("study_results/command_window_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    maneuver_review_row =
      read_json!("study_results/maneuver_review_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    ranking_comparison_row =
      read_json!("study_results/ranking_comparison_report_v1.json")
      |> Map.fetch!("rows")
      |> List.first()

    contention_group =
      read_json!("study_results/contact_contention_report_v1.json")
      |> Map.fetch!("conflict_groups")
      |> List.first()

    station_calendar_contact =
      read_json!("study_results/station_calendar_report_v1.json")
      |> Map.fetch!("affected_contacts")
      |> List.first()

    source_feedback_row =
      read_json!("study_results/operator_review_package_v1.json")
      |> Map.fetch!("rows")
      |> Enum.find(&(&1["review_type"] == "realized_feedback"))
      |> Map.fetch!("source_feedback")

    invalid_review_copy_lineage =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_window_id" => "window_1",
        "source_window_lineage" => %{
          "candidate_activity_id" => "review copy candidate with spaces",
          "source_window_id" => "window_1",
          "source_window_type" => "downlink",
          "scenario_id" => "leo_1"
        }
      })

    assert {:error, review_copy_lineage_report} =
             Schema.validate_artifact(invalid_review_copy_lineage)

    assert Enum.any?(
             review_copy_lineage_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_window_lineage.candidate_activity_id")
           )

    invalid_review_copy_delta =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_delta" => %{
          "activity_id" => "review copy activity with spaces",
          "activity_type" => "downlink",
          "status" => "changed",
          "repair_action" => "moved"
        }
      })

    assert {:error, review_copy_delta_report} =
             Schema.validate_artifact(invalid_review_copy_delta)

    assert Enum.any?(
             review_copy_delta_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_delta.activity_id")
           )

    invalid_review_copy_requirement =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_requirement" => %{
          "activity_id" => "review copy activity with spaces",
          "activity_type" => "downlink",
          "action" => "approve_contact",
          "reason" => "operator review"
        }
      })

    assert {:error, review_copy_requirement_report} =
             Schema.validate_artifact(invalid_review_copy_requirement)

    assert Enum.any?(
             review_copy_requirement_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_requirement.activity_id")
           )

    invalid_review_copy_policy_decision =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_policy_decision" => %{
          "schema_contract" => "policy_decision.v1",
          "classification" => "maybe"
        }
      })

    assert {:error, review_copy_policy_decision_report} =
             Schema.validate_artifact(invalid_review_copy_policy_decision)

    assert Enum.any?(
             review_copy_policy_decision_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_policy_decision.classification")
           )

    invalid_review_copy_policy_escalation =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_policy_escalation" => %{"rule_id" => "rule with spaces"}
      })

    assert {:error, review_copy_policy_escalation_report} =
             Schema.validate_artifact(invalid_review_copy_policy_escalation)

    assert Enum.any?(
             review_copy_policy_escalation_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_policy_escalation.rule_id")
           )

    invalid_review_copy_resource_suppression =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_resource_suppression" => %{
          "id" => "resource suppression with spaces",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "suppressed_reason" => "payload_unavailable"
        }
      })

    assert {:error, review_copy_resource_suppression_report} =
             Schema.validate_artifact(invalid_review_copy_resource_suppression)

    assert Enum.any?(
             review_copy_resource_suppression_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_resource_suppression.id")
           )

    invalid_review_copy_link_capacity =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_link_capacity" => %{
          "ground_station_id" => "station with spaces",
          "contact_count" => 1,
          "selected_contact_count" => 0,
          "estimated_throughput_mb" => 1.0,
          "selected_estimated_throughput_mb" => 0.0,
          "contact_ids" => ["contact_1"],
          "selected_contact_ids" => []
        }
      })

    assert {:error, review_copy_link_capacity_report} =
             Schema.validate_artifact(invalid_review_copy_link_capacity)

    assert Enum.any?(
             review_copy_link_capacity_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_link_capacity.ground_station_id")
           )

    invalid_review_copy_capacity_range =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "capacity_fraction_min" => -0.1,
        "capacity_fraction_max" => 1.2
      })

    assert {:error, review_copy_capacity_range_report} =
             Schema.validate_artifact(invalid_review_copy_capacity_range)

    assert Enum.any?(
             review_copy_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.capacity_fraction_min")
           )

    assert Enum.any?(
             review_copy_capacity_range_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.capacity_fraction_max")
           )

    invalid_review_copy_timeline_diff =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_timeline_diff" =>
          Map.put(source_timeline_diff_row, "timeline_id", "timeline with spaces")
      })

    assert {:error, review_copy_timeline_diff_report} =
             Schema.validate_artifact(invalid_review_copy_timeline_diff)

    assert Enum.any?(
             review_copy_timeline_diff_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_timeline_diff.timeline_id")
           )

    invalid_review_copy_command_window =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_command_window" =>
          Map.put(command_window_row, "ground_station_id", "station with spaces")
      })

    assert {:error, review_copy_command_window_report} =
             Schema.validate_artifact(invalid_review_copy_command_window)

    assert Enum.any?(
             review_copy_command_window_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_command_window.ground_station_id")
           )

    invalid_review_copy_maneuver_review =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_maneuver_review" =>
          Map.put(maneuver_review_row, "maneuver_id", "maneuver with spaces")
      })

    assert {:error, review_copy_maneuver_review_report} =
             Schema.validate_artifact(invalid_review_copy_maneuver_review)

    assert Enum.any?(
             review_copy_maneuver_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_maneuver_review.maneuver_id")
           )

    invalid_review_copy_ranking_comparison =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_ranking_comparison" =>
          Map.put(ranking_comparison_row, "scenario_id", "scenario with spaces")
      })

    assert {:error, review_copy_ranking_comparison_report} =
             Schema.validate_artifact(invalid_review_copy_ranking_comparison)

    assert Enum.any?(
             review_copy_ranking_comparison_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_ranking_comparison.scenario_id")
           )

    invalid_review_copy_contention_group =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_contention_group" =>
          Map.put(contention_group, "ground_station_id", "station with spaces")
      })

    assert {:error, review_copy_contention_group_report} =
             Schema.validate_artifact(invalid_review_copy_contention_group)

    assert Enum.any?(
             review_copy_contention_group_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_contention_group.ground_station_id")
           )

    invalid_review_copy_station_calendar_review =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_station_calendar_review" =>
          Map.put(station_calendar_contact, "ground_station_id", "station with spaces")
      })

    assert {:error, review_copy_station_calendar_review_report} =
             Schema.validate_artifact(invalid_review_copy_station_calendar_review)

    assert Enum.any?(
             review_copy_station_calendar_review_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_station_calendar_review.ground_station_id")
           )

    invalid_review_copy_feedback =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_feedback" => Map.put(source_feedback_row, "activity_id", "activity with spaces")
      })

    assert {:error, review_copy_feedback_report} =
             Schema.validate_artifact(invalid_review_copy_feedback)

    assert Enum.any?(
             review_copy_feedback_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.source_feedback.activity_id")
           )

    invalid_review_copy_feedback_factor =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_feedback" => Map.put(source_feedback_row, "observation_success_factor", 1.2)
      })

    assert {:error, review_copy_feedback_factor_report} =
             Schema.validate_artifact(invalid_review_copy_feedback_factor)

    assert Enum.any?(
             review_copy_feedback_factor_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_feedback.observation_success_factor")
           )

    invalid_review_copy_feedback_quality =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "source_feedback" => Map.put(source_feedback_row, "planned_cloud_cover_fraction", -0.1)
      })

    assert {:error, review_copy_feedback_quality_report} =
             Schema.validate_artifact(invalid_review_copy_feedback_quality)

    assert Enum.any?(
             review_copy_feedback_quality_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.source_feedback.planned_cloud_cover_fraction")
           )

    invalid_review_copy_quality_fraction =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "realized_blur_score" => 1.3
      })

    assert {:error, review_copy_quality_fraction_report} =
             Schema.validate_artifact(invalid_review_copy_quality_fraction)

    assert Enum.any?(
             review_copy_quality_fraction_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.realized_blur_score")
           )

    invalid_review_copy_image_quality_score =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "planned_image_quality_score" => -0.1
      })

    assert {:error, review_copy_image_quality_score_report} =
             Schema.validate_artifact(invalid_review_copy_image_quality_score)

    assert Enum.any?(
             review_copy_image_quality_score_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.planned_image_quality_score")
           )

    invalid_review_copy_link_error_rate =
      put_in(manifest, ["rows", Access.at(0), "source_review_row"], %{
        "planned_packet_loss_rate" => 1.2
      })

    assert {:error, review_copy_link_error_rate_report} =
             Schema.validate_artifact(invalid_review_copy_link_error_rate)

    assert Enum.any?(
             review_copy_link_error_rate_report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.planned_packet_loss_rate")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
