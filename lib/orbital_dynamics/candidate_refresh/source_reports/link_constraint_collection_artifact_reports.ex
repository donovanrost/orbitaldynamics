defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionConstraintResultArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionConstraintReviewArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityArtifactReports

  def constraint_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    LinkConstraintCollectionConstraintResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    ) ++
      LinkConstraintCollectionConstraintReviewArtifactReports.operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) ++
      LinkConstraintCollectionConstraintReviewArtifactReports.cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
  end

  def link_capacity_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    LinkConstraintCollectionLinkCapacityArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end
end
