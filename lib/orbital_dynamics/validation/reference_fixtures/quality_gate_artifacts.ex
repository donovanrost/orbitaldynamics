defmodule OrbitalDynamics.Validation.ReferenceFixtures.QualityGateArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.quality_gate_report.v1" => %{
      "id" => "fixture.artifact.quality_gate_report.v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "curated quality gate report from ready operational readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 5,
        "gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_status" => %{
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
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_ready_for_import_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_freshness_status_counts" => %{},
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_status_counts" => %{},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by quality_gate_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks gate projection counts and authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_summary.v1",
      "model_id" => "artifact.operational_quality_gate_summary.v1",
      "reference_case" =>
        "checked-in quality gate summary from resource-pressure review evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_quality_gate_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_summary.v1"
      },
      "expected" => %{
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
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "gate_count" => 6,
        "row_derived_gate_count" => 6,
        "passed_gate_count" => 3,
        "row_derived_passed_gate_count" => 3,
        "review_gate_count" => 3,
        "row_derived_review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 3,
        "row_derived_non_passed_gate_count" => 3,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "non_passed_gate_keys" => "cadence_import|operator_review|resource_availability",
        "row_derived_non_passed_gate_keys" =>
          "cadence_import|operator_review|resource_availability",
        "non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_count" => 3,
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "row_derived_non_passed_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks base quality-gate summary routing, review pressure, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
      "model_id" => "artifact.operational_quality_gate_import_readiness_summary.v1",
      "reference_case" =>
        "checked-in quality gate import-readiness summary from stale freshness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_import_readiness_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
        "model" => "artifact_only_quality_gate_import_readiness_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "import_readiness_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 1,
        "row_derived_stale_freshness_count" => 1,
        "unknown_freshness_count" => 0,
        "freshness_status_counts" => %{"stale" => 1},
        "freshness_status_keys" => "stale",
        "import_status_counts" => %{"ready_for_import" => 1},
        "import_status_keys" => "ready_for_import",
        "cadence_import_status_counts" => %{"present" => 1},
        "cadence_import_status_keys" => "present",
        "row_derived_cadence_import_present_count" => 1,
        "freshness_review_required" => true,
        "import_preparation_required" => false,
        "import_blocked" => false,
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["cadence_import"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "blocked_quality_gate_row_keys" => "",
        "ready_quality_gate_row_keys" => "",
        "analysis_only_quality_gate_row_keys" => "",
        "stale_or_unknown_freshness_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "import_preparation_quality_gate_row_keys" => "",
        "blocked_import_quality_gate_row_keys" => "",
        "import_readiness_gate_keys" => "cadence_import",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "import_readiness_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_cadence_import_present_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_import_readiness_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import-readiness status maps, freshness review routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "reference_case" =>
        "generated quality gate unavailable-resource summary from contact allocation resource pressure",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "source_artifact_type" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "model" => "artifact_only_quality_gate_unavailable_resource_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source_artifact_id" => "validation_unavailable_resource_fixture",
        "source_quality_gate_report_id" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "source_readiness_report_id" =>
          "operational_readiness:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "resource_availability_row_count" => 1,
        "row_derived_resource_availability_row_count" => 1,
        "unavailable_resource_row_count" => 1,
        "unavailable_resource_pressure_count" => 1,
        "row_derived_unavailable_resource_pressure_count" => 1,
        "unavailable_resource_reason_counts" => %{"antenna_unavailable" => 1},
        "unavailable_resource_reason_keys" => "antenna_unavailable",
        "station_availability_reason_counts" => %{},
        "station_availability_reason_keys" => "",
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "blocked_contact_ids_by_blocking_dimension" => %{"antenna" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_spacecraft_id" => %{"leo_1" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_status" => %{"review_required" => ["dl_resource_blocked"]},
        "quality_gate_row_ids_by_status" => %{
          "review_required" => [
            "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4"
          ]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4",
        "blocked_quality_gate_row_keys" => "",
        "resource_availability_gate_keys" => "resource_availability",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "resource_availability_row_count" => 0,
        "row_derived_resource_availability_row_count" => 0,
        "unavailable_resource_row_count" => 0,
        "unavailable_resource_pressure_count" => 0,
        "row_derived_unavailable_resource_pressure_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_unavailable_resource_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external operations validation",
        "checks unavailable-resource reason maps, row-status routing, contact ID maps, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
      %{
        "id" =>
          "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
        "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
        "reference_case" =>
          "checked-in quality gate unavailable-resource summary from resource projection pressure",
        "validation_level" => "artifact_contract",
        "fixture_type" => "curated_internal_artifact_regression",
        "inputs" => %{
          "artifact_path" =>
            "study_results/operational_quality_gate_unavailable_resource_summary_v1.json",
          "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
          "source_artifact_type" => "resource_projection_report.v1"
        },
        "expected" => %{
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
          "row_derived_resource_availability_row_count" => 1,
          "unavailable_resource_row_count" => 1,
          "unavailable_resource_pressure_count" => 2,
          "row_derived_unavailable_resource_pressure_count" => 2,
          "unavailable_resource_reason_counts" => %{
            "antenna_unavailable" => 1,
            "payload_unavailable" => 1
          },
          "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
          "station_availability_reason_counts" => %{},
          "station_availability_reason_keys" => "",
          "resource_blocking_dimension_counts" => %{},
          "blocked_contact_ids_by_blocking_dimension" => %{},
          "blocked_contact_ids_by_spacecraft_id" => %{},
          "blocked_contact_ids_by_status" => %{},
          "quality_gate_row_ids_by_status" => %{
            "review_required" => [
              "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
            ]
          },
          "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
          "review_required_quality_gate_row_keys" =>
            "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
          "blocked_quality_gate_row_keys" => "",
          "resource_availability_gate_keys" => "resource_availability",
          "row_derived_review_required_quality_gate_row_count" => 1,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "execution_boundary" => "artifact_only_no_cadence_write",
          "operator_authority" => "not_granted_by_unavailable_resource_summary",
          "cadence_write" => "not_performed_by_summary",
          "command_execution" => "not_performed_by_summary",
          "model_limit_count" => 2
        },
        "tolerances" => %{
          "resource_availability_row_count" => 0,
          "row_derived_resource_availability_row_count" => 0,
          "unavailable_resource_row_count" => 0,
          "unavailable_resource_pressure_count" => 0,
          "row_derived_unavailable_resource_pressure_count" => 0,
          "row_derived_review_required_quality_gate_row_count" => 0,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "model_limit_count" => 0
        },
        "evidence" => [
          "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
          "schema-linted by mix orbital_dynamics.schema.lint"
        ],
        "known_limits" => [
          "internal checked-in artifact regression, not external operations validation",
          "checks resource-projection unavailable-resource reason maps, review routing, and no-authority boundary only"
        ]
      },
    "fixture.artifact.operational_quality_gate_operator_training_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
      "model_id" => "artifact.operational_quality_gate_operator_training_summary.v1",
      "reference_case" =>
        "checked-in quality gate operator-training summary from review-required training evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_operator_training_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_operator_training_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
        "model" => "artifact_only_quality_gate_operator_training_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "operator_training_row_count" => 1,
        "operator_training_requirement_count" => 5,
        "row_derived_operator_training_requirement_count" => 5,
        "operator_training_requirement_counts" => %{
          "certification" => 1,
          "operator_role" => 2,
          "qualification" => 1,
          "training" => 1
        },
        "operator_training_requirement_keys" =>
          "certification|operator_role|qualification|training",
        "required_operator_role_keys" => "contact_operator|mission_director",
        "required_training_keys" => "contact_replan_drill",
        "required_certification_keys" => "cadence_import_cert",
        "required_qualification_keys" => "sat_ops_current",
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
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "blocked_quality_gate_row_keys" => "",
        "review_only_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "operator_training_gate_keys" => "operator_training",
        "operator_training_review_required" => true,
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_review_only_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "operator_training_row_count" => 0,
        "operator_training_requirement_count" => 0,
        "row_derived_operator_training_requirement_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_review_only_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_operator_training_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-training requirement routing and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
      "model_id" => "artifact.operational_quality_gate_schema_validation_summary.v1",
      "reference_case" =>
        "checked-in quality gate schema-validation summary from failed schema evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_schema_validation_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_schema_validation_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
        "model" => "artifact_only_quality_gate_schema_validation_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "schema_validation_row_count" => 1,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 1,
        "row_derived_schema_validation_fail_count" => 1,
        "schema_validation_error_count" => 1,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 1,
        "schema_validation_status_counts" => %{"fail" => 1},
        "schema_validation_status_keys" => "fail",
        "schema_validation_import_blocked" => true,
        "quality_gate_row_ids_by_status" => %{
          "blocked" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
        "blocked_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "review_required_quality_gate_row_keys" => "",
        "failed_schema_validation_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "schema_validation_gate_keys" => "cadence_import",
        "row_derived_blocked_quality_gate_row_count" => 1,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "schema_validation_row_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_schema_validation_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks schema-validation status maps, blocked row routing, and no-authority boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
