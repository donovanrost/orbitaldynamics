defmodule OrbitalDynamics.Schema.StationReservationHoldRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "station_reservation_hold_summary.v1" => %{
        "schema_contract" => "station_reservation_hold_summary.v1",
        "artifact_family" => "station_reservation_hold_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "source",
          "reservation_hold_count",
          "affected_contact_reservation_hold_count",
          "provider_calendar_contention_hold_count",
          "reservation_hold_review_status",
          "reservation_hold_expiration_count",
          "reservation_hold_expiration_status_counts",
          "reservation_hold_status_counts",
          "reservation_hold_ids",
          "reservation_hold_ids_by_expiration_status",
          "reservation_hold_ids_by_status",
          "reservation_hold_ids_by_reserved_by",
          "reservation_hold_ids_by_row_type",
          "reservation_hold_contact_ids_by_expiration_status",
          "review_contact_ids",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "earliest_reservation_hold_expires_at_s",
          "model_limits"
        ],
        "nested_contracts" => ["station_reservation_review_summary.v1"]
      },
      "station_reservation_hold_import_readiness_summary.v1" => %{
        "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
        "artifact_family" => "station_reservation_hold_import_readiness_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "reservation_hold_count",
          "import_readiness_status",
          "import_classification",
          "ready_for_import_count",
          "review_required_before_import_count",
          "no_import_required_count",
          "reservation_hold_import_status_counts",
          "reservation_hold_status_counts",
          "reservation_hold_expiration_status_counts",
          "required_import_action_counts",
          "reservation_hold_ids",
          "reservation_hold_ids_by_import_status",
          "reservation_hold_ids_by_expiration_status",
          "reservation_hold_ids_by_status",
          "reservation_hold_ids_by_reserved_by",
          "reservation_hold_ids_by_required_import_action",
          "reservation_hold_contact_ids_by_import_status",
          "reservation_hold_contact_ids_by_expiration_status",
          "review_contact_ids",
          "import_readiness_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "reservation_hold_ids_by_direction",
          "reservation_hold_ids_by_direction_and_ground_station_id",
          "reservation_hold_contact_ids_by_direction",
          "reservation_hold_contact_ids_by_direction_and_ground_station_id",
          "model_limits"
        ],
        "nested_contracts" => ["station_reservation_report.v1"]
      }
    }
  end
end
