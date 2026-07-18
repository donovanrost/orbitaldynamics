defmodule OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy do
  @moduledoc false

  def collection_ends_at_s(activity, first_number) do
    first_number.(activity, [
      "collection_ends_at_s",
      "collection_end_s",
      "observation_ends_at_s",
      "observed_ends_at_s"
    ])
  end

  def planned_delivery_at_s(activity, first_number) do
    first_number.(activity, [
      "planned_delivery_at_s",
      "planned_delivered_at_s",
      "planned_downlink_at_s",
      "delivery_due_at_s"
    ])
  end

  def actual_delivery_at_s(activity, first_number) do
    first_number.(activity, [
      "actual_delivery_at_s",
      "actual_delivered_at_s",
      "delivered_at_s",
      "received_at_s",
      "actual_downlink_at_s"
    ])
  end

  def max_latency_s(activity, first_number) do
    first_number.(activity, [
      "max_latency_s",
      "required_latency_s",
      "target_latency_s"
    ])
  end

  def planned_latency_s(
        activity,
        collection_ends_at_s,
        planned_delivery_at_s,
        first_number,
        delta
      ) do
    first_number.(activity, ["planned_latency_s"]) ||
      delta.(planned_delivery_at_s, collection_ends_at_s)
  end

  def actual_latency_s(
        activity,
        collection_ends_at_s,
        actual_delivery_at_s,
        first_number,
        delta
      ) do
    first_number.(activity, ["actual_latency_s"]) ||
      delta.(actual_delivery_at_s, collection_ends_at_s)
  end
end
