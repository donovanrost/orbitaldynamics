defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEncoding

  def from_preconditions(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&TimelineActivityPreconditionReviewImportEncoding.stringify_keys/1)
  end

  def status(rows) do
    cond do
      Enum.any?(rows, &(precondition_row_status(&1) == "blocked")) ->
        "blocked"

      Enum.any?(rows, &(precondition_row_status(&1) == "review_required")) ->
        "review_required"

      true ->
        "clear"
    end
  end

  def count(rows, status) do
    Enum.count(rows, &(precondition_row_status(&1) == status))
  end

  def types(rows, status) do
    rows
    |> Enum.filter(&(precondition_row_status(&1) == status))
    |> Enum.map(&Map.get(&1, "type"))
    |> sorted_string_values()
  end

  defp precondition_row_status(row), do: row["status"]
end
