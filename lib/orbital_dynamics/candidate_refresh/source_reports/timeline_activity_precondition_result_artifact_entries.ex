defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPrecondition

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionResultArtifactEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    TimelineActivityPrecondition.entries(path, artifact) ++
      nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun)
  end

  defp nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    [
      {"#{path}.source_timeline_activity_precondition_summary",
       Map.get(artifact, "source_timeline_activity_precondition_summary")},
      {"#{path}.timeline_activity_precondition_summary",
       Map.get(artifact, "timeline_activity_precondition_summary")}
    ]
    |> Enum.flat_map(fn {entry_path, summary} ->
      TimelineActivityPrecondition.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(summary, artifact)
      )
    end)
  end

  defp stringify_keys(value),
    do: TimelineActivityPreconditionResultArtifactEncoding.stringify_keys(value)
end
