defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionDirectReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineActivityStateCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineActivityStateCollectionArtifactReports.result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, state} ->
      TimelineActivityStateCollectionArtifactReports.activity_state_source?(state)
    end)
    |> Enum.map(fn {path, state} ->
      {path, TimelineActivityStateCollectionArtifactReports.stringify_keys(state)}
    end)
  end
end
