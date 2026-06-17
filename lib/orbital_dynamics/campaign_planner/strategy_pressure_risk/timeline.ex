defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.Timeline do
  @moduledoc false

  def timeline_integrity_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_integrity_pressure_risk?/1)
  end

  def timeline_integrity_pressure_risk?(%{"type" => "timeline_integrity_issue"}), do: true
  def timeline_integrity_pressure_risk?(_risk), do: false

  def timeline_dependency_impact_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_dependency_impact_pressure_risk?/1)
  end

  def timeline_dependency_impact_pressure_risk?(%{"type" => "timeline_dependency_impact"}),
    do: true

  def timeline_dependency_impact_pressure_risk?(_risk), do: false

  def timeline_publication_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_publication_pressure_risk?/1)
  end

  def timeline_publication_pressure_risk?(%{"type" => "timeline_publication_pressure"}),
    do: true

  def timeline_publication_pressure_risk?(_risk), do: false

  def timeline_transition_application_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_transition_application_pressure_risk?/1)
  end

  def timeline_transition_application_pressure_risk?(%{
        "type" => "timeline_transition_application_pressure"
      }),
      do: true

  def timeline_transition_application_pressure_risk?(_risk), do: false

  def timeline_activity_state_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_activity_state_pressure_risk?/1)
  end

  defp timeline_activity_state_pressure_risk?(%{
         "type" => "timeline_activity_lifecycle_state_review"
       }),
       do: true

  defp timeline_activity_state_pressure_risk?(_risk), do: false

  def timeline_lifecycle_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_lifecycle_pressure_risk?/1)
  end

  defp timeline_lifecycle_pressure_risk?(%{"type" => "timeline_lifecycle_state_review"}),
    do: true

  defp timeline_lifecycle_pressure_risk?(_risk), do: false

  def timeline_lifecycle_state_review_risk?(%{"type" => "timeline_lifecycle_state_review"}),
    do: true

  def timeline_lifecycle_state_review_risk?(_risk), do: false

  def timeline_activity_lifecycle_state_review_risk?(%{
        "type" => "timeline_activity_lifecycle_state_review"
      }),
      do: true

  def timeline_activity_lifecycle_state_review_risk?(_risk), do: false

  def timeline_precondition_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_precondition_pressure_risk?/1)
  end

  def timeline_precondition_pressure_risk?(%{"type" => "timeline_activity_precondition_review"}),
    do: true

  def timeline_precondition_pressure_risk?(_risk), do: false

  def timeline_preservation_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_preservation_pressure_risk?/1)
  end

  defp timeline_preservation_pressure_risk?(%{"type" => "timeline_preservation_review"}),
    do: true

  defp timeline_preservation_pressure_risk?(_risk), do: false

  def timeline_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_pressure_risk?/1)
  end

  defp timeline_pressure_risk?(_risk), do: false
end
