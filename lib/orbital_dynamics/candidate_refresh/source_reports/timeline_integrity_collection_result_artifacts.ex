defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionResultArtifacts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrity
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = TimelineIntegrityCollectionEncoding.stringify_keys(artifact)

      path
      |> artifact_reports(artifact)
      |> Enum.flat_map(fn {entry_path, report} ->
        TimelineIntegrity.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp artifact_reports(path, artifact) do
    [
      {"#{path}", artifact},
      {"#{path}.source_timeline_integrity_report",
       Map.get(artifact, "source_timeline_integrity_report")},
      {"#{path}.timeline_integrity_report", Map.get(artifact, "timeline_integrity_report")}
    ]
  end
end
