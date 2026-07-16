defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionResultArtifacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionResultArtifactEntries

  def result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      TimelineActivityStateCollectionResultArtifactEntries.states(
        path,
        artifact,
        inherit_result_artifact_trust_boundary_fun
      )
    end)
  end
end
