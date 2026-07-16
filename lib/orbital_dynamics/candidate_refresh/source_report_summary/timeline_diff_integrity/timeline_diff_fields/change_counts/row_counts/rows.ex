defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.Rows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_rows: 1]

  def row_count(report), do: report |> source_rows() |> length()

  def count(report, predicate) do
    report
    |> values()
    |> Enum.count(predicate)
  end

  def values(report) do
    source_rows(report)
  end
end
