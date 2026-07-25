defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineDiffSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical timeline-diff reports" do
    report = %{
      "schema_contract" => "timeline_diff_report.v1",
      "rows" => [%{"timeline_id" => "timeline:obs_1", "diff_status" => "changed"}]
    }

    assert RepairSourceReports.timeline_diff(%{"source_timeline_diff_report" => report}) ==
             report

    assert RepairSourceReports.timeline_diff(%{"source_timeline_diff_report" => [report]}) ==
             report

    assert RepairSourceReports.timeline_diff(%{"timeline_diff_report" => report}) == report
  end

  test "returns nil when candidate refresh has no timeline-diff report" do
    assert RepairSourceReports.timeline_diff(%{}) == nil
    assert RepairSourceReports.timeline_diff(nil) == nil
  end

  test "resolves source, collected, and canonical timeline-diff summaries" do
    summary = %{
      "schema_contract" => "timeline_diff_summary.v1",
      "review_required_count" => 1,
      "review_rows" => [%{"timeline_id" => "timeline:obs_1", "diff_status" => "changed"}]
    }

    assert RepairSourceReports.timeline_diff_summary(%{
             "source_timeline_diff_summary" => summary
           }) == summary

    assert RepairSourceReports.timeline_diff_summary(%{
             "source_timeline_diff_summary" => [summary]
           }) == summary

    assert RepairSourceReports.timeline_diff_summary(%{"timeline_diff_summary" => summary}) ==
             summary
  end

  test "returns nil when candidate refresh has no timeline-diff summary" do
    assert RepairSourceReports.timeline_diff_summary(%{}) == nil
    assert RepairSourceReports.timeline_diff_summary(nil) == nil
  end
end
