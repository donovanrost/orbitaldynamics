defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.DiffReports do
  @moduledoc false

  def candidate_diff_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &candidate_diff_pressure_risk?/1)
  end

  defp candidate_diff_pressure_risk?(%{"type" => "candidate_diff_pressure"}), do: true
  defp candidate_diff_pressure_risk?(_risk), do: false

  def candidate_diff_event_pressure_risk?(%{"feedback_scope" => "candidate_diff"}), do: true
  def candidate_diff_event_pressure_risk?(%{"type" => "candidate_diff_replacement"}), do: true

  def candidate_diff_event_pressure_risk?(%{"feedback_source" => source})
      when is_binary(source) do
    String.contains?(source, "candidate_diff_report")
  end

  def candidate_diff_event_pressure_risk?(_risk), do: false

  def timeline_diff_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_diff_pressure_risk?/1)
  end

  defp timeline_diff_pressure_risk?(%{"type" => "timeline_diff_pressure"}), do: true
  defp timeline_diff_pressure_risk?(_risk), do: false

  def timeline_diff_event_pressure_risk?(%{"feedback_scope" => "timeline_diff"}), do: true
  def timeline_diff_event_pressure_risk?(%{"type" => "timeline_diff_pressure"}), do: true

  def timeline_diff_event_pressure_risk?(%{"feedback_source" => source})
      when is_binary(source) do
    String.contains?(source, "timeline_diff_report")
  end

  def timeline_diff_event_pressure_risk?(_risk), do: false
end
