defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.ExecutionFeedback do
  @moduledoc false

  def execution_feedback_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &execution_feedback_pressure_risk?/1)
  end

  defp execution_feedback_pressure_risk?(%{"type" => type})
       when type in [
              "contact_success_rate_low",
              "observation_success_rate_low",
              "station_throughput_factor_low",
              "command_success_rate_low",
              "maneuver_success_rate_low",
              "maneuver_execution_uncertainty_high",
              "maneuver_execution_uncertainty_missing"
            ],
       do: true

  defp execution_feedback_pressure_risk?(_risk), do: false
end
