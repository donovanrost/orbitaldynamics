defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.PreconditionRows.StatusValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def count(rows, status) do
    Enum.count(rows, &status?(&1, status))
  end

  def status(rows) do
    cond do
      Enum.any?(rows, &status?(&1, "blocked")) ->
        "blocked"

      Enum.any?(rows, &status?(&1, "review_required")) ->
        "review_required"

      true ->
        "clear"
    end
  end

  def types(rows, status) do
    rows
    |> Enum.filter(&status?(&1, status))
    |> Enum.map(&Map.get(&1, "type"))
    |> sorted_string_values()
  end

  defp status?(row, status), do: row["status"] == status
end
