defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateResultArtifacts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateValues

  def result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineActivityLifecycleStateResultArtifacts.result_artifact_states(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def entries(path, state) do
    TimelineActivityLifecycleStateValues.entries(path, state)
  end

  def lifecycle_state_source?(state),
    do: TimelineActivityLifecycleStateValues.lifecycle_state_source?(state)

  def stringify_keys(value), do: TimelineActivityLifecycleStateValues.stringify_keys(value)
end
