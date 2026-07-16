defmodule OrbitalDynamics.Schema.HandoffFieldContracts do
  @moduledoc false

  def validate_observation_quality_fraction_fields(issues, path, row, callbacks) do
    [
      "cloud_cover_fraction",
      "planned_cloud_cover_fraction",
      "realized_cloud_cover_fraction",
      "blur_score",
      "planned_blur_score",
      "realized_blur_score"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_image_quality_score_fields(issues, path, row, callbacks) do
    [
      "image_quality_score",
      "planned_image_quality_score",
      "realized_image_quality_score"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_observation_quality_handoff_fields(issues, path, row, callbacks) do
    issues
    |> validate_observation_quality_fraction_fields(path, row, callbacks)
    |> validate_image_quality_score_fields(path, row, callbacks)
    |> expect_optional_number(callbacks, path, row, "image_quality_score_delta")
    |> expect_optional_number(callbacks, path, row, "cloud_cover_fraction_delta")
    |> expect_optional_number(callbacks, path, row, "blur_score_delta")
    |> expect_optional_type(callbacks, path, row, "image_quality_status", :binary)
    |> expect_optional_type(callbacks, path, row, "planned_image_quality_status", :binary)
    |> expect_optional_type(callbacks, path, row, "realized_image_quality_status", :binary)
    |> expect_optional_type(callbacks, path, row, "image_quality_status_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "image_quality_source", :binary)
  end

  def validate_feedback_maneuver_handoff_fields(issues, path, row, callbacks) do
    issues
    |> expect_optional_number(callbacks, path, row, "feedback_weight")
    |> expect_field_at_least(callbacks, path, row, "feedback_weight", 0.0)
    |> expect_optional_type(callbacks, path, row, "feedback_weight_source", :binary)
    |> expect_optional_type(callbacks, path, row, "maneuver_success", :boolean)
    |> expect_optional_type(callbacks, path, row, "maneuver_result", :binary)
    |> expect_optional_probability(callbacks, path, row, "maneuver_success_factor")
    |> expect_optional_type(callbacks, path, row, "maneuver_success_factor_source", :binary)
  end

  def validate_link_error_rate_fields(issues, path, row, callbacks) do
    [
      "bit_error_rate",
      "planned_bit_error_rate",
      "realized_bit_error_rate",
      "packet_loss_rate",
      "planned_packet_loss_rate",
      "realized_packet_loss_rate",
      "frame_loss_rate",
      "planned_frame_loss_rate",
      "realized_frame_loss_rate"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_link_handoff_fields(issues, path, row, callbacks) do
    issues
    |> validate_link_error_rate_fields(path, row, callbacks)
    |> validate_link_handoff_string_fields(path, row, callbacks)
    |> validate_link_handoff_number_fields(path, row, callbacks)
    |> validate_link_handoff_boolean_fields(path, row, callbacks)
  end

  def validate_link_handoff_string_fields(issues, path, row, callbacks) do
    [
      "link_protocol",
      "planned_link_protocol",
      "realized_link_protocol",
      "link_protocol_match_status",
      "frequency_band",
      "planned_frequency_band",
      "realized_frequency_band",
      "frequency_band_match_status",
      "modulation",
      "planned_modulation",
      "realized_modulation",
      "modulation_match_status",
      "coding_scheme",
      "planned_coding_scheme",
      "realized_coding_scheme",
      "coding_scheme_match_status",
      "polarization",
      "planned_polarization",
      "realized_polarization",
      "polarization_match_status",
      "link_quality_status",
      "planned_link_quality_status",
      "realized_link_quality_status"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_type(acc, callbacks, path, row, field, :binary)
    end)
  end

  def validate_link_handoff_number_fields(issues, path, row, callbacks) do
    [
      "data_rate_mbps",
      "downlink_rate_mbps",
      "data_rate_mb_s",
      "downlink_rate_mb_s",
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mbps",
      "received_rate_mbps",
      "delivered_rate_mb_s",
      "received_rate_mb_s",
      "actual_duration_s",
      "actual_contact_duration_s",
      "contact_duration_s",
      "planned_data_rate_mbps",
      "realized_data_rate_mbps",
      "data_rate_delta_mbps",
      "link_margin_db",
      "planned_link_margin_db",
      "realized_link_margin_db",
      "link_margin_delta_db",
      "snr_db",
      "planned_snr_db",
      "realized_snr_db",
      "snr_delta_db",
      "eb_no_db",
      "planned_eb_no_db",
      "realized_eb_no_db",
      "eb_no_delta_db"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_number(acc, callbacks, path, row, field)
    end)
  end

  def validate_link_handoff_boolean_fields(issues, path, row, callbacks) do
    [
      "carrier_lock",
      "planned_carrier_lock",
      "realized_carrier_lock",
      "symbol_lock",
      "planned_symbol_lock",
      "realized_symbol_lock"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_type(acc, callbacks, path, row, field, :boolean)
    end)
  end

  def validate_completion_fraction_fields(issues, path, row, callbacks) do
    ["throughput_completion_fraction", "completed_fraction"]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_station_capacity_fraction_fields(issues, path, row, callbacks) do
    ["capacity_fraction", "capacity_fraction_min", "capacity_fraction_max"]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_eclipse_overlap_fraction_fields(issues, path, row, callbacks) do
    [
      "eclipse_overlap_fraction",
      "planned_eclipse_overlap_fraction",
      "realized_eclipse_overlap_fraction"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  def validate_eclipse_lighting_handoff_fields(issues, path, row, callbacks) do
    issues
    |> validate_eclipse_overlap_fraction_fields(path, row, callbacks)
    |> expect_optional_number(callbacks, path, row, "eclipse_overlap_s")
    |> expect_optional_number(callbacks, path, row, "planned_eclipse_overlap_s")
    |> expect_optional_number(callbacks, path, row, "realized_eclipse_overlap_s")
    |> expect_optional_type(callbacks, path, row, "lighting_condition", :binary)
    |> expect_optional_type(callbacks, path, row, "planned_lighting_condition", :binary)
    |> expect_optional_type(callbacks, path, row, "realized_lighting_condition", :binary)
    |> expect_optional_type(callbacks, path, row, "lighting_condition_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "lighting_condition_detail", :binary)
    |> expect_optional_type(callbacks, path, row, "lighting_condition_model", :binary)
    |> expect_optional_type(callbacks, path, row, "lighting_detail_model", :binary)
    |> expect_optional_number_or_string(callbacks, path, row, "lighting_confidence")
  end

  def validate_thermal_handoff_fields(issues, path, row, callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, ["thermal_zone_id"])
    |> expect_optional_number(callbacks, path, row, "temperature_c")
    |> expect_optional_number(callbacks, path, row, "planned_temperature_c")
    |> expect_optional_number(callbacks, path, row, "actual_temperature_c")
    |> expect_optional_number(callbacks, path, row, "temperature_delta_c")
    |> expect_optional_number(callbacks, path, row, "min_operating_temperature_c")
    |> expect_optional_number(callbacks, path, row, "max_operating_temperature_c")
    |> expect_optional_number(callbacks, path, row, "thermal_margin_c")
    |> expect_optional_type(callbacks, path, row, "thermal_status", :binary)
    |> expect_optional_type(callbacks, path, row, "thermal_model", :binary)
    |> expect_optional_type(callbacks, path, row, "thermal_source", :binary)
    |> expect_optional_probability(callbacks, path, row, "thermal_confidence")
  end

  def validate_resource_availability_variance_fields(issues, path, row, callbacks) do
    issues
    |> expect_optional_type(callbacks, path, row, "spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "spacecraft_available_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_payload_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_payload_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "payload_available_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "antenna_available_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "degraded", :boolean)
    |> expect_optional_type(callbacks, path, row, "planned_degraded", :boolean)
    |> expect_optional_type(callbacks, path, row, "realized_degraded", :boolean)
    |> expect_optional_type(callbacks, path, row, "degraded_match_status", :binary)
    |> expect_optional_type(callbacks, path, row, "mode", :binary)
    |> expect_optional_type(callbacks, path, row, "planned_mode", :binary)
    |> expect_optional_type(callbacks, path, row, "realized_mode", :binary)
    |> expect_optional_type(callbacks, path, row, "mode_match_status", :binary)
  end

  defp expect_optional_probability(issues, callbacks, path, row, field) do
    apply(require_callback(callbacks, :expect_optional_probability), [issues, path, row, field])
  end

  defp expect_optional_number(issues, callbacks, path, row, field) do
    apply(require_callback(callbacks, :expect_optional_number), [issues, path, row, field])
  end

  defp expect_optional_type(issues, callbacks, path, row, field, type) do
    apply(require_callback(callbacks, :expect_optional_type), [issues, path, row, field, type])
  end

  defp expect_field_at_least(issues, callbacks, path, row, field, minimum) do
    apply(require_callback(callbacks, :expect_field_at_least), [
      issues,
      path,
      row,
      field,
      minimum
    ])
  end

  defp expect_optional_number_or_string(issues, callbacks, path, row, field) do
    apply(require_callback(callbacks, :expect_optional_number_or_string), [
      issues,
      path,
      row,
      field
    ])
  end

  defp validate_stable_ids(issues, callbacks, path, row, fields) do
    apply(require_callback(callbacks, :validate_stable_ids), [issues, path, row, fields])
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
