defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.StationSuppression do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_contact_filter_station_suppression_count" =>
        source_report_family_count(source_reports, "station_suppression_count"),
      "source_report_contact_filter_station_suppression_ground_station_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_suppression_ground_station_counts"
        ),
      "source_report_contact_filter_station_suppression_availability_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_suppression_availability_counts"
        ),
      "source_report_contact_filter_station_suppression_status_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "station_suppression_status_counts"
        ),
      "source_report_contact_filter_station_suppression_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_contact_ids_by_ground_station"
        ),
      "source_report_contact_filter_station_suppression_contact_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_contact_ids_by_availability"
        ),
      "source_report_contact_filter_station_suppression_contact_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_contact_ids_by_status"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_entry_ids_by_ground_station"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_entry_ids_by_availability"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_entry_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_entry_ids_by_status"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_provider_entry_ids_by_availability"
        ),
      "source_report_contact_filter_station_suppression_station_calendar_provider_entry_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_calendar_provider_entry_ids_by_status"
        ),
      "source_report_contact_filter_station_suppression_station_reservation_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_reservation_ids_by_ground_station"
        ),
      "source_report_contact_filter_station_suppression_station_reservation_ids_by_availability" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_reservation_ids_by_availability"
        ),
      "source_report_contact_filter_station_suppression_station_reservation_ids_by_status" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "station_suppression_station_reservation_ids_by_status"
        )
    }
  end
end
