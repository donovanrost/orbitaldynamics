defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.StationCalendarPairs.RowValues.SourceContacts.RowFieldValues do
  @moduledoc false

  def row_field_values(row, fields) do
    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> List.flatten()
  end
end
