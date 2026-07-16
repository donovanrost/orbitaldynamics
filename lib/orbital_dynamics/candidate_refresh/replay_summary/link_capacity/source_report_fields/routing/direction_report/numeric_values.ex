defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.NumericValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows,
    only: [
      non_empty_map: 1,
      numeric_value: 1,
      row_direction: 1,
      rows_for_summary: 1
    ]

  def numeric_values_by_direction(report, field) do
    report
    |> rows_for_summary()
    |> Enum.reduce(%{}, fn row, totals ->
      direction = row_direction(row)
      value = row |> Map.get(field) |> numeric_value()

      if direction in [nil, ""] or is_nil(value) do
        totals
      else
        Map.update(totals, direction, value, &(&1 + value))
      end
    end)
    |> non_empty_map()
  end
end
