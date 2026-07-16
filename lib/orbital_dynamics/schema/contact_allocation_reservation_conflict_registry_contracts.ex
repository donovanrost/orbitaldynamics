defmodule OrbitalDynamics.Schema.ContactAllocationReservationConflictRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "contact_allocation_reservation_conflict_summary.v1" => %{
        "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
        "artifact_family" => "contact_allocation_reservation_conflict_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "input_contact_count",
          "station_reservation_contact_count",
          "reservation_conflict_contact_count",
          "reservation_review_contact_count",
          "station_reservation_match_status_counts",
          "reservation_conflict_match_status_counts",
          "station_reservation_status_counts",
          "station_reserved_by_counts",
          "station_reservation_ids",
          "station_reservation_expires_at_s",
          "station_reservation_expiration_status_counts",
          "reservation_conflict_contact_ids",
          "reservation_review_contact_ids",
          "station_reservation_contact_ids_by_match_status",
          "reservation_conflict_contact_ids_by_match_status",
          "station_reservation_contact_ids_by_status",
          "station_reservation_contact_ids_by_reserved_by",
          "station_reservation_contact_ids_by_expiration_status",
          "station_reservation_ids_by_match_status",
          "reservation_conflict_reservation_ids_by_match_status",
          "station_reservation_ids_by_status",
          "station_reservation_ids_by_reserved_by",
          "station_reservation_ids_by_expiration_status",
          "rows",
          "reservation_conflict_rows",
          "reservation_review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "station_reservation_expiration_now_s",
          "earliest_station_reservation_expires_at_s",
          "reservation_conflict_contact_ids_by_direction",
          "reservation_conflict_contact_ids_by_direction_and_ground_station_id",
          "model_limits"
        ],
        "nested_contracts" => ["contact_allocation_report.v1"]
      }
    }
  end
end
