defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateCollectionDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineActivityLifecycleStateCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineActivityLifecycleStateReports.result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, state} ->
      TimelineActivityLifecycleStateReports.lifecycle_state_source?(state)
    end)
    |> Enum.map(fn {path, state} ->
      {path, TimelineActivityLifecycleStateReports.stringify_keys(state)}
    end)
  end
end
