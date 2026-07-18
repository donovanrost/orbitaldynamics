defmodule OrbitalDynamics.Timeline.ActivityLinkContext do
  @moduledoc false

  def build(activity) do
    %{
      "link_protocol" => first_scalar_string(activity, ["link_protocol"]),
      "frequency_band" => first_scalar_string(activity, ["frequency_band", "rf_band"]),
      "modulation" => first_scalar_string(activity, ["modulation"]),
      "coding_scheme" => first_scalar_string(activity, ["coding_scheme"]),
      "polarization" => first_scalar_string(activity, ["polarization"]),
      "data_rate_mbps" => first_number(activity, ["data_rate_mbps"]),
      "downlink_rate_mbps" => first_number(activity, ["downlink_rate_mbps"]),
      "data_rate_mb_s" => first_number(activity, ["data_rate_mb_s"]),
      "downlink_rate_mb_s" => first_number(activity, ["downlink_rate_mb_s"]),
      "actual_data_rate_mbps" => first_number(activity, ["actual_data_rate_mbps"]),
      "actual_downlink_rate_mbps" => first_number(activity, ["actual_downlink_rate_mbps"]),
      "actual_data_rate_mb_s" => first_number(activity, ["actual_data_rate_mb_s"]),
      "actual_downlink_rate_mb_s" => first_number(activity, ["actual_downlink_rate_mb_s"]),
      "delivered_rate_mbps" => first_number(activity, ["delivered_rate_mbps"]),
      "received_rate_mbps" => first_number(activity, ["received_rate_mbps"]),
      "delivered_rate_mb_s" => first_number(activity, ["delivered_rate_mb_s"]),
      "received_rate_mb_s" => first_number(activity, ["received_rate_mb_s"]),
      "actual_duration_s" => first_number(activity, ["actual_duration_s"]),
      "actual_contact_duration_s" => first_number(activity, ["actual_contact_duration_s"]),
      "contact_duration_s" => first_number(activity, ["contact_duration_s"]),
      "link_margin_db" => first_number(activity, ["link_margin_db", "link_margin_d_b"]),
      "snr_db" => first_number(activity, ["snr_db"]),
      "eb_no_db" => first_number(activity, ["eb_no_db", "ebn0_db", "eb_no_d_b"]),
      "bit_error_rate" => first_number(activity, ["bit_error_rate", "ber"]),
      "packet_loss_rate" => first_number(activity, ["packet_loss_rate"]),
      "frame_loss_rate" => first_number(activity, ["frame_loss_rate"]),
      "carrier_lock" => first_boolean(activity, ["carrier_lock", "carrier_locked"]),
      "symbol_lock" => first_boolean(activity, ["symbol_lock", "symbol_locked"]),
      "link_quality_status" => first_scalar_string(activity, ["link_quality_status", "rf_status"])
    }
    |> compact_map()
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

  defp first_boolean(activity, keys) do
    OrbitalDynamics.Timeline.ActivityBooleanPolicy.first_boolean(activity, keys)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
