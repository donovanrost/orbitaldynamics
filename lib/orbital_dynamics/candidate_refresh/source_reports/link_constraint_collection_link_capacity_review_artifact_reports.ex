defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityReviewArtifactTraversal

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    LinkConstraintCollectionLinkCapacityReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &LinkCapacity.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    LinkConstraintCollectionLinkCapacityReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &LinkCapacity.cadence_import_manifest_report/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
