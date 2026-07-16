defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.ReasonFields.ReasonCounts.RowCounts.ListValues do
  @moduledoc false

  def values(rows, field) do
    Enum.flat_map(rows, &row_values(&1, field))
  end

  defp row_values(%{} = row, field) do
    row
    |> Map.get(field)
    |> list_value()
  end

  defp row_values(_row, _field), do: []

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
