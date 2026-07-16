defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublication
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationResultArtifactEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    TimelinePublication.entries(path, artifact) ++
      nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun)
  end

  defp nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    [
      {"#{path}.source_timeline_publication_summary",
       Map.get(artifact, "source_timeline_publication_summary")},
      {"#{path}.timeline_publication_summary", Map.get(artifact, "timeline_publication_summary")}
    ]
    |> Enum.flat_map(fn {entry_path, summary} ->
      TimelinePublication.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(summary, artifact)
      )
    end)
  end

  defp stringify_keys(value), do: TimelinePublicationResultArtifactEncoding.stringify_keys(value)
end
