defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpact

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactResultArtifactEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    TimelineDependencyImpact.entries(path, artifact) ++
      nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun)
  end

  defp nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    [
      {"#{path}.source_timeline_dependency_impact_summary",
       Map.get(artifact, "source_timeline_dependency_impact_summary")},
      {"#{path}.timeline_dependency_impact_summary",
       Map.get(artifact, "timeline_dependency_impact_summary")}
    ]
    |> Enum.flat_map(fn {entry_path, summary} ->
      TimelineDependencyImpact.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(summary, artifact)
      )
    end)
  end

  defp stringify_keys(value),
    do: TimelineDependencyImpactResultArtifactEncoding.stringify_keys(value)
end
