defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.GroupedIds do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows,
    only: [
      spacecraft_contact_pairs: 1,
      spacecraft_source_window_pairs: 1,
      spacecraft_station_calendar_entry_pairs: 1,
      spacecraft_station_calendar_provider_entry_pairs: 1
    ]

  alias __MODULE__.GroupedMaps

  def contact_ids_by_spacecraft(report) do
    GroupedMaps.grouped_ids_by_spacecraft(
      report,
      &spacecraft_contact_pairs/1,
      "contact_ids_by_spacecraft"
    )
  end

  def source_window_ids_by_spacecraft(report) do
    GroupedMaps.grouped_ids_by_spacecraft(
      report,
      &spacecraft_source_window_pairs/1,
      "source_window_ids_by_spacecraft"
    )
  end

  def station_calendar_entry_ids_by_spacecraft(report) do
    GroupedMaps.grouped_ids_by_spacecraft(
      report,
      &spacecraft_station_calendar_entry_pairs/1,
      "station_calendar_entry_ids_by_spacecraft"
    )
  end

  def station_calendar_provider_entry_ids_by_spacecraft(report) do
    GroupedMaps.grouped_ids_by_spacecraft(
      report,
      &spacecraft_station_calendar_provider_entry_pairs/1,
      "station_calendar_provider_entry_ids_by_spacecraft"
    )
  end
end
