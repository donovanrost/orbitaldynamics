defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.ReservationHold do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_reservation_hold_fields(source_reports) do
    %{
      "source_report_station_reservation_hold_count" =>
        source_report_family_count(source_reports, "reservation_hold_count"),
      "source_report_station_reservation_affected_contact_hold_count" =>
        source_report_family_count(source_reports, "affected_contact_reservation_hold_count"),
      "source_report_station_reservation_provider_calendar_contention_hold_count" =>
        source_report_family_count(source_reports, "provider_calendar_contention_hold_count"),
      "source_report_station_reservation_hold_review_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reservation_hold_review_status_counts"
        ),
      "source_report_station_reservation_hold_expiration_count" =>
        source_report_family_count(source_reports, "reservation_hold_expiration_count"),
      "source_report_station_reservation_earliest_hold_expires_at_s" =>
        source_report_family_numeric_min(
          source_reports,
          "earliest_reservation_hold_expires_at_s"
        ),
      "source_report_station_reservation_hold_expiration_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reservation_hold_expiration_status_counts"
        ),
      "source_report_station_reservation_hold_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "reservation_hold_status_counts"),
      "source_report_station_reservation_hold_import_readiness_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reservation_hold_import_readiness_status_counts"
        ),
      "source_report_station_reservation_hold_import_classification_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reservation_hold_import_classification_counts"
        ),
      "source_report_station_reservation_hold_ready_for_import_count" =>
        source_report_family_count(source_reports, "reservation_hold_ready_for_import_count"),
      "source_report_station_reservation_hold_review_required_before_import_count" =>
        source_report_family_count(
          source_reports,
          "reservation_hold_review_required_before_import_count"
        ),
      "source_report_station_reservation_hold_no_import_required_count" =>
        source_report_family_count(source_reports, "reservation_hold_no_import_required_count"),
      "source_report_station_reservation_hold_import_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "reservation_hold_import_status_counts"
        ),
      "source_report_station_reservation_hold_required_import_action_counts" =>
        source_report_family_merge_count_maps(source_reports, "required_import_action_counts"),
      "source_report_station_reservation_hold_ids" =>
        source_report_family_merge_string_lists(source_reports, "reservation_hold_ids"),
      "source_report_station_reservation_hold_ids_by_import_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_import_status"
        ),
      "source_report_station_reservation_hold_ids_by_required_import_action" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_required_import_action"
        ),
      "source_report_station_reservation_hold_ids_by_expiration_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_expiration_status"
        ),
      "source_report_station_reservation_hold_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_status"
        ),
      "source_report_station_reservation_hold_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_reserved_by"
        ),
      "source_report_station_reservation_hold_ids_by_row_type" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_row_type"
        ),
      "source_report_station_reservation_hold_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_ids_by_direction"
        ),
      "source_report_station_reservation_hold_contact_ids_by_import_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_contact_ids_by_import_status"
        ),
      "source_report_station_reservation_hold_contact_ids_by_expiration_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_contact_ids_by_expiration_status"
        ),
      "source_report_station_reservation_hold_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_hold_contact_ids_by_direction"
        ),
      "source_report_station_reservation_hold_review_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "reservation_hold_review_contact_ids"
        )
    }
  end
end
