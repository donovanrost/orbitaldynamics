defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionReviewArtifactTraversal
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilter
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjection

  def operator_review_resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ResourceProjection.entries/3,
      &ResourceProjection.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def operator_review_resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ResourceFilter.build_entries/3,
      &ResourceFilter.operator_review_package_report/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_resource_projection_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ResourceProjection.entries/3,
      &ResourceProjection.cadence_import_manifest_report/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end

  def cadence_import_resource_filter_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ResourceCollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &ResourceFilter.build_entries/3,
      &ResourceFilter.cadence_import_manifest_report/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
