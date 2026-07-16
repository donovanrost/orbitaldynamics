defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferSummaryCountFallbacks do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def summary_count(summary, field, rows_or_count) do
    case numeric_report_count(summary, field) do
      0 when is_list(rows_or_count) -> length(rows_or_count)
      0 when is_integer(rows_or_count) -> rows_or_count
      count -> count
    end
  end
end
