defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalQualityGateSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical operational quality-gate summaries" do
    summary = %{
      "schema_contract" => "operational_quality_gate_summary.v1",
      "gate_count" => 6,
      "non_passed_gate_count" => 3
    }

    assert RepairSourceReports.operational_quality_gate_summary(%{
             "source_operational_quality_gate_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_quality_gate_summary(%{
             "source_operational_quality_gate_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_quality_gate_summary(%{
             "operational_quality_gate_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no operational quality-gate summary" do
    assert RepairSourceReports.operational_quality_gate_summary(%{}) == nil
    assert RepairSourceReports.operational_quality_gate_summary(nil) == nil
  end
end
