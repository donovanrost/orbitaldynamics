defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Precedence do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_precedence_fields(source_reports) do
    %{
      "source_report_station_calendar_precedence_review_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "precedence_review_status_counts"),
      "source_report_station_calendar_applied_availability_counts" =>
        source_report_family_merge_count_maps(source_reports, "applied_availability_counts"),
      "source_report_station_calendar_overlap_availability_counts" =>
        source_report_family_merge_count_maps(source_reports, "overlap_availability_counts"),
      "source_report_station_calendar_affected_contact_ids_by_applied_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "affected_contact_ids_by_applied_availability"
        ),
      "source_report_station_calendar_affected_contact_ids_by_overlap_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "affected_contact_ids_by_overlap_availability"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_contact_count" =>
        source_report_family_count(
          source_reports,
          "reserved_under_higher_precedence_contact_count"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "reserved_under_higher_precedence_contact_ids"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reserved_under_higher_precedence_contact_ids_by_applied_availability"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "reserved_under_higher_precedence_reservation_ids"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reserved_under_higher_precedence_reservation_ids_by_status"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reserved_under_higher_precedence_reservation_ids_by_reserved_by"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reserved_under_higher_precedence_contact_ids_by_reservation_status"
        ),
      "source_report_station_calendar_reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "reserved_under_higher_precedence_contact_ids_by_reserved_by"
        )
    }
  end
end
