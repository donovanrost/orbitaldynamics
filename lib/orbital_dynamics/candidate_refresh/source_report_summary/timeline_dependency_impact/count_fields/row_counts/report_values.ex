defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowCounts.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      numeric_report_count: 2
    ]

  def row_count(report, top_level_field) do
    case Rows.rows(report) do
      [] -> numeric_report_count(report, top_level_field)
      rows -> length(rows)
    end
  end

  def scope_count(report, top_level_field, scope) do
    case Rows.rows(report) do
      [] -> numeric_report_count(report, top_level_field)
      rows -> Enum.count(rows, &(Rows.row_scope(&1) == scope))
    end
  end

  def row_counts(report, top_level_field, row_field) do
    case Rows.rows(report) do
      [] ->
        Map.get(report, top_level_field)

      rows ->
        rows
        |> Enum.map(&Rows.row_value(&1, row_field))
        |> count_source_report_values()
    end
  end
end
