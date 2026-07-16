defmodule OrbitalDynamics.CampaignPlanner.ContactThroughputFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{FeedbackNumericValues, ScalarValues}

  def station_throughput_value(activity), do: station_throughput_value(activity, callbacks())

  def station_throughput_value(activity, callbacks) do
    actual = actual_contact_throughput_mb(activity, callbacks)
    expected = expected_contact_throughput_mb(activity, callbacks)

    if is_number(actual) and is_number(expected) and expected > 0 do
      actual
      |> Kernel./(expected)
      |> FeedbackNumericValues.clamp_unit_interval()
    end
  end

  def actual_contact_throughput_mb(activity),
    do: actual_contact_throughput_mb(activity, callbacks())

  def actual_contact_throughput_mb(activity, callbacks) do
    first_numeric_activity_value(
      activity,
      [
        "actual_throughput_mb",
        "actual_downlink_mb",
        "actual_data_volume_mb",
        "delivered_data_mb",
        "received_data_mb",
        ["throughput_model", "actual_throughput_mb"],
        ["throughput_model", "actual_downlink_mb"],
        ["throughput_model", "actual_data_volume_mb"],
        ["throughput_model", "delivered_data_mb"],
        ["throughput_model", "received_data_mb"]
      ],
      callbacks
    ) || actual_data_rate_contact_throughput_mb(activity, callbacks)
  end

  def actual_data_rate_contact_throughput_mb(activity),
    do: actual_data_rate_contact_throughput_mb(activity, callbacks())

  def actual_data_rate_contact_throughput_mb(activity, callbacks) do
    duration_s = actual_contact_duration_s(activity, callbacks)

    cond do
      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_contact_data_rate_mb_s(activity, callbacks) ->
        rate_mb_s * duration_s

      rate_mbps = actual_contact_data_rate_mbps(activity, callbacks) ->
        rate_mbps * duration_s / 8.0

      true ->
        nil
    end
  end

  def expected_contact_throughput_mb(activity),
    do: expected_contact_throughput_mb(activity, callbacks())

  def expected_contact_throughput_mb(activity, callbacks) do
    first_numeric_activity_value(
      activity,
      [
        "estimated_throughput_mb",
        "planned_throughput_mb",
        "estimated_downlink_mb",
        "required_downlink_mb",
        ["throughput_model", "estimated_throughput_mb"],
        ["throughput_model", "planned_throughput_mb"],
        ["throughput_model", "estimated_downlink_mb"],
        ["throughput_model", "required_downlink_mb"]
      ],
      callbacks
    )
  end

  defp actual_contact_data_rate_mb_s(activity, callbacks) do
    first_numeric_activity_value(
      activity,
      [
        "actual_data_rate_mb_s",
        "actual_downlink_rate_mb_s",
        "delivered_rate_mb_s",
        "received_rate_mb_s",
        ["throughput_model", "actual_data_rate_mb_s"],
        ["throughput_model", "actual_downlink_rate_mb_s"],
        ["throughput_model", "delivered_rate_mb_s"],
        ["throughput_model", "received_rate_mb_s"]
      ],
      callbacks
    )
  end

  defp actual_contact_data_rate_mbps(activity, callbacks) do
    first_numeric_activity_value(
      activity,
      [
        "actual_data_rate_mbps",
        "actual_downlink_rate_mbps",
        "delivered_rate_mbps",
        "received_rate_mbps",
        ["throughput_model", "actual_data_rate_mbps"],
        ["throughput_model", "actual_downlink_rate_mbps"],
        ["throughput_model", "delivered_rate_mbps"],
        ["throughput_model", "received_rate_mbps"]
      ],
      callbacks
    )
  end

  defp actual_contact_duration_s(activity, callbacks) do
    first_numeric_activity_value(
      activity,
      [
        "actual_duration_s",
        "actual_contact_duration_s",
        "contact_duration_s",
        "duration_s",
        ["throughput_model", "actual_duration_s"],
        ["throughput_model", "actual_contact_duration_s"],
        ["throughput_model", "contact_duration_s"],
        ["throughput_model", "duration_s"]
      ],
      callbacks
    ) || actual_contact_interval_duration_s(activity, callbacks)
  end

  defp actual_contact_interval_duration_s(activity, callbacks) do
    start_s =
      first_numeric_activity_value(
        activity,
        [
          "actual_starts_at_s",
          "actual_start_s",
          "starts_at_s",
          "start_s"
        ],
        callbacks
      )

    end_s =
      first_numeric_activity_value(
        activity,
        [
          "actual_ends_at_s",
          "actual_end_s",
          "ends_at_s",
          "end_s"
        ],
        callbacks
      )

    if is_number(start_s) and is_number(end_s) and end_s > start_s do
      end_s - start_s
    end
  end

  defp first_numeric_activity_value(activity, keys, callbacks) do
    FeedbackNumericValues.first_numeric_activity_value(activity, keys, callbacks)
  end

  defp callbacks,
    do: [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      feedback_value_missing?: &feedback_value_missing?/1
    ]

  defp feedback_value_missing?(nil), do: true
  defp feedback_value_missing?(""), do: true
  defp feedback_value_missing?(_value), do: false
end
