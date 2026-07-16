defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.EntryIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.ProviderEntryIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.SourceContacts.EntryIds,
    as: SourceContactEntryIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.SourceContacts.ProviderEntryIds,
    as: SourceContactProviderEntryIds

  @selected_contact_object_fields [
    "selected_contacts",
    "selected_contact"
  ]

  @actual_throughput_contact_object_fields [
    "actual_throughput_contacts",
    "actual_throughput_contact"
  ]

  def selected_contact_station_calendar_entry_ids(row) do
    SourceContactEntryIds.row_station_calendar_entry_ids(row, @selected_contact_object_fields) ||
      EntryIds.station_calendar_entry_ids(row)
  end

  def actual_throughput_station_calendar_entry_ids(row) do
    SourceContactEntryIds.row_station_calendar_entry_ids(
      row,
      @actual_throughput_contact_object_fields
    ) || EntryIds.station_calendar_entry_ids(row)
  end

  def selected_contact_station_calendar_provider_entry_ids(row) do
    SourceContactProviderEntryIds.row_station_calendar_provider_entry_ids(
      row,
      @selected_contact_object_fields
    ) || ProviderEntryIds.station_calendar_provider_entry_ids(row)
  end

  def actual_throughput_station_calendar_provider_entry_ids(row) do
    SourceContactProviderEntryIds.row_station_calendar_provider_entry_ids(
      row,
      @actual_throughput_contact_object_fields
    ) || ProviderEntryIds.station_calendar_provider_entry_ids(row)
  end
end
