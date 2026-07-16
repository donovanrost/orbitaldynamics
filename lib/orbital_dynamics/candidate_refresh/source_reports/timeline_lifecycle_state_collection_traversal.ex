defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleState
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateReports

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineLifecycleStateCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineLifecycleStateReports.result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, summary} -> TimelineLifecycleState.summary?(summary) end)
    |> Enum.map(fn {path, summary} ->
      {path, TimelineLifecycleStateCollectionEncoding.stringify_keys(summary)}
    end)
  end
end
