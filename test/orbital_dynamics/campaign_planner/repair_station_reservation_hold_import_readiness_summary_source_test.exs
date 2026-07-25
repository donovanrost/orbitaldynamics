defmodule OrbitalDynamics.CampaignPlanner.RepairStationReservationHoldImportReadinessSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station hold import-readiness summaries" do
    summary = %{
      "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
      "reservation_hold_count" => 2,
      "import_readiness_status" => "review_required"
    }

    assert RepairSourceReports.station_reservation_hold_import_readiness_summary(%{
             "source_station_reservation_hold_import_readiness_summary" => summary
           }) == summary

    assert RepairSourceReports.station_reservation_hold_import_readiness_summary(%{
             "source_station_reservation_hold_import_readiness_summary" => [summary]
           }) == summary

    assert RepairSourceReports.station_reservation_hold_import_readiness_summary(%{
             "station_reservation_hold_import_readiness_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no station hold import-readiness summary" do
    assert RepairSourceReports.station_reservation_hold_import_readiness_summary(%{}) == nil
    assert RepairSourceReports.station_reservation_hold_import_readiness_summary(nil) == nil
  end
end
