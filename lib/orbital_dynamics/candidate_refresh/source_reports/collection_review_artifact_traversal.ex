defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CollectionReviewArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        source_key,
        artifact_key
      ) do
    embedded =
      refresh
      |> source_result_artifacts_fun.()
      |> Enum.flat_map(fn {path, artifact} ->
        artifact = stringify_keys(artifact)

        [
          {"#{path}", artifact},
          {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
        ]
        |> Enum.flat_map(fn {entry_path, nested_artifact} ->
          entries.(
            entry_path,
            inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact)
          )
        end)
      end)

    CollectionReviewArtifactDirectReports.reports(refresh, entries, source_key, artifact_key) ++
      embedded
  end

  defp stringify_keys(value), do: CollectionReviewArtifactEncoding.stringify_keys(value)
end
