defmodule OrbitalDynamics.CampaignPlanner.RepairContactContentionResolutionSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical compact resolution summaries" do
    summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "recommendation_group_ids" => ["contention:1"]
    }

    assert RepairSourceReports.contact_contention_resolution_summary(%{
             "source_contact_contention_resolution_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_contention_resolution_summary(%{
             "source_contact_contention_resolution_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_contention_resolution_summary(%{
             "contact_contention_resolution_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no compact resolution summary" do
    assert RepairSourceReports.contact_contention_resolution_summary(%{}) == nil
    assert RepairSourceReports.contact_contention_resolution_summary(nil) == nil
  end
end
