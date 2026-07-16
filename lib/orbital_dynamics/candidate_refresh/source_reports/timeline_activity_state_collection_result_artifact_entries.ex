defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionEncoding

  def states(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    EntryFallbacks.map_entry(path, artifact, fn entry_path, entry_artifact ->
      entry_artifact = TimelineActivityStateCollectionEncoding.stringify_keys(entry_artifact)

      TimelineActivityStateCollectionArtifactReports.entries(entry_path, entry_artifact) ++
        nested_states(entry_path, entry_artifact, inherit_result_artifact_trust_boundary_fun)
    end)
  end

  defp nested_states(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    [
      {"#{path}.source_timeline_activity_state",
       Map.get(artifact, "source_timeline_activity_state")},
      {"#{path}.timeline_activity_state", Map.get(artifact, "timeline_activity_state")},
      {"#{path}.source_timeline_activity_status_state",
       Map.get(artifact, "source_timeline_activity_status_state")},
      {"#{path}.timeline_activity_status_state",
       Map.get(artifact, "timeline_activity_status_state")},
      {"#{path}.source_timeline_activity_approval_state",
       Map.get(artifact, "source_timeline_activity_approval_state")},
      {"#{path}.timeline_activity_approval_state",
       Map.get(artifact, "timeline_activity_approval_state")}
    ]
    |> Enum.flat_map(fn {entry_path, state_or_states} ->
      TimelineActivityStateCollectionArtifactReports.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(state_or_states, artifact)
      )
    end)
  end
end
