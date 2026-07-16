defmodule OrbitalDynamics.Schema.QualityGateRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "quality_gate_report.v1" => %{
        "schema_contract" => "quality_gate_report.v1",
        "artifact_family" => "quality_gate_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "report_id",
          "source_artifact_type",
          "source_artifact_id",
          "source_readiness_report_id",
          "readiness_level",
          "import_classification",
          "status",
          "handoff_only",
          "execution_allowed",
          "cadence_write_allowed",
          "operator_authority_granted",
          "execution_boundary",
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "gate_status_counts",
          "gate_classification_counts",
          "rows",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => [
          "gate_ids_by_status",
          "gate_ids_by_classification",
          "quality_gate_row_ids_by_status",
          "quality_gate_row_ids_by_classification",
          "passed_gate_ids",
          "review_required_gate_ids",
          "analysis_only_gate_ids",
          "blocked_gate_ids"
        ],
        "nested_contracts" => ["operational_readiness_report.v1"]
      }
    }
  end
end
