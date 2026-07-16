defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateResultArtifacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateReports

  def result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      states_from_result_artifact(path, artifact, inherit_result_artifact_trust_boundary_fun)
    end)
  end

  defp states_from_result_artifact(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    EntryFallbacks.map_entry(path, artifact, fn entry_path, entry_artifact ->
      entry_artifact = TimelineActivityLifecycleStateReports.stringify_keys(entry_artifact)

      exact = TimelineActivityLifecycleStateReports.entries(entry_path, entry_artifact)

      nested =
        [
          {"#{entry_path}.source_timeline_activity_lifecycle_state",
           Map.get(entry_artifact, "source_timeline_activity_lifecycle_state")},
          {"#{entry_path}.timeline_activity_lifecycle_state",
           Map.get(entry_artifact, "timeline_activity_lifecycle_state")}
        ]
        |> Enum.flat_map(fn {nested_entry_path, state_or_states} ->
          TimelineActivityLifecycleStateReports.entries(
            nested_entry_path,
            inherit_result_artifact_trust_boundary_fun.(state_or_states, entry_artifact)
          )
        end)

      exact ++ nested
    end)
  end
end
