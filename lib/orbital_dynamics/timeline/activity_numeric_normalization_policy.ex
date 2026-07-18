defmodule OrbitalDynamics.Timeline.ActivityNumericNormalizationPolicy do
  @moduledoc false

  @numeric_activity_fields ~w(
    actual_data_volume_mb
    actual_volume_mb
    actual_data_volume_shortfall_mb
    actual_delivery_at_s
    actual_downlink_at_s
    actual_downlink_mb
    actual_latency_s
    actual_storage_mb
    actual_throughput_mb
    attitude_confidence
    attitude_error_deg
    battery_capacity_wh
    battery_energy_used_wh
    battery_energy_generated_wh
    battery_state_of_charge
    bit_error_rate
    blur_score
    candidate_downlink_mb
    capacity_fraction
    capacity_pack_capacity_fraction
    cloud_cover_fraction
    collection_end_s
    collection_ends_at_s
    data_rate_mbps
    downlink_rate_mbps
    data_rate_mb_s
    downlink_rate_mb_s
    actual_data_rate_mbps
    actual_downlink_rate_mbps
    actual_data_rate_mb_s
    actual_downlink_rate_mb_s
    delivered_rate_mbps
    received_rate_mbps
    delivered_rate_mb_s
    received_rate_mb_s
    actual_duration_s
    actual_contact_duration_s
    contact_duration_s
    data_volume_completion_fraction
    data_volume_delta_mb
    data_volume_mb
    data_volume_shortfall_mb
    delivered_at_s
    delivered_data_mb
    delivered_data_volume_mb
    delivered_throughput_mb
    downlink_completion_ratio
    downlink_margin
    eb_no_d_b
    eb_no_db
    ebn0_db
    eclipse_overlap_fraction
    eclipse_overlap_s
    estimated_data_volume_mb
    estimated_downlink_mb
    estimated_storage_mb
    estimated_throughput_mb
    frame_loss_rate
    fuel_margin
    image_quality_score
    link_margin_d_b
    link_margin_db
    look_angle_deg
    max_latency_s
    observation_ends_at_s
    observed_ends_at_s
    off_nadir_angle_deg
    packet_loss_rate
    pitch_deg
    planned_data_volume_mb
    planned_volume_mb
    planned_delivered_at_s
    planned_delivery_at_s
    planned_downlink_at_s
    planned_estimated_throughput_mb
    planned_latency_s
    pointing_confidence
    pointing_error_deg
    power_margin
    received_at_s
    received_data_mb
    received_data_volume_mb
    received_throughput_mb
    required_downlink_mb
    required_volume_mb
    required_data_volume_mb
    required_latency_s
    required_data_volume_gap_mb
    roll_deg
    selected_downlink_mb
    selected_downlink_shortfall_mb
    selected_data_volume_mb
    selected_volume_mb
    selected_data_volume_shortfall_mb
    slew_angle_deg
    slew_rate_deg_s
    snr_db
    station_capacity_fraction
    station_reservation_expires_at_s
    storage_margin
    target_downlink_mb
    target_latency_s
    target_volume_mb
    target_data_volume_mb
    min_downlink_mb
    temperature_c
    planned_temperature_c
    actual_temperature_c
    min_operating_temperature_c
    max_operating_temperature_c
    temperature_delta_c
    thermal_confidence
    thermal_margin_c
    throughput_completion_fraction
    throughput_delta_mb
    yaw_deg
  )

  def normalize_time(activity, canonical_key, alternate_key, numeric_value) do
    canonical_value = numeric_value.(Map.get(activity, canonical_key))
    alternate_value = numeric_value.(Map.get(activity, alternate_key))

    cond do
      is_number(canonical_value) -> Map.put(activity, canonical_key, canonical_value)
      is_number(alternate_value) -> Map.put(activity, canonical_key, alternate_value)
      true -> activity
    end
  end

  def normalize(activity, numeric_value) do
    Enum.reduce(@numeric_activity_fields, activity, fn field, acc ->
      normalize_optional_number_field(acc, field, numeric_value)
    end)
  end

  defp normalize_optional_number_field(%{} = activity, field, numeric_value) do
    case Map.fetch(activity, field) do
      {:ok, value} ->
        case numeric_value.(value) do
          nil -> Map.delete(activity, field)
          number -> Map.put(activity, field, number)
        end

      :error ->
        activity
    end
  end
end
