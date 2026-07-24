defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalReadinessGateSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operational-readiness gate summaries" do
    summary = %{
      "schema_contract" => "operational_readiness_gate_summary.v1",
      "gate_count" => 5,
      "gate_status_counts" => %{"passed" => 5}
    }

    assert RepairSourceReports.operational_readiness_gate_summary(%{
             "source_operational_readiness_gate_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_readiness_gate_summary(%{
             "source_operational_readiness_gate_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_readiness_gate_summary(%{
             "operational_readiness_gate_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no operational-readiness gate summary" do
    assert RepairSourceReports.operational_readiness_gate_summary(%{}) == nil
    assert RepairSourceReports.operational_readiness_gate_summary(nil) == nil
  end
end
