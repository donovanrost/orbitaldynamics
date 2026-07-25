defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationProviderReservationRequestSummarySourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "resolves source, collected, and canonical provider-reservation request summaries" do
    summary = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "provider_reservation_request_status" => "review_required"
    }

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(%{
             "source_contact_allocation_provider_reservation_request_summary" => summary
           }) == summary

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(%{
             "source_contact_allocation_provider_reservation_request_summary" => [summary]
           }) == summary

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(%{
             "contact_allocation_provider_reservation_request_summary" => summary
           }) == summary
  end

  test "returns nil when candidate refresh has no provider-reservation request summary" do
    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(nil) == nil
  end
end
