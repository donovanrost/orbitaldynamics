defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionReviewArtifactDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        builder,
        source_key,
        artifact_key
      ) do
    ResourceCollectionReviewArtifactDirectReports.reports(
      refresh,
      entries,
      builder,
      source_key,
      artifact_key
    ) ++
      embedded_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        builder,
        artifact_key
      )
  end

  defp embedded_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         entries,
         builder,
         artifact_key
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ResourceCollectionEncoding.stringify_keys(artifact)

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
