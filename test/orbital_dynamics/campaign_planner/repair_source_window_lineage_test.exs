defmodule OrbitalDynamics.CampaignPlanner.RepairSourceWindowLineageTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source-window lineage row in source order" do
    first = %{
      schema_contract: "source_window_lineage.v1",
      candidate_activity_id: "candidate:first",
      source_window_id: "window:first",
      source_window_type: "ground_station_access",
      scenario_id: "scenario:first"
    }

    second = %{
      "schema_contract" => "source_window_lineage.v1",
      "candidate_activity_id" => "candidate:second",
      "source_window_id" => "window:second",
      "source_window_type" => "target_visibility",
      "scenario_id" => "scenario:second"
    }

    assert RepairSourceReports.source_window_lineage(%{
             source_window_lineage: [first, "invalid", second]
           }) == [
             %{
               "schema_contract" => "source_window_lineage.v1",
               "candidate_activity_id" => "candidate:first",
               "source_window_id" => "window:first",
               "source_window_type" => "ground_station_access",
               "scenario_id" => "scenario:first"
             },
             second
           ]
  end

  test "returns an empty list without source-window lineage" do
    assert RepairSourceReports.source_window_lineage(%{}) == []
    assert RepairSourceReports.source_window_lineage(nil) == []
  end
end
