defmodule OrbitalDynamics.TimelineFeedback.ReconciliationObservationEvidence do
  @moduledoc false

  def context(planned, realized) do
    %{
      "boresight_axis" => value(planned, "boresight_axis") || value(realized, "boresight_axis"),
      "planned_off_nadir_angle_deg" => value(planned, "off_nadir_angle_deg"),
      "realized_off_nadir_angle_deg" => value(realized, "off_nadir_angle_deg"),
      "off_nadir_angle_delta_deg" =>
        delta(value(realized, "off_nadir_angle_deg"), value(planned, "off_nadir_angle_deg")),
      "planned_slew_angle_deg" => value(planned, "slew_angle_deg"),
      "realized_slew_angle_deg" => value(realized, "slew_angle_deg"),
      "slew_angle_delta_deg" =>
        delta(value(realized, "slew_angle_deg"), value(planned, "slew_angle_deg")),
      "pointing_error_deg" => realized_or_planned(realized, planned, "pointing_error_deg"),
      "pointing_status" => realized_or_planned(realized, planned, "pointing_status"),
      "pointing_model" => realized_or_planned(realized, planned, "pointing_model"),
      "pointing_source" => realized_or_planned(realized, planned, "pointing_source"),
      "pointing_confidence" => realized_or_planned(realized, planned, "pointing_confidence"),
      "planned_roll_deg" => value(planned, "roll_deg"),
      "realized_roll_deg" => value(realized, "roll_deg"),
      "roll_delta_deg" => delta(value(realized, "roll_deg"), value(planned, "roll_deg")),
      "planned_pitch_deg" => value(planned, "pitch_deg"),
      "realized_pitch_deg" => value(realized, "pitch_deg"),
      "pitch_delta_deg" => delta(value(realized, "pitch_deg"), value(planned, "pitch_deg")),
      "planned_yaw_deg" => value(planned, "yaw_deg"),
      "realized_yaw_deg" => value(realized, "yaw_deg"),
      "yaw_delta_deg" => delta(value(realized, "yaw_deg"), value(planned, "yaw_deg")),
      "attitude_error_deg" => realized_or_planned(realized, planned, "attitude_error_deg"),
      "attitude_status" => realized_or_planned(realized, planned, "attitude_status"),
      "attitude_model" => realized_or_planned(realized, planned, "attitude_model"),
      "attitude_source" => realized_or_planned(realized, planned, "attitude_source"),
      "attitude_confidence" => realized_or_planned(realized, planned, "attitude_confidence"),
      "eclipse_overlap_fraction" =>
        realized_or_planned(realized, planned, "eclipse_overlap_fraction"),
      "planned_eclipse_overlap_fraction" => value(planned, "eclipse_overlap_fraction"),
      "realized_eclipse_overlap_fraction" => value(realized, "eclipse_overlap_fraction"),
      "eclipse_overlap_s" => realized_or_planned(realized, planned, "eclipse_overlap_s"),
      "planned_eclipse_overlap_s" => value(planned, "eclipse_overlap_s"),
      "realized_eclipse_overlap_s" => value(realized, "eclipse_overlap_s"),
      "lighting_condition" =>
        value(planned, "lighting_condition") || value(realized, "lighting_condition"),
      "planned_lighting_condition" => value(planned, "lighting_condition"),
      "realized_lighting_condition" => value(realized, "lighting_condition"),
      "lighting_condition_match_status" =>
        match_status(value(planned, "lighting_condition"), value(realized, "lighting_condition")),
      "lighting_condition_detail" =>
        realized_or_planned(realized, planned, "lighting_condition_detail"),
      "lighting_condition_model" =>
        realized_or_planned(realized, planned, "lighting_condition_model"),
      "lighting_detail_model" => realized_or_planned(realized, planned, "lighting_detail_model"),
      "lighting_confidence" => realized_or_planned(realized, planned, "lighting_confidence"),
      "image_quality_score" => realized_or_planned(realized, planned, "image_quality_score"),
      "planned_image_quality_score" => value(planned, "image_quality_score"),
      "realized_image_quality_score" => value(realized, "image_quality_score"),
      "image_quality_score_delta" =>
        delta(value(realized, "image_quality_score"), value(planned, "image_quality_score")),
      "image_quality_status" => realized_or_planned(realized, planned, "image_quality_status"),
      "planned_image_quality_status" => value(planned, "image_quality_status"),
      "realized_image_quality_status" => value(realized, "image_quality_status"),
      "image_quality_status_match_status" =>
        match_status(
          value(planned, "image_quality_status"),
          value(realized, "image_quality_status")
        ),
      "image_quality_source" => realized_or_planned(realized, planned, "image_quality_source"),
      "cloud_cover_fraction" => realized_or_planned(realized, planned, "cloud_cover_fraction"),
      "planned_cloud_cover_fraction" => value(planned, "cloud_cover_fraction"),
      "realized_cloud_cover_fraction" => value(realized, "cloud_cover_fraction"),
      "cloud_cover_fraction_delta" =>
        delta(value(realized, "cloud_cover_fraction"), value(planned, "cloud_cover_fraction")),
      "blur_score" => realized_or_planned(realized, planned, "blur_score"),
      "planned_blur_score" => value(planned, "blur_score"),
      "realized_blur_score" => value(realized, "blur_score"),
      "blur_score_delta" => delta(value(realized, "blur_score"), value(planned, "blur_score")),
      "thermal_zone_id" =>
        value(planned, "thermal_zone_id") || value(realized, "thermal_zone_id"),
      "planned_temperature_c" => value(planned, "planned_temperature_c"),
      "actual_temperature_c" => value(realized, "actual_temperature_c"),
      "temperature_delta_c" =>
        delta(value(realized, "actual_temperature_c"), value(planned, "planned_temperature_c")),
      "min_operating_temperature_c" =>
        realized_or_planned(realized, planned, "min_operating_temperature_c"),
      "max_operating_temperature_c" =>
        realized_or_planned(realized, planned, "max_operating_temperature_c"),
      "thermal_margin_c" => realized_or_planned(realized, planned, "thermal_margin_c"),
      "thermal_status" => realized_or_planned(realized, planned, "thermal_status"),
      "thermal_model" => realized_or_planned(realized, planned, "thermal_model"),
      "thermal_source" => realized_or_planned(realized, planned, "thermal_source"),
      "thermal_confidence" => realized_or_planned(realized, planned, "thermal_confidence")
    }
  end

  defp realized_or_planned(realized, planned, field) do
    case value(realized, field) do
      nil -> value(planned, field)
      value -> value
    end
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)

  defp delta(realized, planned) when is_number(realized) and is_number(planned),
    do: realized - planned

  defp delta(_realized, _planned), do: nil

  defp match_status(planned, realized)
       when planned in [nil, "", []] and realized in [nil, "", []],
       do: nil

  defp match_status(planned, _realized) when planned in [nil, "", []], do: "realized_only"
  defp match_status(_planned, realized) when realized in [nil, "", []], do: "planned_only"
  defp match_status(value, value), do: "matched"
  defp match_status(_planned, _realized), do: "mismatch"
end
