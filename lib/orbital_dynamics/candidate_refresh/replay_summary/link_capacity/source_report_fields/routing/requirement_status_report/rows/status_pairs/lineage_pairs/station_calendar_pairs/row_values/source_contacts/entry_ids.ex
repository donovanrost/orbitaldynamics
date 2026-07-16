defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.SourceContacts.EntryIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactStationCalendarEntryIds

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.SourceContacts.RowFieldValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def row_station_calendar_entry_ids(row, fields) do
    row
    |> RowFieldValues.row_field_values(fields)
    |> Enum.flat_map(&contact_station_calendar_entry_ids/1)
    |> sorted_non_empty_values()
  end

  def source_contact_station_calendar_entry_ids(row) do
    row
    |> SourceContactValues.source_contact_maps(Normalization)
    |> Enum.flat_map(&contact_station_calendar_entry_ids/1)
  end

  defp contact_station_calendar_entry_ids(%{} = contact) do
    ContactStationCalendarEntryIds.contact_station_calendar_entry_ids(contact, Normalization)
  end

  defp contact_station_calendar_entry_ids(_contact), do: []

  defp sorted_non_empty_values(values), do: Normalization.sorted_non_empty_values(values)
end
