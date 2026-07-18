defmodule OrbitalDynamics.Timeline.ActivityOrientationContext do
  @moduledoc false

  def pointing(activity, stable_id_pattern) do
    %{
      "pointing_mode" => first_scalar_string(activity, ["pointing_mode", "attitude_mode"]),
      "pointing_target_id" =>
        first_stable_identifier(
          activity,
          ["pointing_target_id", "attitude_target_id"],
          stable_id_pattern
        ),
      "boresight_axis" => first_scalar_string(activity, ["boresight_axis", "sensor_axis"]),
      "off_nadir_angle_deg" => first_number(activity, ["off_nadir_angle_deg", "look_angle_deg"]),
      "slew_angle_deg" => first_number(activity, ["slew_angle_deg"]),
      "slew_rate_deg_s" => first_number(activity, ["slew_rate_deg_s"]),
      "pointing_error_deg" =>
        first_number(activity, ["pointing_error_deg", "attitude_error_deg"]),
      "pointing_status" => first_scalar_string(activity, ["pointing_status", "attitude_status"]),
      "pointing_model" => first_scalar_string(activity, ["pointing_model", "attitude_model"]),
      "pointing_source" => first_scalar_string(activity, ["pointing_source", "attitude_source"]),
      "pointing_confidence" =>
        first_number(activity, ["pointing_confidence", "attitude_confidence"])
    }
    |> compact_map()
  end

  def attitude(activity, stable_id_pattern) do
    %{
      "attitude_mode" => first_scalar_string(activity, ["attitude_mode"]),
      "attitude_target_id" =>
        first_stable_identifier(activity, ["attitude_target_id"], stable_id_pattern),
      "roll_deg" => first_number(activity, ["roll_deg"]),
      "pitch_deg" => first_number(activity, ["pitch_deg"]),
      "yaw_deg" => first_number(activity, ["yaw_deg"]),
      "attitude_error_deg" => first_number(activity, ["attitude_error_deg"]),
      "attitude_status" => first_scalar_string(activity, ["attitude_status"]),
      "attitude_model" => first_scalar_string(activity, ["attitude_model"]),
      "attitude_source" => first_scalar_string(activity, ["attitude_source"]),
      "attitude_confidence" => first_number(activity, ["attitude_confidence"])
    }
    |> compact_map()
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

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
