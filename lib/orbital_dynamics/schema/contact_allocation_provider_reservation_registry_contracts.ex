defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_allocation_provider_reservation_request_summary.v1" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "artifact_family" => "contact_allocation_provider_reservation_request_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "input_contact_count",
          "provider_reservation_candidate_contact_count",
          "provider_reservation_request_contact_count",
          "provider_reservation_review_contact_count",
          "provider_reservation_no_request_contact_count",
          "provider_reservation_request_status",
          "provider_reservation_request_contact_ids",
          "provider_reservation_review_contact_ids",
          "provider_reservation_no_request_contact_ids",
          "provider_reservation_request_contact_ids_by_ground_station_id",
          "provider_reservation_review_contact_ids_by_ground_station_id",
          "provider_reservation_request_contact_ids_by_match_status",
          "provider_reservation_review_contact_ids_by_match_status",
          "provider_reservation_request_ids_by_match_status",
          "provider_reservation_review_ids_by_match_status",
          "rows",
          "provider_reservation_request_rows",
          "provider_reservation_review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "provider_reservation_no_request_contact_ids_by_direction",
          "provider_reservation_request_contact_ids_by_direction",
          "provider_reservation_review_contact_ids_by_direction",
          "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
          "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
          "model_limits"
        ],
        "nested_contracts" => ["contact_allocation_report.v1"]
      }
    }
  end
end
