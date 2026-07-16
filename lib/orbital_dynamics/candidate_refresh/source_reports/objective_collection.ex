defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfaction
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionArtifactReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionDirectReports
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionReportValues

  def objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ObjectiveCollectionDirectReports.objective_satisfaction_reports()
    |> Kernel.++(
      ObjectiveCollectionArtifactReports.objective_satisfaction_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ObjectiveSatisfaction.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  def objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    refresh
    |> ObjectiveCollectionDirectReports.objective_tradeoff_reports()
    |> Kernel.++(
      ObjectiveCollectionArtifactReports.objective_tradeoff_reports(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      )
    )
    |> Enum.filter(fn {_path, report} -> ObjectiveTradeoff.report?(report) end)
    |> Enum.map(fn {path, report} -> {path, stringify_keys(report)} end)
  end

  defp stringify_keys(value), do: ObjectiveCollectionReportValues.stringify_keys(value)
end
