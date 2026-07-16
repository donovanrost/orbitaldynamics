defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContention

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResultArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionReviewArtifactTraversal

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ContactContention.entries/3,
      &ContactContention.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ContactContention.entries/3,
      &ContactContention.cadence_import_manifest_report/2,
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
      &ContactReviewCollectionContactContentionResultArtifactReports.stringify_keys/1
    )
  end
end
