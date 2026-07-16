defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessReviewTraversal

  def operator_review_operational_readiness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ReadinessQualityGateOperationalReadinessReviewTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &OperationalReadiness.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_operational_readiness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ReadinessQualityGateOperationalReadinessReviewTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &OperationalReadiness.cadence_import_manifest_report/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
