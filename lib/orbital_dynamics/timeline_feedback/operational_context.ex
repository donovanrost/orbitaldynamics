defmodule OrbitalDynamics.TimelineFeedback.OperationalContext do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.{
    ArtifactValue,
    RealizedIdentity,
    SuccessFactor,
    Throughput
  }

  def build(activity, stable_id_pattern) do
    activity
    |> resource_context()
    |> Map.merge(pointing_context(activity, stable_id_pattern))
    |> Map.merge(attitude_context(activity, stable_id_pattern))
    |> Map.merge(command_authority_context(activity))
    |> Map.merge(lighting_context(activity))
    |> Map.merge(observation_quality_context(activity))
  end

  defp resource_context(activity) do
    %{
      "fuel_margin" => first_number(activity, ["fuel_margin"]),
      "power_margin" => resource_power_margin(activity),
      "storage_margin" => first_number(activity, ["storage_margin"]),
      "downlink_margin" =>
        first_number(activity, ["downlink_margin", "downlink_capacity_margin"]),
      "battery_capacity_wh" => first_number(activity, ["battery_capacity_wh"]),
      "battery_energy_used_wh" => first_number(activity, ["battery_energy_used_wh"]),
      "battery_energy_generated_wh" => battery_energy_generated_wh(activity),
      "battery_state_of_charge" => first_number(activity, ["battery_state_of_charge"]),
      "spacecraft_available" =>
        first_boolean(activity, [
          "spacecraft_available",
          "spacecraft_availability",
          ["metadata", "spacecraft_available"],
          ["metadata", "spacecraft_availability"]
        ]),
      "payload_available" =>
        first_boolean(activity, [
          "payload_available",
          "payload_available?",
          ["metadata", "payload_available"],
          ["metadata", "payload_available?"]
        ]),
      "antenna_available" =>
        first_boolean(activity, [
          "antenna_available",
          "antenna_available?",
          ["metadata", "antenna_available"],
          ["metadata", "antenna_available?"]
        ]),
      "degraded" =>
        first_boolean(activity, [
          "degraded",
          "degraded?",
          ["metadata", "degraded"],
          ["metadata", "degraded?"]
        ]),
      "mode" => first_string(activity, ["mode"]),
      "incompatible_activity_types" =>
        first_value(activity, ["incompatible_activity_types"])
        |> normalize_string_list(),
      "suppressed_activity_types" =>
        first_value(activity, ["suppressed_activity_types"])
        |> normalize_string_list()
    }
    |> compact_map()
  end

  defp pointing_context(activity, stable_id_pattern) do
    %{
      "pointing_mode" => first_string(activity, ["pointing_mode", "attitude_mode"]),
      "pointing_target_id" =>
        first_identifier(
          activity,
          ["pointing_target_id", "attitude_target_id"],
          stable_id_pattern
        ),
      "boresight_axis" => first_string(activity, ["boresight_axis", "sensor_axis"]),
      "off_nadir_angle_deg" => first_number(activity, ["off_nadir_angle_deg", "look_angle_deg"]),
      "slew_angle_deg" => first_number(activity, ["slew_angle_deg"]),
      "slew_rate_deg_s" => first_number(activity, ["slew_rate_deg_s"]),
      "pointing_error_deg" =>
        first_number(activity, ["pointing_error_deg", "attitude_error_deg"]),
      "pointing_status" => first_string(activity, ["pointing_status", "attitude_status"]),
      "pointing_model" => first_string(activity, ["pointing_model", "attitude_model"]),
      "pointing_source" => first_string(activity, ["pointing_source", "attitude_source"]),
      "pointing_confidence" =>
        first_number(activity, ["pointing_confidence", "attitude_confidence"])
    }
    |> compact_map()
  end

  defp attitude_context(activity, stable_id_pattern) do
    %{
      "attitude_mode" => first_string(activity, ["attitude_mode"]),
      "attitude_target_id" =>
        first_identifier(activity, ["attitude_target_id"], stable_id_pattern),
      "roll_deg" => first_number(activity, ["roll_deg"]),
      "pitch_deg" => first_number(activity, ["pitch_deg"]),
      "yaw_deg" => first_number(activity, ["yaw_deg"]),
      "attitude_error_deg" => first_number(activity, ["attitude_error_deg"]),
      "attitude_status" => first_string(activity, ["attitude_status"]),
      "attitude_model" => first_string(activity, ["attitude_model"]),
      "attitude_source" => first_string(activity, ["attitude_source"]),
      "attitude_confidence" => first_number(activity, ["attitude_confidence"])
    }
    |> compact_map()
  end

  defp command_authority_context(activity) do
    %{
      "command_authority_status" =>
        first_string(activity, [
          "command_authority_status",
          "authority_status",
          ["metadata", "command_authority_status"],
          ["metadata", "authority_status"]
        ]),
      "required_authority" =>
        first_string(activity, [
          "required_authority",
          "required_escalation_authority",
          ["metadata", "required_authority"],
          ["metadata", "required_escalation_authority"]
        ]),
      "command_safety_status" =>
        first_string(activity, [
          "command_safety_status",
          "safety_status",
          ["metadata", "command_safety_status"],
          ["metadata", "safety_status"]
        ]),
      "command_authorized" =>
        first_boolean(activity, [
          "command_authorized",
          "command_authorized?",
          "authority_granted",
          ["metadata", "command_authorized"],
          ["metadata", "command_authorized?"],
          ["metadata", "authority_granted"]
        ]),
      "command_safety_checked" =>
        first_boolean(activity, [
          "command_safety_checked",
          "command_safety_checked?",
          "safety_checked",
          ["metadata", "command_safety_checked"],
          ["metadata", "command_safety_checked?"],
          ["metadata", "safety_checked"]
        ])
    }
    |> compact_map()
  end

  defp lighting_context(activity) do
    %{
      "eclipse_overlap_fraction" =>
        first_number(activity, [
          "eclipse_overlap_fraction",
          "eclipse_fraction",
          "eclipse_fraction_of_activity"
        ]),
      "eclipse_overlap_s" => first_number(activity, ["eclipse_overlap_s", "eclipse_duration_s"]),
      "lighting_condition" =>
        first_string(activity, ["lighting_condition", "illumination_condition"]),
      "lighting_condition_detail" =>
        first_string(activity, ["lighting_condition_detail", "illumination_detail"]),
      "lighting_condition_model" =>
        first_string(activity, ["lighting_condition_model", "illumination_model"]),
      "lighting_detail_model" =>
        first_string(activity, ["lighting_detail_model", "illumination_detail_model"]),
      "lighting_confidence" =>
        first_number(activity, ["lighting_confidence", "illumination_confidence"])
    }
    |> compact_map()
  end

  defp observation_quality_context(activity) do
    %{
      "image_quality_score" =>
        first_number(activity, [
          "image_quality_score",
          "product_quality_score",
          "quality_score",
          ["metadata", "image_quality_score"],
          ["metadata", "product_quality_score"],
          ["metadata", "quality_score"]
        ]),
      "image_quality_status" =>
        first_string(activity, [
          "image_quality_status",
          "product_quality_status",
          "quality_status"
        ]),
      "image_quality_source" =>
        first_string(activity, [
          "image_quality_source",
          "product_quality_source",
          "quality_source"
        ]),
      "cloud_cover_fraction" =>
        first_unit_interval_number(activity, [
          "cloud_cover_fraction",
          "cloud_fraction",
          "cloud_cover",
          ["metadata", "cloud_cover_fraction"],
          ["metadata", "cloud_fraction"],
          ["metadata", "cloud_cover"]
        ]),
      "blur_score" =>
        first_unit_interval_number(activity, [
          "blur_score",
          "image_blur_score",
          "sharpness_loss_fraction",
          ["metadata", "blur_score"],
          ["metadata", "image_blur_score"],
          ["metadata", "sharpness_loss_fraction"]
        ])
    }
    |> compact_map()
  end

  defp resource_power_margin(activity) do
    first_number(activity, ["power_margin"]) ||
      first_number(activity, ["battery_state_of_charge"])
  end

  defp battery_energy_generated_wh(activity) do
    first_number(activity, [
      "battery_energy_generated_wh",
      "energy_generated_wh",
      "estimated_energy_generated_wh",
      "estimated_battery_energy_generated_wh",
      "planned_energy_generated_wh",
      ["metadata", "battery_energy_generated_wh"],
      ["metadata", "energy_generated_wh"],
      ["metadata", "estimated_energy_generated_wh"],
      ["metadata", "estimated_battery_energy_generated_wh"],
      ["metadata", "planned_energy_generated_wh"]
    ])
  end

  defp first_boolean(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      value =
        case key do
          path when is_list(path) -> get_in(map, path)
          key -> first_value(map, [key])
        end

      case ArtifactValue.boolean_value(value) do
        value when is_boolean(value) -> {:halt, value}
        nil -> {:cont, nil}
      end
    end)
  end

  defp first_string(map, keys) do
    Enum.find_value(keys, fn key ->
      case first_value(map, [key]) |> ArtifactValue.stringify_scalar() do
        value when value in [nil, ""] -> nil
        value -> value
      end
    end)
  end

  defp normalize_string_list(nil), do: nil

  defp normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&ArtifactValue.stringify_scalar/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp normalize_string_list(value), do: normalize_string_list([value])

  defp first_identifier(map, keys, stable_id_pattern),
    do: RealizedIdentity.first_identifier(map, keys, stable_id_pattern)

  defp first_value(map, keys), do: RealizedIdentity.first_value(map, keys)
  defp first_number(map, keys), do: Throughput.first_number(map, keys)

  defp first_unit_interval_number(activity, fields),
    do: SuccessFactor.first_unit_interval_number(activity, fields)

  defp compact_map(map), do: ArtifactValue.compact_map(map)
end
