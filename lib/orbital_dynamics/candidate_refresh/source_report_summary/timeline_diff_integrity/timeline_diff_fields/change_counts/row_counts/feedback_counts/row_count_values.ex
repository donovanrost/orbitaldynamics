defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.FeedbackCounts.RowCountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.Rows

  def removed_downlink_count(report) do
    Rows.count(report, &OperationalFeedback.timeline_diff_removed_downlink_feedback_row?/1)
  end

  def changed_downlink_shortfall_count(report) do
    Rows.count(
      report,
      &OperationalFeedback.timeline_diff_changed_downlink_shortfall_feedback_row?/1
    )
  end

  def changed_contact_feedback_count(report) do
    Rows.count(report, &OperationalFeedback.timeline_diff_changed_contact_feedback_row?/1)
  end

  def changed_observation_quality_feedback_count(report) do
    Rows.count(
      report,
      &OperationalFeedback.timeline_diff_changed_observation_quality_feedback_row?/1
    )
  end

  def changed_command_feedback_count(report) do
    Rows.count(report, &OperationalFeedback.timeline_diff_changed_command_feedback_row?/1)
  end

  def changed_maneuver_feedback_count(report) do
    Rows.count(report, &OperationalFeedback.timeline_diff_changed_maneuver_feedback_row?/1)
  end
end
