defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.CountFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "rejected_count" => sum_report_count(reports, &rejected_count/1),
      "reviewable_count" => sum_report_count(reports, &reviewable_count/1),
      "invalid_candidate_input_count" =>
        sum_report_count(reports, &invalid_candidate_input_count/1)
    }
  end

  defp row_count(report) do
    case numeric_report_count(report, "row_count") do
      0 -> report_rows_count(report)
      count -> count
    end
  end

  defp rejected_count(report), do: numeric_report_count(report, "rejected_count")

  defp reviewable_count(report), do: numeric_report_count(report, "reviewable_count")

  defp invalid_candidate_input_count(report),
    do: numeric_report_count(report, "invalid_candidate_input_count")

  defp report_rows_count(report), do: length(Map.get(report, "rows", []))
end
