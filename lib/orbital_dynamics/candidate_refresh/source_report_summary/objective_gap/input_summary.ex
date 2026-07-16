defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.InputSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.{
    InputSummary.ReportFields,
    ObjectiveSatisfaction,
    ObjectiveTradeoffFields,
    ScoreTermFields
  }

  def objective_satisfaction_report_input_summary(sources),
    do:
      ReportFields.fields(
        :objective_satisfaction,
        "objective_satisfaction_report.v1",
        sources,
        ObjectiveSatisfaction
      )

  def objective_tradeoff_report_input_summary(sources),
    do:
      ReportFields.fields(
        :objective_tradeoff,
        "objective_tradeoff_report.v1",
        sources,
        ObjectiveTradeoffFields
      )

  def score_term_report_input_summary(sources),
    do: ReportFields.fields(:score_term, "score_term_report.v1", sources, ScoreTermFields)
end
