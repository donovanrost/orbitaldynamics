defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGate
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateArtifactReportsEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateReportSources

  def quality_gate_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_quality_gate_trust_boundary_fun
      ) do
    refresh
    |> source_result_artifacts_fun.()
    |> Enum.flat_map(fn {path, artifact} ->
      artifact = ReadinessQualityGateArtifactReportsEncoding.stringify_keys(artifact)

      path
      |> ReadinessQualityGateReportSources.artifact_entries(artifact)
      |> Enum.flat_map(fn {entry_path, report} ->
        QualityGate.entries(
          entry_path,
          inherit_result_artifact_quality_gate_trust_boundary_fun.(report, artifact)
        )
      end)
    end)
  end

  defdelegate stringify_keys(value), to: ReadinessQualityGateArtifactReportsEncoding
end
