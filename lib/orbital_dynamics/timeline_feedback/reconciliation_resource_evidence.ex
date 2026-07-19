defmodule OrbitalDynamics.TimelineFeedback.ReconciliationResourceEvidence do
  @moduledoc false

  def context(planned, realized) do
    %{
      "fuel_margin" => realized_or_planned(realized, planned, "fuel_margin"),
      "power_margin" => realized_or_planned(realized, planned, "power_margin"),
      "storage_margin" => realized_or_planned(realized, planned, "storage_margin"),
      "downlink_margin" => realized_or_planned(realized, planned, "downlink_margin"),
      "battery_capacity_wh" => realized_or_planned(realized, planned, "battery_capacity_wh"),
      "battery_energy_used_wh" =>
        realized_or_planned(realized, planned, "battery_energy_used_wh"),
      "battery_energy_generated_wh" =>
        realized_or_planned(realized, planned, "battery_energy_generated_wh"),
      "battery_state_of_charge" =>
        realized_or_planned(realized, planned, "battery_state_of_charge"),
      "spacecraft_available" => realized_or_planned(realized, planned, "spacecraft_available"),
      "planned_spacecraft_available" => value(planned, "spacecraft_available"),
      "realized_spacecraft_available" => value(realized, "spacecraft_available"),
      "spacecraft_available_match_status" =>
        match_status(
          value(planned, "spacecraft_available"),
          value(realized, "spacecraft_available")
        ),
      "payload_available" => realized_or_planned(realized, planned, "payload_available"),
      "planned_payload_available" => value(planned, "payload_available"),
      "realized_payload_available" => value(realized, "payload_available"),
      "payload_available_match_status" =>
        match_status(value(planned, "payload_available"), value(realized, "payload_available")),
      "antenna_available" => realized_or_planned(realized, planned, "antenna_available"),
      "planned_antenna_available" => value(planned, "antenna_available"),
      "realized_antenna_available" => value(realized, "antenna_available"),
      "antenna_available_match_status" =>
        match_status(value(planned, "antenna_available"), value(realized, "antenna_available")),
      "degraded" => realized_or_planned(realized, planned, "degraded"),
      "planned_degraded" => value(planned, "degraded"),
      "realized_degraded" => value(realized, "degraded"),
      "degraded_match_status" =>
        match_status(value(planned, "degraded"), value(realized, "degraded")),
      "mode" => realized_or_planned(realized, planned, "mode"),
      "planned_mode" => value(planned, "mode"),
      "realized_mode" => value(realized, "mode"),
      "mode_match_status" => match_status(value(planned, "mode"), value(realized, "mode")),
      "incompatible_activity_types" =>
        realized_or_planned(realized, planned, "incompatible_activity_types"),
      "suppressed_activity_types" =>
        realized_or_planned(realized, planned, "suppressed_activity_types")
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

  defp match_status(planned, realized)
       when planned in [nil, "", []] and realized in [nil, "", []],
       do: nil

  defp match_status(planned, _realized) when planned in [nil, "", []], do: "realized_only"
  defp match_status(_planned, realized) when realized in [nil, "", []], do: "planned_only"
  defp match_status(value, value), do: "matched"
  defp match_status(_planned, _realized), do: "mismatch"
end
