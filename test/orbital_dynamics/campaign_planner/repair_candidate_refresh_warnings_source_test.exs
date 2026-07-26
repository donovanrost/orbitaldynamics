defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshWarningsSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves exact warning order and duplicates" do
    warnings = ["second source warning", "first source warning", "second source warning"]

    assert RepairSourceReports.candidate_refresh_warnings(%{warnings: warnings}) == warnings
  end

  test "distinguishes an empty warning list from an absent source list" do
    assert RepairSourceReports.candidate_refresh_warnings(%{"warnings" => []}) == []
    assert RepairSourceReports.candidate_refresh_warnings(%{}) == nil
    assert RepairSourceReports.candidate_refresh_warnings(nil) == nil
  end
end
