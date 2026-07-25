defmodule OrbitalDynamics.CampaignPlanner.RepairOperationalQualityGateUnavailableResourceSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical unavailable-resource quality-gate summaries" do
    summary = %{
      "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
      "unavailable_resource_pressure_count" => 2,
      "blocked_contact_ids_by_spacecraft_id" => %{"leo_1" => ["contact:blocked"]}
    }

    assert RepairSourceReports.operational_quality_gate_unavailable_resource_summary(%{
             "source_operational_quality_gate_unavailable_resource_summary" => summary
           }) == summary

    assert RepairSourceReports.operational_quality_gate_unavailable_resource_summary(%{
             "source_operational_quality_gate_unavailable_resource_summary" => [summary]
           }) == summary

    assert RepairSourceReports.operational_quality_gate_unavailable_resource_summary(%{
             "operational_quality_gate_unavailable_resource_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no unavailable-resource quality-gate summary" do
    assert RepairSourceReports.operational_quality_gate_unavailable_resource_summary(%{}) == nil
    assert RepairSourceReports.operational_quality_gate_unavailable_resource_summary(nil) == nil
  end
end
