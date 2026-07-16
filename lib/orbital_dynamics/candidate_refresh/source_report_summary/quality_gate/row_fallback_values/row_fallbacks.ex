defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.RowFallbacks do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues.{
    ReportRows,
    ReportValues
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report, field) do
    row_or_report_value(report, field, &ReportRows.count/2, &numeric_report_count/2)
  end

  def count_map(report, field) do
    row_or_report_value(report, field, &ReportRows.count_map/2, &ReportValues.string_list_map/2)
  end

  def string_list(report, field) do
    row_or_report_value(report, field, &ReportRows.string_list/2, &ReportValues.string_list/2)
  end

  def string_list_map(report, field) do
    row_or_report_value(
      report,
      field,
      &ReportRows.string_list_map/2,
      &ReportValues.string_list_map/2
    )
  end

  defp row_or_report_value(report, field, row_value, report_value) do
    case ReportRows.values(report) do
      [] -> report_value.(report, field)
      rows -> row_value.(rows, field)
    end
  end
end
