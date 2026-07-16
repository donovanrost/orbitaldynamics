defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.ProviderContentionFields.Aggregates.MetricFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_numeric_list_maps: 1
    ]

  def fields(reports) do
    %{
      "provider_calendar_contention_direction_counts" =>
        reports
        |> Enum.map(&ProviderContentionReport.direction_counts/1)
        |> merge_count_maps(),
      "provider_calendar_contention_capacity_fractions_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.capacity_fractions_by_direction/1)
        |> merge_numeric_list_maps()
    }
  end
end
