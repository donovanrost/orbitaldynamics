defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewOperationalFeedback do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CommandWindowOperationalFeedback,
    ContactThroughputFields,
    FeedbackNumericValues,
    ManeuverReviewOperationalFeedback,
    ObservationQualityValues,
    OperatorReviewFeedbackRows,
    RealizedActivitySuccessValues,
    RealizedDownlinkDemandFeedback,
    RealizedFeedbackAggregation,
    RealizedFeedbackRows
  }

  def from_rows(rows) do
    operational_timeline_rows = OperatorReviewFeedbackRows.operational_timeline_rows(rows)
    realized_feedback_rows = OperatorReviewFeedbackRows.realized_feedback_rows(rows)

    from_rows(rows, operational_timeline_rows, realized_feedback_rows, default_callbacks())
  end

  def from_rows(rows, operational_timeline_rows, realized_feedback_rows) do
    from_rows(rows, operational_timeline_rows, realized_feedback_rows, default_callbacks())
  end

  def from_rows(rows, operational_timeline_rows, realized_feedback_rows, opts)
      when is_list(opts) do
    command_feedback = Keyword.fetch!(opts, :command_feedback)
    maneuver_feedback = Keyword.fetch!(opts, :maneuver_feedback)
    row_sets = row_sets(rows, operational_timeline_rows, realized_feedback_rows, opts)

    row_sets.contact
    |> from_contact_observation_rows(row_sets.observation, opts)
    |> Map.merge(command_feedback.(row_sets.command))
    |> Map.merge(maneuver_feedback.(row_sets.maneuver))
  end

  def from_contact_observation_rows(contact_rows, observation_rows) do
    from_contact_observation_rows(contact_rows, observation_rows, default_callbacks())
  end

  def from_contact_observation_rows(contact_rows, observation_rows, opts) when is_list(opts) do
    station_feedback_average = Keyword.fetch!(opts, :station_feedback_average)
    target_feedback_average = Keyword.fetch!(opts, :target_feedback_average)
    target_feedback_text = Keyword.fetch!(opts, :target_feedback_text)
    contact_success_value = Keyword.fetch!(opts, :contact_success_value)
    observation_success_value = Keyword.fetch!(opts, :observation_success_value)
    image_quality_score_value = Keyword.fetch!(opts, :image_quality_score_value)
    image_quality_status_value = Keyword.fetch!(opts, :image_quality_status_value)
    image_quality_source_value = Keyword.fetch!(opts, :image_quality_source_value)
    cloud_cover_fraction_value = Keyword.fetch!(opts, :cloud_cover_fraction_value)
    blur_score_value = Keyword.fetch!(opts, :blur_score_value)
    station_throughput_value = Keyword.fetch!(opts, :station_throughput_value)
    station_downlink_demand_feedback = Keyword.fetch!(opts, :station_downlink_demand_feedback)

    %{
      "contact_success_rate" => station_feedback_average.(contact_rows, contact_success_value),
      "observation_success_rate" =>
        target_feedback_average.(observation_rows, observation_success_value),
      "image_quality_score" =>
        target_feedback_average.(observation_rows, image_quality_score_value),
      "image_quality_status" =>
        target_feedback_text.(observation_rows, image_quality_status_value),
      "image_quality_source" =>
        target_feedback_text.(observation_rows, image_quality_source_value),
      "cloud_cover_fraction" =>
        target_feedback_average.(observation_rows, cloud_cover_fraction_value),
      "blur_score" => target_feedback_average.(observation_rows, blur_score_value),
      "station_throughput_factor" =>
        station_feedback_average.(contact_rows, station_throughput_value),
      "downlink_demand_mb" => station_downlink_demand_feedback.(contact_rows)
    }
  end

  defp row_sets(rows, operational_timeline_rows, realized_feedback_rows, opts) do
    contact_feedback_row? = Keyword.fetch!(opts, :contact_feedback_row?)
    observation_feedback_row? = Keyword.fetch!(opts, :observation_feedback_row?)
    command_feedback_row? = Keyword.fetch!(opts, :command_feedback_row?)
    maneuver_feedback_row? = Keyword.fetch!(opts, :maneuver_feedback_row?)
    command_window_rows = Keyword.fetch!(opts, :command_window_rows)
    maneuver_review_rows = Keyword.fetch!(opts, :maneuver_review_rows)

    timeline_and_realized_rows = operational_timeline_rows ++ realized_feedback_rows

    %{
      contact: Enum.filter(timeline_and_realized_rows, contact_feedback_row?),
      observation: Enum.filter(timeline_and_realized_rows, observation_feedback_row?),
      command:
        rows
        |> command_window_rows.()
        |> Kernel.++(Enum.filter(operational_timeline_rows, command_feedback_row?))
        |> Kernel.++(Enum.filter(realized_feedback_rows, command_feedback_row?)),
      maneuver:
        rows
        |> maneuver_review_rows.()
        |> Kernel.++(Enum.filter(operational_timeline_rows, maneuver_feedback_row?))
        |> Kernel.++(Enum.filter(realized_feedback_rows, maneuver_feedback_row?))
    }
  end

  defp default_callbacks do
    [
      contact_feedback_row?: &RealizedFeedbackRows.operator_review_contact?/1,
      observation_feedback_row?: &RealizedFeedbackRows.operator_review_observation?/1,
      command_feedback_row?: &RealizedFeedbackRows.operator_review_command?/1,
      maneuver_feedback_row?: &RealizedFeedbackRows.operator_review_maneuver?/1,
      command_window_rows: &CommandWindowOperationalFeedback.operator_review_rows/1,
      maneuver_review_rows: &ManeuverReviewOperationalFeedback.operator_review_rows/1,
      command_feedback: &CommandWindowOperationalFeedback.from_rows/1,
      maneuver_feedback: &ManeuverReviewOperationalFeedback.from_rows/1,
      station_feedback_average: &RealizedFeedbackAggregation.station_average/2,
      target_feedback_average: &RealizedFeedbackAggregation.target_average/2,
      target_feedback_text: &RealizedFeedbackAggregation.target_text/2,
      contact_success_value: &operational_timeline_contact_success_value/1,
      observation_success_value: &operational_timeline_observation_success_value/1,
      image_quality_score_value: &ObservationQualityValues.image_quality_score/1,
      image_quality_status_value: &ObservationQualityValues.image_quality_status/1,
      image_quality_source_value: &ObservationQualityValues.image_quality_source/1,
      cloud_cover_fraction_value: &ObservationQualityValues.cloud_cover_fraction/1,
      blur_score_value: &ObservationQualityValues.blur_score/1,
      station_throughput_value: &ContactThroughputFields.station_throughput_value/1,
      station_downlink_demand_feedback: &RealizedDownlinkDemandFeedback.station_feedback/1
    ]
  end

  defp operational_timeline_contact_success_value(row) do
    case FeedbackNumericValues.unit_interval_number_or_nil(row["contact_success_factor"]) do
      value when is_number(value) -> value
      _value -> RealizedActivitySuccessValues.contact(row)
    end
  end

  defp operational_timeline_observation_success_value(row) do
    case FeedbackNumericValues.unit_interval_number_or_nil(row["observation_success_factor"]) do
      value when is_number(value) -> value
      _value -> RealizedActivitySuccessValues.observation(row)
    end
  end
end
