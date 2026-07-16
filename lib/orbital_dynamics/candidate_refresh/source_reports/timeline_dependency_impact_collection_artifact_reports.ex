defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewArtifactReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineDependencyImpactResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineDependencyImpactReviewArtifactReports.operator_review_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineDependencyImpactReviewArtifactReports.cadence_import_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def stringify_keys(value),
    do: TimelineDependencyImpactResultArtifactReports.stringify_keys(value)
end
