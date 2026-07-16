defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.PreconditionRows.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_rows(rows) do
    rows
    |> Enum.flat_map(fn
      %{} = row -> List.wrap(Map.get(row, "preconditions"))
      _row -> []
    end)
    |> normalize()
  end

  def normalize(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
