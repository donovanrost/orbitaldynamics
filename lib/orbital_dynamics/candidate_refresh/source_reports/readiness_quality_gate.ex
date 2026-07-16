defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGate

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessReports

  def operational_readiness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    ReadinessQualityGateOperationalReadinessReports.operational_readiness_reports(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def quality_gate_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_quality_gate_trust_boundary_fun
      ) do
    refresh
    |> ReadinessQualityGateDirectReports.reports()
    |> Kernel.++(
      ReadinessQualityGateArtifactReports.quality_gate_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_quality_gate_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> QualityGate.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ReadinessQualityGateArtifactReports.stringify_keys(report)}
    end)
  end
end
