defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.FeedbackCounts.RowCounts.Predicates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def contact, do: &OperationalFeedback.operational_timeline_contact_feedback_row?/1

  def command, do: &OperationalFeedback.operational_timeline_command_feedback_row?/1

  def maneuver, do: &OperationalFeedback.operational_timeline_maneuver_feedback_row?/1

  def observation, do: &OperationalFeedback.operational_timeline_observation_feedback_row?/1

  def station_throughput,
    do: &OperationalFeedback.operational_timeline_station_throughput_feedback_row?/1
end
