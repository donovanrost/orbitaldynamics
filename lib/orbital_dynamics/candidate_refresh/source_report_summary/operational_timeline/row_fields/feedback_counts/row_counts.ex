defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.FeedbackCounts.RowCounts do
  @moduledoc false

  alias __MODULE__.Predicates

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.RowValues

  def contact_count(report) do
    feedback_count(report, Predicates.contact())
  end

  def command_count(report) do
    feedback_count(report, Predicates.command())
  end

  def maneuver_count(report) do
    feedback_count(report, Predicates.maneuver())
  end

  def observation_count(report) do
    feedback_count(report, Predicates.observation())
  end

  def station_throughput_count(report) do
    feedback_count(report, Predicates.station_throughput())
  end

  defp feedback_count(report, predicate) when is_function(predicate, 1) do
    RowValues.feedback_count(report, predicate)
  end
end
