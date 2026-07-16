defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues.CountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def maneuver_id_counts([], report), do: Map.get(report, "maneuver_id_counts")

  def maneuver_id_counts(rows, _report) do
    rows
    |> Enum.map(&OperationalFeedback.maneuver_review_feedback_key/1)
    |> count_source_report_values()
  end

  def required_operator_action_counts([], report) do
    Map.get(report, "required_operator_action_counts")
  end

  def required_operator_action_counts(rows, _report) do
    rows
    |> Enum.map(&Map.get(&1, "required_operator_action"))
    |> count_source_report_values()
  end
end
