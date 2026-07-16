defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.StationCalendarPairs.RowValues.SourceContacts.ProviderEntryIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactStationCalendarProviderEntryIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def source_contact_station_calendar_provider_entry_ids(row) do
    row
    |> SourceContactValues.source_contact_maps(Normalization)
    |> Enum.flat_map(
      &ContactStationCalendarProviderEntryIds.contact_station_calendar_provider_entry_ids(
        &1,
        Normalization
      )
    )
  end
end
