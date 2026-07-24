defmodule OrbitalDynamics.CampaignPlanner.RepairStationReservationSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station-reservation reports" do
    report = %{
      "schema_contract" => "station_reservation_report.v1",
      "affected_contacts" => [%{"contact_id" => "dl_reserved"}]
    }

    assert RepairSourceReports.station_reservation(%{
             "source_station_reservation_report" => report
           }) == report

    assert RepairSourceReports.station_reservation(%{
             "source_station_reservation_report" => [report]
           }) == report

    assert RepairSourceReports.station_reservation(%{
             "station_reservation_report" => report
           }) == report
  end

  test "returns nil when candidate refresh has no station-reservation report" do
    assert RepairSourceReports.station_reservation(%{}) == nil
    assert RepairSourceReports.station_reservation(nil) == nil
  end
end
