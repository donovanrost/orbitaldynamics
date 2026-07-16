defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs do
  @moduledoc false

  alias __MODULE__.Normalization
  alias __MODULE__.RowDirection
  alias __MODULE__.SourceContacts.ContactDirections, as: SourceContactDirections
  alias __MODULE__.SourceWindowPairs
  alias __MODULE__.StationCalendarPairs

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.ContactIdValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def direction_contact_pairs(row) do
    row = stringify_keys(row)
    row_direction = row_direction(row)

    row
    |> SourceContactValues.source_contact_values()
    |> Enum.map(fn contact ->
      {SourceContactDirections.source_contact_direction(contact) || row_direction,
       ContactIdValues.source_contact_id(contact, Normalization)}
    end)
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  def direction_source_window_pairs(row) do
    SourceWindowPairs.direction_source_window_pairs(row)
  end

  def direction_station_calendar_entry_pairs(row) do
    StationCalendarPairs.direction_station_calendar_entry_pairs(row)
  end

  def direction_station_calendar_provider_entry_pairs(row) do
    StationCalendarPairs.direction_station_calendar_provider_entry_pairs(row)
  end

  def row_direction(row), do: RowDirection.row_direction(row)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
