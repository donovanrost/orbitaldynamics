defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget do
  @moduledoc false

  alias __MODULE__.InputSummary

  def freshness_report_input_summary([]), do: nil

  def freshness_report_input_summary(sources),
    do: InputSummary.freshness_report_input_summary(sources)

  def refresh_budget_report_input_summary([]), do: nil

  def refresh_budget_report_input_summary(sources),
    do: InputSummary.refresh_budget_report_input_summary(sources)
end
