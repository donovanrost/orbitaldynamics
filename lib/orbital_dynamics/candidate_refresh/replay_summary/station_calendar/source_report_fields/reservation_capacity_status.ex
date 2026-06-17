defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ReservationCapacityStatus do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_reservation_capacity_status_fields(source_reports) do
    %{
      "source_report_station_calendar_reserved_by_counts" =>
        source_report_family_merge_count_maps(source_reports, "reserved_by_counts"),
      "source_report_station_calendar_contact_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_reserved_by"
        ),
      "source_report_station_calendar_entry_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_reserved_by"
        ),
      "source_report_station_calendar_reservation_ids_by_reserved_by" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_reserved_by"
        ),
      "source_report_station_calendar_reservation_expires_at_s" =>
        source_report_family_merge_numeric_lists(
          source_reports,
          "station_reservation_expires_at_s"
        ),
      "source_report_station_calendar_earliest_reservation_expires_at_s" =>
        source_report_family_numeric_min(
          source_reports,
          "earliest_station_reservation_expires_at_s"
        ),
      "source_report_station_calendar_capacity_fractions" =>
        source_report_family_merge_numeric_lists(
          source_reports,
          "station_capacity_fractions"
        ),
      "source_report_station_calendar_minimum_capacity_fraction" =>
        source_report_family_numeric_min(source_reports, "minimum_station_capacity_fraction"),
      "source_report_station_calendar_capacity_fractions_by_status" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "station_capacity_fractions_by_status"
        ),
      "source_report_station_calendar_capacity_fractions_by_ground_station" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "station_capacity_fractions_by_ground_station"
        ),
      "source_report_station_calendar_capacity_fractions_by_availability" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "station_capacity_fractions_by_availability"
        ),
      "source_report_station_calendar_entry_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_status"
        ),
      "source_report_station_calendar_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_ground_station"
        ),
      "source_report_station_calendar_entry_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_calendar_entry_ids_by_availability"
        ),
      "source_report_station_calendar_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_status"
        ),
      "source_report_station_calendar_reservation_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_ground_station"
        ),
      "source_report_station_calendar_reservation_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_reservation_ids_by_availability"
        ),
      "source_report_station_calendar_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_status"),
      "source_report_station_calendar_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_ground_station"
        ),
      "source_report_station_calendar_contact_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "contact_ids_by_availability"
        ),
      "source_report_station_calendar_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "station_calendar_status_counts"),
      "source_report_station_calendar_affected_contact_ground_station_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "affected_contact_ground_station_counts"
        ),
      "source_report_station_calendar_affected_contact_availability_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "affected_contact_availability_counts"
        )
    }
  end
end
