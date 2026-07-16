defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues.FeedbackCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues.Rows

  def command(report) do
    report
    |> Rows.normalized()
    |> Enum.count(&OperationalFeedback.command_window_feedback_row?/1)
  end

  def maneuver_success(report) do
    report
    |> Rows.normalized()
    |> Enum.count(&OperationalFeedback.maneuver_review_success_feedback_row?/1)
  end

  def execution_uncertainty_status(report, status) do
    report
    |> Rows.normalized()
    |> Enum.count(
      &(OperationalFeedback.maneuver_review_execution_uncertainty_status(&1) == status)
    )
  end
end
