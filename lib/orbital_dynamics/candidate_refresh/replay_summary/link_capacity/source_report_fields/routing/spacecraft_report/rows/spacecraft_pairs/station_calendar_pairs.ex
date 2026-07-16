defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.StationCalendarPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs.SpacecraftIdValues

  alias __MODULE__.RowValues.EntryIds
  alias __MODULE__.RowValues.ProviderEntryIds

  def spacecraft_station_calendar_entry_pairs(row) do
    row = stringify_keys(row)
    spacecraft_id = SpacecraftIdValues.spacecraft_id(row)

    row
    |> EntryIds.station_calendar_entry_ids()
    |> List.wrap()
    |> Enum.map(&{spacecraft_id, &1})
    |> Enum.reject(fn {spacecraft_id, station_calendar_entry_id} ->
      spacecraft_id in [nil, ""] or station_calendar_entry_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def spacecraft_station_calendar_provider_entry_pairs(row) do
    row = stringify_keys(row)
    spacecraft_id = SpacecraftIdValues.spacecraft_id(row)

    row
    |> ProviderEntryIds.station_calendar_provider_entry_ids()
    |> List.wrap()
    |> Enum.map(&{spacecraft_id, &1})
    |> Enum.reject(fn {spacecraft_id, station_calendar_provider_entry_id} ->
      spacecraft_id in [nil, ""] or station_calendar_provider_entry_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
