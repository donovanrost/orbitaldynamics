defmodule OrbitalDynamics.OperationalReadiness.GateSummary do
  @moduledoc false

  def build(report, schema_contract) do
    gates = Map.get(report, "gates", []) |> Enum.filter(&is_map/1)
    non_passed_gates = Enum.reject(gates, &(&1["status"] == "passed"))
    gate_counts = counts(gates)

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_operational_readiness_gate_summary",
      "source" => "operational_readiness_report.v1",
      "source_artifact_type" => report["source_artifact_type"],
      "source_artifact_id" => report["source_artifact_id"],
      "readiness_level" => report["readiness_level"],
      "import_classification" => report["import_classification"],
      "status" => report["status"],
      "gate_count" => gate_counts.gate_count,
      "passed_gate_count" => gate_counts.passed_gate_count,
      "review_gate_count" => gate_counts.review_gate_count,
      "analysis_gate_count" => gate_counts.analysis_gate_count,
      "blocked_gate_count" => gate_counts.blocked_gate_count,
      "non_passed_gate_count" => length(non_passed_gates),
      "gate_status_counts" => field_counts(gates, "status"),
      "gate_classification_counts" => field_counts(gates, "classification"),
      "gate_ids_by_status" => id_map(gates, "status"),
      "gate_ids_by_classification" => id_map(gates, "classification"),
      "passed_gate_ids" => ids(gates, "passed"),
      "review_required_gate_ids" => ids(gates, "review_required"),
      "analysis_only_gate_ids" => ids(gates, "analysis_only"),
      "blocked_gate_ids" => ids(gates, "blocked"),
      "non_passed_gate_ids" => Enum.map(non_passed_gates, & &1["id"]),
      "non_passed_gates" => non_passed_gates,
      "gates" => gates,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "model_limits" => [
        "operational_readiness_gate_summary_routes_only",
        "operational_readiness_gate_summary_does_not_approve_or_import"
      ]
    }
  end

  def counts(gates) do
    %{
      gate_count: length(gates),
      passed_gate_count: count(gates, "passed"),
      review_gate_count: count(gates, "review_required"),
      analysis_gate_count: count(gates, "analysis_only"),
      blocked_gate_count: count(gates, "blocked")
    }
  end

  def count(gates, status), do: Enum.count(gates, &(&1["status"] == status))

  def field_counts(gates, field) do
    gates
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end

  defp id_map(gates, field) do
    gates
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} ->
      ids =
        ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {key, ids}
    end)
  end

  defp ids(gates, status) do
    gates
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(& &1["id"])
  end
end
