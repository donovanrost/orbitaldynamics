defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.InputSummary

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceFields,
    as: TimelineDiffSourceFields

  def timeline_diff_report_input_summary([]), do: nil

  defdelegate timeline_diff_report_input_summary(sources), to: InputSummary

  def timeline_diff_report_source(%{} = report) do
    TimelineDiffSourceFields.fields(report)
  end

  def integrity_report_input_summary([]), do: nil

  defdelegate integrity_report_input_summary(sources), to: InputSummary
end
