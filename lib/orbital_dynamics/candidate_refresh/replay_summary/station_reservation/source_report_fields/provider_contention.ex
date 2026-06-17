defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.ProviderContention do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Aggregation

  def source_report_provider_contention_fields(source_reports) do
    %{
      "source_report_station_reservation_provider_calendar_contention_group_count" =>
        source_report_family_count(source_reports, "provider_calendar_contention_group_count"),
      "source_report_station_reservation_provider_calendar_contention_group_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_group_ids"
        ),
      "source_report_station_reservation_provider_calendar_contention_source_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_source_entry_ids"
        ),
      "source_report_station_reservation_provider_calendar_contention_provider_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_provider_entry_ids"
        ),
      "source_report_station_reservation_provider_calendar_contention_provider_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_calendar_contention_provider_counts"
        ),
      "source_report_station_reservation_provider_calendar_contention_ground_station_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_calendar_contention_ground_station_counts"
        ),
      "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_provider" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_provider"
        ),
      "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_ground_station"
        ),
      "source_report_station_reservation_provider_calendar_contention_provider_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_direction"
        )
    }
  end
end
