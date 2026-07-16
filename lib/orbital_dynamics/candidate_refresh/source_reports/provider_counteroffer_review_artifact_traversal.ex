defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewArtifactDirectReports

  def review_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        source_key,
        artifact_key
      ) do
    ProviderCounterofferReviewArtifactDirectReports.reports(
      refresh,
      builder,
      source_key,
      artifact_key
    ) ++
      embedded_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        builder,
        artifact_key
      )
  end

  defp embedded_reports(
         refresh,
         source_result_artifacts_fun,
         inherit_result_artifact_trust_boundary_fun,
         builder,
         artifact_key
       ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
      ]
      |> Enum.flat_map(fn {entry_path, nested_artifact} ->
        ProviderCounteroffer.build_entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact),
          builder
        )
      end)
    end)
  end

  defp stringify_keys(value), do: ProviderCounterofferEncoding.stringify_keys(value)
end
