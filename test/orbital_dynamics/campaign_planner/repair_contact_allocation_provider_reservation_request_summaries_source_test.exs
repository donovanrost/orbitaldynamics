defmodule OrbitalDynamics.CampaignPlanner.RepairContactAllocationProviderReservationRequestSummariesSourceTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.RepairSourceReports

  test "preserves every source and canonical provider-reservation-request summary in source order" do
    source_a = %{
      schema_contract: "contact_allocation_provider_reservation_request_summary.v1",
      source: "provider_reservation_request:source_a"
    }

    source_b = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "source" => "provider_reservation_request:source_b"
    }

    canonical = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "source" => "provider_reservation_request:canonical"
    }

    candidate_refresh = %{
      source_contact_allocation_provider_reservation_request_summary: [source_a, source_b],
      contact_allocation_provider_reservation_request_summary: canonical
    }

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summaries(
             candidate_refresh
           ) == [
             %{
               "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
               "source" => "provider_reservation_request:source_a"
             },
             source_b,
             canonical
           ]

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(
             candidate_refresh
           ) ==
             %{
               "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
               "source" => "provider_reservation_request:source_a"
             }
  end

  test "returns an empty collection and no compatibility mirror without summaries" do
    assert RepairSourceReports.contact_allocation_provider_reservation_request_summaries(%{}) ==
             []

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summaries(nil) ==
             []

    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(%{}) == nil
    assert RepairSourceReports.contact_allocation_provider_reservation_request_summary(nil) == nil
  end
end
