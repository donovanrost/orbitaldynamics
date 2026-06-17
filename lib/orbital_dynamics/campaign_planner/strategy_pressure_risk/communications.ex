defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.Communications do
  @moduledoc false

  def link_capacity_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &link_capacity_pressure_risk?/1)
  end

  def link_capacity_pressure_risk?(%{
        "type" => "downlink_completion_gap",
        "feedback_scope" => "link_capacity"
      }),
      do: true

  def link_capacity_pressure_risk?(_risk), do: false

  def contact_intent_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &contact_intent_pressure_risk?/1)
  end

  defp contact_intent_pressure_risk?(%{
         "type" => "downlink_completion_gap",
         "feedback_scope" => "contact_intent"
       }),
       do: true

  defp contact_intent_pressure_risk?(_risk), do: false

  def contact_contention_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &contact_contention_pressure_risk?/1)
  end

  defp contact_contention_pressure_risk?(%{
         "type" => "downlink_completion_gap",
         "feedback_scope" => scope
       })
       when scope in ["contact_contention", "contact_contention_resolution"],
       do: true

  defp contact_contention_pressure_risk?(_risk), do: false

  def contact_filter_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &contact_filter_pressure_risk?/1)
  end

  def contact_filter_pressure_risk?(%{
        "type" => "downlink_completion_gap",
        "feedback_scope" => "contact_filter"
      }),
      do: true

  def contact_filter_pressure_risk?(_risk), do: false
end
