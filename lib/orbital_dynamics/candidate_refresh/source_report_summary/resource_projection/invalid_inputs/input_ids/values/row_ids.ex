defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.Values.RowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_rows(rows, id_fields) do
    rows
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&from_row(&1, id_fields))
  end

  defp from_row(row, id_fields) do
    Enum.find_value(id_fields, &Map.get(row, &1))
  end
end
