defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs do
  @moduledoc false

  alias __MODULE__.Normalization
  alias __MODULE__.RowValues.SourceContacts.ContactIds, as: SourceContactIds
  alias __MODULE__.RowValues.SourceWindowIds
  alias __MODULE__.StationCalendarPairs
  alias __MODULE__.StationIdValues

  def ground_station_contact_pairs(row) do
    row = stringify_keys(row)
    station_id = StationIdValues.station_id(row)

    row
    |> SourceContactIds.source_contact_ids()
    |> List.wrap()
    |> Enum.map(&{station_id, &1})
    |> Enum.reject(fn {station_id, contact_id} ->
      station_id in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def ground_station_source_window_pairs(row) do
    row = stringify_keys(row)
    station_id = StationIdValues.station_id(row)

    row
    |> SourceWindowIds.source_window_ids()
    |> List.wrap()
    |> Enum.map(&{station_id, &1})
    |> Enum.reject(fn {station_id, source_window_id} ->
      station_id in [nil, ""] or source_window_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def ground_station_station_calendar_entry_pairs(row) do
    StationCalendarPairs.ground_station_station_calendar_entry_pairs(row)
  end

  def ground_station_station_calendar_provider_entry_pairs(row) do
    StationCalendarPairs.ground_station_station_calendar_provider_entry_pairs(row)
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
