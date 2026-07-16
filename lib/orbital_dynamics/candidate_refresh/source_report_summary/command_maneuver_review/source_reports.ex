defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.SourceReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.SourceReports.CommandWindowSource

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.SourceReports.ManeuverReviewSource

  def command_window_report_source(%{} = report) do
    CommandWindowSource.source(report)
  end

  def command_window_report_source_required_operator_action_counts(report) do
    CommandWindowSource.required_operator_action_counts(report)
  end

  def maneuver_review_report_source(%{} = report) do
    ManeuverReviewSource.source(report)
  end

  def maneuver_review_report_source_required_operator_action_counts(report) do
    ManeuverReviewSource.required_operator_action_counts(report)
  end
end
