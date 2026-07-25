defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical compact allocation summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_summary.v1",
      "review_row_count" => 3
    }

    assert RepairSourceReports.contact_allocation_summary(%{
             "source_contact_allocation_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_allocation_summary(%{
             "source_contact_allocation_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_allocation_summary(%{
             "contact_allocation_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no compact allocation summary" do
    assert RepairSourceReports.contact_allocation_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_summary(nil) == nil
  end
end
