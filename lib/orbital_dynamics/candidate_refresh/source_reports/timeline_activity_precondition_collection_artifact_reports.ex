defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewArtifactReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineActivityPreconditionResultArtifactReports.reports(
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
    TimelineActivityPreconditionReviewArtifactReports.operator_review_reports(
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
    TimelineActivityPreconditionReviewArtifactReports.cadence_import_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def stringify_keys(value),
    do: TimelineActivityPreconditionResultArtifactReports.stringify_keys(value)
end
