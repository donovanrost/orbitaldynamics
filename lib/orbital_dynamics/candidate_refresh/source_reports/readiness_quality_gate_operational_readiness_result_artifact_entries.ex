defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessResultArtifactEntries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadiness

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ReadinessQualityGateOperationalReadinessEncoding

  def entries(path, artifact, inherit_result_artifact_trust_boundary_fun) do
    artifact = stringify_keys(artifact)

    path
    |> entry_reports(artifact)
    |> Enum.flat_map(fn {entry_path, report} ->
      OperationalReadiness.entries(
        entry_path,
        inherit_result_artifact_trust_boundary_fun.(report, artifact)
      )
    end)
  end

  defp entry_reports(path, artifact) do
    [
      {"#{path}", artifact},
      {"#{path}.source_operational_readiness_report",
       Map.get(artifact, "source_operational_readiness_report")},
      {"#{path}.operational_readiness_report", Map.get(artifact, "operational_readiness_report")},
      {"#{path}.source_operational_import_eligibility_summary",
       Map.get(artifact, "source_operational_import_eligibility_summary")},
      {"#{path}.operational_import_eligibility_summary",
       Map.get(artifact, "operational_import_eligibility_summary")},
      {"#{path}.source_operational_readiness_gate_summary",
       Map.get(artifact, "source_operational_readiness_gate_summary")},
      {"#{path}.operational_readiness_gate_summary",
       Map.get(artifact, "operational_readiness_gate_summary")},
      {"#{path}.source_operational_execution_boundary_summary",
       Map.get(artifact, "source_operational_execution_boundary_summary")},
      {"#{path}.operational_execution_boundary_summary",
       Map.get(artifact, "operational_execution_boundary_summary")}
    ]
  end

  defp stringify_keys(value),
    do: ReadinessQualityGateOperationalReadinessEncoding.stringify_keys(value)
end
