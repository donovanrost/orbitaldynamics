defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineTransitionApplicationSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical transition-application summaries" do
    summary = %{
      "schema_contract" => "timeline_transition_application_summary.v1",
      "application_count" => 2
    }

    assert RepairSourceReports.timeline_transition_application_summary(%{
             "source_timeline_transition_application_summary" => summary
           }) == summary

    assert RepairSourceReports.timeline_transition_application_summary(%{
             "source_timeline_transition_application_summary" => [summary]
           }) == summary

    assert RepairSourceReports.timeline_transition_application_summary(%{
             "timeline_transition_application_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no transition-application summary" do
    assert RepairSourceReports.timeline_transition_application_summary(%{}) == nil
    assert RepairSourceReports.timeline_transition_application_summary(nil) == nil
  end
end
