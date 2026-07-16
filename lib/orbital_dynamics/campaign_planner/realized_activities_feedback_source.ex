defmodule OrbitalDynamics.CampaignPlanner.RealizedActivitiesFeedbackSource do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    DownlinkActivityNormalization,
    ObservationQualityValues,
    OperationalFeedbackSourceMetadata,
    PriorActivityContext,
    RealizedActivitySuccessValues,
    RealizedDownlinkDemandFeedback,
    RealizedFeedbackContext,
    RealizedFeedbackInputValidation,
    RealizedFeedbackTrustBoundaries,
    RealizedFeedbackWeights,
    RealizedResourceFeedback,
    ValueEncoding
  }

  def source(realized_activities, feedback, prior_plan),
    do: source(realized_activities, feedback, prior_plan, callbacks())

  def source(realized_activities, feedback, prior_plan, callbacks)
      when is_list(realized_activities) do
    if realized_activities == [] do
      nil
    else
      stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

      invalid_realized_activity_feedback_input? =
        Keyword.fetch!(callbacks, :invalid_realized_activity_feedback_input?)

      enrich_realized_activities_with_planned_context =
        Keyword.fetch!(callbacks, :enrich_realized_activities_with_planned_context)

      operational_feedback_data_keys = Keyword.fetch!(callbacks, :operational_feedback_data_keys)

      invalid_realized_activity_feedback_sections =
        Keyword.fetch!(callbacks, :invalid_realized_activity_feedback_sections)

      activity_trust_boundaries = Keyword.fetch!(callbacks, :activity_trust_boundaries)
      feedback_trust_boundaries = Keyword.fetch!(callbacks, :feedback_trust_boundaries)
      weighted_feedback_row_count = Keyword.fetch!(callbacks, :weighted_feedback_row_count)
      feedback_weight_sources = Keyword.fetch!(callbacks, :feedback_weight_sources)
      put_invalid_sections = Keyword.fetch!(callbacks, :put_invalid_sections)
      compact_map = Keyword.fetch!(callbacks, :compact_map)

      realized_activities = Enum.map(realized_activities, stringify_keys)

      feedback_realized_activities =
        Enum.reject(realized_activities, invalid_realized_activity_feedback_input?)

      enriched_realized_activities =
        enrich_realized_activities_with_planned_context.(feedback_realized_activities, prior_plan)

      input_keys = operational_feedback_data_keys.(feedback)
      invalid_sections = invalid_realized_activity_feedback_sections.(realized_activities)

      trust_boundaries =
        realized_activities
        |> Enum.flat_map(activity_trust_boundaries)
        |> Enum.uniq()
        |> Enum.sort()

      feedback_trust_boundaries = feedback_trust_boundaries.(enriched_realized_activities)
      weighted_feedback_row_count = weighted_feedback_row_count.(realized_activities)
      feedback_weight_sources = feedback_weight_sources.(realized_activities)

      %{
        "source" => "mission_state.realized_activities",
        "input_keys" => input_keys,
        "realized_activity_count" => length(realized_activities),
        "trust_boundary_status" => if(trust_boundaries == [], do: "missing", else: "declared"),
        "trust_boundaries" => trust_boundaries,
        "feedback_trust_boundaries" =>
          if(feedback_trust_boundaries == %{}, do: nil, else: feedback_trust_boundaries),
        "weighted_feedback_row_count" =>
          if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
        "feedback_weight_sources" =>
          if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources)
      }
      |> put_invalid_sections.(invalid_sections)
      |> compact_map.()
    end
  end

  def source(_realized_activities, _feedback, _prior_plan, _callbacks), do: nil

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      invalid_realized_activity_feedback_input?:
        &RealizedFeedbackInputValidation.invalid_input?/1,
      enrich_realized_activities_with_planned_context: &PriorActivityContext.enrich/2,
      operational_feedback_data_keys: &OperationalFeedbackSourceMetadata.data_keys/1,
      invalid_realized_activity_feedback_sections: &RealizedFeedbackInputValidation.sections/1,
      activity_trust_boundaries: &RealizedFeedbackTrustBoundaries.activity_boundaries/1,
      feedback_trust_boundaries: &feedback_trust_boundaries/1,
      weighted_feedback_row_count: &RealizedFeedbackWeights.weighted_row_count/1,
      feedback_weight_sources: &RealizedFeedbackWeights.sources/1,
      put_invalid_sections: &put_invalid_sections/2,
      compact_map: &ValueEncoding.compact_map/1
    ]
  end

  defp feedback_trust_boundaries(realized_activities) do
    RealizedFeedbackTrustBoundaries.feedback_boundaries(
      realized_activities,
      trust_boundary_callbacks()
    )
  end

  defp trust_boundary_callbacks do
    [
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      station_throughput_value: &ContactThroughputFields.station_throughput_value/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      realized_downlink_demand_mb: &RealizedDownlinkDemandFeedback.realized_mb/1,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      blur_score_value: &ObservationQualityValues.blur_score/1,
      target_priority_override_value: &target_priority_override_value/1,
      observation_downlink_demand_mb: &RealizedDownlinkDemandFeedback.observation_mb/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      resource_feedback_spacecraft_id: &RealizedResourceFeedback.spacecraft_id/1,
      realized_activity_resource_margins: &RealizedResourceFeedback.activity_resource_margins/1,
      realized_activity_resource_availability:
        &RealizedResourceFeedback.activity_resource_availability/1
    ]
  end

  defp put_invalid_sections(source, []), do: source

  defp put_invalid_sections(source, invalid_sections) do
    OperationalFeedbackSourceMetadata.put_invalid_sections(source, invalid_sections)
  end

  defp target_priority_override_value(%{"__realized_target_priority" => value})
       when is_number(value),
       do: max(value, 0.0)

  defp target_priority_override_value(_activity), do: nil
end
