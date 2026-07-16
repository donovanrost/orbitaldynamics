defmodule OrbitalDynamics.Schema.OperationalReadinessRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "operational_readiness_report.v1" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "artifact_family" => "operational_readiness_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "report_id",
          "source_artifact_type",
          "source_artifact_id",
          "readiness_level",
          "import_classification",
          "status",
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "gates",
          "evidence",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => [],
        "nested_contracts" => [
          "operator_review_package.v1",
          "cadence_import_manifest.v1"
        ]
      },
      "operational_import_eligibility_summary.v1" => %{
        "schema_contract" => "operational_import_eligibility_summary.v1",
        "artifact_family" => "operational_import_eligibility_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_artifact_type",
          "source_artifact_id",
          "readiness_level",
          "import_classification",
          "status",
          "import_eligible",
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "non_passed_gates",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => ["operational_readiness_report.v1"]
      },
      "operational_readiness_gate_summary.v1" => %{
        "schema_contract" => "operational_readiness_gate_summary.v1",
        "artifact_family" => "operational_readiness_gate_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_artifact_type",
          "source_artifact_id",
          "readiness_level",
          "import_classification",
          "status",
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "gate_status_counts",
          "gate_classification_counts",
          "gate_ids_by_status",
          "gate_ids_by_classification",
          "passed_gate_ids",
          "review_required_gate_ids",
          "analysis_only_gate_ids",
          "blocked_gate_ids",
          "non_passed_gate_ids",
          "non_passed_gates",
          "gates",
          "assumptions"
        ],
        "optional_fields" => ["model_limits"],
        "nested_contracts" => ["operational_readiness_report.v1"]
      },
      "operational_execution_boundary_summary.v1" => %{
        "schema_contract" => "operational_execution_boundary_summary.v1",
        "artifact_family" => "operational_execution_boundary_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "source_artifact_type",
          "source_artifact_id",
          "readiness_level",
          "import_classification",
          "status",
          "import_eligible",
          "handoff_only",
          "execution_allowed",
          "cadence_write_allowed",
          "operator_authority_granted",
          "execution_boundary",
          "operational_mode_gate",
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "non_passed_gate_ids",
          "assumptions"
        ],
        "optional_fields" => [
          "analysis_mode",
          "analysis_mode_source",
          "model_limits"
        ],
        "nested_contracts" => ["operational_readiness_report.v1"]
      }
    }
  end
end
