defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationPressureFixtures do
  def contact_allocation_provider_reservation_request_summary_fixture(prefix) do
    request_row = %{
      "contact_id" => "#{prefix}_dl_reserved_owner",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_1",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed"
    }

    review_row = %{
      "contact_id" => "#{prefix}_dl_review_overlap",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "#{prefix}_reservation_review",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed"
    }

    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" =>
        "campaign_planner_test.#{prefix}.contact_allocation_provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["#{prefix}_dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["#{prefix}_dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["#{prefix}_dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["#{prefix}_dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["#{prefix}_reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["#{prefix}_reservation_review"]
      },
      "provider_reservation_request_rows" => [request_row],
      "provider_reservation_review_rows" => [review_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_provider_reservation_request_fixture"}
    }
  end
end
