defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.StationCalendarPairs.RowValues.ProviderEntryIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.StationCalendarPairs.RowValues.SourceContacts.ProviderEntryIds,
    as: SourceContactProviderEntryIds

  def station_calendar_provider_entry_ids(row) do
    [
      row["station_calendar_provider_entry_id"],
      row["station_calendar_provider_entry_ids"],
      row["provider_entry_id"],
      row["provider_entry_ids"],
      get_in(row, ["station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(row, ["station_calendar_entry", "provider_entry_id"]),
      get_in(row, ["source_station_calendar_entry", "station_calendar_provider_entry_id"]),
      get_in(row, ["source_station_calendar_entry", "provider_entry_id"]),
      SourceContactProviderEntryIds.source_contact_station_calendar_provider_entry_ids(row)
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      station_calendar_provider_entry_ids -> station_calendar_provider_entry_ids
    end
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
