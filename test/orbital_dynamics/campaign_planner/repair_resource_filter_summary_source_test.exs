defmodule OrbitalDynamics.CampaignPlanner.RepairResourceFilterSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical resource-filter summaries" do
    summary = %{
      "schema_contract" => "resource_filter_summary.v1",
      "review_rows" => [%{"id" => "candidate_1"}]
    }

    assert RepairSourceReports.resource_filter_summary(%{
             "source_resource_filter_summary" => summary
           }) == summary

    assert RepairSourceReports.resource_filter_summary(%{
             "source_resource_filter_summary" => [summary]
           }) == summary

    assert RepairSourceReports.resource_filter_summary(%{
             "resource_filter_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no resource-filter summary" do
    assert RepairSourceReports.resource_filter_summary(%{}) == nil
    assert RepairSourceReports.resource_filter_summary(nil) == nil
  end
end
