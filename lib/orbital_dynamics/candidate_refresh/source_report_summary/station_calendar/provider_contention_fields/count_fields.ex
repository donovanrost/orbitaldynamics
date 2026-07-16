defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.ProviderContentionFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report,
    as: StationCalendarReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "provider_calendar_contention_group_count" =>
        sum_report_count(
          reports,
          &StationCalendarReport.provider_calendar_contention_group_count/1
        ),
      "provider_calendar_contention_provider_counts" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_counts/1)
        |> merge_count_maps(),
      "provider_calendar_contention_ground_station_counts" =>
        reports
        |> Enum.map(&ProviderContentionReport.ground_station_counts/1)
        |> merge_count_maps()
    }
  end
end
