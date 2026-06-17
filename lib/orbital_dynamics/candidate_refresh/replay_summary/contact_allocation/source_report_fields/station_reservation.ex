defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Aggregation

  import Aggregation

  def source_report_station_reservation_fields(source_reports) do
    %{
      "source_report_contact_allocation_station_reservation_match_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_reservation_match_status_counts"
        ),
      "source_report_contact_allocation_station_reservation_contact_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_contact_ids_by_match_status"
        ),
      "source_report_contact_allocation_station_reservation_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_match_status"
        ),
      "source_report_contact_allocation_station_reservation_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_reservation_status_counts"
        ),
      "source_report_contact_allocation_station_reserved_by_counts" =>
        source_report_family_merge_count_maps(source_reports, "station_reserved_by_counts"),
      "source_report_contact_allocation_station_reservation_ids" =>
        source_report_family_merge_string_lists(source_reports, "station_reservation_ids"),
      "source_report_contact_allocation_station_reservation_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_contact_ids_by_status"
        ),
      "source_report_contact_allocation_station_reservation_contact_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_contact_ids_by_reserved_by"
        ),
      "source_report_contact_allocation_station_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_status"
        ),
      "source_report_contact_allocation_station_reservation_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_reserved_by"
        ),
      "source_report_contact_allocation_station_reservation_expires_at_s" =>
        source_report_family_merge_numeric_lists(
          source_reports,
          "station_reservation_expires_at_s"
        ),
      "source_report_contact_allocation_station_reservation_expiration_now_s" =>
        source_report_family_numeric_min(
          source_reports,
          "station_reservation_expiration_now_s"
        ),
      "source_report_contact_allocation_station_reservation_expiration_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_reservation_expiration_status_counts"
        ),
      "source_report_contact_allocation_station_reservation_active_contact_count" =>
        source_report_family_count(source_reports, "station_reservation_active_contact_count"),
      "source_report_contact_allocation_station_reservation_expired_contact_count" =>
        source_report_family_count(source_reports, "station_reservation_expired_contact_count"),
      "source_report_contact_allocation_station_reservation_declared_expiration_contact_count" =>
        source_report_family_count(
          source_reports,
          "station_reservation_declared_expiration_contact_count"
        ),
      "source_report_contact_allocation_station_reservation_missing_expiration_contact_count" =>
        source_report_family_count(
          source_reports,
          "station_reservation_missing_expiration_contact_count"
        ),
      "source_report_contact_allocation_earliest_station_reservation_expires_at_s" =>
        source_report_family_numeric_min(
          source_reports,
          "earliest_station_reservation_expires_at_s"
        ),
      "source_report_contact_allocation_station_reservation_contact_ids_by_expiration_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_contact_ids_by_expiration_status"
        ),
      "source_report_contact_allocation_station_reservation_ids_by_expiration_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_expiration_status"
        )
    }
  end
end
