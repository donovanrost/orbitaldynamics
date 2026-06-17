defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.Resources do
  @moduledoc false

  def storage_downlink_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &storage_downlink_pressure_risk?/1)
  end

  defp storage_downlink_pressure_risk?(%{"type" => type})
       when type in [
              "storage_margin_low",
              "downlink_margin_low",
              "storage_overflow",
              "downlink_shortfall"
            ],
       do: true

  defp storage_downlink_pressure_risk?(_risk), do: false

  def resource_projection_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &resource_projection_pressure_risk?/1)
  end

  defp resource_projection_pressure_risk?(%{
         "type" => "downlink_completion_gap",
         "feedback_scope" => "resource_projection"
       }),
       do: true

  defp resource_projection_pressure_risk?(_risk), do: false

  def resource_filter_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &resource_filter_pressure_risk?/1)
  end

  defp resource_filter_pressure_risk?(%{"feedback_scope" => "resource_filter"}), do: true
  defp resource_filter_pressure_risk?(_risk), do: false

  def resource_margin_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &resource_margin_pressure_risk?/1)
  end

  defp resource_margin_pressure_risk?(%{"feedback_scope" => "resource_filter"}), do: false

  defp resource_margin_pressure_risk?(%{"type" => type})
       when type in [
              "fuel_margin_low",
              "power_margin_low",
              "thermal_margin_c_low"
            ],
       do: true

  defp resource_margin_pressure_risk?(_risk), do: false

  def battery_depletion_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &battery_depletion_pressure_risk?/1)
  end

  defp battery_depletion_pressure_risk?(%{"type" => "battery_depletion"}), do: true
  defp battery_depletion_pressure_risk?(_risk), do: false

  def relay_data_path_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &relay_data_path_pressure_risk?/1)
  end

  defp relay_data_path_pressure_risk?(%{"type" => "relay_data_path_pressure"}), do: true
  defp relay_data_path_pressure_risk?(_risk), do: false
end
