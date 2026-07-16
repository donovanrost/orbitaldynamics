defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap do
  @moduledoc false

  alias __MODULE__.InputSummary

  def objective_satisfaction_report_input_summary([]), do: nil

  def objective_satisfaction_report_input_summary(sources),
    do: InputSummary.objective_satisfaction_report_input_summary(sources)

  def objective_tradeoff_report_input_summary([]), do: nil

  def objective_tradeoff_report_input_summary(sources),
    do: InputSummary.objective_tradeoff_report_input_summary(sources)

  def score_term_report_input_summary([]), do: nil

  def score_term_report_input_summary(sources),
    do: InputSummary.score_term_report_input_summary(sources)
end
