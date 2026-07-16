defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.InputKeys do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.TimelineFeedback, as: TimelineFeedbackReport

  def from_reports(reports) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> TimelineFeedbackReport.operational_feedback()
      |> from_feedback()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def from_feedback(feedback) do
    OperationalFeedback.data_keys(feedback)
  end
end
