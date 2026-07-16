defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.Counts.CountValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report, count_field, rows_field) do
    report
    |> numeric_report_count(count_field)
    |> case do
      0 -> length(Map.get(report, rows_field, []))
      count -> count
    end
  end
end
