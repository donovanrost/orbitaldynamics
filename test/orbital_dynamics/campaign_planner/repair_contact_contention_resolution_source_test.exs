defmodule OrbitalDynamics.CampaignPlanner.RepairContactContentionResolutionSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves direct, collected, and allocation-embedded resolution reports" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [%{"group_id" => "contention:1"}]
    }

    assert RepairSourceReports.contact_contention_resolution(%{
             "contact_contention_resolution_report" => report
           }) == report

    assert RepairSourceReports.contact_contention_resolution(%{
             "source_contact_contention_resolution_report" => [report]
           }) == report

    assert RepairSourceReports.contact_contention_resolution(%{
             "contact_allocation_report" => %{
               "contact_contention_resolution_report" => report
             }
           }) == report
  end

  test "returns nil when candidate refresh has no resolution report" do
    assert RepairSourceReports.contact_contention_resolution(%{}) == nil
    assert RepairSourceReports.contact_contention_resolution(nil) == nil
  end
end
