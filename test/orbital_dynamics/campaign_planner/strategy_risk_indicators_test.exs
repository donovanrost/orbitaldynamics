defmodule OrbitalDynamics.CampaignPlanner.StrategyRiskIndicatorsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.StrategyRiskIndicators
  alias OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthority

  test "metadata-only evidence warnings do not become scored operational risks" do
    risks =
      StrategyRiskIndicators.build(
        %{"events" => []},
        %{"warnings" => [AcceptedStateEvidenceAuthority.warning_message(), "contact failed"]},
        %{"activities" => []},
        %{mission_state: %{"objectives" => []}},
        %{},
        nil,
        %{},
        %{}
      )

    assert risks == [
             %{"type" => "repair_warning", "severity" => "medium", "reason" => "contact failed"}
           ]
  end
end
