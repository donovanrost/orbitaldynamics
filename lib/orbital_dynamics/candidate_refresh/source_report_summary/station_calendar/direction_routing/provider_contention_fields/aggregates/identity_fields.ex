defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.DirectionRouting.ProviderContentionFields.Aggregates.IdentityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.ProviderContention.Report,
    as: ProviderContentionReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    %{
      "provider_calendar_contention_provider_ids_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_ids_by_direction/1)
        |> merge_string_list_maps(),
      "provider_calendar_contention_group_ids_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.group_ids_by_direction/1)
        |> merge_string_list_maps(),
      "provider_calendar_contention_source_entry_ids_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.source_entry_ids_by_direction/1)
        |> merge_string_list_maps(),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        reports
        |> Enum.map(&ProviderContentionReport.provider_entry_ids_by_direction/1)
        |> merge_string_list_maps()
    }
  end
end
