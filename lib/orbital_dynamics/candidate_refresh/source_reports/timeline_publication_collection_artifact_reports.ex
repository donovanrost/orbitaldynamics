defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationReviewArtifactReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelinePublicationResultArtifactReports.reports(
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
    TimelinePublicationReviewArtifactReports.operator_review_reports(
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
    TimelinePublicationReviewArtifactReports.cadence_import_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def stringify_keys(value), do: TimelinePublicationResultArtifactReports.stringify_keys(value)
end
