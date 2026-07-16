defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.ProviderContentionFields.CapacityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_numeric_list_maps: 1
    ]

  def fields(reports) do
    %{
      "provider_calendar_contention_capacity_fractions" =>
        ProviderContentionReport.capacity_fractions(reports),
      "provider_calendar_contention_minimum_capacity_fraction" =>
        reports
        |> ProviderContentionReport.capacity_fractions()
        |> min_list(),
      "provider_calendar_contention_capacity_fractions_by_provider" =>
        reports
        |> Enum.map(&ProviderContentionReport.capacity_fractions_by_provider/1)
        |> merge_numeric_list_maps(),
      "provider_calendar_contention_capacity_fractions_by_ground_station" =>
        reports
        |> Enum.map(&ProviderContentionReport.capacity_fractions_by_ground_station/1)
        |> merge_numeric_list_maps()
    }
  end

  defp min_list(values) when is_list(values), do: Enum.min(values, fn -> nil end)
  defp min_list(_values), do: nil
end
