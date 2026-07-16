defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleState
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateResultArtifacts

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineLifecycleStateResultArtifacts.result_artifact_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def entries(path, value), do: TimelineLifecycleState.entries(path, value)
end
