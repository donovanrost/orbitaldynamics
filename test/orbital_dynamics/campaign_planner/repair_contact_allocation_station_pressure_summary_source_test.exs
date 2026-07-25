defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationStationPressureSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical station-pressure summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "station_pressure_review_contact_count" => 1
    }

    assert RepairSourceReports.contact_allocation_station_pressure_summary(%{
             "source_contact_allocation_station_pressure_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_allocation_station_pressure_summary(%{
             "source_contact_allocation_station_pressure_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_allocation_station_pressure_summary(%{
             "contact_allocation_station_pressure_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no station-pressure summary" do
    assert RepairSourceReports.contact_allocation_station_pressure_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_station_pressure_summary(nil) == nil
  end
end
