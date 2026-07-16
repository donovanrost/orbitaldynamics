defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.Counts.CountMaps.RowCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1
    ]

  def from_rows(rows, row_field) do
    rows
    |> Enum.map(&Map.get(&1, row_field))
    |> count_source_report_values()
  end

  def value_count(rows, row_field, value) do
    Enum.count(rows, &(&1[row_field] == value))
  end
end
