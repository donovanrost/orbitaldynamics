defmodule OrbitalDynamics.CampaignPlanner.RepairContactContentionSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves direct, collected, and allocation-embedded contention reports" do
    report = %{
      "schema_contract" => "contact_contention_report.v1",
      "conflict_groups" => [%{"id" => "contention:1"}]
    }

    assert RepairSourceReports.contact_contention(%{
             "contact_contention_report" => report
           }) == report

    assert RepairSourceReports.contact_contention(%{
             "source_contact_contention_report" => [report]
           }) == report

    assert RepairSourceReports.contact_contention(%{
             "contact_allocation_report" => %{"contact_contention_report" => report}
           }) == report

    assert RepairSourceReports.contact_contention(%{
             "source_contact_allocation_report" => %{
               "contact_contention_report" => report
             }
           }) == report
  end

  test "returns nil when candidate refresh has no contention report" do
    assert RepairSourceReports.contact_contention(%{}) == nil
    assert RepairSourceReports.contact_contention(nil) == nil
  end
end
