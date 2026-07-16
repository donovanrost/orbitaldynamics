defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.TrustBoundaries.ReportBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveTradeoffFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ScoreTermFields

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.TrustBoundaries.RowBoundaries

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  def objective_satisfaction(%{"rows" => rows} = report) when is_list(rows) do
    RowBoundaries.values(rows, report, &ObjectiveSatisfactionSourceObjectives.trust_boundary/1)
  end

  def objective_satisfaction(%{} = report), do: RowBoundaries.source_report_values(report)

  def objective_tradeoff(%{} = report) do
    report
    |> ObjectiveTradeoffFields.report_rows()
    |> RowBoundaries.values(report, &ObjectiveTradeoffFields.trust_boundary/1)
  end

  def score_term(%{"rows" => rows} = report) when is_list(rows) do
    report
    |> ScoreTermFields.rows()
    |> RowBoundaries.values(report, &ScoreTermFields.trust_boundary/1)
  end

  def score_term(%{} = report), do: RowBoundaries.source_report_values(report)
end
