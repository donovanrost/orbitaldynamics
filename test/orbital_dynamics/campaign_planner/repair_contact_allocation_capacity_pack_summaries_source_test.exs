defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationCapacityPackSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical capacity-pack summary in source order" do
    source_a = %{
      schema_contract: "contact_allocation_capacity_pack_summary.v1",
      source: "capacity_pack:source_a"
    }

    source_b = %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "source" => "capacity_pack:source_b"
    }

    canonical = %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "source" => "capacity_pack:canonical"
    }

    candidate_refresh = %{
      source_contact_allocation_capacity_pack_summary: [source_a, source_b],
      contact_allocation_capacity_pack_summary: canonical
    }

    assert RepairSourceReports.contact_allocation_capacity_pack_summaries(candidate_refresh) == [
             %{
               "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
               "source" => "capacity_pack:source_a"
             },
             source_b,
             canonical
           ]

    assert RepairSourceReports.contact_allocation_capacity_pack_summary(candidate_refresh) == %{
             "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
             "source" => "capacity_pack:source_a"
           }
  end

  test "returns an empty collection and no compatibility mirror without summaries" do
    assert RepairSourceReports.contact_allocation_capacity_pack_summaries(%{}) == []
    assert RepairSourceReports.contact_allocation_capacity_pack_summaries(nil) == []
    assert RepairSourceReports.contact_allocation_capacity_pack_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_capacity_pack_summary(nil) == nil
  end
end
