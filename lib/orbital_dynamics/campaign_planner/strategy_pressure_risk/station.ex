defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.Station do
  @moduledoc false

  def station_calendar_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &station_calendar_pressure_risk?/1)
  end

  def station_calendar_pressure_risk?(%{"feedback_scope" => "station_calendar"} = risk) do
    not station_reservation_expiration_pressure_risk?(risk)
  end

  def station_calendar_pressure_risk?(%{"type" => type} = risk)
      when type in [
             "ground_station_reserved",
             "ground_station_outage",
             "reduced_downlink_capacity"
           ],
      do: not station_reservation_expiration_pressure_risk?(risk)

  def station_calendar_pressure_risk?(_risk), do: false

  def station_reservation_expiration_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &station_reservation_expiration_pressure_risk?/1)
  end

  def station_reservation_expiration_pressure_risk?(risk) do
    station_reservation_expiration_pressure_status?(risk["station_reservation_expiration_status"])
  end

  defp station_reservation_expiration_pressure_status?(status)
       when status in ["expired", "missing"],
       do: true

  defp station_reservation_expiration_pressure_status?(_status), do: false
end
