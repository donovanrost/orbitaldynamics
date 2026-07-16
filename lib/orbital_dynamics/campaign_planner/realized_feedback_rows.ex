defmodule OrbitalDynamics.CampaignPlanner.RealizedFeedbackRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CommandActivityClassification,
    ContactThroughputFields,
    DownlinkActivityNormalization,
    FeedbackNumericValues,
    ManeuverReviewExecutionUncertainty,
    ObservationQualityValues,
    RealizedActivitySuccessValues,
    RealizedDownlinkDemandFeedback,
    RealizedFeedbackContext,
    ScalarValues
  }

  def realized_contact?(activity), do: realized_contact?(activity, callbacks())

  def realized_contact?(activity, callbacks) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)
    contact_success_value = Keyword.fetch!(callbacks, :contact_success_value)

    (type in ["downlink", "contact", "planned_contact"] or downlink_activity?.(activity) or
       Map.has_key?(activity, "ground_station_id") or Map.has_key?(activity, "station_id")) and
      (not is_nil(contact_success_value.(activity)) or
         not is_nil(station_throughput_value(activity, callbacks)))
  end

  def realized_observation?(activity), do: realized_observation?(activity, callbacks())

  def realized_observation?(activity, callbacks) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")

    type == "observe" and
      (Map.get(activity, "target_id") || Map.get(activity, "id")) not in [nil, ""] and
      (not is_nil(value(callbacks, :observation_success_value, activity)) or
         not is_nil(value(callbacks, :image_quality_score_value, activity)) or
         not is_nil(value(callbacks, :image_quality_status_value, activity)) or
         not is_nil(value(callbacks, :image_quality_source_value, activity)) or
         not is_nil(value(callbacks, :cloud_cover_fraction_value, activity)) or
         not is_nil(value(callbacks, :blur_score_value, activity)) or
         not is_nil(value(callbacks, :observation_downlink_demand_mb, activity)) or
         not is_nil(value(callbacks, :target_priority_override_value, activity)))
  end

  def realized_maneuver?(activity), do: realized_maneuver?(activity, callbacks())

  def realized_maneuver?(activity, callbacks) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")

    (type in ["maneuver", "impulsive_burn"] or Map.has_key?(activity, "maneuver_success") or
       Map.has_key?(activity, "maneuver_result")) and
      activity_id(activity, callbacks) not in [nil, ""] and
      not is_nil(value(callbacks, :maneuver_success_value, activity))
  end

  def realized_command?(activity), do: realized_command?(activity, callbacks())

  def realized_command?(activity, callbacks) do
    command_activity? = Keyword.fetch!(callbacks, :command_activity?)

    command_activity?.(activity) and activity_id(activity, callbacks) not in [nil, ""] and
      not is_nil(value(callbacks, :command_success_value, activity))
  end

  def operator_review_contact?(row), do: operator_review_contact?(row, callbacks())

  def operator_review_contact?(row, callbacks) do
    usable?(row) and
      (realized_contact?(row, callbacks) or
         (activity_id(row, callbacks) not in [nil, ""] and
            (Map.get(row, "ground_station_id") || Map.get(row, "station_id")) not in [nil, ""] and
            not is_nil(unit_interval(callbacks, row["contact_success_factor"]))))
  end

  def operator_review_observation?(row), do: operator_review_observation?(row, callbacks())

  def operator_review_observation?(row, callbacks) do
    usable?(row) and
      (realized_observation?(row, callbacks) or
         ((Map.get(row, "target_id") || Map.get(row, "id")) not in [nil, ""] and
            not is_nil(unit_interval(callbacks, row["observation_success_factor"]))))
  end

  def operator_review_command?(row), do: operator_review_command?(row, callbacks())

  def operator_review_command?(row, callbacks) do
    usable?(row) and
      (realized_command?(row, callbacks) or
         (activity_id(row, callbacks) not in [nil, ""] and
            not is_nil(unit_interval(callbacks, row["command_success_factor"]))))
  end

  def operator_review_maneuver?(row), do: operator_review_maneuver?(row, callbacks())

  def operator_review_maneuver?(row, callbacks) do
    uncertainty_entry = Keyword.fetch!(callbacks, :maneuver_review_execution_uncertainty_entry)

    usable?(row) and
      (realized_maneuver?(row, callbacks) or
         (activity_id(row, callbacks) not in [nil, ""] and
            (not is_nil(unit_interval(callbacks, row["maneuver_success_factor"])) or
               uncertainty_entry.(row) != %{})))
  end

  def operator_review_usable?(row), do: usable?(row)

  defp usable?(%{"_operator_review_invalid_realized_feedback_input" => true}), do: false
  defp usable?(%{"_operator_review_invalid_activity_input" => true}), do: false

  defp usable?(%{"_operator_review_match_strategy" => "ambiguous_timeline_id"}), do: false

  defp usable?(%{"_operator_review_realized_match_count" => count})
       when is_integer(count) and count > 1,
       do: false

  defp usable?(%{"_operator_review_feedback_status" => status})
       when status in ["planned_only", "realized_only"],
       do: false

  defp usable?(_row), do: true

  defp activity_id(row, callbacks),
    do: Keyword.fetch!(callbacks, :realized_feedback_activity_id).(row)

  defp unit_interval(callbacks, value),
    do:
      FeedbackNumericValues.unit_interval_number_or_nil(
        value,
        feedback_numeric_callbacks(callbacks)
      )

  defp station_throughput_value(activity, callbacks) do
    ContactThroughputFields.station_throughput_value(
      activity,
      feedback_numeric_callbacks(callbacks)
    )
  end

  defp feedback_numeric_callbacks(callbacks),
    do: [
      numeric_or_nil: Keyword.fetch!(callbacks, :numeric_or_nil),
      feedback_value_missing?: Keyword.fetch!(callbacks, :feedback_value_missing?)
    ]

  defp value(callbacks, key, row),
    do: Keyword.fetch!(callbacks, key).(row)

  defp callbacks do
    [
      blur_score_value: &ObservationQualityValues.blur_score/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      command_activity?: &CommandActivityClassification.command?/1,
      command_success_value: &RealizedActivitySuccessValues.command/1,
      contact_success_value: &RealizedActivitySuccessValues.contact/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      feedback_value_missing?: &feedback_value_missing?/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      maneuver_review_execution_uncertainty_entry: &ManeuverReviewExecutionUncertainty.entry/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      observation_downlink_demand_mb: &RealizedDownlinkDemandFeedback.observation_mb/1,
      observation_success_value: &RealizedActivitySuccessValues.observation/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      target_priority_override_value: &target_priority_override_value/1
    ]
  end

  defp target_priority_override_value(%{"__realized_target_priority" => value})
       when is_number(value),
       do: max(value, 0.0)

  defp target_priority_override_value(_activity), do: nil

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
