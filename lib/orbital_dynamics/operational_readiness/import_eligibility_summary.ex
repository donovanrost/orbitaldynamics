defmodule OrbitalDynamics.OperationalReadiness.ImportEligibilitySummary do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.GateSummary

  @schema_contract "operational_import_eligibility_summary.v1"

  def schema_contract, do: @schema_contract

  def build(report) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    gate_counts = GateSummary.counts(gates)

    non_passed_gates =
      gates
      |> Enum.reject(&(&1["status"] == "passed"))

    %{
      "schema_contract" => @schema_contract,
      "model" => "artifact_only_import_eligibility_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => report["import_classification"] == "importable",
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gates" => non_passed_gates,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_import_eligibility_summary_routes_only",
        "operational_import_eligibility_summary_does_not_approve_or_import"
      ]
    }
  end
end
