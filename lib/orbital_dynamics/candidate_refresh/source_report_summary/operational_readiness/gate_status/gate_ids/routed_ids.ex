defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.RoutedIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.NonPassedRows

  def by_status(report) do
    report
    |> NonPassedRows.ids_by_status()
    |> Fallbacks.ids_by_status(report)
  end

  def by_classification(report) do
    report
    |> NonPassedRows.ids_by_classification()
    |> Fallbacks.ids_by_classification(report)
  end
end
