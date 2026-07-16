defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionReviewArtifactReports

  def resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionResultArtifactReports.resource_projection_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      ResourceCollectionReviewArtifactReports.operator_review_resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ResourceCollectionReviewArtifactReports.cadence_import_resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  def resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionResultArtifactReports.resource_filter_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      ResourceCollectionReviewArtifactReports.operator_review_resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      ResourceCollectionReviewArtifactReports.cadence_import_resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end
end
