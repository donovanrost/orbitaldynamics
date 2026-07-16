defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterArtifactEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterReviewReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterResultArtifactReports

  def result_artifact_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactFilterResultArtifactReports.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def operator_review_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactFilterReviewReports.operator_review_contact_filter_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def cadence_import_contact_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ContactReviewCollectionContactFilterReviewReports.cadence_import_contact_filter_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def stringify_keys(value),
    do: ContactReviewCollectionContactFilterArtifactEncoding.stringify_keys(value)
end
