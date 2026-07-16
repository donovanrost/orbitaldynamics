defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.Rows.RejectionReasons do
  @moduledoc false

  def from_row(row) do
    row
    |> Map.get("rejection_reasons")
    |> list_value()
    |> fallback_to_primary_reason(row)
  end

  defp fallback_to_primary_reason([], row),
    do: List.wrap(Map.get(row, "primary_rejection_reason"))

  defp fallback_to_primary_reason(reasons, _row), do: reasons

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
