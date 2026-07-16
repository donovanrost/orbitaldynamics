defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocation

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionReviewArtifactTraversal

  def operator_review_contact_allocation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ContactAllocation.build_entries/3,
      &ContactAllocation.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_contact_allocation_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ContactAllocation.build_entries/3,
      &ContactAllocation.cadence_import_manifest_report/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end

  defp review_artifact_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         entries,
         builder,
         source_key,
         artifact_key
       ) do
    ContactReviewCollectionReviewArtifactTraversal.review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      entries,
      builder,
      source_key,
      artifact_key,
      &ContactReviewCollectionContactAllocationArtifactReports.stringify_keys/1
    )
  end
end
