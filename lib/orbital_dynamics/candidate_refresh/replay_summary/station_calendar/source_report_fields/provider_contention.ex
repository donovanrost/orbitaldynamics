defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_provider_contention_fields(source_reports) do
    %{
      "source_report_station_calendar_provider_calendar_contention_group_count" =>
        source_report_family_count(source_reports, "provider_calendar_contention_group_count"),
      "source_report_station_calendar_provider_calendar_contention_group_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_group_ids"
        ),
      "source_report_station_calendar_provider_calendar_contention_source_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_source_entry_ids"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_entry_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "provider_calendar_contention_provider_entry_ids"
        ),
      "source_report_station_calendar_provider_calendar_contention_capacity_fractions" =>
        source_report_family_merge_numeric_lists(
          source_reports,
          "provider_calendar_contention_capacity_fractions"
        ),
      "source_report_station_calendar_provider_calendar_contention_minimum_capacity_fraction" =>
        source_report_family_numeric_min(
          source_reports,
          "provider_calendar_contention_minimum_capacity_fraction"
        ),
      "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_provider" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "provider_calendar_contention_capacity_fractions_by_provider"
        ),
      "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_ground_station" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "provider_calendar_contention_capacity_fractions_by_ground_station"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_provider" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_provider"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_ground_station"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_ids_by_direction"
        ),
      "source_report_station_calendar_provider_calendar_contention_direction_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_calendar_contention_direction_counts"
        ),
      "source_report_station_calendar_provider_calendar_contention_group_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_group_ids_by_direction"
        ),
      "source_report_station_calendar_provider_calendar_contention_source_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_source_entry_ids_by_direction"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_entry_ids_by_direction" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "provider_calendar_contention_provider_entry_ids_by_direction"
        ),
      "source_report_station_calendar_provider_calendar_contention_capacity_fractions_by_direction" =>
        source_report_family_merge_numeric_list_maps(
          source_reports,
          "provider_calendar_contention_capacity_fractions_by_direction"
        ),
      "source_report_station_calendar_provider_calendar_contention_provider_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_calendar_contention_provider_counts"
        ),
      "source_report_station_calendar_provider_calendar_contention_ground_station_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "provider_calendar_contention_ground_station_counts"
        )
    }
  end
end
