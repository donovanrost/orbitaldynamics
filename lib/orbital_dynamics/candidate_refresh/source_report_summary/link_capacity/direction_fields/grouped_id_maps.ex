defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.DirectionFields.GroupedIdMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.GroupedIds,
    as: DirectionGroupedIds

  alias __MODULE__.MergedValues

  def fields(reports) do
    %{
      direction_counts: MergedValues.count_map(reports, &DirectionGroupedIds.direction_counts/1),
      contact_ids_by_direction:
        MergedValues.string_list_map(reports, &DirectionGroupedIds.contact_ids_by_direction/1),
      source_window_ids_by_direction:
        MergedValues.string_list_map(
          reports,
          &DirectionGroupedIds.source_window_ids_by_direction/1
        ),
      station_calendar_entry_ids_by_direction:
        MergedValues.string_list_map(
          reports,
          &DirectionGroupedIds.station_calendar_entry_ids_by_direction/1
        ),
      station_calendar_provider_entry_ids_by_direction:
        MergedValues.string_list_map(
          reports,
          &DirectionGroupedIds.station_calendar_provider_entry_ids_by_direction/1
        )
    }
  end
end
