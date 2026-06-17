defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.BranchSignal
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.GovernancePressure
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.OperationalFeedback
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.ResourcePressure
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.ReviewPressure
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.StationDownlinkPressure
  alias OrbitalDynamics.CampaignPlanner.EventRiskIndicator.TimelinePressure

  def indicators(event) do
    case GovernancePressure.indicators(event) do
      [] -> timeline_or_local_indicators(event)
      indicators -> indicators
    end
  end

  defp timeline_or_local_indicators(event) do
    case TimelinePressure.indicators(event) do
      [] -> operational_feedback_or_local_indicators(event)
      indicators -> indicators
    end
  end

  defp operational_feedback_or_local_indicators(event) do
    case OperationalFeedback.indicators(event) do
      [] -> resource_pressure_or_local_indicators(event)
      indicators -> indicators
    end
  end

  defp resource_pressure_or_local_indicators(event) do
    case ResourcePressure.indicators(event) do
      [] -> station_downlink_or_local_indicators(event)
      indicators -> indicators
    end
  end

  defp station_downlink_or_local_indicators(event) do
    case StationDownlinkPressure.indicators(event) do
      [] -> review_pressure_or_local_indicators(event)
      indicators -> indicators
    end
  end

  defp review_pressure_or_local_indicators(event) do
    case ReviewPressure.indicators(event) do
      [] -> BranchSignal.indicators(event)
      indicators -> indicators
    end
  end
end
