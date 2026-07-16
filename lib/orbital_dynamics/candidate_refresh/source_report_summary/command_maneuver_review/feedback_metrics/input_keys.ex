defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.InputKeys do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def command_window(reports) do
    source_report_input_keys(
      reports,
      &OperationalFeedback.command_window_report_feedback/1
    )
  end

  def maneuver_review(reports) do
    source_report_input_keys(
      reports,
      &OperationalFeedback.maneuver_review_report_feedback/1
    )
  end

  defp source_report_input_keys(reports, feedback_fun) when is_function(feedback_fun, 1) do
    reports
    |> Enum.flat_map(fn report ->
      report
      |> feedback_fun.()
      |> OperationalFeedback.data_keys()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
