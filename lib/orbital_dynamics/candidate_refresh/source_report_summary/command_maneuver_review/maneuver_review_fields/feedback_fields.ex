defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.ManeuverReviewFields.FeedbackFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &FeedbackMetrics.report_rows_count/1),
      "maneuver_success_feedback_count" =>
        sum_report_count(reports, &FeedbackMetrics.maneuver_success_feedback_count/1),
      "execution_uncertainty_declared_count" =>
        sum_report_count(
          reports,
          &FeedbackMetrics.maneuver_execution_uncertainty_declared_count/1
        ),
      "execution_uncertainty_missing_count" =>
        sum_report_count(reports, &FeedbackMetrics.maneuver_execution_uncertainty_missing_count/1),
      "input_keys" => FeedbackMetrics.maneuver_review_input_keys(reports),
      "maneuver_id_counts" => FeedbackMetrics.maneuver_id_counts(reports),
      "required_operator_action_counts" =>
        FeedbackMetrics.required_operator_action_counts(reports)
    }
  end
end
