defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrity

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionResultArtifacts

  def reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> TimelineIntegrityCollectionDirectReports.reports()
    |> Kernel.++(
      TimelineIntegrityCollectionResultArtifacts.reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> TimelineIntegrity.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value), do: TimelineIntegrityCollectionEncoding.stringify_keys(value)
end
