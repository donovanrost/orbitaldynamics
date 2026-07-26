defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshRemainingHorizonSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact normalized CandidateRefresh sampling horizon" do
    remaining_horizon = %{
      schema_contract: "remaining_horizon.v1",
      starts_at_s: 120.0,
      ends_at_s: 720.0,
      output_step_s: 30.0,
      duration_s: 600.0
    }

    assert RepairSourceReports.candidate_refresh_remaining_horizon(%{
             remaining_horizon: remaining_horizon
           }) == %{
             "schema_contract" => "remaining_horizon.v1",
             "starts_at_s" => 120.0,
             "ends_at_s" => 720.0,
             "output_step_s" => 30.0,
             "duration_s" => 600.0
           }
  end

  test "keeps an absent or non-map source horizon absent" do
    assert RepairSourceReports.candidate_refresh_remaining_horizon(%{}) == nil

    assert RepairSourceReports.candidate_refresh_remaining_horizon(%{
             "remaining_horizon" => []
           }) == nil

    assert RepairSourceReports.candidate_refresh_remaining_horizon(nil) == nil
  end
end
