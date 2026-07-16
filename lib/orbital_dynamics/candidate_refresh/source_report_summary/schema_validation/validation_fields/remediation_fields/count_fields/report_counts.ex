defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation.ValidationFields.RemediationFields.CountFields.ReportCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def sum(reports, count_field, list_field) do
    sum_report_count(reports, &count_or_list_length(&1, count_field, list_field))
  end

  defp count_or_list_length(report, count_field, list_field) do
    case numeric_report_count(report, count_field) do
      0 -> length(Map.get(report, list_field, []))
      count -> count
    end
  end
end
