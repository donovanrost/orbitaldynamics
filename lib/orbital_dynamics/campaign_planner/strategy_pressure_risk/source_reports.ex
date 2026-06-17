defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk.SourceReports do
  @moduledoc false

  def command_window_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &command_window_pressure_risk?/1)
  end

  defp command_window_pressure_risk?(%{"type" => "command_window_pressure"}), do: true
  defp command_window_pressure_risk?(_risk), do: false

  def objective_gap_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &objective_gap_pressure_risk?/1)
  end

  defp objective_gap_pressure_risk?(%{"type" => "objective_gap_pressure"}), do: true
  defp objective_gap_pressure_risk?(_risk), do: false

  def objective_gap_event_pressure_risk?(%{"feedback_scope" => scope})
      when scope in ["objective_satisfaction", "objective_tradeoff", "score_term"],
      do: true

  def objective_gap_event_pressure_risk?(_risk), do: false

  def timeline_feedback_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &timeline_feedback_pressure_risk?/1)
  end

  defp timeline_feedback_pressure_risk?(%{"type" => "timeline_feedback_pressure"}), do: true
  defp timeline_feedback_pressure_risk?(_risk), do: false

  def timeline_feedback_event_pressure_risk?(%{"feedback_scope" => "timeline_feedback"}),
    do: true

  def timeline_feedback_event_pressure_risk?(%{"feedback_source" => source})
      when is_binary(source) do
    String.contains?(source, "timeline_feedback_report")
  end

  def timeline_feedback_event_pressure_risk?(_risk), do: false

  def operational_timeline_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &operational_timeline_pressure_risk?/1)
  end

  defp operational_timeline_pressure_risk?(%{"type" => "operational_timeline_pressure"}),
    do: true

  defp operational_timeline_pressure_risk?(_risk), do: false

  def operational_timeline_event_pressure_risk?(%{"feedback_scope" => "operational_timeline"}),
    do: true

  def operational_timeline_event_pressure_risk?(%{"feedback_source" => source})
      when is_binary(source) do
    String.contains?(source, "operational_timeline_report")
  end

  def operational_timeline_event_pressure_risk?(_risk), do: false

  def maneuver_review_pressure_risk_count(risk_indicators) do
    Enum.count(risk_indicators, &maneuver_review_pressure_risk?/1)
  end

  defp maneuver_review_pressure_risk?(%{"type" => "maneuver_review_pressure"}), do: true
  defp maneuver_review_pressure_risk?(_risk), do: false
end
