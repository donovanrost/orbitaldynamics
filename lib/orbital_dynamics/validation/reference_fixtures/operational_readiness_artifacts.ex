defmodule OrbitalDynamics.Validation.ReferenceFixtures.OperationalReadinessArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.operator_review_package.v1" => %{
      "id" => "fixture.artifact.operator_review_package.v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in standalone operator review package artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_package_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 8,
        "row_derived_review_count" => 8,
        "approval_requirement_count" => 1,
        "policy_escalation_count" => 1,
        "realized_feedback_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_suppression_count" => 1,
        "contact_suppression_count" => 1,
        "link_capacity_review_count" => 1,
        "timeline_diff_count" => 1,
        "row_derived_review_type_counts" => %{
          "approval_requirement" => 1,
          "contact_suppression" => 1,
          "link_capacity_review" => 1,
          "policy_escalation" => 1,
          "realized_feedback" => 1,
          "resource_projection_review" => 1,
          "resource_suppression" => 1,
          "timeline_diff_review" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "approve_manual_contact" => 1,
          "review_contact_variance" => 1,
          "review_link_capacity_summary" => 1,
          "review_policy_escalation" => 1,
          "review_resource_projection" => 1,
          "review_suppressed_contact" => 1,
          "review_suppressed_observation" => 1,
          "review_timeline_change" => 1
        },
        "row_derived_review_queue_counts" => %{
          "approval_requirement|approve_manual_contact|operator_review_required" => 1,
          "contact_suppression|review_suppressed_contact|operator_review_required" => 1,
          "link_capacity_review|review_link_capacity_summary|operator_review_required" => 1,
          "policy_escalation|review_policy_escalation|operator_review_required" => 1,
          "realized_feedback|review_contact_variance|operator_review_required" => 1,
          "resource_projection_review|review_resource_projection|operator_review_required" => 1,
          "resource_suppression|review_suppressed_observation|operator_review_required" => 1,
          "timeline_diff_review|review_timeline_change|operator_review_required" => 1
        },
        "row_derived_review_row_ids_by_type" => %{
          "approval_requirement" => ["approval:operator_review_package:manual_contact:1"],
          "contact_suppression" => ["contact_suppression:leo_1_downlink_equator_prime_1:1"],
          "link_capacity_review" => ["link_capacity:equator_prime:1"],
          "policy_escalation" => ["policy_escalation:contact_execution_coordination:1"],
          "realized_feedback" => ["realized_feedback:downlink_equator:1"],
          "resource_projection_review" => ["resource_projection:leo_1:1"],
          "resource_suppression" => ["resource_suppression:leo_1_observe_target_a_1:1"],
          "timeline_diff_review" => ["timeline_diff:timeline:downlink_equator:1"]
        }
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-review import surface counts only"
      ]
    },
    "fixture.artifact.operational_execution_boundary_summary.v1" => %{
      "id" => "fixture.artifact.operational_execution_boundary_summary.v1",
      "model_id" => "artifact.operational_execution_boundary_summary.v1",
      "reference_case" =>
        "checked-in operational execution boundary summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_execution_boundary_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_execution_boundary_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
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
        "operational_mode_gate_id" => "operational_mode",
        "operational_mode_gate_status" => "passed",
        "operational_mode_gate_classification" => "importable",
        "gate_count" => 5,
        "passed_gate_count" => 5,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "assumption_execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_execution_boundary_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks execution/write/authority denial, gate counts, and handoff boundary only"
      ]
    },
    "fixture.artifact.operational_import_eligibility_summary.v1" => %{
      "id" => "fixture.artifact.operational_import_eligibility_summary.v1",
      "model_id" => "artifact.operational_import_eligibility_summary.v1",
      "reference_case" =>
        "checked-in operational import eligibility summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_import_eligibility_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_import_eligibility_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
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
        "row_derived_non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_import_eligibility_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import eligibility, gate counts, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" =>
        "curated operational readiness report from ready Cadence import evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_report_v1.json",
        "source_contract" => "cadence_import_manifest.v1",
        "contract" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
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
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
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
        "review_row_count" => 0,
        "import_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "freshness_status_counts" => %{},
        "row_derived_freshness_status_counts" => %{},
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "schema_validation_status_counts" => %{},
        "row_derived_schema_validation_status_counts" => %{},
        "import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "source_model_count" => 1,
        "source_model_limit_count" => 1,
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
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "review_row_count" => 0,
        "import_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "source_model_count" => 0,
        "source_model_limit_count" => 0,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks readiness classification and evidence counts only"
      ]
    },
    "fixture.artifact.operational_readiness_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_readiness_gate_summary.v1",
      "model_id" => "artifact.operational_readiness_gate_summary.v1",
      "reference_case" =>
        "checked-in operational readiness gate summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_gate_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_readiness_gate_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_gate_summary.v1",
        "model" => "artifact_only_operational_readiness_gate_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
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
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
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
        "passed_gate_keys" =>
          "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import",
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
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
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks gate routing maps, gate counts, and no-authority boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
