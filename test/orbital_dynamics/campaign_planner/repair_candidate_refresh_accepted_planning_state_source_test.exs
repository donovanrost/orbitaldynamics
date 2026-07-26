defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshAcceptedPlanningStateSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves the exact normalized CandidateRefresh accepted-state reference" do
    accepted_state = %{
      snapshot_id: "ops-state-1",
      spacecraft_state_count: 4,
      accepted_at: "2026-05-14T00:00:00Z",
      maneuver_execution_delta_count: 2,
      source_family: "fleet_snapshot"
    }

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(%{
             accepted_planning_state: accepted_state
           }) == %{
             "snapshot_id" => "ops-state-1",
             "spacecraft_state_count" => 4,
             "accepted_at" => "2026-05-14T00:00:00Z",
             "maneuver_execution_delta_count" => 2,
             "source_family" => "fleet_snapshot"
           }
  end

  test "keeps an absent or non-map accepted-state reference absent" do
    assert RepairSourceReports.candidate_refresh_accepted_planning_state(%{}) == nil

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(%{
             "accepted_planning_state" => []
           }) == nil

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(nil) == nil
  end
end
