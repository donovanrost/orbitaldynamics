defmodule OrbitalDynamics.CampaignPlanner.RepairLinkCapacitySummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical compact link-capacity summaries" do
    summary = %{
      "schema_contract" => "link_capacity_summary.v1",
      "ground_station_ids" => ["equator_prime"]
    }

    assert RepairSourceReports.link_capacity_summary(%{
             "source_link_capacity_summary" => summary
           }) == summary

    assert RepairSourceReports.link_capacity_summary(%{
             "source_link_capacity_summary" => [summary]
           }) == summary

    assert RepairSourceReports.link_capacity_summary(%{
             "link_capacity_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no compact link-capacity summary" do
    assert RepairSourceReports.link_capacity_summary(%{}) == nil
    assert RepairSourceReports.link_capacity_summary(nil) == nil
  end
end
