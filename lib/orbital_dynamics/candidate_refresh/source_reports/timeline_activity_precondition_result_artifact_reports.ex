defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactEntries

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelineActivityPreconditionResultArtifactEntries.entries(
        path,
        artifact,
        inherit_result_artifact_trust_boundary_fun
      )
    end)
  end

  def stringify_keys(value),
    do: TimelineActivityPreconditionResultArtifactEncoding.stringify_keys(value)
end
