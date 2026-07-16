defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.FeedbackCounts
  alias __MODULE__.Rows

  def report_rows_count(report), do: Rows.count(report)

  def command_feedback_count(report) do
    FeedbackCounts.command(report)
  end

  def maneuver_success_feedback_count(report) do
    FeedbackCounts.maneuver_success(report)
  end

  def maneuver_execution_uncertainty_declared_count(report) do
    FeedbackCounts.execution_uncertainty_status(report, "declared")
  end

  def maneuver_execution_uncertainty_missing_count(report) do
    FeedbackCounts.execution_uncertainty_status(report, "missing")
  end

  def maneuver_id_counts(report) do
    report
    |> Rows.normalized()
    |> CountMaps.maneuver_id_counts(report)
  end

  def required_operator_action_counts(report) do
    report
    |> Rows.normalized()
    |> CountMaps.required_operator_action_counts(report)
  end
end
