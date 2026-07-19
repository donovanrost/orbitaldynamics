defmodule OrbitalDynamics.TimelineFeedback.ThermalContext do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{ArtifactValue, RealizedIdentity, Throughput}

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def build(activity) do
    planned_temperature_c = planned_temperature_c(activity)
    actual_temperature_c = actual_temperature_c(activity)

    observed_temperature_c =
      actual_temperature_c || planned_temperature_c || temperature_c(activity)

    %{
      "thermal_zone_id" =>
        RealizedIdentity.first_identifier(
          activity,
          ["thermal_zone_id", "thermal_component_id", "thermal_node_id"],
          @stable_id_pattern
        ),
      "temperature_c" => temperature_c(activity),
      "planned_temperature_c" => planned_temperature_c,
      "actual_temperature_c" => actual_temperature_c,
      "temperature_delta_c" => delta(actual_temperature_c, planned_temperature_c),
      "min_operating_temperature_c" => min_operating_temperature_c(activity),
      "max_operating_temperature_c" => max_operating_temperature_c(activity),
      "thermal_margin_c" => thermal_margin_c(activity, observed_temperature_c),
      "thermal_status" => first_string(activity, ["thermal_status", "temperature_status"]),
      "thermal_model" => first_string(activity, ["thermal_model", "temperature_model"]),
      "thermal_source" => first_string(activity, ["thermal_source", "temperature_source"]),
      "thermal_confidence" =>
        Throughput.first_number(activity, ["thermal_confidence", "temperature_confidence"])
    }
    |> ArtifactValue.compact_map()
  end

  defp temperature_c(activity) do
    Throughput.first_number(activity, ["temperature_c", "temp_c"])
  end

  defp planned_temperature_c(activity) do
    Throughput.first_number(activity, [
      "planned_temperature_c",
      "planned_temp_c",
      "predicted_temperature_c",
      "estimated_temperature_c"
    ])
  end

  defp actual_temperature_c(activity) do
    Throughput.first_number(activity, [
      "actual_temperature_c",
      "actual_temp_c",
      "measured_temperature_c",
      "measured_temp_c"
    ])
  end

  defp min_operating_temperature_c(activity) do
    Throughput.first_number(activity, [
      "min_operating_temperature_c",
      "minimum_operating_temperature_c",
      "min_temperature_c"
    ])
  end

  defp max_operating_temperature_c(activity) do
    Throughput.first_number(activity, [
      "max_operating_temperature_c",
      "maximum_operating_temperature_c",
      "max_temperature_c"
    ])
  end

  defp thermal_margin_c(activity, observed_temperature_c) do
    Throughput.first_number(activity, ["thermal_margin_c", "temperature_margin_c"]) ||
      derived_thermal_margin_c(
        observed_temperature_c,
        min_operating_temperature_c(activity),
        max_operating_temperature_c(activity)
      )
  end

  defp derived_thermal_margin_c(temperature_c, min_c, max_c)
       when is_number(temperature_c) and is_number(min_c) and is_number(max_c) do
    min(temperature_c - min_c, max_c - temperature_c)
  end

  defp derived_thermal_margin_c(temperature_c, nil, max_c)
       when is_number(temperature_c) and is_number(max_c),
       do: max_c - temperature_c

  defp derived_thermal_margin_c(temperature_c, min_c, nil)
       when is_number(temperature_c) and is_number(min_c),
       do: temperature_c - min_c

  defp derived_thermal_margin_c(_temperature_c, _min_c, _max_c), do: nil

  defp first_string(map, keys) do
    Enum.find_value(keys, fn key ->
      case RealizedIdentity.first_value(map, [key]) |> ArtifactValue.stringify_scalar() do
        value when value in [nil, ""] -> nil
        value -> value
      end
    end)
  end

  defp delta(actual, planned) when is_number(actual) and is_number(planned),
    do: actual - planned

  defp delta(_actual, _planned), do: nil
end
