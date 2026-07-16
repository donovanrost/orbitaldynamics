defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactEntries

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelineDependencyImpactResultArtifactEntries.entries(
        path,
        artifact,
        inherit_result_artifact_trust_boundary_fun
      )
    end)
  end

  def stringify_keys(value),
    do: TimelineDependencyImpactResultArtifactEncoding.stringify_keys(value)
end
