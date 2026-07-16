defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationArtifactTraversal do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationValueEncoding

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
      artifact = ModelValidationValueEncoding.stringify_keys(artifact)

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
