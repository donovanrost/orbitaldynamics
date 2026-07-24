defmodule OrbitalDynamics.CampaignPlanner.RepairLinkCapacitySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source and canonical link-capacity reports" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [%{"ground_station_id" => "equator_prime"}]
    }

    assert RepairSourceReports.link_capacity(%{
             "source_link_capacity_report" => report
           }) == report

    assert RepairSourceReports.link_capacity(%{
             "source_link_capacity_report" => [report]
           }) == report

    assert RepairSourceReports.link_capacity(%{
             "link_capacity_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no link-capacity report" do
    assert RepairSourceReports.link_capacity(%{}) == nil
    assert RepairSourceReports.link_capacity(nil) == nil
  end
end
