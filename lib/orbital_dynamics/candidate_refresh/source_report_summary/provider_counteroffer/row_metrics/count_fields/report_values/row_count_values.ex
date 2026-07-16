defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.CountFields.ReportValues.RowCountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def row_count(report) do
    count_or_row_value(report, "counteroffer_count", &Rows.row_count_from_rows/1)
  end

  def reviewable_count(report) do
    count_or_row_value(report, "reviewable_count", fn report ->
      report
      |> Rows.raw_rows()
      |> Enum.count(& &1["reviewable"])
    end)
  end

  def status_counts(report) do
    count_by_field(report, "counteroffer_status_counts", "provider_counteroffer_status")
  end

  def required_action_counts(report) do
    count_by_field(report, "required_operator_action_counts", "required_operator_action")
  end

  defp count_or_row_value(report, field, row_value_fun) do
    case numeric_report_count(report, field) do
      count when count in [0, 0.0] -> row_value_fun.(report)
      count -> count
    end
  end

  defp count_by_field(report, top_level_field, row_field) do
    Rows.count_by_field(report, top_level_field, row_field)
  end
end
