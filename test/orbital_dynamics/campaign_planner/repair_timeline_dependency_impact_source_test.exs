defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineDependencyImpactSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical dependency-impact summaries" do
    summary = %{
      "schema_contract" => "timeline_dependency_impact_summary.v1",
      "dependency_impact_status" => "review_required"
    }

    assert RepairSourceReports.timeline_dependency_impact(%{
             "source_timeline_dependency_impact_summary" => summary
           }) == summary

    assert RepairSourceReports.timeline_dependency_impact(%{
             "source_timeline_dependency_impact_summary" => [summary]
           }) == summary

    assert RepairSourceReports.timeline_dependency_impact(%{
             "timeline_dependency_impact_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no dependency-impact summary" do
    assert RepairSourceReports.timeline_dependency_impact(%{}) == nil
    assert RepairSourceReports.timeline_dependency_impact(nil) == nil
  end
end
