defmodule OrbitalDynamics.Schema.ValidationAcceptanceRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "validation_record.v1" => %{
        "schema_contract" => "validation_record.v1",
        "artifact_family" => "validation_record",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "id",
          "model",
          "implementation",
          "validation_level",
          "covered_regime",
          "evidence",
          "known_limits",
          "tolerances"
        ],
        "nested_contracts" => []
      },
      "model_acceptance_report.v1" => %{
        "schema_contract" => "model_acceptance_report.v1",
        "artifact_family" => "model_acceptance_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "report_id",
          "intended_use",
          "status",
          "model_count",
          "accepted_count",
          "review_required_count",
          "blocked_count",
          "unknown_model_count",
          "validation_level_counts",
          "records",
          "rows",
          "assumptions",
          "model_limits"
        ],
        "nested_contracts" => ["validation_record.v1"],
        "optional_fields" => [
          "status_counts",
          "model_ids_by_status",
          "model_ids_by_validation_level",
          "model_ids_by_intended_use"
        ]
      },
      "validation_safety_case_summary.v1" => %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "artifact_family" => "validation_safety_case_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "source",
          "summary_id",
          "status",
          "evidence_count",
          "blocked_evidence_count",
          "review_required_evidence_count",
          "accepted_evidence_count",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => [
          "case_id",
          "input_contracts",
          "evidence_status_counts",
          "evidence_refs_by_status",
          "evidence_refs_by_contract",
          "model_accepted_count",
          "model_review_required_count",
          "model_blocked_count",
          "unknown_model_count",
          "readiness_review_required_count",
          "readiness_blocked_count",
          "ready_for_import_count",
          "quality_gate_review_count",
          "quality_gate_blocked_count",
          "schema_error_count",
          "schema_warning_count",
          "schema_validation_report_count",
          "schema_validation_failed_report_count",
          "fixture_passed_count",
          "fixture_failed_count",
          "evidence"
        ],
        "nested_contracts" => [
          "model_acceptance_report.v1",
          "operational_readiness_report.v1",
          "quality_gate_report.v1",
          "schema_validation_report.v1",
          "schema_validation_batch_report.v1",
          "validation_reference_fixture_report.v1"
        ]
      }
    }
  end
end
