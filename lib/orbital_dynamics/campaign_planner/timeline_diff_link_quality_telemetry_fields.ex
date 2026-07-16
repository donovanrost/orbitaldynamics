defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffLinkQualityTelemetryFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{ScalarValues, TimelineDiffFieldValues}

  def carrier_lock(row), do: carrier_lock(row, default_callbacks())

  def carrier_lock(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_boolean).(row, [
      "realized_carrier_lock",
      "replacement_realized_carrier_lock",
      ["replacement_activity_context", "realized_carrier_lock"],
      ["replacement_activity_context", "carrier_lock"],
      ["replacement_activity_context", "link", "carrier_lock"],
      ["replacement_activity_context", "communications", "carrier_lock"],
      "carrier_lock",
      "replacement_carrier_lock",
      "source_realized_carrier_lock",
      ["source_activity_context", "realized_carrier_lock"],
      ["source_activity_context", "carrier_lock"],
      ["source_activity_context", "link", "carrier_lock"],
      ["source_activity_context", "communications", "carrier_lock"]
    ])
  end

  def symbol_lock(row), do: symbol_lock(row, default_callbacks())

  def symbol_lock(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_boolean).(row, [
      "realized_symbol_lock",
      "replacement_realized_symbol_lock",
      ["replacement_activity_context", "realized_symbol_lock"],
      ["replacement_activity_context", "symbol_lock"],
      ["replacement_activity_context", "link", "symbol_lock"],
      ["replacement_activity_context", "communications", "symbol_lock"],
      "symbol_lock",
      "replacement_symbol_lock",
      "source_realized_symbol_lock",
      ["source_activity_context", "realized_symbol_lock"],
      ["source_activity_context", "symbol_lock"],
      ["source_activity_context", "link", "symbol_lock"],
      ["source_activity_context", "communications", "symbol_lock"]
    ])
  end

  def link_margin_db(row), do: link_margin_db(row, default_callbacks())

  def link_margin_db(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_link_margin_db",
      "replacement_realized_link_margin_db",
      ["replacement_activity_context", "realized_link_margin_db"],
      ["replacement_activity_context", "link_margin_db"],
      ["replacement_activity_context", "link", "link_margin_db"],
      ["replacement_activity_context", "communications", "link_margin_db"],
      "link_margin_db",
      "replacement_link_margin_db",
      "source_realized_link_margin_db",
      ["source_activity_context", "realized_link_margin_db"],
      ["source_activity_context", "link_margin_db"],
      ["source_activity_context", "link", "link_margin_db"],
      ["source_activity_context", "communications", "link_margin_db"]
    ])
  end

  def snr_db(row), do: snr_db(row, default_callbacks())

  def snr_db(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_snr_db",
      "replacement_realized_snr_db",
      ["replacement_activity_context", "realized_snr_db"],
      ["replacement_activity_context", "snr_db"],
      ["replacement_activity_context", "link", "snr_db"],
      ["replacement_activity_context", "communications", "snr_db"],
      "snr_db",
      "replacement_snr_db",
      "source_realized_snr_db",
      ["source_activity_context", "realized_snr_db"],
      ["source_activity_context", "snr_db"],
      ["source_activity_context", "link", "snr_db"],
      ["source_activity_context", "communications", "snr_db"]
    ])
  end

  def eb_no_db(row), do: eb_no_db(row, default_callbacks())

  def eb_no_db(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_eb_no_db",
      "replacement_realized_eb_no_db",
      ["replacement_activity_context", "realized_eb_no_db"],
      ["replacement_activity_context", "eb_no_db"],
      ["replacement_activity_context", "link", "eb_no_db"],
      ["replacement_activity_context", "communications", "eb_no_db"],
      "eb_no_db",
      "replacement_eb_no_db",
      "source_realized_eb_no_db",
      ["source_activity_context", "realized_eb_no_db"],
      ["source_activity_context", "eb_no_db"],
      ["source_activity_context", "link", "eb_no_db"],
      ["source_activity_context", "communications", "eb_no_db"]
    ])
  end

  def bit_error_rate(row), do: bit_error_rate(row, default_callbacks())

  def bit_error_rate(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_bit_error_rate",
      "replacement_realized_bit_error_rate",
      ["replacement_activity_context", "realized_bit_error_rate"],
      ["replacement_activity_context", "bit_error_rate"],
      ["replacement_activity_context", "link", "bit_error_rate"],
      ["replacement_activity_context", "communications", "bit_error_rate"],
      "bit_error_rate",
      "replacement_bit_error_rate",
      "source_realized_bit_error_rate",
      ["source_activity_context", "realized_bit_error_rate"],
      ["source_activity_context", "bit_error_rate"],
      ["source_activity_context", "link", "bit_error_rate"],
      ["source_activity_context", "communications", "bit_error_rate"]
    ])
  end

  def packet_loss_rate(row), do: packet_loss_rate(row, default_callbacks())

  def packet_loss_rate(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_packet_loss_rate",
      "replacement_realized_packet_loss_rate",
      ["replacement_activity_context", "realized_packet_loss_rate"],
      ["replacement_activity_context", "packet_loss_rate"],
      ["replacement_activity_context", "link", "packet_loss_rate"],
      ["replacement_activity_context", "communications", "packet_loss_rate"],
      "packet_loss_rate",
      "replacement_packet_loss_rate",
      "source_realized_packet_loss_rate",
      ["source_activity_context", "realized_packet_loss_rate"],
      ["source_activity_context", "packet_loss_rate"],
      ["source_activity_context", "link", "packet_loss_rate"],
      ["source_activity_context", "communications", "packet_loss_rate"]
    ])
  end

  def frame_loss_rate(row), do: frame_loss_rate(row, default_callbacks())

  def frame_loss_rate(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "realized_frame_loss_rate",
      "replacement_realized_frame_loss_rate",
      ["replacement_activity_context", "realized_frame_loss_rate"],
      ["replacement_activity_context", "frame_loss_rate"],
      ["replacement_activity_context", "link", "frame_loss_rate"],
      ["replacement_activity_context", "communications", "frame_loss_rate"],
      "frame_loss_rate",
      "replacement_frame_loss_rate",
      "source_realized_frame_loss_rate",
      ["source_activity_context", "realized_frame_loss_rate"],
      ["source_activity_context", "frame_loss_rate"],
      ["source_activity_context", "link", "frame_loss_rate"],
      ["source_activity_context", "communications", "frame_loss_rate"]
    ])
  end

  def link_quality_status(row), do: link_quality_status(row, default_callbacks())

  def link_quality_status(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_string).(row, [
      "realized_link_quality_status",
      "replacement_realized_link_quality_status",
      ["replacement_activity_context", "realized_link_quality_status"],
      ["replacement_activity_context", "link_quality_status"],
      ["replacement_activity_context", "link", "link_quality_status"],
      ["replacement_activity_context", "communications", "link_quality_status"],
      "link_quality_status",
      "replacement_link_quality_status",
      "source_realized_link_quality_status",
      ["source_activity_context", "realized_link_quality_status"],
      ["source_activity_context", "link_quality_status"],
      ["source_activity_context", "link", "link_quality_status"],
      ["source_activity_context", "communications", "link_quality_status"]
    ])
    |> callback!(callbacks, :normalized_status_token).()
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)

  defp default_callbacks do
    [
      timeline_diff_first_boolean: &TimelineDiffFieldValues.first_boolean/2,
      timeline_diff_first_number: &TimelineDiffFieldValues.first_number/2,
      timeline_diff_first_string: &TimelineDiffFieldValues.first_string/2,
      normalized_status_token: &ScalarValues.normalized_status_token/1
    ]
  end
end
