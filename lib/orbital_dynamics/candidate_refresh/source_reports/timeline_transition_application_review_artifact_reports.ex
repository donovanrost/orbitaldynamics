defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewArtifactTraversal

  def operator_review_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineTransitionApplicationReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &TimelineTransitionApplication.operator_review_entries/2,
      "source_operator_review_package",
      "operator_review_package"
    )
  end

  def cadence_import_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineTransitionApplicationReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      &TimelineTransitionApplication.cadence_import_entries/2,
      "source_cadence_import_manifest",
      "cadence_import_manifest"
    )
  end
end
