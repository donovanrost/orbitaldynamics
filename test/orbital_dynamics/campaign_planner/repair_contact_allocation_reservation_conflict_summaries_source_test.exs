defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationReservationConflictSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical reservation-conflict summary in source order" do
    source_a = %{
      schema_contract: "contact_allocation_reservation_conflict_summary.v1",
      source: "reservation_conflict:source_a"
    }

    source_b = %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "source" => "reservation_conflict:source_b"
    }

    canonical = %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "source" => "reservation_conflict:canonical"
    }

    candidate_refresh = %{
      source_contact_allocation_reservation_conflict_summary: [source_a, source_b],
      contact_allocation_reservation_conflict_summary: canonical
    }

    assert RepairSourceReports.contact_allocation_reservation_conflict_summaries(
             candidate_refresh
           ) == [
             %{
               "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
               "source" => "reservation_conflict:source_a"
             },
             source_b,
             canonical
           ]

    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(candidate_refresh) ==
             %{
               "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
               "source" => "reservation_conflict:source_a"
             }
  end

  test "returns an empty collection and no compatibility mirror without summaries" do
    assert RepairSourceReports.contact_allocation_reservation_conflict_summaries(%{}) == []
    assert RepairSourceReports.contact_allocation_reservation_conflict_summaries(nil) == []
    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(nil) == nil
  end
end
