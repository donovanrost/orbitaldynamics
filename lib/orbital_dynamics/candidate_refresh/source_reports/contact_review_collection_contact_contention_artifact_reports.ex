defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResultArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionReviewArtifactReports

  def contact_contention_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactContentionResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      ContactReviewCollectionContactContentionReviewArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ContactReviewCollectionContactContentionReviewArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  def stringify_keys(value) do
    ContactReviewCollectionContactContentionResultArtifactReports.stringify_keys(value)
  end
end
