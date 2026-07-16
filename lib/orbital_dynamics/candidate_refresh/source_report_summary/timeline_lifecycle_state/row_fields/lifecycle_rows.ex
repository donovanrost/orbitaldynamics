defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.LifecycleRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def all(%{} = summary) do
    summary
    |> preferred_rows()
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end

  def review_required(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.filter(&(&1["review_required"] == true))
  end

  defp preferred_rows(summary) do
    case map_rows(summary, "rows") do
      [] -> map_rows(summary, "review_rows")
      rows -> rows
    end
  end

  defp map_rows(summary, field) do
    summary
    |> Map.get(field, [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
  end
end
