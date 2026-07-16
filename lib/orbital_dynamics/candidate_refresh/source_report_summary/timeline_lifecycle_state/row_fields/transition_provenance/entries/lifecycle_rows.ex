defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance.Entries.LifecycleRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(%{} = summary) do
    summary
    |> row_values()
    |> fallback_to_review_rows(summary)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  defp row_values(summary), do: map_rows(summary, "rows")

  defp fallback_to_review_rows([], summary), do: map_rows(summary, "review_rows")
  defp fallback_to_review_rows(rows, _summary), do: rows

  defp map_rows(summary, field) do
    summary
    |> Map.get(field, [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
  end
end
