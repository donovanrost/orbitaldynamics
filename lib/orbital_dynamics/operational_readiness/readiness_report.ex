defmodule OrbitalDynamics.OperationalReadiness.ReadinessReport do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness.AdapterBoundaryGate
  alias OrbitalDynamics.OperationalReadiness.CadenceImportGate
  alias OrbitalDynamics.OperationalReadiness.GateSummary
  alias OrbitalDynamics.OperationalReadiness.MissionPolicyGate
  alias OrbitalDynamics.OperationalReadiness.OperatorReviewGate
  alias OrbitalDynamics.OperationalReadiness.OperatorTrainingGate
  alias OrbitalDynamics.OperationalReadiness.OperationalModeGate
  alias OrbitalDynamics.OperationalReadiness.ResourceAvailabilityGate
  alias OrbitalDynamics.OperationalReadiness.SourceContractGate
  alias OrbitalDynamics.OperationalReadiness.SourceIdentity

  @schema_contract "operational_readiness_report.v1"
  @schema_version 1

  def build(
        artifact,
        review_package,
        import_manifest,
        opts,
        evidence,
        model_limits
      ) do
    source_artifact_type = SourceIdentity.artifact_type(artifact, review_package, import_manifest)
    source_artifact_id = SourceIdentity.artifact_id(artifact, review_package, import_manifest)

    gates =
      [
        SourceContractGate.build(source_artifact_type),
        OperationalModeGate.build(artifact, opts),
        AdapterBoundaryGate.build(evidence),
        MissionPolicyGate.build(evidence),
        OperatorTrainingGate.build(evidence),
        ResourceAvailabilityGate.build(evidence),
        OperatorReviewGate.build(evidence),
        CadenceImportGate.build(evidence)
      ]
      |> Enum.reject(&is_nil/1)

    import_classification = import_classification(gates)

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => @schema_version,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => SourceIdentity.readiness_report_id(source_artifact_type, source_artifact_id),
      "source_artifact_type" => source_artifact_type,
      "source_artifact_id" => source_artifact_id,
      "readiness_level" => readiness_level(import_classification),
      "import_classification" => import_classification,
      "status" => report_status(import_classification),
      "gate_count" => length(gates),
      "passed_gate_count" => GateSummary.count(gates, "passed"),
      "review_gate_count" => GateSummary.count(gates, "review_required"),
      "analysis_gate_count" => GateSummary.count(gates, "analysis_only"),
      "blocked_gate_count" => GateSummary.count(gates, "blocked"),
      "gates" => gates,
      "evidence" => evidence,
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => model_limits
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
end
