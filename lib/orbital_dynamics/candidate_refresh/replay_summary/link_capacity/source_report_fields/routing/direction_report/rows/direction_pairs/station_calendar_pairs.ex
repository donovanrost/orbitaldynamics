defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.StationCalendarPairs do
  @moduledoc false

  alias __MODULE__.PairRows
  alias __MODULE__.RowValues.EntryIds
  alias __MODULE__.RowValues.ProviderEntryIds
  alias __MODULE__.RowValues.SourceContacts.EntryIds, as: SourceContactEntryIds
  alias __MODULE__.RowValues.SourceContacts.ProviderEntryIds, as: SourceContactProviderEntryIds

  def direction_station_calendar_entry_pairs(row) do
    PairRows.direction_station_calendar_pairs(
      row,
      &SourceContactEntryIds.contact_station_calendar_entry_ids/1,
      &EntryIds.station_calendar_entry_ids/1
    )
  end

  def direction_station_calendar_provider_entry_pairs(row) do
    PairRows.direction_station_calendar_pairs(
      row,
      &SourceContactProviderEntryIds.contact_station_calendar_provider_entry_ids/1,
      &ProviderEntryIds.station_calendar_provider_entry_ids/1
    )
  end
end
