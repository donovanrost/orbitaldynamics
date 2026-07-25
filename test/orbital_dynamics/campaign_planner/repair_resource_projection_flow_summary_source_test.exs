defmodule OrbitalDynamics.CampaignPlanner.RepairResourceProjectionFlowSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical resource-flow summaries" do
    summary = %{
      "schema_contract" => "resource_projection_flow_summary.v1",
      "projected_resources" => [%{"spacecraft_id" => "leo_1"}]
    }

    assert RepairSourceReports.resource_projection_flow_summary(%{
             "source_resource_projection_flow_summary" => summary
           }) == summary

    assert RepairSourceReports.resource_projection_flow_summary(%{
             "source_resource_projection_flow_summary" => [summary]
           }) == summary

    assert RepairSourceReports.resource_projection_flow_summary(%{
             "resource_projection_flow_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no resource-flow summary" do
    assert RepairSourceReports.resource_projection_flow_summary(%{}) == nil
    assert RepairSourceReports.resource_projection_flow_summary(nil) == nil
  end
end
