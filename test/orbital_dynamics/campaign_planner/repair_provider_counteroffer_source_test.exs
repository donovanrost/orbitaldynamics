defmodule OrbitalDynamics.CampaignPlanner.RepairProviderCounterofferSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical provider-counteroffer reports" do
    report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "station_calendar_report.affected_contacts",
      "counteroffer_count" => 1
    }

    assert RepairSourceReports.provider_counteroffer(%{
             "source_provider_counteroffer_report" => report
           }) == report

    assert RepairSourceReports.provider_counteroffer(%{
             "source_provider_counteroffer_report" => [report]
           }) == report

    assert RepairSourceReports.provider_counteroffer(%{
             "provider_counteroffer_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no provider-counteroffer report" do
    assert RepairSourceReports.provider_counteroffer(%{}) == nil
    assert RepairSourceReports.provider_counteroffer(nil) == nil
  end
end
