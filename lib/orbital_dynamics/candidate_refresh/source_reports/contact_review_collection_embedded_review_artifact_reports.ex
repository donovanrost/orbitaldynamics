defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionEmbeddedReviewArtifactReports do
  @moduledoc false

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        builder,
        artifact_key,
        stringify
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify.(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
      ]
      |> Enum.flat_map(fn {entry_path, nested_artifact} ->
        entries.(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact),
          builder
        )
      end)
    end)
  end
end
