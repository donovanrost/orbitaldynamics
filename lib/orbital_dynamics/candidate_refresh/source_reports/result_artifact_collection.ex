defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResultArtifactCollectionEncoding

  def reports(refresh) do
    [
      {"accepted_planning_state.source_result_artifact",
       get_in(refresh, ["accepted_planning_state", "source_result_artifact"])},
      {"accepted_planning_state.result_artifact",
       get_in(refresh, ["accepted_planning_state", "result_artifact"])},
      {"mission_state.source_result_artifact",
       get_in(refresh, ["mission_state", "source_result_artifact"])},
      {"mission_state.result_artifact", get_in(refresh, ["mission_state", "result_artifact"])},
      {"source_result_artifact", Map.get(refresh, "source_result_artifact")},
      {"result_artifact", Map.get(refresh, "result_artifact")}
    ]
    |> Enum.flat_map(fn {path, artifact_or_artifacts} ->
      entries(path, artifact_or_artifacts)
    end)
  end

  defp entries(path, artifact) do
    EntryFallbacks.entries(path, artifact, fn entry_path, entry_artifact ->
      {entry_path, ResultArtifactCollectionEncoding.stringify_keys(entry_artifact)}
    end)
  end
end
