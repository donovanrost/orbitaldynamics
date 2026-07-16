defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactTraversal

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        source_key,
        artifact_key
      ) do
    CollectionReviewArtifactTraversal.reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun,
      entries,
      source_key,
      artifact_key
    )
  end
end
