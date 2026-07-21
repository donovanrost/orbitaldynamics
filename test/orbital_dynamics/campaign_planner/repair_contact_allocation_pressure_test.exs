defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationPressureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairContactAllocationPressure

  test "keeps only viable exact reduced-capacity allocation candidates" do
    report = %{
      "rows" => [
        %{
          "contact_id" => "dl_reduced",
          "effective_allocation_status" => "allocated",
          "station_availability" => "reduced_capacity"
        },
        %{
          "contact_id" => "dl_numeric_reduced",
          "allocation_status" => "ALLOCATED",
          "capacity_fraction" => "0.5"
        },
        %{
          "contact_id" => "dl_deferred",
          "effective_allocation_status" => "deferred",
          "capacity_fraction" => 0.5
        },
        %{
          "contact_id" => "dl_policy_blocked",
          "effective_allocation_status" => "policy_blocked",
          "capacity_fraction" => 0.5
        },
        %{
          "contact_id" => "dl_reserved",
          "effective_allocation_status" => "allocated",
          "station_availability" => "reserved"
        },
        %{
          "contact_id" => "dl_nominal",
          "effective_allocation_status" => "allocated",
          "capacity_fraction" => 1.0
        }
      ]
    }

    assert RepairContactAllocationPressure.candidate_ids(report) ==
             MapSet.new(["dl_reduced", "dl_numeric_reduced"])
  end

  test "missing or compact allocation evidence remains neutral" do
    assert RepairContactAllocationPressure.candidate_ids(nil) == MapSet.new()
    assert RepairContactAllocationPressure.candidate_ids(%{}) == MapSet.new()
    assert RepairContactAllocationPressure.candidate_ids(%{"rows" => []}) == MapSet.new()
  end
end
