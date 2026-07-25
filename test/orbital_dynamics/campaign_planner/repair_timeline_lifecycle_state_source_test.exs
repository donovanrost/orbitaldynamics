defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineLifecycleStateSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical lifecycle-state summaries" do
    summary = %{
      "schema_contract" => "timeline_lifecycle_state_summary.v1",
      "review_required_count" => 1
    }

    assert RepairSourceReports.timeline_lifecycle_state(%{
             "source_timeline_lifecycle_state_summary" => summary
           }) == summary

    assert RepairSourceReports.timeline_lifecycle_state(%{
             "source_timeline_lifecycle_state_summary" => [summary]
           }) == summary

    assert RepairSourceReports.timeline_lifecycle_state(%{
             "timeline_lifecycle_state_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no lifecycle-state summary" do
    assert RepairSourceReports.timeline_lifecycle_state(%{}) == nil
    assert RepairSourceReports.timeline_lifecycle_state(nil) == nil
  end
end
