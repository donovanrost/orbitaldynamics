defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationReservationConflictSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical reservation-conflict summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
      "reservation_review_contact_count" => 1
    }

    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(%{
             "source_contact_allocation_reservation_conflict_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(%{
             "source_contact_allocation_reservation_conflict_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(%{
             "contact_allocation_reservation_conflict_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no reservation-conflict summary" do
    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_reservation_conflict_summary(nil) == nil
  end
end
