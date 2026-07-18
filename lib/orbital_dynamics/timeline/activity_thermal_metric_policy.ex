defmodule OrbitalDynamics.Timeline.ActivityThermalMetricPolicy do
  @moduledoc false

  def temperature_c(activity, first_number) do
    first_number.(activity, ["temperature_c", "temp_c"])
  end

  def planned_temperature_c(activity, first_number) do
    first_number.(activity, [
      "planned_temperature_c",
      "planned_temp_c",
      "predicted_temperature_c",
      "estimated_temperature_c"
    ])
  end

  def actual_temperature_c(activity, first_number) do
    first_number.(activity, [
      "actual_temperature_c",
      "actual_temp_c",
      "measured_temperature_c",
      "measured_temp_c"
    ])
  end

  def min_operating_temperature_c(activity, first_number) do
    first_number.(activity, [
      "min_operating_temperature_c",
      "minimum_operating_temperature_c",
      "min_temperature_c"
    ])
  end

  def max_operating_temperature_c(activity, first_number) do
    first_number.(activity, [
      "max_operating_temperature_c",
      "maximum_operating_temperature_c",
      "max_temperature_c"
    ])
  end

  def thermal_margin_c(activity, observed_temperature_c, first_number) do
    first_number.(activity, ["thermal_margin_c", "temperature_margin_c"]) ||
      derived_thermal_margin_c(
        observed_temperature_c,
        min_operating_temperature_c(activity, first_number),
        max_operating_temperature_c(activity, first_number)
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
end
