defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateResultArtifacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateReports

  def result_artifact_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      summaries_from_result_artifact(path, artifact, inherit_result_artifact_trust_boundary_fun)
    end)
  end

  defp summaries_from_result_artifact(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    EntryFallbacks.map_entry(path, artifact, fn entry_path, entry_artifact ->
      entry_artifact = TimelineLifecycleStateCollectionEncoding.stringify_keys(entry_artifact)

      exact = TimelineLifecycleStateReports.entries(entry_path, entry_artifact)

      nested =
        [
          {"#{entry_path}.source_timeline_lifecycle_state_summary",
           Map.get(entry_artifact, "source_timeline_lifecycle_state_summary")},
          {"#{entry_path}.timeline_lifecycle_state_summary",
           Map.get(entry_artifact, "timeline_lifecycle_state_summary")}
        ]
        |> Enum.flat_map(fn {nested_entry_path, summary} ->
          TimelineLifecycleStateReports.entries(
            nested_entry_path,
            inherit_result_artifact_trust_boundary_fun.(summary, entry_artifact)
          )
        end)

      exact ++ nested
    end)
  end
end
