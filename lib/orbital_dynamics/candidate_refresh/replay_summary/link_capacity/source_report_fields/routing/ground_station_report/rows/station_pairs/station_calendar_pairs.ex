defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.StationCalendarPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.StationIdValues

  alias __MODULE__.RowValues.EntryIds
  alias __MODULE__.RowValues.ProviderEntryIds

  def ground_station_station_calendar_entry_pairs(row) do
    row = stringify_keys(row)
    station_id = StationIdValues.station_id(row)

    row
    |> EntryIds.station_calendar_entry_ids()
    |> List.wrap()
    |> Enum.map(&{station_id, &1})
    |> Enum.reject(fn {station_id, station_calendar_entry_id} ->
      station_id in [nil, ""] or station_calendar_entry_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def ground_station_station_calendar_provider_entry_pairs(row) do
    row = stringify_keys(row)
    station_id = StationIdValues.station_id(row)

    row
    |> ProviderEntryIds.station_calendar_provider_entry_ids()
    |> List.wrap()
    |> Enum.map(&{station_id, &1})
    |> Enum.reject(fn {station_id, station_calendar_provider_entry_id} ->
      station_id in [nil, ""] or station_calendar_provider_entry_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
