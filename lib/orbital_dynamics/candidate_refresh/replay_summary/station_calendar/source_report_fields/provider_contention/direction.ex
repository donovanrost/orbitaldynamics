defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Direction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_direction_fields(source_reports) do
    %{
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
        )
    }
  end
end
