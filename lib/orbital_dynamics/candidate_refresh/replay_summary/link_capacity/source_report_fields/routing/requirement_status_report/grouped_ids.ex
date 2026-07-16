defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.GroupedIds do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows,
    only: [
      requirement_status_contact_pairs: 1,
      requirement_status_source_window_pairs: 1,
      requirement_status_station_calendar_entry_pairs: 1,
      requirement_status_station_calendar_provider_entry_pairs: 1
    ]

  alias __MODULE__.GroupedMaps
  alias __MODULE__.RequirementStatusCounts

  def requirement_status_counts(report) do
    RequirementStatusCounts.requirement_status_counts(report)
  end

  def contact_ids_by_requirement_status(report) do
    GroupedMaps.grouped_ids_by_requirement_status(
      report,
      &requirement_status_contact_pairs/1,
      "contact_ids_by_requirement_status"
    )
  end

  def source_window_ids_by_requirement_status(report) do
    GroupedMaps.grouped_ids_by_requirement_status(
      report,
      &requirement_status_source_window_pairs/1,
      "source_window_ids_by_requirement_status"
    )
  end

  def station_calendar_entry_ids_by_requirement_status(report) do
    GroupedMaps.grouped_ids_by_requirement_status(
      report,
      &requirement_status_station_calendar_entry_pairs/1,
      "station_calendar_entry_ids_by_requirement_status"
    )
  end

  def station_calendar_provider_entry_ids_by_requirement_status(report) do
    GroupedMaps.grouped_ids_by_requirement_status(
      report,
      &requirement_status_station_calendar_provider_entry_pairs/1,
      "station_calendar_provider_entry_ids_by_requirement_status"
    )
  end
end
