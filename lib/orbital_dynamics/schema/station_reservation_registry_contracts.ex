defmodule OrbitalDynamics.Schema.StationReservationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "station_reservation_report.v1" => %{
        "schema_contract" => "station_reservation_report.v1",
        "artifact_family" => "station_reservation_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "schema_version",
          "model",
          "source",
          "affected_contact_reservation_count",
          "provider_calendar_contention_group_count",
          "reservation_review_count",
          "reservation_review_status",
          "station_reservation_match_status_counts",
          "reservation_status_counts",
          "reservation_ids",
          "affected_contacts",
          "provider_calendar_contention_groups",
          "assumptions"
        ],
        "optional_fields" => [
          "reservation_ids_by_status",
          "reservation_ids_by_match_status"
        ],
        "nested_contracts" => ["station_calendar_report.v1"]
      },
      "station_reservation_review_summary.v1" => %{
        "schema_contract" => "station_reservation_review_summary.v1",
        "artifact_family" => "station_reservation_review_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "source",
          "reservation_count",
          "affected_contact_reservation_count",
          "provider_calendar_contention_group_count",
          "reservation_review_status",
          "reservation_expiration_count",
          "reservation_expiration_status_counts",
          "reservation_ids_by_expiration_status",
          "expired_reservation_count",
          "active_reservation_count",
          "missing_reservation_expiration_count",
          "review_reservation_ids",
          "review_rows",
          "assumptions"
        ],
        "optional_fields" => [
          "earliest_reservation_expires_at_s",
          "model_limits"
        ],
        "nested_contracts" => ["station_reservation_report.v1"]
      }
    }
  end
end
