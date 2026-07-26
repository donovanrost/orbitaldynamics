defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshOperationalFeedbackSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact normalized CandidateRefresh operational feedback" do
    operational_feedback = %{
      station_throughput_factor: %{equator_prime: 0.5},
      downlink_demand_mb: %{leo_1: 120.0},
      resource_margin_overrides: %{leo_1: %{battery_margin_wh: 40.0}},
      extra_feedback_family: %{source: "future_adapter"}
    }

    assert RepairSourceReports.candidate_refresh_operational_feedback(%{
             operational_feedback: operational_feedback
           }) == %{
             "station_throughput_factor" => %{"equator_prime" => 0.5},
             "downlink_demand_mb" => %{"leo_1" => 120.0},
             "resource_margin_overrides" => %{
               "leo_1" => %{"battery_margin_wh" => 40.0}
             },
             "extra_feedback_family" => %{"source" => "future_adapter"}
           }
  end

  test "distinguishes an explicit empty map from absent or non-map feedback" do
    assert RepairSourceReports.candidate_refresh_operational_feedback(%{
             "operational_feedback" => %{}
           }) == %{}

    assert RepairSourceReports.candidate_refresh_operational_feedback(%{}) == nil

    assert RepairSourceReports.candidate_refresh_operational_feedback(%{
             "operational_feedback" => []
           }) == nil

    assert RepairSourceReports.candidate_refresh_operational_feedback(nil) == nil
  end
end
