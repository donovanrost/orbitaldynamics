defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineReviewArtifactTraversal

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        source_key,
        artifact_key
      ) do
    TimelineReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      entries,
      source_key,
      artifact_key
    )
  end
end
