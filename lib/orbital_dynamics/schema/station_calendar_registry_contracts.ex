defmodule OrbitalDynamics.Schema.StationCalendarRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "station_calendar_provider.v1" => %{
        "schema_contract" => "station_calendar_provider.v1",
        "artifact_family" => "station_calendar_provider",
        "schema_version" => 1,
        "required_fields" => ["schema_contract", "id", "entries"],
        "optional_fields" => ["provider_id", "trust_boundary", "provenance", "assumptions"],
        "nested_contracts" => []
      },
      "station_calendar_report.v1" => %{
        "schema_contract" => "station_calendar_report.v1",
        "artifact_family" => "station_calendar_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "input_contact_count",
          "calendar_entry_count",
          "affected_contact_count",
          "affected_contacts",
          "assumptions"
        ],
        "optional_fields" => [
          "affected_duration_s",
          "calendar_entry_trust_boundary_status_counts",
          "duplicate_affected_contact_id_count",
          "duplicate_affected_contact_row_count",
          "affected_contact_availability_counts",
          "affected_contact_ground_station_counts",
          "direction_counts",
          "model_limits",
          "provider_calendar_contention_group_count",
          "provider_calendar_contention_groups",
          "provider_counteroffer_count",
          "station_calendar_status_counts",
          "station_reservation_match_status_counts",
          "affected_contact_ids_by_reservation_match_status",
          "affected_contact_ids_by_station_calendar_trust_boundary_status",
          "station_calendar_trust_boundary_status_counts"
        ],
        "nested_contracts" => ["station_calendar_provider.v1"]
      },
      "station_calendar_precedence_summary.v1" => %{
        "schema_contract" => "station_calendar_precedence_summary.v1",
        "artifact_family" => "station_calendar_precedence_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source_artifact_type",
          "affected_contact_count",
          "precedence_review_status",
          "applied_availability_counts",
          "overlap_availability_counts",
          "affected_contact_ids_by_applied_availability",
          "affected_contact_ids_by_overlap_availability",
          "reserved_under_higher_precedence_contact_count",
          "reserved_under_higher_precedence_contact_ids",
          "reserved_under_higher_precedence_contact_ids_by_applied_availability",
          "unavailable_contact_ids",
          "reserved_overlap_contact_ids",
          "reduced_capacity_contact_ids",
          "assumptions"
        ],
        "optional_fields" => [
          "source",
          "model_limits",
          "applied_status_counts",
          "affected_contact_ids_by_applied_status",
          "reserved_under_higher_precedence_contact_ids_by_applied_status",
          "reserved_under_higher_precedence_reservation_ids",
          "reserved_under_higher_precedence_reservation_ids_by_status",
          "reserved_under_higher_precedence_reservation_ids_by_reserved_by",
          "reserved_under_higher_precedence_contact_ids_by_reservation_status",
          "reserved_under_higher_precedence_contact_ids_by_reserved_by"
        ],
        "nested_contracts" => ["station_calendar_report.v1"]
      }
    }
  end
end
