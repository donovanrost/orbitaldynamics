defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.BaseFields.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def summary_rows(summary) do
    summary
    |> Map.get("rows", [])
    |> normalize_rows()
  end

  def review_rows(summary) do
    summary
    |> review_row_values()
    |> normalize_rows()
  end

  defp review_row_values(summary) do
    Map.get(summary, "review_rows") || Map.get(summary, "reservation_review_rows") || []
  end

  defp normalize_rows(rows) do
    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys_with_keyword_maps/1)
  end
end
