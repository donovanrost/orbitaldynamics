defmodule OrbitalDynamics.CampaignPlanner.ManeuverReviewSourceMetadata do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ManeuverReviewExecutionUncertainty,
    RealizedFeedbackWeights,
    ReviewSourceReports
  }

  def prior_plan(prior_plan, callbacks) do
    reports_with_sources = callback!(callbacks, :prior_plan_reports).(prior_plan)
    source_rows = callback!(callbacks, :prior_plan_source_rows).(prior_plan)
    feedback_rows = feedback_rows(source_rows, callbacks)

    ReviewSourceReports.maneuver_review_source_metadata(
      reports_with_sources,
      feedback_rows,
      source_rows,
      prior_plan_extra_metadata(prior_plan, callbacks),
      source_metadata_callbacks(callbacks)
    )
  end

  def mission_state(mission_state, callbacks) do
    reports_with_sources = callback!(callbacks, :mission_state_reports).(mission_state)
    source_rows = callback!(callbacks, :mission_state_source_rows).(mission_state)
    feedback_rows = feedback_rows(source_rows, callbacks)

    ReviewSourceReports.maneuver_review_source_metadata(
      reports_with_sources,
      feedback_rows,
      source_rows,
      %{},
      source_metadata_callbacks(callbacks)
    )
  end

  defp prior_plan_extra_metadata(prior_plan, callbacks) do
    %{
      "source_result_artifact_count" =>
        positive_count(callback!(callbacks, :prior_plan_result_artifacts).(prior_plan)),
      "source_result_artifact_maneuver_review_row_count" =>
        positive_count(callback!(callbacks, :prior_plan_result_artifact_rows).(prior_plan))
    }
  end

  defp feedback_rows(source_rows, callbacks) do
    feedback_row? = callback!(callbacks, :feedback_row?)
    Enum.filter(source_rows, feedback_row?)
  end

  defp positive_count([]), do: nil
  defp positive_count(rows), do: length(rows)

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp source_metadata_callbacks(callbacks) do
    Keyword.get_lazy(callbacks, :source_metadata_callbacks, fn ->
      [
        weighted_feedback_row_count: &RealizedFeedbackWeights.weighted_row_count/1,
        feedback_weight_sources: &RealizedFeedbackWeights.sources/1,
        execution_uncertainty_status_count: &ManeuverReviewExecutionUncertainty.status_count/2
      ]
    end)
  end
end
