defmodule OrbitalDynamics.Validation.ReferenceFixtures.ResourcePressureHandoffArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.cadence_import_manifest.resource_pressure_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" => "checked-in resource-pressure Cadence import manifest artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/cadence_import_resource_pressure_v1.json",
        "contract" => "cadence_import_manifest.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "manifest_id" =>
          "cadence_import_manifest:operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "operational_readiness_report.v1",
        "source_artifact_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "row_count" => 4,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 4,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 4,
        "import_status_counts" => %{"review_required_before_import" => 4},
        "row_derived_import_status_counts" => %{"review_required_before_import" => 4},
        "import_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_import_action_counts" => %{"review_operational_readiness" => 4},
        "cadence_import_status_counts" => %{"present" => 4},
        "row_derived_cadence_import_status_counts" => %{"present" => 4},
        "required_operator_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "source_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_source_review_type_counts" => %{
          "operational_readiness_review" => 4
        },
        "import_side_counts" => %{"source" => 4},
        "row_derived_import_side_counts" => %{"source" => 4},
        "source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "row_derived_source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_import_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 0,
        "resource_availability_import_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-pressure import routing and no-write authorization boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.resource_pressure_v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" => "checked-in resource-pressure operational readiness artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_resource_pressure_v1.json",
        "contract" => "operational_readiness_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
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
        "row_derived_gate_status_counts" => %{
          "passed" => 3,
          "review_required" => 3
        },
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "review_row_count" => 1,
        "import_row_count" => 1,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "import_status_counts" => %{"review_required_before_import" => 1},
        "row_derived_import_status_counts" => %{},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{},
        "resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "resource_availability_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "source_model_count" => 1,
        "source_model_limit_count" => 9,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "resource_availability_pressure_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "source_model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure readiness classification and no-execution boundary only"
      ]
    },
    "fixture.artifact.operator_review_package.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_pressure_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in resource-pressure operator review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_resource_pressure_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 4,
        "row_derived_review_count" => 4,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0,
        "row_derived_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "row_derived_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_review_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable"
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "resource_availability_review_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operator workflow validation",
        "checks resource-pressure review routing and artifact-only review boundary only"
      ]
    },
    "fixture.artifact.quality_gate_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.quality_gate_report.resource_pressure_v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "checked-in resource-pressure quality gate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/quality_gate_resource_pressure_v1.json",
        "contract" => "quality_gate_report.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
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
        "row_count" => 6,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "resource_availability_gate_count" => 1,
        "row_derived_resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_import_status_counts" => %{},
        "row_derived_cadence_import_status_counts" => %{},
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
        "resource_availability_gate_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure gate routing and no-authority boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
