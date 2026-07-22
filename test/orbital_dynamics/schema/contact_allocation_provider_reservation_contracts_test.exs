defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates provider reservation request direction maps against rows" do
    request_row = %{
      "id" => "provider_request:request",
      "contact_id" => "reserved_downlink",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "station_reservation_id" => "reservation_downlink",
      "station_reservation_match_status" => "matched",
      "station_reservation_status" => "confirmed"
    }

    review_row = %{
      "id" => "provider_request:review",
      "contact_id" => "reserved_overlap_uplink",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "ground_station_id" => "polar_prime",
      "direction" => "uplink",
      "station_reservation_id" => "reservation_overlap",
      "station_reservation_match_status" => "overlap",
      "station_reservation_status" => "confirmed"
    }

    no_request_row = %{
      "id" => "provider_request:no_request",
      "contact_id" => "unreserved_tracking",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "ground_station_id" => "dss_43",
      "direction" => "tracking"
    }

    summary = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.provider_reservation_request_summary",
      "input_contact_count" => 3,
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["reserved_downlink"],
      "provider_reservation_review_contact_ids" => ["reserved_overlap_uplink"],
      "provider_reservation_no_request_contact_ids" => ["unreserved_tracking"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["reserved_downlink"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "polar_prime" => ["reserved_overlap_uplink"]
      },
      "provider_reservation_no_request_contact_ids_by_direction" => %{
        "tracking" => ["unreserved_tracking"]
      },
      "provider_reservation_request_contact_ids_by_direction" => %{
        "downlink" => ["reserved_downlink"]
      },
      "provider_reservation_review_contact_ids_by_direction" => %{
        "uplink" => ["reserved_overlap_uplink"]
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["reserved_downlink"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["reserved_overlap_uplink"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["reservation_downlink"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["reservation_overlap"]
      },
      "rows" => [request_row, review_row, no_request_row],
      "provider_reservation_request_rows" => [request_row],
      "provider_reservation_review_rows" => [review_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "provider_reservation_execution" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_provider_reservation_request_summary"
      }
    }

    assert {:ok,
            %{"schema_contract" => "contact_allocation_provider_reservation_request_summary.v1"}} =
             Schema.validate_artifact(summary)

    invalid_match_status_routes =
      Map.merge(summary, %{
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "provider_review" => ["reserved_downlink"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "provider_review" => ["reservation_downlink"]
        }
      })

    assert {:error, invalid_match_status_routes_report} =
             Schema.validate_artifact(invalid_match_status_routes)

    for field <- [
          "provider_reservation_request_contact_ids_by_match_status",
          "provider_reservation_request_ids_by_match_status"
        ] do
      assert Enum.any?(
               invalid_match_status_routes_report["errors"],
               &(&1["path"] == "$.#{field}" and
                   String.starts_with?(&1["message"], "keys must be one of"))
             )
    end

    [
      {
        "provider_reservation_no_request_contact_ids_by_direction",
        %{"tracking" => ["stale_unreserved"]},
        "must equal row-derived provider_reservation_no_request_contact_ids_by_direction"
      },
      {
        "provider_reservation_request_contact_ids_by_direction",
        %{"downlink" => ["stale_request"]},
        "must equal row-derived provider_reservation_request_contact_ids_by_direction"
      },
      {
        "provider_reservation_review_contact_ids_by_direction",
        %{"uplink" => ["stale_review"]},
        "must equal row-derived provider_reservation_review_contact_ids_by_direction"
      }
    ]
    |> Enum.each(fn {field, stale_value, message} ->
      stale_summary = Map.put(summary, field, stale_value)

      assert {:error, validation_report} = Schema.validate_artifact(stale_summary)

      assert Enum.any?(
               validation_report["errors"],
               &(&1["path"] == "$.#{field}" and &1["message"] == message)
             )
    end)
  end
end
