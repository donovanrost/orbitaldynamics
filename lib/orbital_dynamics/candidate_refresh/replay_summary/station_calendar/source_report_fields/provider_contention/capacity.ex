defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Capacity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Aggregation

  def source_report_capacity_fields(source_reports) do
    %{
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
        )
    }
  end
end
