defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.StationCalendarPairs.RowValues.SourceContacts.ProviderEntryIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionContactStationCalendarIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def source_contact_station_calendar_provider_entry_ids(row) do
    row
    |> SourceContactValues.source_contact_maps(Normalization)
    |> Enum.flat_map(&contact_station_calendar_provider_entry_ids/1)
  end

  def contact_station_calendar_provider_entry_ids(%{} = contact) do
    DirectionContactStationCalendarIds.contact_station_calendar_provider_entry_ids(
      contact,
      Normalization
    )
  end

  def contact_station_calendar_provider_entry_ids(_contact), do: []
end
