defmodule OrbitalDynamics.Timeline.ActivityProductDeliveryContext do
  @moduledoc false

  def build(activity, stable_id_pattern) do
    collection_ends_at_s = collection_ends_at_s(activity)
    planned_delivery_at_s = planned_delivery_at_s(activity)
    actual_delivery_at_s = actual_delivery_at_s(activity)
    max_latency_s = max_latency_s(activity)
    planned_latency_s = planned_latency_s(activity, collection_ends_at_s, planned_delivery_at_s)
    actual_latency_s = actual_latency_s(activity, collection_ends_at_s, actual_delivery_at_s)

    %{
      "collection_id" => first_value(activity, ["collection_id", "collection"]),
      "product_id" => first_value(activity, ["product_id", "data_product_id"]),
      "product_ids" =>
        first_value(activity, ["product_ids", "data_product_ids"])
        |> normalize_id_list(["id", "product_id", "data_product_id"], stable_id_pattern),
      "payload_id" => first_value(activity, ["payload_id", "payload"]),
      "instrument_id" => first_value(activity, ["instrument_id", "instrument"]),
      "data_volume_mb" =>
        first_number(activity, [
          "data_volume_mb",
          "planned_data_volume_mb",
          "estimated_data_volume_mb",
          "estimated_storage_mb",
          "estimated_downlink_mb"
        ]),
      "planned_data_volume_mb" => planned_data_volume_mb(activity),
      "actual_data_volume_mb" => actual_data_volume_mb(activity),
      "data_volume_delta_mb" =>
        delta(actual_data_volume_mb(activity), planned_data_volume_mb(activity)),
      "data_volume_completion_fraction" =>
        completion_fraction(actual_data_volume_mb(activity), planned_data_volume_mb(activity)),
      "estimated_data_volume_mb" =>
        first_number(activity, [
          "estimated_data_volume_mb",
          "data_volume_mb",
          "planned_data_volume_mb"
        ]),
      "estimated_storage_mb" =>
        first_number(activity, [
          "estimated_storage_mb",
          "data_volume_mb",
          "planned_data_volume_mb"
        ]),
      "estimated_downlink_mb" => first_number(activity, ["estimated_downlink_mb"]),
      "required_downlink_mb" => first_number(activity, ["required_downlink_mb"]),
      "collection_ends_at_s" => collection_ends_at_s,
      "planned_delivery_at_s" => planned_delivery_at_s,
      "actual_delivery_at_s" => actual_delivery_at_s,
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "actual_latency_s" => actual_latency_s,
      "latency_delta_s" => delta(actual_latency_s, planned_latency_s),
      "latency_margin_s" => delta(max_latency_s, actual_latency_s || planned_latency_s),
      "target_priority" => first_number(activity, ["target_priority"]),
      "target_priority_source" => first_scalar_string(activity, ["target_priority_source"]),
      "target_priority_objective_ids" =>
        first_value(activity, ["target_priority_objective_ids", "observation_objective_ids"])
        |> normalize_id_list(["id", "objective_id"], stable_id_pattern),
      "target_priority_objective_type" =>
        first_scalar_string(activity, [
          "target_priority_objective_type",
          "observation_objective_type"
        ])
    }
    |> compact_map()
  end

  defp collection_ends_at_s(activity) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.collection_ends_at_s(
      activity,
      &first_number/2
    )
  end

  defp planned_delivery_at_s(activity) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.planned_delivery_at_s(
      activity,
      &first_number/2
    )
  end

  defp actual_delivery_at_s(activity) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.actual_delivery_at_s(
      activity,
      &first_number/2
    )
  end

  defp max_latency_s(activity) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.max_latency_s(
      activity,
      &first_number/2
    )
  end

  defp planned_latency_s(activity, collection_ends_at_s, planned_delivery_at_s) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.planned_latency_s(
      activity,
      collection_ends_at_s,
      planned_delivery_at_s,
      &first_number/2,
      &delta/2
    )
  end

  defp actual_latency_s(activity, collection_ends_at_s, actual_delivery_at_s) do
    OrbitalDynamics.Timeline.ActivityDeliveryTimingPolicy.actual_latency_s(
      activity,
      collection_ends_at_s,
      actual_delivery_at_s,
      &first_number/2,
      &delta/2
    )
  end

  defp planned_data_volume_mb(activity) do
    first_number(activity, [
      "planned_data_volume_mb",
      "data_volume_mb",
      "estimated_data_volume_mb",
      "estimated_storage_mb",
      "estimated_downlink_mb"
    ])
  end

  defp actual_data_volume_mb(activity) do
    first_number(activity, [
      "actual_data_volume_mb",
      "actual_storage_mb",
      "actual_downlink_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  defp first_value(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_value(activity, keys)
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp normalize_id_list(value, map_keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityReferenceIdPolicy.normalize(
      value,
      map_keys,
      &OrbitalDynamics.Timeline.StableIdentifierPolicy.valid?(&1, stable_id_pattern)
    )
  end

  defp delta(replacement, source) do
    OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy.delta(replacement, source)
  end

  defp completion_fraction(actual, planned) do
    OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy.completion_fraction(actual, planned)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
