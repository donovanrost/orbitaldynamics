defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationCollectionEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    TimelineTransitionApplication.entries(path, artifact) ++
      nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun)
  end

  defp nested_entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    [
      {"#{path}.source_timeline_transition_application_summary",
       Map.get(artifact, "source_timeline_transition_application_summary")},
      {"#{path}.timeline_transition_application_summary",
       Map.get(artifact, "timeline_transition_application_summary")},
      {"#{path}.source_timeline_transition_application_report",
       Map.get(artifact, "source_timeline_transition_application_report")},
      {"#{path}.timeline_transition_application_report",
       Map.get(artifact, "timeline_transition_application_report")}
    ]
    |> Enum.flat_map(fn {entry_path, report_or_summary} ->
      TimelineTransitionApplication.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(report_or_summary, artifact)
      )
    end)
  end

  defp stringify_keys(value),
    do: TimelineTransitionApplicationCollectionEncoding.stringify_keys(value)
end
