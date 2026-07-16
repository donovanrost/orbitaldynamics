defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.RowMetrics.Measurements.ReportValues.ResolvedValues.FallbackValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def count(report, field, row_value_fun) do
    case numeric_report_count(report, field) do
      count when count in [0, 0.0] -> row_value_fun.(report)
      count -> count
    end
  end

  def total(report, field, row_value_fun) do
    case NumericValue.value(Map.get(report, field)) do
      total when total in [nil, 0, 0.0] -> row_value_fun.(report)
      total -> total
    end
  end
end
