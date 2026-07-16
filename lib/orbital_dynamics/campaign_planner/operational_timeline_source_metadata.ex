defmodule OrbitalDynamics.CampaignPlanner.OperationalTimelineSourceMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalTimelineFeedbackTrustBoundaries,
    RealizedFeedbackWeights,
    ReviewSourceReports
  }

  def prior_plan(prior_plan, callbacks) do
    ReviewSourceReports.operational_timeline_source_metadata(
      callback!(callbacks, :prior_plan_reports).(prior_plan),
      callback!(callbacks, :prior_plan_rows).(prior_plan),
      source_metadata_callbacks(callbacks)
    )
  end

  def mission_state(mission_state, callbacks) do
    ReviewSourceReports.operational_timeline_source_metadata(
      callback!(callbacks, :mission_state_reports).(mission_state),
      callback!(callbacks, :mission_state_rows).(mission_state),
      source_metadata_callbacks(callbacks)
    )
  end

  defp source_metadata_callbacks(callbacks) do
    [
      weighted_feedback_row_count: &RealizedFeedbackWeights.weighted_row_count/1,
      feedback_weight_sources: &RealizedFeedbackWeights.sources/1,
      feedback_trust_boundaries:
        Keyword.get(
          callbacks,
          :feedback_trust_boundaries,
          &OperationalTimelineFeedbackTrustBoundaries.feedback_boundaries/1
        )
    ]
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
