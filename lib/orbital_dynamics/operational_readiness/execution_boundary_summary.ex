defmodule OrbitalDynamics.OperationalReadiness.ExecutionBoundarySummary do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.GateSummary

  def build(report, schema_contract) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    operational_mode_gate = Enum.find(gates, &(&1["id"] == "operational_mode"))
    non_passed_gates = Enum.reject(gates, &(&1["status"] == "passed"))
    import_eligible? = report["import_classification"] == "importable"
    gate_counts = GateSummary.counts(gates)

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_operational_execution_boundary_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "import_eligible" => import_eligible?,
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => boundary(report["import_classification"]),
      "analysis_mode" => Map.get(operational_mode_gate || %{}, "analysis_mode"),
      "analysis_mode_source" => Map.get(operational_mode_gate || %{}, "analysis_mode_source"),
      "operational_mode_gate" => operational_mode_gate,
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "non_passed_gate_ids" => Enum.map(non_passed_gates, & &1["id"]),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "operational_execution_boundary_summary_routes_only",
        "operational_execution_boundary_summary_does_not_execute_or_import"
      ]
    }
    |> compact_map()
  end

  def boundary("importable"), do: "adapter_handoff_only"
  def boundary("review_only"), do: "operator_review_required_before_import"
  def boundary("analysis_only"), do: "analysis_only_not_for_execution"
  def boundary("blocked"), do: "blocked_not_for_import_or_execution"

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
