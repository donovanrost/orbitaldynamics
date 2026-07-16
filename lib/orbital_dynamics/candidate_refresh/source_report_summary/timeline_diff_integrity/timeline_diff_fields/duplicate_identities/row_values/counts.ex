defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.RowValues.Counts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      source_rows: 1
    ]

  def value(report, field, row_predicate) do
    case numeric_report_count(report, field) do
      0 ->
        report
        |> source_rows()
        |> Enum.count(row_predicate)

      count ->
        count
    end
  end
end
