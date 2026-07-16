defmodule OrbitalDynamics.Schema.LinkHandoffJsonSchema do
  @moduledoc false

  @string_fields [
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

  @number_fields [
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

  @boolean_fields [
    "carrier_lock",
    "planned_carrier_lock",
    "realized_carrier_lock",
    "symbol_lock",
    "planned_symbol_lock",
    "realized_symbol_lock"
  ]

  @probability_fields [
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

  def properties(opts) do
    probability_schema = Keyword.fetch!(opts, :probability_schema)

    @string_fields
    |> typed_fields("string")
    |> Map.merge(typed_fields(@number_fields, "number"))
    |> Map.merge(typed_fields(@boolean_fields, "boolean"))
    |> Map.merge(Map.new(@probability_fields, &{&1, probability_schema}))
  end

  defp typed_fields(fields, type) do
    Map.new(fields, &{&1, %{"type" => type}})
  end
end
