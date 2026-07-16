defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionResultArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReportValues

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun,
        report_module,
        report_keys
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ObjectiveCollectionReportValues.stringify_keys(artifact)

      path
      |> result_artifact_reports(artifact, report_keys)
      |> Enum.flat_map(fn {entry_path, report} ->
        report_module.entries(
          entry_path,
          inherit_result_artifact_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defp result_artifact_reports(path, artifact, report_keys) do
    [{path, artifact}] ++
      Enum.map(report_keys, fn report_key ->
        {"#{path}.#{report_key}", Map.get(artifact, report_key)}
      end)
  end
end
