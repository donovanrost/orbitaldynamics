defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.SourceWindowPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.{
    Normalization,
    RowDirection
  }

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.SourceContacts.ContactDirections,
    as: SourceContactDirections

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.SourceContactValues

  alias __MODULE__.SourceWindowIds

  def direction_source_window_pairs(row) do
    row = stringify_keys(row)
    row_direction = RowDirection.row_direction(row)

    contact_pairs =
      row
      |> SourceContactValues.source_contact_values()
      |> Enum.filter(&is_map/1)
      |> Enum.flat_map(fn contact ->
        contact = stringify_keys(contact)
        direction = SourceContactDirections.source_contact_direction(contact) || row_direction

        contact
        |> SourceWindowIds.contact_source_window_ids()
        |> Enum.map(&{direction, &1})
      end)

    row_pairs =
      row
      |> SourceWindowIds.row_source_window_ids()
      |> Enum.map(&{row_direction, &1})

    (contact_pairs ++ row_pairs)
    |> Enum.reject(fn {direction, source_window_id} ->
      direction in [nil, ""] or source_window_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
