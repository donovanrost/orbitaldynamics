defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics do
  @moduledoc false

  alias __MODULE__.InputKeys
  alias __MODULE__.ReportCountMaps
  alias __MODULE__.RowValues

  def report_rows_count(report), do: RowValues.report_rows_count(report)

  def command_feedback_count(report), do: RowValues.command_feedback_count(report)

  def maneuver_success_feedback_count(report),
    do: RowValues.maneuver_success_feedback_count(report)

  def maneuver_execution_uncertainty_declared_count(report) do
    RowValues.maneuver_execution_uncertainty_declared_count(report)
  end

  def maneuver_execution_uncertainty_missing_count(report) do
    RowValues.maneuver_execution_uncertainty_missing_count(report)
  end

  def maneuver_id_counts(reports) when is_list(reports) do
    ReportCountMaps.maneuver_id_counts(reports)
  end

  def maneuver_id_counts(report) do
    RowValues.maneuver_id_counts(report)
  end

  def required_operator_action_counts(reports) when is_list(reports) do
    ReportCountMaps.required_operator_action_counts(reports)
  end

  def required_operator_action_counts(report) do
    RowValues.required_operator_action_counts(report)
  end

  def command_window_input_keys(reports), do: InputKeys.command_window(reports)

  def maneuver_review_input_keys(reports), do: InputKeys.maneuver_review(reports)
end
