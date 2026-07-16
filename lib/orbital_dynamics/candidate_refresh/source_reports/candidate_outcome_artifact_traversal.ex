defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeValueEncoding

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        fields,
        source_module
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = CandidateOutcomeValueEncoding.stringify_keys(artifact)

      path
      |> artifact_reports(artifact, fields)
      |> Enum.flat_map(fn {entry_path, report} ->
        source_module.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp artifact_reports(path, artifact, fields) do
    [{"#{path}", artifact}] ++
      Enum.map(fields, fn field -> {"#{path}.#{field}", Map.get(artifact, field)} end)
  end
end
