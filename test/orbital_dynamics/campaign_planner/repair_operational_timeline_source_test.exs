defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalTimelineSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operational-timeline reports" do
    report = %{
      "schema_contract" => "operational_timeline_report.v1",
      "row_count" => 1
    }

    assert RepairSourceReports.operational_timeline(%{
             "source_operational_timeline_report" => report
           }) == report

    assert RepairSourceReports.operational_timeline(%{
             "source_operational_timeline_report" => [report]
           }) == report

    assert RepairSourceReports.operational_timeline(%{
             "operational_timeline_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no operational-timeline report" do
    assert RepairSourceReports.operational_timeline(%{}) == nil
    assert RepairSourceReports.operational_timeline(nil) == nil
  end
end
