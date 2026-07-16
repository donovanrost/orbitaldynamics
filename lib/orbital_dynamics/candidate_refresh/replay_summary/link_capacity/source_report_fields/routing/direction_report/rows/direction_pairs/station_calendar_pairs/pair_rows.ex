defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.StationCalendarPairs.PairRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.{
    Normalization,
    RowDirection
  }

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.SourceContacts.ContactDirections,
    as: SourceContactDirections

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  def direction_station_calendar_pairs(row, contact_id_fun, row_id_fun) do
    row = stringify_keys(row)
    row_direction = row_direction(row)

    contact_pairs =
      row
      |> SourceContactValues.source_contact_values()
      |> Enum.filter(&is_map/1)
      |> Enum.flat_map(fn contact ->
        contact = stringify_keys(contact)
        direction = source_contact_direction(contact) || row_direction

        contact
        |> contact_id_fun.()
        |> Enum.map(&{direction, &1})
      end)

    row_pairs =
      row
      |> row_id_fun.()
      |> List.wrap()
      |> Enum.map(&{row_direction, &1})

    (contact_pairs ++ row_pairs)
    |> Enum.reject(fn {direction, station_calendar_entry_id} ->
      direction in [nil, ""] or station_calendar_entry_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp row_direction(row), do: RowDirection.row_direction(row)

  defp source_contact_direction(contact),
    do: SourceContactDirections.source_contact_direction(contact)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
