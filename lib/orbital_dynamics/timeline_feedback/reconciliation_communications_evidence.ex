defmodule OrbitalDynamics.TimelineFeedback.ReconciliationCommunicationsEvidence do
  @moduledoc false

  def context(planned, realized) do
    %{
      "data_rate_mbps" => realized_or_planned(realized, planned, "data_rate_mbps"),
      "planned_data_rate_mbps" => value(planned, "data_rate_mbps"),
      "realized_data_rate_mbps" => value(realized, "data_rate_mbps"),
      "data_rate_delta_mbps" =>
        delta(value(realized, "data_rate_mbps"), value(planned, "data_rate_mbps")),
      "link_margin_db" => realized_or_planned(realized, planned, "link_margin_db"),
      "planned_link_margin_db" => value(planned, "link_margin_db"),
      "realized_link_margin_db" => value(realized, "link_margin_db"),
      "link_margin_delta_db" =>
        delta(value(realized, "link_margin_db"), value(planned, "link_margin_db")),
      "snr_db" => realized_or_planned(realized, planned, "snr_db"),
      "planned_snr_db" => value(planned, "snr_db"),
      "realized_snr_db" => value(realized, "snr_db"),
      "snr_delta_db" => delta(value(realized, "snr_db"), value(planned, "snr_db")),
      "eb_no_db" => realized_or_planned(realized, planned, "eb_no_db"),
      "planned_eb_no_db" => value(planned, "eb_no_db"),
      "realized_eb_no_db" => value(realized, "eb_no_db"),
      "eb_no_delta_db" => delta(value(realized, "eb_no_db"), value(planned, "eb_no_db")),
      "bit_error_rate" => realized_or_planned(realized, planned, "bit_error_rate"),
      "planned_bit_error_rate" => value(planned, "bit_error_rate"),
      "realized_bit_error_rate" => value(realized, "bit_error_rate"),
      "packet_loss_rate" => realized_or_planned(realized, planned, "packet_loss_rate"),
      "planned_packet_loss_rate" => value(planned, "packet_loss_rate"),
      "realized_packet_loss_rate" => value(realized, "packet_loss_rate"),
      "frame_loss_rate" => realized_or_planned(realized, planned, "frame_loss_rate"),
      "planned_frame_loss_rate" => value(planned, "frame_loss_rate"),
      "realized_frame_loss_rate" => value(realized, "frame_loss_rate"),
      "carrier_lock" => realized_or_planned(realized, planned, "carrier_lock"),
      "planned_carrier_lock" => value(planned, "carrier_lock"),
      "realized_carrier_lock" => value(realized, "carrier_lock"),
      "symbol_lock" => realized_or_planned(realized, planned, "symbol_lock"),
      "planned_symbol_lock" => value(planned, "symbol_lock"),
      "realized_symbol_lock" => value(realized, "symbol_lock"),
      "link_quality_status" => realized_or_planned(realized, planned, "link_quality_status"),
      "planned_link_quality_status" => value(planned, "link_quality_status"),
      "realized_link_quality_status" => value(realized, "link_quality_status"),
      "command_authority_status" =>
        value(planned, "command_authority_status") ||
          value(realized, "command_authority_status"),
      "planned_command_authority_status" => value(planned, "command_authority_status"),
      "realized_command_authority_status" => value(realized, "command_authority_status"),
      "command_authority_status_match_status" =>
        match_status(
          value(planned, "command_authority_status"),
          value(realized, "command_authority_status")
        ),
      "required_authority" =>
        value(planned, "required_authority") || value(realized, "required_authority"),
      "planned_required_authority" => value(planned, "required_authority"),
      "realized_required_authority" => value(realized, "required_authority"),
      "required_authority_match_status" =>
        match_status(value(planned, "required_authority"), value(realized, "required_authority")),
      "command_safety_status" =>
        value(planned, "command_safety_status") || value(realized, "command_safety_status"),
      "planned_command_safety_status" => value(planned, "command_safety_status"),
      "realized_command_safety_status" => value(realized, "command_safety_status"),
      "command_safety_status_match_status" =>
        match_status(
          value(planned, "command_safety_status"),
          value(realized, "command_safety_status")
        ),
      "command_authorized" => realized_or_planned(realized, planned, "command_authorized"),
      "planned_command_authorized" => value(planned, "command_authorized"),
      "realized_command_authorized" => value(realized, "command_authorized"),
      "command_authorized_match_status" =>
        match_status(value(planned, "command_authorized"), value(realized, "command_authorized")),
      "command_safety_checked" =>
        realized_or_planned(realized, planned, "command_safety_checked"),
      "planned_command_safety_checked" => value(planned, "command_safety_checked"),
      "realized_command_safety_checked" => value(realized, "command_safety_checked"),
      "command_safety_checked_match_status" =>
        match_status(
          value(planned, "command_safety_checked"),
          value(realized, "command_safety_checked")
        )
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
