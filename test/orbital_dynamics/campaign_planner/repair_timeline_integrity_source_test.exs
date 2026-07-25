defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineIntegritySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical timeline-integrity reports" do
    report = %{
      "schema_contract" => "timeline_integrity_report.v1",
      "timeline_integrity_status" => "review_required"
    }

    assert RepairSourceReports.timeline_integrity(%{
             "source_timeline_integrity_report" => report
           }) == report

    assert RepairSourceReports.timeline_integrity(%{
             "source_timeline_integrity_report" => [report]
           }) == report

    assert RepairSourceReports.timeline_integrity(%{
             "timeline_integrity_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no timeline-integrity report" do
    assert RepairSourceReports.timeline_integrity(%{}) == nil
    assert RepairSourceReports.timeline_integrity(nil) == nil
  end
end
