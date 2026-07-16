defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.DirectionValues
  alias __MODULE__.{RowIds, Rows}

  def direction_identifier_pairs(report) do
    report
    |> Rows.normalized()
    |> Enum.map(fn row ->
      {row_direction(row), RowIds.activity_id(row) || RowIds.window_id(row)}
    end)
    |> Rows.reject_empty_pairs()
  end

  def activity_direction_pairs(report) do
    report
    |> Rows.normalized()
    |> Enum.map(fn row ->
      {row_direction(row), RowIds.activity_id(row)}
    end)
    |> Rows.reject_empty_pairs()
  end

  def window_direction_pairs(report) do
    report
    |> Rows.normalized()
    |> Enum.map(fn row ->
      {row_direction(row), RowIds.window_id(row)}
    end)
    |> Rows.reject_empty_pairs()
  end

  defp row_direction(row), do: DirectionValues.from_row(row)
end
