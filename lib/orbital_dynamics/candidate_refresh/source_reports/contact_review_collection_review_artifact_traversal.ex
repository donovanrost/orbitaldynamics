defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionEmbeddedReviewArtifactReports

  def review_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        builder,
        source_key,
        artifact_key,
        stringify
      ) do
    direct_reports =
      CollectionReviewArtifactDirectReports.reports(
        refresh,
        entries_with_builder(entries, builder),
        source_key,
        artifact_key
      )

    direct_reports ++
      ContactReviewCollectionEmbeddedReviewArtifactReports.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        builder,
        artifact_key,
        stringify
      )
  end

  defp entries_with_builder(entries, builder) do
    fn path, artifact_or_artifacts ->
      entries.(path, artifact_or_artifacts, builder)
    end
  end
end
