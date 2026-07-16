defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.GroupedIds do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows,
    only: [
      ground_station_contact_pairs: 1,
      ground_station_source_window_pairs: 1,
      ground_station_station_calendar_entry_pairs: 1,
      ground_station_station_calendar_provider_entry_pairs: 1
    ]

  alias __MODULE__.GroupedMaps

  def contact_ids_by_ground_station(report) do
    GroupedMaps.grouped_ids_by_ground_station_summary(
      report,
      "contact_ids_by_ground_station_id",
      &ground_station_contact_pairs/1,
      "contact_ids_by_ground_station"
    )
  end

  def source_window_ids_by_ground_station(report) do
    GroupedMaps.grouped_ids_by_ground_station(
      report,
      &ground_station_source_window_pairs/1,
      "source_window_ids_by_ground_station"
    )
  end

  def station_calendar_entry_ids_by_ground_station(report) do
    GroupedMaps.grouped_ids_by_ground_station_summary(
      report,
      "station_calendar_entry_ids_by_ground_station_id",
      &ground_station_station_calendar_entry_pairs/1,
      "station_calendar_entry_ids_by_ground_station"
    )
  end

  def station_calendar_provider_entry_ids_by_ground_station(report) do
    GroupedMaps.grouped_ids_by_ground_station(
      report,
      &ground_station_station_calendar_provider_entry_pairs/1,
      "station_calendar_provider_entry_ids_by_ground_station"
    )
  end
end
