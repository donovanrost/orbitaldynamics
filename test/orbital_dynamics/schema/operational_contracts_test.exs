defmodule OrbitalDynamics.Schema.OperationalContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates checked-in operational import eligibility summary fixture" do
    report = read_json!("study_results/operational_readiness_report_v1.json")
    summary = read_json!("study_results/operational_import_eligibility_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_import_eligibility(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "operational_import_eligibility_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_import_eligibility_summary.v1",
             "model" => "artifact_only_import_eligibility_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "import_eligible" => true,
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "review_gate_count" => 0,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 0,
             "non_passed_gates" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_summary",
               "source" => "operational_readiness_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "operational_import_eligibility_summary_routes_only",
             "operational_import_eligibility_summary_does_not_approve_or_import"
           ]

    assert {:ok, import_eligibility_schema} =
             Schema.json_schema("operational_import_eligibility_summary.v1")

    assert get_in(import_eligibility_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational readiness gate summary fixture" do
    report = read_json!("study_results/operational_readiness_report_v1.json")
    summary = read_json!("study_results/operational_readiness_gate_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_readiness_gate_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "operational_readiness_gate_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_readiness_gate_summary.v1",
             "model" => "artifact_only_operational_readiness_gate_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "review_gate_count" => 0,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 0,
             "gate_status_counts" => %{"passed" => 5},
             "gate_classification_counts" => %{"importable" => 5},
             "gate_ids_by_status" => %{
               "passed" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ]
             },
             "gate_ids_by_classification" => %{
               "importable" => [
                 "adapter_boundary",
                 "cadence_import",
                 "operational_mode",
                 "operator_review",
                 "source_contract"
               ]
             },
             "passed_gate_ids" => [
               "source_contract",
               "operational_mode",
               "adapter_boundary",
               "operator_review",
               "cadence_import"
             ],
             "review_required_gate_ids" => [],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => [],
             "non_passed_gate_ids" => [],
             "non_passed_gates" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_summary",
               "source" => "operational_readiness_report.v1"
             }
           } = summary

    assert Enum.map(summary["gates"], & &1["id"]) == [
             "source_contract",
             "operational_mode",
             "adapter_boundary",
             "operator_review",
             "cadence_import"
           ]

    assert summary["model_limits"] == [
             "operational_readiness_gate_summary_routes_only",
             "operational_readiness_gate_summary_does_not_approve_or_import"
           ]

    assert {:ok, gate_summary_schema} =
             Schema.json_schema("operational_readiness_gate_summary.v1")

    assert get_in(gate_summary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational execution boundary summary fixture" do
    report = read_json!("study_results/operational_readiness_report_v1.json")
    summary = read_json!("study_results/operational_execution_boundary_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_execution_boundary_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "operational_execution_boundary_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_execution_boundary_summary.v1",
             "model" => "artifact_only_operational_execution_boundary_summary",
             "source" => "operational_readiness_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "status" => "passed",
             "import_eligible" => true,
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "adapter_handoff_only",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "review_gate_count" => 0,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 0,
             "non_passed_gate_ids" => [],
             "operational_mode_gate" => %{
               "classification" => "importable",
               "id" => "operational_mode",
               "reason" =>
                 "artifact is not marked as simulation, rehearsal, trade study, or not-for-execution",
               "status" => "passed"
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
               "operator_authority" => "not_granted_by_execution_boundary_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "operational_readiness_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "operational_execution_boundary_summary_routes_only",
             "operational_execution_boundary_summary_does_not_execute_or_import"
           ]

    assert {:ok, execution_boundary_schema} =
             Schema.json_schema("operational_execution_boundary_summary.v1")

    assert get_in(execution_boundary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational quality gate summary fixture" do
    report = read_json!("study_results/quality_gate_resource_pressure_v1.json")
    summary = read_json!("study_results/operational_quality_gate_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_quality_gate_summary(report)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_quality_gate_summary.v1",
             "model" => "artifact_only_quality_gate_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "resource_summaries",
             "source_quality_gate_report_id" =>
               "quality_gate:resource_projection_report.v1:resource_summaries",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:resource_summaries",
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "execution_boundary" => "operator_review_required_before_import",
             "gate_count" => 6,
             "passed_gate_count" => 3,
             "review_gate_count" => 3,
             "analysis_gate_count" => 0,
             "blocked_gate_count" => 0,
             "non_passed_gate_count" => 3,
             "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
             "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
             "gate_ids_by_status" => %{
               "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
               "review_required" => [
                 "cadence_import",
                 "operator_review",
                 "resource_availability"
               ]
             },
             "gate_ids_by_classification" => %{
               "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
               "review_only" => ["cadence_import", "operator_review", "resource_availability"]
             },
             "passed_gate_ids" => ["adapter_boundary", "operational_mode", "source_contract"],
             "review_required_gate_ids" => [
               "cadence_import",
               "operator_review",
               "resource_availability"
             ],
             "analysis_only_gate_ids" => [],
             "blocked_gate_ids" => [],
             "non_passed_gate_ids" => [
               "cadence_import",
               "operator_review",
               "resource_availability"
             ],
             "non_passed_quality_gate_row_ids" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6",
               "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_quality_gate_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             }
           } = summary

    assert Enum.map(summary["rows"], & &1["id"]) == [
             "quality_gate:resource_projection_report.v1:resource_summaries:source_contract:1",
             "quality_gate:resource_projection_report.v1:resource_summaries:operational_mode:2",
             "quality_gate:resource_projection_report.v1:resource_summaries:adapter_boundary:3",
             "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
             "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
             "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6"
           ]

    assert summary["quality_gate_row_ids_by_status"] == %{
             "passed" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:adapter_boundary:3",
               "quality_gate:resource_projection_report.v1:resource_summaries:operational_mode:2",
               "quality_gate:resource_projection_report.v1:resource_summaries:source_contract:1"
             ],
             "review_required" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6",
               "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ]
           }

    assert summary["quality_gate_row_ids_by_classification"] == %{
             "importable" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:adapter_boundary:3",
               "quality_gate:resource_projection_report.v1:resource_summaries:operational_mode:2",
               "quality_gate:resource_projection_report.v1:resource_summaries:source_contract:1"
             ],
             "review_only" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6",
               "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ]
           }

    assert summary["model_limits"] == [
             "quality_gate_summary_derives_classification_from_gate_rows",
             "quality_gate_summary_does_not_approve_or_import"
           ]

    assert {:ok, quality_gate_summary_schema} =
             Schema.json_schema("operational_quality_gate_summary.v1")

    assert get_in(quality_gate_summary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational quality gate unavailable-resource summary fixture" do
    report = read_json!("study_results/quality_gate_resource_pressure_v1.json")

    summary =
      read_json!("study_results/operational_quality_gate_unavailable_resource_summary_v1.json")

    generated_summary =
      OrbitalDynamics.operational_quality_gate_unavailable_resource_summary(report)

    assert generated_summary == summary

    assert {:ok,
            %{
              "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"
            }} = Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
             "model" => "artifact_only_quality_gate_unavailable_resource_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "resource_summaries",
             "source_quality_gate_report_id" =>
               "quality_gate:resource_projection_report.v1:resource_summaries",
             "source_readiness_report_id" =>
               "operational_readiness:resource_projection_report.v1:resource_summaries",
             "resource_availability_row_count" => 1,
             "unavailable_resource_row_count" => 1,
             "unavailable_resource_pressure_count" => 2,
             "unavailable_resource_reason_counts" => %{
               "antenna_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "unavailable_resource_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "station_availability_reason_counts" => %{},
             "station_availability_reason_ids" => [],
             "resource_blocking_dimension_counts" => %{},
             "blocked_contact_ids_by_blocking_dimension" => %{},
             "blocked_contact_ids_by_spacecraft_id" => %{},
             "blocked_contact_ids_by_status" => %{},
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [
                 "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
               ]
             },
             "quality_gate_ids_by_status" => %{
               "review_required" => ["resource_availability"]
             },
             "review_required_quality_gate_row_ids" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ],
             "blocked_quality_gate_row_ids" => [],
             "resource_availability_gate_ids" => ["resource_availability"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "source" => "quality_gate_report.v1",
               "operator_authority" => "not_granted_by_unavailable_resource_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary"
             }
           } = summary

    assert summary["model_limits"] == [
             "quality_gate_unavailable_resource_summary_routes_only",
             "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
           ]

    assert {:ok, unavailable_resource_schema} =
             Schema.json_schema("operational_quality_gate_unavailable_resource_summary.v1")

    assert get_in(unavailable_resource_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational quality gate operator training summary fixture" do
    source = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "cadence_import_manifest_fixture",
      "manifest_id" => "manifest_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "import_replacement_activity",
          "import_status" => "ready_for_import",
          "cadence_import_status" => "present",
          "required_operator_roles" => ["mission_director", "contact_operator"],
          "required_training_ids" => ["contact_replan_drill"],
          "required_certification_ids" => ["cadence_import_cert"],
          "required_qualification_ids" => ["sat_ops_current"]
        }
      ]
    }

    summary =
      read_json!("study_results/operational_quality_gate_operator_training_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_quality_gate_operator_training_summary(source)

    assert generated_summary == summary

    assert {:ok,
            %{
              "schema_contract" => "operational_quality_gate_operator_training_summary.v1"
            }} = Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
             "model" => "artifact_only_quality_gate_operator_training_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
             "operator_training_row_count" => 1,
             "operator_training_requirement_count" => 5,
             "operator_training_requirement_counts" => %{
               "certification" => 1,
               "operator_role" => 2,
               "qualification" => 1,
               "training" => 1
             },
             "operator_training_requirement_ids" => [
               "certification",
               "operator_role",
               "qualification",
               "training"
             ],
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"],
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [
                 "quality_gate:planned_activity.v1:activity_1:operator_training:4"
               ]
             },
             "quality_gate_row_ids_by_classification" => %{
               "review_only" => [
                 "quality_gate:planned_activity.v1:activity_1:operator_training:4"
               ]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
             "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
             "review_required_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:operator_training:4"
             ],
             "review_only_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:operator_training:4"
             ],
             "blocked_quality_gate_row_ids" => [],
             "operator_training_gate_ids" => ["operator_training"],
             "operator_training_review_required" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_operator_training_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "quality_gate_operator_training_summary_routes_only",
             "quality_gate_operator_training_summary_does_not_approve_or_import"
           ]

    assert {:ok, operator_training_schema} =
             Schema.json_schema("operational_quality_gate_operator_training_summary.v1")

    assert get_in(operator_training_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational quality gate schema validation summary fixture" do
    source = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "cadence_import_manifest_fixture",
      "manifest_id" => "manifest_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "import_replacement_activity",
          "import_status" => "ready_for_import",
          "cadence_import_status" => "present",
          "source_schema_validation_report" => %{
            "schema_contract" => "schema_validation_report.v1",
            "model" => "artifact_contract_validation",
            "validation_mode" => "artifact_file",
            "validated_contract" => "campaign_plan.v1",
            "validated_artifact_family" => "campaign_plan",
            "status" => "fail",
            "error_count" => 1,
            "warning_count" => 0,
            "remediation_count" => 1,
            "errors" => [
              %{
                "path" => "$.plan_id",
                "message" => "is required",
                "severity" => "error"
              }
            ],
            "warnings" => [],
            "remediation" => [
              %{
                "path" => "$.plan_id",
                "category" => "missing_required_field",
                "action" => "Populate this required field"
              }
            ],
            "artifact_path" => "study_results/bad_campaign.json",
            "assumptions" => %{"validation_scope" => "artifact_contract"}
          }
        }
      ]
    }

    summary =
      read_json!("study_results/operational_quality_gate_schema_validation_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_quality_gate_schema_validation_summary(source)

    assert generated_summary == summary

    assert {:ok,
            %{
              "schema_contract" => "operational_quality_gate_schema_validation_summary.v1"
            }} = Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
             "model" => "artifact_only_quality_gate_schema_validation_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
             "schema_validation_row_count" => 1,
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_warning_count" => 0,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "schema_validation_status_ids" => ["fail"],
             "schema_validation_import_blocked" => true,
             "quality_gate_row_ids_by_status" => %{
               "blocked" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
             },
             "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
             "blocked_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:cadence_import:5"
             ],
             "review_required_quality_gate_row_ids" => [],
             "failed_schema_validation_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:cadence_import:5"
             ],
             "schema_validation_gate_ids" => ["cadence_import"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_schema_validation_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "quality_gate_schema_validation_summary_routes_only",
             "quality_gate_schema_validation_summary_does_not_approve_or_import"
           ]

    assert {:ok, schema_validation_schema} =
             Schema.json_schema("operational_quality_gate_schema_validation_summary.v1")

    assert get_in(schema_validation_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  test "validates checked-in operational quality gate import readiness summary fixture" do
    source = %{
      "schema_contract" => "cadence_import_manifest.v1",
      "model" => "cadence_import_manifest_fixture",
      "manifest_id" => "manifest_1",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "activity_1",
      "model_limits" => ["adapter_handoff_only"],
      "rows" => [
        %{
          "id" => "import_1",
          "rank" => 1,
          "import_action" => "import_replacement_activity",
          "import_status" => "ready_for_import",
          "cadence_import_status" => "present",
          "source_freshness_report" => %{
            "schema_contract" => "freshness_report.v1",
            "model" => "accepted_snapshot_horizon_and_quality_freshness",
            "generated_at" => "2026-05-14T00:00:00Z",
            "source" => "accepted_planning_state",
            "accepted_state_snapshot_id" => "accepted_state_1",
            "accepted_state_age_s" => 120.0,
            "max_accepted_state_age_s" => 60.0,
            "horizon_start_s" => 0.0,
            "horizon_end_s" => 600.0,
            "accepted_state_epoch_s" => -120.0,
            "state_quality" => "planning_accepted",
            "allowed_state_quality_levels" => ["planning_accepted"],
            "status" => "stale",
            "stale_reasons" => ["accepted_snapshot_older_than_policy"],
            "unknown_reasons" => []
          }
        }
      ]
    }

    summary =
      read_json!("study_results/operational_quality_gate_import_readiness_summary_v1.json")

    generated_summary = OrbitalDynamics.operational_quality_gate_import_readiness_summary(source)

    assert generated_summary == summary

    assert {:ok, %{"schema_contract" => "operational_quality_gate_import_readiness_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert %{
             "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
             "model" => "artifact_only_quality_gate_import_readiness_summary",
             "source" => "quality_gate_report.v1",
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "activity_1",
             "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
             "source_readiness_report_id" =>
               "operational_readiness:planned_activity.v1:activity_1",
             "import_readiness_row_count" => 1,
             "ready_for_import_count" => 1,
             "manifest_review_required_count" => 0,
             "blocked_import_count" => 0,
             "missing_import_count" => 0,
             "invalid_cadence_import_count" => 0,
             "current_freshness_count" => 0,
             "stale_freshness_count" => 1,
             "unknown_freshness_count" => 0,
             "freshness_status_counts" => %{"stale" => 1},
             "freshness_status_ids" => ["stale"],
             "import_status_counts" => %{"ready_for_import" => 1},
             "import_status_ids" => ["ready_for_import"],
             "cadence_import_status_counts" => %{"present" => 1},
             "cadence_import_status_ids" => ["present"],
             "freshness_review_required" => true,
             "import_preparation_required" => false,
             "import_blocked" => false,
             "quality_gate_row_ids_by_status" => %{
               "review_required" => [
                 "quality_gate:planned_activity.v1:activity_1:cadence_import:5"
               ]
             },
             "quality_gate_ids_by_status" => %{"review_required" => ["cadence_import"]},
             "review_required_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:cadence_import:5"
             ],
             "blocked_quality_gate_row_ids" => [],
             "ready_quality_gate_row_ids" => [],
             "analysis_only_quality_gate_row_ids" => [],
             "stale_or_unknown_freshness_quality_gate_row_ids" => [
               "quality_gate:planned_activity.v1:activity_1:cadence_import:5"
             ],
             "import_preparation_quality_gate_row_ids" => [],
             "blocked_import_quality_gate_row_ids" => [],
             "import_readiness_gate_ids" => ["cadence_import"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_cadence_write",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "cadence_write" => "not_performed_by_summary",
               "command_execution" => "not_performed_by_summary",
               "source" => "quality_gate_report.v1"
             }
           } = summary

    assert summary["model_limits"] == [
             "quality_gate_import_readiness_summary_routes_only",
             "quality_gate_import_readiness_summary_does_not_approve_or_import"
           ]

    assert {:ok, import_readiness_schema} =
             Schema.json_schema("operational_quality_gate_import_readiness_summary.v1")

    assert get_in(import_readiness_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
