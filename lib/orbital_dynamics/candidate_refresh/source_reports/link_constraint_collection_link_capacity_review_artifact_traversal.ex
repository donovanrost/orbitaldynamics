defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityEmbeddedReviewArtifactReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        source_key,
        artifact_key
      ) do
    direct_reports =
      CollectionReviewArtifactDirectReports.reports(
        refresh,
        entries_with_builder(builder),
        source_key,
        artifact_key
      )

    direct_reports ++
      LinkConstraintCollectionLinkCapacityEmbeddedReviewArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        artifact_key
      )
  end

  defp entries_with_builder(builder) do
    fn path, artifact_or_artifacts ->
      LinkCapacity.entries(path, artifact_or_artifacts, builder)
    end
  end
end
