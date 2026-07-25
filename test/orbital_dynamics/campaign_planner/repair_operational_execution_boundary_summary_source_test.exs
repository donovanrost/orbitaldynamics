defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalExecutionBoundarySummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operational execution-boundary summaries" do
    summary = %{
      "schema_contract" => "operational_execution_boundary_summary.v1",
      "handoff_only" => true,
      "execution_allowed" => false
    }

    assert RepairSourceReports.operational_execution_boundary_summary(%{
             "source_operational_execution_boundary_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_execution_boundary_summary(%{
             "source_operational_execution_boundary_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_execution_boundary_summary(%{
             "operational_execution_boundary_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no operational execution-boundary summary" do
    assert RepairSourceReports.operational_execution_boundary_summary(%{}) == nil
    assert RepairSourceReports.operational_execution_boundary_summary(nil) == nil
  end
end
