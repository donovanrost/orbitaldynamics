defmodule OrbitalDynamics.CampaignPlanner.RepairStationReservationHoldSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station reservation hold summaries" do
    summary = %{
      "schema_contract" => "station_reservation_hold_summary.v1",
      "reservation_hold_count" => 2,
      "reservation_hold_review_status" => "review_required"
    }

    assert RepairSourceReports.station_reservation_hold_summary(%{
             "source_station_reservation_hold_summary" => summary
           }) == summary

    assert RepairSourceReports.station_reservation_hold_summary(%{
             "source_station_reservation_hold_summary" => [summary]
           }) == summary

    assert RepairSourceReports.station_reservation_hold_summary(%{
             "station_reservation_hold_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no station reservation hold summary" do
    assert RepairSourceReports.station_reservation_hold_summary(%{}) == nil
    assert RepairSourceReports.station_reservation_hold_summary(nil) == nil
  end
end
