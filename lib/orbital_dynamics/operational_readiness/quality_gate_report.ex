defmodule OrbitalDynamics.OperationalReadiness.QualityGateReport do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.ExecutionBoundarySummary
  alias OrbitalDynamics.OperationalReadiness.GateSummary
  alias OrbitalDynamics.OperationalReadiness.QualityGateRow
  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  @schema_contract "quality_gate_report.v1"
  @schema_version 1

  def build(readiness_report) do
    gates = Map.get(readiness_report, "gates", []) |> Enum.filter(&is_map/1)

    rows =
      gates
      |> Enum.with_index(1)
      |> Enum.map(fn {gate, rank} -> QualityGateRow.build(gate, readiness_report, rank) end)

    import_classification = import_classification(rows)

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_quality_gate_report",
      "report_id" =>
        SourceIdentity.quality_gate_report_id(
          readiness_report["source_artifact_type"],
          readiness_report["source_artifact_id"]
        ),
      "source_artifact_type" => readiness_report["source_artifact_type"],
      "source_artifact_id" => readiness_report["source_artifact_id"],
      "source_readiness_report_id" => readiness_report["report_id"],
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "handoff_only" => true,
      "execution_allowed" => false,
      "cadence_write_allowed" => false,
      "operator_authority_granted" => false,
      "execution_boundary" => ExecutionBoundarySummary.boundary(import_classification),
      "gate_count" => length(rows),
      "passed_gate_count" => GateSummary.count(rows, "passed"),
      "review_gate_count" => GateSummary.count(rows, "review_required"),
      "analysis_gate_count" => GateSummary.count(rows, "analysis_only"),
      "blocked_gate_count" => GateSummary.count(rows, "blocked"),
      "gate_status_counts" => GateSummary.field_counts(rows, "status"),
      "gate_classification_counts" => GateSummary.field_counts(rows, "classification"),
      "gate_ids_by_status" => quality_gate_ids_by(rows, "status"),
      "gate_ids_by_classification" => quality_gate_ids_by(rows, "classification"),
      "quality_gate_row_ids_by_status" => quality_gate_row_ids_by(rows, "status"),
      "quality_gate_row_ids_by_classification" => quality_gate_row_ids_by(rows, "classification"),
      "passed_gate_ids" => quality_gate_ids(rows, "passed"),
      "review_required_gate_ids" => quality_gate_ids(rows, "review_required"),
      "analysis_only_gate_ids" => quality_gate_ids(rows, "analysis_only"),
      "blocked_gate_ids" => quality_gate_ids(rows, "blocked"),
      "rows" => rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "operational_readiness_report.v1",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "model_limits" => [
        "quality_gate_report_derives_classification_from_gate_rows",
        "quality_gate_report_does_not_approve_or_import"
      ]
    }
  end

  defp import_classification(gates) do
    statuses = Enum.map(gates, & &1["status"])

    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      true -> "importable"
    end
  end

  defp readiness_level("importable"), do: "import_eligible"
  defp readiness_level("review_only"), do: "operator_review"
  defp readiness_level("analysis_only"), do: "analysis_only"
  defp readiness_level("blocked"), do: "blocked"

  defp report_status("importable"), do: "passed"
  defp report_status("review_only"), do: "review_required"
  defp report_status("analysis_only"), do: "analysis_only"
  defp report_status("blocked"), do: "blocked"

  defp quality_gate_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["gate_id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp quality_gate_ids(rows, status) do
    rows
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(& &1["gate_id"])
    |> stable_sorted_ids()
  end

  defp quality_gate_row_ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["id"])
    |> Enum.reject(fn {key, ids} -> key in [nil, ""] or Enum.all?(ids, &is_nil/1) end)
    |> Map.new(fn {key, ids} -> {key, stable_sorted_ids(ids)} end)
  end

  defp stable_sorted_ids(ids) do
    ids
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
