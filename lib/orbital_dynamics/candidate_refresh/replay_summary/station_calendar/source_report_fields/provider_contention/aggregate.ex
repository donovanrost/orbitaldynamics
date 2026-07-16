defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Aggregate do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_aggregate_fields(source_reports) do
    %{
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
