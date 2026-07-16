defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.ProviderContentionFields.Aggregates.EntryIdMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "provider_calendar_contention_provider_entry_ids_by_provider" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_entry_ids_by_provider/1)
        |> merge_string_list_maps(),
      "provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_entry_ids_by_ground_station/1)
        |> merge_string_list_maps(),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_entry_ids_by_direction/1)
        |> merge_string_list_maps()
    }
  end
end
