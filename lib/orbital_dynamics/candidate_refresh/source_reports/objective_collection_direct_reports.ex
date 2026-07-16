defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveCollectionDirectSources
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfaction
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoff

  def objective_satisfaction_reports(refresh) do
    refresh
    |> ObjectiveCollectionDirectSources.sources("objective_satisfaction_report")
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ObjectiveSatisfaction.entries(path, report_or_reports)
    end)
  end

  def objective_tradeoff_reports(refresh) do
    refresh
    |> ObjectiveCollectionDirectSources.sources("objective_tradeoff_report")
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ObjectiveTradeoff.entries(path, report_or_reports)
    end)
  end
end
