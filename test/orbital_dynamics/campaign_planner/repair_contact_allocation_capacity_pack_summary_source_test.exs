defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationCapacityPackSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical capacity-pack summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "reduced_capacity_pack_group_count" => 1
    }

    assert RepairSourceReports.contact_allocation_capacity_pack_summary(%{
             "source_contact_allocation_capacity_pack_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_allocation_capacity_pack_summary(%{
             "source_contact_allocation_capacity_pack_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_allocation_capacity_pack_summary(%{
             "contact_allocation_capacity_pack_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no capacity-pack summary" do
    assert RepairSourceReports.contact_allocation_capacity_pack_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_capacity_pack_summary(nil) == nil
  end
end
