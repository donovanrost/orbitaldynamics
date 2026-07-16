defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpact

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineReviewArtifactTraversal

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &TimelineDependencyImpact.operator_review_entries/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &TimelineDependencyImpact.cadence_import_entries/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
