defmodule OrbitalDynamics.CampaignPlanner.RepairStationCalendarPrecedenceSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station calendar precedence summaries" do
    summary = %{
      "schema_contract" => "station_calendar_precedence_summary.v1",
      "affected_contact_count" => 1,
      "precedence_review_status" => "review_required"
    }

    assert RepairSourceReports.station_calendar_precedence_summary(%{
             "source_station_calendar_precedence_summary" => summary
           }) == summary

    assert RepairSourceReports.station_calendar_precedence_summary(%{
             "source_station_calendar_precedence_summary" => [summary]
           }) == summary

    assert RepairSourceReports.station_calendar_precedence_summary(%{
             "station_calendar_precedence_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no station calendar precedence summary" do
    assert RepairSourceReports.station_calendar_precedence_summary(%{}) == nil
    assert RepairSourceReports.station_calendar_precedence_summary(nil) == nil
  end
end
