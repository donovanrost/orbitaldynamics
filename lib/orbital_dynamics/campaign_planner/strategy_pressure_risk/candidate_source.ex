defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.CandidateSource do
  @moduledoc false

  def candidate_rejection_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &candidate_rejection_pressure_risk?/1)
  end

  def candidate_rejection_pressure_risk?(%{"feedback_scope" => "candidate_rejection"}),
    do: true

  def candidate_rejection_pressure_risk?(%{"type" => "candidate_rejection_pressure"}),
    do: true

  def candidate_rejection_pressure_risk?(_risk), do: false

  def provider_counteroffer_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &provider_counteroffer_pressure_risk?/1)
  end

  def provider_counteroffer_pressure_risk?(%{"feedback_scope" => "provider_counteroffer"}),
    do: true

  def provider_counteroffer_pressure_risk?(%{"type" => "provider_counteroffer_review"}),
    do: true

  def provider_counteroffer_pressure_risk?(_risk), do: false
end
