defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ProviderContentionFields.Aggregates.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
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
