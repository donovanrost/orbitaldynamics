defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape.Applications do
  @moduledoc false

  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def row_count_or(report, fallback) do
    case row_count(report) do
      0 -> fallback.()
      count -> count
    end
  end

  def count_matching(report, top_level_field, row_predicate) do
    case rows(report) do
      [] -> numeric_report_count(report, top_level_field)
      rows -> Enum.count(rows, row_predicate)
    end
  end

  def count_rows(rows, field) do
    Rows.count(rows, field)
  end

  def rows(report) do
    Rows.from_report(report)
  end

  defp row_count(report), do: report |> rows() |> length()
end
