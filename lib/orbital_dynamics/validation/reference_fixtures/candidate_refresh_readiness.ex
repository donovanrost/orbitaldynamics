defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshReadiness do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.candidate_refresh.resource_projection_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_projection_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of resource-projection pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_resource_projection_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_resource_projection_report_count" => 1,
        "source_resource_projection_row_count" => 4,
        "source_resource_projection_projected_resource_count" => 2,
        "source_resource_projection_invalid_activity_input_count" => 1,
        "source_resource_projection_invalid_resource_summary_input_count" => 1,
        "source_resource_projection_resource_pressure_status_counts" => %{
          "downlink_shortfall" => 1,
          "storage_shortfall" => 1
        },
        "source_resource_projection_resource_pressure_type_counts" => %{
          "downlink_shortfall" => 1,
          "storage_pressure" => 1,
          "storage_shortfall" => 1
        },
        "source_resource_projection_resource_pressure_direction_counts" => %{
          "downlink" => 1,
          "tracking" => 1
        },
        "source_resource_projection_resource_pressure_activity_ids_by_status" => %{
          "downlink_shortfall" => ["dl_pressure_1"],
          "storage_shortfall" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_resource_pressure_activity_ids_by_type" => %{
          "downlink_shortfall" => ["dl_pressure_1"],
          "storage_pressure" => ["dl_pressure_1"],
          "storage_shortfall" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_resource_pressure_activity_ids_by_direction" => %{
          "downlink" => ["dl_pressure_1"],
          "tracking" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_resource_projection_report_count" => 0,
        "source_resource_projection_row_count" => 0,
        "source_resource_projection_projected_resource_count" => 0,
        "source_resource_projection_invalid_activity_input_count" => 0,
        "source_resource_projection_invalid_resource_summary_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not resource execution validation",
        "checks candidate-refresh replay of resource-projection pressure provenance without resource mutation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.quality_gate_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.quality_gate_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of quality-gate resource pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_quality_gate_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 6,
        "source_quality_gate_report_count" => 1,
        "source_quality_gate_row_count" => 6,
        "source_quality_gate_gate_count" => 6,
        "source_quality_gate_passed_gate_count" => 3,
        "source_quality_gate_review_gate_count" => 3,
        "source_quality_gate_analysis_gate_count" => 0,
        "source_quality_gate_blocked_gate_count" => 0,
        "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
        "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
        "source_quality_gate_status_counts" => %{"review_required" => 1},
        "source_quality_gate_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "source_quality_gate_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "source_quality_gate_ready_for_import_count" => 0,
        "source_quality_gate_trust_boundary_status" => "declared",
        "source_quality_gate_resource_availability_pressure_count" => 2,
        "source_quality_gate_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "source_quality_gate_resource_availability_reason_ids" =>
          "antenna_unavailable|payload_unavailable",
        "source_quality_gate_branch_local_review_pressure" => true,
        "source_quality_gate_branch_local_import_pressure" => false,
        "source_quality_gate_branch_local_resource_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_quality_gate_report_count" => 0,
        "source_quality_gate_row_count" => 0,
        "source_quality_gate_gate_count" => 0,
        "source_quality_gate_passed_gate_count" => 0,
        "source_quality_gate_review_gate_count" => 0,
        "source_quality_gate_analysis_gate_count" => 0,
        "source_quality_gate_blocked_gate_count" => 0,
        "source_quality_gate_ready_for_import_count" => 0,
        "source_quality_gate_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external readiness validation",
        "checks candidate-refresh replay of quality-gate resource-pressure provenance without granting operator authority, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.operational_readiness_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.operational_readiness_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of operational-readiness resource pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_operational_readiness_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_operational_readiness_report_count" => 1,
        "source_operational_readiness_row_count" => 1,
        "source_operational_readiness_gate_count" => 6,
        "source_operational_readiness_passed_gate_count" => 3,
        "source_operational_readiness_review_gate_count" => 3,
        "source_operational_readiness_analysis_gate_count" => 0,
        "source_operational_readiness_blocked_gate_count" => 0,
        "source_operational_readiness_readiness_level_counts" => %{"operator_review" => 1},
        "source_operational_readiness_import_classification_counts" => %{
          "review_only" => 1
        },
        "source_operational_readiness_status_counts" => %{"review_required" => 1},
        "source_operational_readiness_trust_boundary_status" => "declared",
        "source_operational_readiness_resource_availability_pressure_count" => 2,
        "source_operational_readiness_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "source_operational_readiness_resource_availability_reason_ids" =>
          "antenna_unavailable|payload_unavailable",
        "source_operational_readiness_branch_local_review_pressure" => true,
        "source_operational_readiness_branch_local_import_pressure" => true,
        "source_operational_readiness_branch_local_resource_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_operational_readiness_report_count" => 0,
        "source_operational_readiness_row_count" => 0,
        "source_operational_readiness_gate_count" => 0,
        "source_operational_readiness_passed_gate_count" => 0,
        "source_operational_readiness_review_gate_count" => 0,
        "source_operational_readiness_analysis_gate_count" => 0,
        "source_operational_readiness_blocked_gate_count" => 0,
        "source_operational_readiness_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external operations validation",
        "checks candidate-refresh replay of operational-readiness provenance without granting execution, operator authority, candidate selection, import approval, or Cadence writes"
      ]
    }
  }

  def all, do: @fixtures
end
