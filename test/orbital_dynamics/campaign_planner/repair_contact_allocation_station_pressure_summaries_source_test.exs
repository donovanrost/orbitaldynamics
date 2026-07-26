defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationStationPressureSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical station-pressure summary in source order" do
    source_a = %{
      schema_contract: "contact_allocation_station_pressure_summary.v1",
      source: "station_pressure:source_a"
    }

    source_b = %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "source" => "station_pressure:source_b"
    }

    canonical = %{
      "schema_contract" => "contact_allocation_station_pressure_summary.v1",
      "source" => "station_pressure:canonical"
    }

    candidate_refresh = %{
      source_contact_allocation_station_pressure_summary: [source_a, source_b],
      contact_allocation_station_pressure_summary: canonical
    }

    assert RepairSourceReports.contact_allocation_station_pressure_summaries(candidate_refresh) ==
             [
               %{
                 "schema_contract" => "contact_allocation_station_pressure_summary.v1",
                 "source" => "station_pressure:source_a"
               },
               source_b,
               canonical
             ]

    assert RepairSourceReports.contact_allocation_station_pressure_summary(candidate_refresh) ==
             %{
               "schema_contract" => "contact_allocation_station_pressure_summary.v1",
               "source" => "station_pressure:source_a"
             }
  end

  test "returns an empty collection and no compatibility mirror without summaries" do
    assert RepairSourceReports.contact_allocation_station_pressure_summaries(%{}) == []
    assert RepairSourceReports.contact_allocation_station_pressure_summaries(nil) == []
    assert RepairSourceReports.contact_allocation_station_pressure_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_station_pressure_summary(nil) == nil
  end
end
