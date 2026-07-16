defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.IdentityStatus do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_identity_status_fields(source_reports) do
    %{
      "source_report_station_reservation_affected_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "affected_contact_ids"),
      "source_report_station_reservation_contact_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_match_status"
        ),
      "source_report_station_reservation_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_status"),
      "source_report_station_reservation_expires_at_s" =>
        source_report_family_merge_numeric_lists(source_reports, "reservation_expires_at_s"),
      "source_report_station_reservation_earliest_expires_at_s" =>
        source_report_family_numeric_min(source_reports, "earliest_reservation_expires_at_s"),
      "source_report_station_reservation_match_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_reservation_match_status_counts"
        ),
      "source_report_station_reservation_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "reservation_status_counts"),
      "source_report_station_reservation_ids" =>
        source_report_family_merge_string_lists(source_reports, "reservation_ids"),
      "source_report_station_reservation_ids_by_match_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_match_status"
        ),
      "source_report_station_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_status"
        ),
      "source_report_station_reservation_reserved_by_counts" =>
        source_report_family_merge_count_maps(source_reports, "reserved_by_counts"),
      "source_report_station_reservation_contact_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_reserved_by"
        ),
      "source_report_station_reservation_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reservation_ids_by_reserved_by"
        )
    }
  end
end
