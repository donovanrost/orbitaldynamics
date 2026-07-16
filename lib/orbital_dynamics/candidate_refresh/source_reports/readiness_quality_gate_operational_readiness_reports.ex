defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessArtifactReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessDirectReports

  def operational_readiness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ReadinessQualityGateOperationalReadinessDirectReports.reports()
    |> Kernel.++(
      ReadinessQualityGateOperationalReadinessArtifactReports.operational_readiness_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> OperationalReadiness.report?(report) end)
    |> Enum.map(fn {path, report} ->
      {path, ReadinessQualityGateOperationalReadinessArtifactReports.stringify_keys(report)}
    end)
  end
end
