defmodule OrbitalDynamics.CampaignPlanner.RepairTimelineTransitionApplicationSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical transition-application reports" do
    report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "application_count" => 1
    }

    assert RepairSourceReports.timeline_transition_application(%{
             "source_timeline_transition_application_report" => report
           }) == report

    assert RepairSourceReports.timeline_transition_application(%{
             "source_timeline_transition_application_report" => [report]
           }) == report

    assert RepairSourceReports.timeline_transition_application(%{
             "timeline_transition_application_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no transition-application report" do
    assert RepairSourceReports.timeline_transition_application(%{}) == nil
    assert RepairSourceReports.timeline_transition_application(nil) == nil
  end
end
