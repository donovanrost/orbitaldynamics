defmodule OrbitalDynamics.CampaignPlanner.TimelineFeedbackSourceMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    OperationalFeedbackNormalization,
    OperationalFeedbackSourceMetadata,
    RealizedFeedbackTrustBoundaries,
    ReviewSourceReports,
    ScalarValues
  }

  def prior_plan(prior_plan, callbacks) do
    ReviewSourceReports.timeline_feedback_source_metadata(
      callback!(callbacks, :prior_plan_reports).(prior_plan),
      source_metadata_callbacks(callbacks)
    )
  end

  def mission_state(mission_state, callbacks) do
    ReviewSourceReports.timeline_feedback_source_metadata(
      callback!(callbacks, :mission_state_reports).(mission_state),
      source_metadata_callbacks(callbacks)
    )
  end

  defp source_metadata_callbacks(callbacks) do
    Keyword.get(callbacks, :source_metadata_callbacks, default_source_metadata_callbacks())
  end

  defp default_source_metadata_callbacks do
    [
      operational_feedback_provenance_trust_boundaries:
        &RealizedFeedbackTrustBoundaries.provenance_boundaries/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      merge_feedback_trust_boundary_maps:
        &OperationalFeedbackSourceMetadata.merge_feedback_trust_boundary_maps/1,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      operational_feedback_value_present: &OperationalFeedbackSourceMetadata.value_present?/1,
      put_feedback_trust_boundary:
        &OperationalFeedbackSourceMetadata.put_feedback_trust_boundary/4
    ]
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
