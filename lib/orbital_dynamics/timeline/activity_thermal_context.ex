defmodule OrbitalDynamics.Timeline.ActivityThermalContext do
  @moduledoc false

  def build(activity, stable_id_pattern) do
    planned_temperature_c = planned_temperature_c(activity)
    actual_temperature_c = actual_temperature_c(activity)

    observed_temperature_c =
      actual_temperature_c || planned_temperature_c || temperature_c(activity)

    %{
      "thermal_zone_id" =>
        first_stable_identifier(
          activity,
          ["thermal_zone_id", "thermal_component_id", "thermal_node_id"],
          stable_id_pattern
        ),
      "temperature_c" => temperature_c(activity),
      "planned_temperature_c" => planned_temperature_c,
      "actual_temperature_c" => actual_temperature_c,
      "temperature_delta_c" => delta(actual_temperature_c, planned_temperature_c),
      "min_operating_temperature_c" => min_operating_temperature_c(activity),
      "max_operating_temperature_c" => max_operating_temperature_c(activity),
      "thermal_margin_c" => thermal_margin_c(activity, observed_temperature_c),
      "thermal_status" => first_scalar_string(activity, ["thermal_status", "temperature_status"]),
      "thermal_model" => first_scalar_string(activity, ["thermal_model", "temperature_model"]),
      "thermal_source" => first_scalar_string(activity, ["thermal_source", "temperature_source"]),
      "thermal_confidence" =>
        first_number(activity, ["thermal_confidence", "temperature_confidence"])
    }
    |> compact_map()
  end

  defp temperature_c(activity) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.temperature_c(
      activity,
      &first_number/2
    )
  end

  defp planned_temperature_c(activity) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.planned_temperature_c(
      activity,
      &first_number/2
    )
  end

  defp actual_temperature_c(activity) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.actual_temperature_c(
      activity,
      &first_number/2
    )
  end

  defp min_operating_temperature_c(activity) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.min_operating_temperature_c(
      activity,
      &first_number/2
    )
  end

  defp max_operating_temperature_c(activity) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.max_operating_temperature_c(
      activity,
      &first_number/2
    )
  end

  defp thermal_margin_c(activity, observed_temperature_c) do
    OrbitalDynamics.Timeline.ActivityThermalMetricPolicy.thermal_margin_c(
      activity,
      observed_temperature_c,
      &first_number/2
    )
  end

  defp first_stable_identifier(activity, keys, stable_id_pattern) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_stable_identifier(
      activity,
      keys,
      &OrbitalDynamics.Timeline.StableIdentifierPolicy.valid?(&1, stable_id_pattern)
    )
  end

  defp first_scalar_string(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_scalar_string(activity, keys)
  end

  defp first_number(activity, keys) do
    OrbitalDynamics.Timeline.ActivityFieldValuePolicy.first_number(
      activity,
      keys,
      &OrbitalDynamics.Timeline.ActivityNumericValuePolicy.numeric_value/1
    )
  end

  defp delta(replacement, source) do
    OrbitalDynamics.Timeline.ActivityMetricCalculationPolicy.delta(replacement, source)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
