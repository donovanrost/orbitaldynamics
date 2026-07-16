defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.NormalizedRows

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.StatusCounts

  def status_counts(report) do
    report
    |> rows()
    |> StatusCounts.counts()
  end

  def type_counts(report) do
    report
    |> rows()
    |> Counts.normalized_rows("objective")
  end

  def rows(report), do: NormalizedRows.values(report)
end
