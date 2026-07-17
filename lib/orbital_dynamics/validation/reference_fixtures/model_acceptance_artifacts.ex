defmodule OrbitalDynamics.Validation.ReferenceFixtures.ModelAcceptanceArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.model_acceptance_report.operational_import" => %{
      "id" => "fixture.artifact.model_acceptance_report.operational_import",
      "model_id" => "artifact.model_acceptance_report.v1",
      "reference_case" =>
        "curated model acceptance report for operational import evidence boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "model_acceptance_report.v1",
        "intended_use" => "operational_import",
        "model_ids" => [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ]
      },
      "expected" => %{
        "schema_contract" => "model_acceptance_report.v1",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "model_count" => 4,
        "record_count" => 3,
        "row_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "status_counts" => %{
          "accepted" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "validation_level_counts" => %{
          "analysis" => 1,
          "artifact_contract" => 1,
          "educational" => 1,
          "unknown" => 1
        },
        "model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "blocked" => ["propagator.two_body", "missing.model"],
          "review_required" => ["event.access_windows"]
        },
        "model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"],
          "educational" => ["propagator.two_body"],
          "unknown" => ["missing.model"]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => [
            "orbit_data.simple_json",
            "event.access_windows",
            "propagator.two_body",
            "missing.model"
          ]
        }
      },
      "tolerances" => %{
        "model_count" => 0,
        "record_count" => 0,
        "row_count" => 0,
        "accepted_count" => 0,
        "review_required_count" => 0,
        "blocked_count" => 0,
        "unknown_model_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by model_acceptance_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external model certification",
        "checks intended-use acceptance counts and unknown-model blocking only"
      ]
    },
    "fixture.artifact.validation_safety_case_summary.v1" => %{
      "id" => "fixture.artifact.validation_safety_case_summary.v1",
      "model_id" => "artifact.validation_safety_case_summary.v1",
      "reference_case" =>
        "curated validation safety-case summary for artifact-only handoff boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "validation_safety_case_summary.v1",
        "artifact_path" => "study_results/validation_safety_case_summary_v1.json",
        "case_id" => "case:compatibility-example"
      },
      "expected" => %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "model" => "artifact_only_validation_safety_case_summary",
        "source" => "validation.safety_case_evidence",
        "summary_id" => "validation_safety_case:case:compatibility-example",
        "case_id" => "case:compatibility-example",
        "status" => "blocked",
        "evidence_count" => 4,
        "accepted_evidence_count" => 1,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 2,
        "model_accepted_count" => 1,
        "model_review_required_count" => 1,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 2,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 2,
        "evidence_status_counts" => %{
          "accepted_for_use" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "model_acceptance_evidence_status_counts" => %{
          "accepted" => 1,
          "review_required" => 1
        },
        "model_acceptance_evidence_model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "review_required" => ["event.access_windows"]
        },
        "model_acceptance_evidence_model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"]
        },
        "model_acceptance_evidence_model_ids_by_intended_use" => %{
          "operational_import" => ["orbit_data.simple_json", "event.access_windows"]
        },
        "evidence_refs_by_status" => %{
          "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
          "blocked" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ],
          "review_required" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ],
          "schema_validation_report.v1" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ]
        },
        "model_limit_count" => 3,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "certification_authority" => "not_granted_by_summary",
        "operator_authority" => "not_granted_by_summary"
      },
      "tolerances" => %{
        "evidence_count" => 0,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 0,
        "blocked_evidence_count" => 0,
        "model_accepted_count" => 0,
        "model_review_required_count" => 0,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by validation_safety_case_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external safety-case certification",
        "checks evidence counts, routing maps, and authority boundaries only",
        "does not approve imports, certify models, or write to Cadence"
      ]
    }
  }

  def all, do: @fixtures
end
