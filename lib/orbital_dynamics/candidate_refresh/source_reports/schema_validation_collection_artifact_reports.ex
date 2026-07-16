defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationResultArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewArtifactReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    SchemaValidationResultArtifactReports.reports(
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
    SchemaValidationReviewArtifactReports.operator_review_reports(
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
    SchemaValidationReviewArtifactReports.cadence_import_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def stringify_keys(value), do: SchemaValidationResultArtifactReports.stringify_keys(value)
end
