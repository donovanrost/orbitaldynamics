defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessEmbeddedReviewReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessArtifactReports

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
      artifact = stringify_keys(artifact)

      [
        {"#{path}", artifact},
        {"#{path}.#{artifact_key}", Map.get(artifact, artifact_key)}
      ]
      |> Enum.flat_map(fn {entry_path, nested_artifact} ->
        OperationalReadiness.build_entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(nested_artifact, artifact),
          builder
        )
      end)
    end)
  end

  defp stringify_keys(value) do
    ReadinessQualityGateOperationalReadinessArtifactReports.stringify_keys(value)
  end
end
