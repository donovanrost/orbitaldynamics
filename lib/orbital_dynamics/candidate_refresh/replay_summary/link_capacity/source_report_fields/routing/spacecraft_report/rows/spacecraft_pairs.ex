defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SpacecraftReport.Rows.SpacecraftPairs do
  @moduledoc false

  alias __MODULE__.Normalization
  alias __MODULE__.RowValues.SourceContacts.ContactIds, as: SourceContactIds
  alias __MODULE__.RowValues.SourceWindowIds
  alias __MODULE__.SpacecraftIdValues
  alias __MODULE__.StationCalendarPairs

  def spacecraft_contact_pairs(row) do
    row = stringify_keys(row)
    spacecraft_id = SpacecraftIdValues.spacecraft_id(row)

    row
    |> SourceContactIds.source_contact_ids()
    |> List.wrap()
    |> Enum.map(&{spacecraft_id, &1})
    |> Enum.reject(fn {spacecraft_id, contact_id} ->
      spacecraft_id in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def spacecraft_source_window_pairs(row) do
    row = stringify_keys(row)
    spacecraft_id = SpacecraftIdValues.spacecraft_id(row)

    row
    |> SourceWindowIds.source_window_ids()
    |> List.wrap()
    |> Enum.map(&{spacecraft_id, &1})
    |> Enum.reject(fn {spacecraft_id, source_window_id} ->
      spacecraft_id in [nil, ""] or source_window_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def spacecraft_station_calendar_entry_pairs(row) do
    StationCalendarPairs.spacecraft_station_calendar_entry_pairs(row)
  end

  def spacecraft_station_calendar_provider_entry_pairs(row) do
    StationCalendarPairs.spacecraft_station_calendar_provider_entry_pairs(row)
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
