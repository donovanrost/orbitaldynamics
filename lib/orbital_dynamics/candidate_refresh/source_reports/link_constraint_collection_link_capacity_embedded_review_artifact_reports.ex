defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityEmbeddedReviewArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkConstraintCollectionLinkCapacityReviewArtifactTraversalEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        artifact_key
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact =
        LinkConstraintCollectionLinkCapacityReviewArtifactTraversalEncoding.stringify_keys(
          artifact
        )

      [
        {"#{path}", artifact},
        {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
      ]
      |> Enum.flat_map(fn {entry_path, nested_artifact} ->
        LinkCapacity.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact),
          builder
        )
      end)
    end)
  end
end
