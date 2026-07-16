defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Identity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_identity_fields(source_reports) do
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
        )
    }
  end
end
