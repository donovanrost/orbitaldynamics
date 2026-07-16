defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterResultArtifactEntries

  def reports(refresh, source_result_artifacts_fun, inherit_result_artifact_trust_boundary_fun) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      ContactReviewCollectionContactFilterResultArtifactEntries.entries(
        path,
        artifact,
        inherit_result_artifact_trust_boundary_fun
      )
    end)
  end
end
