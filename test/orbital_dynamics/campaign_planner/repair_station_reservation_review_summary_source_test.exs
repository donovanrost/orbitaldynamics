defmodule OrbitalDynamics.CampaignPlanner.RepairStationReservationReviewSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station reservation review summaries" do
    summary = %{
      "schema_contract" => "station_reservation_review_summary.v1",
      "reservation_count" => 3,
      "reservation_review_status" => "review_required"
    }

    assert RepairSourceReports.station_reservation_review_summary(%{
             "source_station_reservation_review_summary" => summary
           }) == summary

    assert RepairSourceReports.station_reservation_review_summary(%{
             "source_station_reservation_review_summary" => [summary]
           }) == summary

    assert RepairSourceReports.station_reservation_review_summary(%{
             "station_reservation_review_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no station reservation review summary" do
    assert RepairSourceReports.station_reservation_review_summary(%{}) == nil
    assert RepairSourceReports.station_reservation_review_summary(nil) == nil
  end
end
