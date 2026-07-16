defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.TimelineReportSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.TimelineFeedback

  def operational_timeline_feedback(reports) when is_list(reports) do
    reports
    |> OperationalFeedback.source_report_feedback(
      &OperationalFeedback.operational_timeline_report_feedback/1
    )
    |> OperationalFeedback.put_source_operational_timeline_trust_boundary(reports)
    |> OperationalFeedback.compact()
  end

  def operational_timeline_feedback(_reports), do: %{}

  def timeline_feedback(reports) when is_list(reports) do
    reports
    |> OperationalFeedback.source_report_feedback(&TimelineFeedback.operational_feedback/1)
    |> OperationalFeedback.put_source_timeline_feedback_trust_boundary(reports)
    |> OperationalFeedback.compact()
  end

  def timeline_feedback(_reports), do: %{}

  def timeline_diff_feedback(reports) when is_list(reports) do
    reports
    |> OperationalFeedback.source_report_feedback(
      &OperationalFeedback.timeline_diff_report_feedback/1
    )
    |> OperationalFeedback.put_source_timeline_diff_trust_boundary(reports)
    |> OperationalFeedback.compact()
  end

  def timeline_diff_feedback(_reports), do: %{}

  def command_window_feedback(reports) when is_list(reports) do
    reports
    |> OperationalFeedback.source_report_feedback(
      &OperationalFeedback.command_window_report_feedback/1
    )
    |> OperationalFeedback.put_source_command_window_trust_boundary(reports)
    |> OperationalFeedback.compact()
  end

  def command_window_feedback(_reports), do: %{}

  def maneuver_review_feedback(reports) when is_list(reports) do
    reports
    |> OperationalFeedback.source_report_feedback(
      &OperationalFeedback.maneuver_review_report_feedback/1
    )
    |> OperationalFeedback.put_source_maneuver_review_trust_boundary(reports)
    |> OperationalFeedback.compact()
  end

  def maneuver_review_feedback(_reports), do: %{}
end
