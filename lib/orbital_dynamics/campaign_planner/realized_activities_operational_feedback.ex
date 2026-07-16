defmodule OrbitalDynamics.CampaignPlanner.RealizedActivitiesOperationalFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    ObservationQualityValues,
    PriorActivityContext,
    RealizedActivitySuccessValues,
    RealizedDownlinkDemandFeedback,
    RealizedFeedbackAggregation,
    RealizedFeedbackInputValidation,
    RealizedFeedbackRows,
    RealizedResourceFeedback,
    ValueEncoding
  }

  def feedback(mission_state, prior_plan), do: feedback(mission_state, prior_plan, callbacks())

  def feedback(mission_state, prior_plan, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    invalid_input? = Keyword.fetch!(callbacks, :invalid_realized_activity_feedback_input?)
    enrich_with_planned_context = Keyword.fetch!(callbacks, :enrich_with_planned_context)
    realized_contact? = Keyword.fetch!(callbacks, :realized_contact?)
    realized_observation? = Keyword.fetch!(callbacks, :realized_observation?)
    realized_maneuver? = Keyword.fetch!(callbacks, :realized_maneuver?)
    realized_command? = Keyword.fetch!(callbacks, :realized_command?)
    contact_success_value = Keyword.fetch!(callbacks, :contact_success_value)
    observation_success_value = Keyword.fetch!(callbacks, :observation_success_value)
    image_quality_score_value = Keyword.fetch!(callbacks, :image_quality_score_value)
    image_quality_status_value = Keyword.fetch!(callbacks, :image_quality_status_value)
    image_quality_source_value = Keyword.fetch!(callbacks, :image_quality_source_value)
    cloud_cover_fraction_value = Keyword.fetch!(callbacks, :cloud_cover_fraction_value)
    blur_score_value = Keyword.fetch!(callbacks, :blur_score_value)
    maneuver_success_value = Keyword.fetch!(callbacks, :maneuver_success_value)
    command_success_value = Keyword.fetch!(callbacks, :command_success_value)
    station_throughput_value = Keyword.fetch!(callbacks, :station_throughput_value)

    observation_downlink_demand_feedback =
      Keyword.fetch!(callbacks, :observation_downlink_demand_feedback)

    station_downlink_demand_feedback =
      Keyword.fetch!(callbacks, :station_downlink_demand_feedback)

    merge_downlink_demand_feedback = Keyword.fetch!(callbacks, :merge_downlink_demand_feedback)

    observation_downlink_demand_sources =
      Keyword.fetch!(callbacks, :observation_downlink_demand_sources)

    station_downlink_demand_sources = Keyword.fetch!(callbacks, :station_downlink_demand_sources)

    merge_downlink_demand_source_feedback =
      Keyword.fetch!(callbacks, :merge_downlink_demand_source_feedback)

    realized_resource_margin_feedback =
      Keyword.fetch!(callbacks, :realized_resource_margin_feedback)

    realized_resource_availability_feedback =
      Keyword.fetch!(callbacks, :realized_resource_availability_feedback)

    raw_realized_activities =
      mission_state
      |> Map.get("realized_activities", [])
      |> Enum.map(&stringify_keys.(&1))

    feedback_realized_activities = Enum.reject(raw_realized_activities, &invalid_input?.(&1))

    realized_activities =
      feedback_realized_activities
      |> enrich_with_planned_context.(prior_plan)

    realized_contacts = Enum.filter(realized_activities, &realized_contact?.(&1))
    realized_observations = Enum.filter(realized_activities, &realized_observation?.(&1))
    realized_maneuvers = Enum.filter(realized_activities, &realized_maneuver?.(&1))
    realized_commands = Enum.filter(realized_activities, &realized_command?.(&1))

    %{
      "contact_success_rate" =>
        RealizedFeedbackAggregation.station_average(realized_contacts, contact_success_value),
      "observation_success_rate" =>
        RealizedFeedbackAggregation.target_average(
          realized_observations,
          observation_success_value
        ),
      "image_quality_score" =>
        RealizedFeedbackAggregation.target_average(
          realized_observations,
          image_quality_score_value
        ),
      "image_quality_status" =>
        RealizedFeedbackAggregation.target_text(realized_observations, image_quality_status_value),
      "image_quality_source" =>
        RealizedFeedbackAggregation.target_text(realized_observations, image_quality_source_value),
      "cloud_cover_fraction" =>
        RealizedFeedbackAggregation.target_average(
          realized_observations,
          cloud_cover_fraction_value
        ),
      "blur_score" =>
        RealizedFeedbackAggregation.target_average(realized_observations, blur_score_value),
      "maneuver_success_rate" =>
        RealizedFeedbackAggregation.activity_average(realized_maneuvers, maneuver_success_value),
      "command_success_rate" =>
        RealizedFeedbackAggregation.activity_average(realized_commands, command_success_value),
      "station_throughput_factor" =>
        RealizedFeedbackAggregation.station_average(realized_contacts, station_throughput_value),
      "downlink_demand_mb" =>
        merge_downlink_demand_feedback.(
          observation_downlink_demand_feedback.(realized_observations),
          station_downlink_demand_feedback.(realized_contacts)
        ),
      "downlink_demand_sources" =>
        merge_downlink_demand_source_feedback.(
          observation_downlink_demand_sources.(realized_observations),
          station_downlink_demand_sources.(realized_contacts)
        ),
      "target_priority_overrides" =>
        RealizedFeedbackAggregation.target_priority_average(realized_observations),
      "resource_margin_overrides" =>
        realized_resource_margin_feedback.(feedback_realized_activities),
      "resource_availability_overrides" =>
        realized_resource_availability_feedback.(feedback_realized_activities)
    }
  end

  defp callbacks do
    [
      stringify_keys: &ValueEncoding.stringify_keys/1,
      invalid_realized_activity_feedback_input?:
        &RealizedFeedbackInputValidation.invalid_input?/1,
      enrich_with_planned_context: &PriorActivityContext.enrich/2,
      realized_contact?: &RealizedFeedbackRows.realized_contact?/1,
      realized_observation?: &RealizedFeedbackRows.realized_observation?/1,
      realized_maneuver?: &RealizedFeedbackRows.realized_maneuver?/1,
      realized_command?: &RealizedFeedbackRows.realized_command?/1,
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      blur_score_value: &ObservationQualityValues.blur_score/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      station_throughput_value: &ContactThroughputFields.station_throughput_value/1,
      observation_downlink_demand_feedback:
        &RealizedDownlinkDemandFeedback.observation_feedback/1,
      station_downlink_demand_feedback: &RealizedDownlinkDemandFeedback.station_feedback/1,
      merge_downlink_demand_feedback: &RealizedDownlinkDemandFeedback.merge_feedback/2,
      observation_downlink_demand_sources: &RealizedDownlinkDemandFeedback.observation_sources/1,
      station_downlink_demand_sources: &RealizedDownlinkDemandFeedback.station_sources/1,
      merge_downlink_demand_source_feedback:
        &RealizedDownlinkDemandFeedback.merge_source_feedback/2,
      realized_resource_margin_feedback: &RealizedResourceFeedback.margin_feedback/1,
      realized_resource_availability_feedback: &RealizedResourceFeedback.availability_feedback/1
    ]
  end
end
