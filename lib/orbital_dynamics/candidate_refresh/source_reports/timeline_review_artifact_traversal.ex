defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineReviewArtifactDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineReviewArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        source_key,
        artifact_key
      ) do
    TimelineReviewArtifactDirectReports.reports(refresh, entries, source_key, artifact_key) ++
      embedded_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        entries,
        artifact_key
      )
  end

  defp embedded_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         entries,
         artifact_key
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = TimelineReviewArtifactEncoding.stringify_keys(artifact)

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
  end
end
