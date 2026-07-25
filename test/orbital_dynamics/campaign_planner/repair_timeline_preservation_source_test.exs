defmodule OrbitalDynamics.CampaignPlanner.RepairTimelinePreservationSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical timeline-preservation reports" do
    report = %{
      "schema_contract" => "timeline_preservation_report.v1",
      "timeline_preservation_status" => "review_required"
    }

    assert RepairSourceReports.timeline_preservation(%{
             "source_timeline_preservation_report" => report
           }) == report

    assert RepairSourceReports.timeline_preservation(%{
             "source_timeline_preservation_report" => [report]
           }) == report

    assert RepairSourceReports.timeline_preservation(%{
             "timeline_preservation_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no timeline-preservation report" do
    assert RepairSourceReports.timeline_preservation(%{}) == nil
    assert RepairSourceReports.timeline_preservation(nil) == nil
  end
end
