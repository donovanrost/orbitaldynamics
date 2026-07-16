defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection do
  @moduledoc false

  alias __MODULE__.InputSummary

  def candidate_diff_report_input_summary([]), do: nil

  def candidate_diff_report_input_summary(sources),
    do: InputSummary.candidate_diff_report_input_summary(sources)

  def candidate_rejection_report_input_summary([]), do: nil

  def candidate_rejection_report_input_summary(sources),
    do: InputSummary.candidate_rejection_report_input_summary(sources)
end
