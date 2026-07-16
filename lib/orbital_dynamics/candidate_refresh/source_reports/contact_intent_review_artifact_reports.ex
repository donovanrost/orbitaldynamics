defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntent

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    review_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ContactIntent.operator_review_package_intents/2,
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
      &ContactIntent.cadence_import_manifest_intents/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end

  defp review_artifact_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         builder,
         source_key,
         artifact_key
       ) do
    CollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      fn path, artifact_or_artifacts ->
        ContactIntent.build_entries(path, artifact_or_artifacts, builder)
      end,
      source_key,
      artifact_key
    )
  end
end
