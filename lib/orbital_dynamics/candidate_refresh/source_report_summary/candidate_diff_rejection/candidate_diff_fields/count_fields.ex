defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.CountFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &row_count/1),
      "retained_candidate_count" => sum_report_count(reports, &retained_count/1),
      "new_candidate_count" => sum_report_count(reports, &new_count/1),
      "invalidated_candidate_count" => sum_report_count(reports, &invalidated_count/1)
    }
  end

  defp row_count(report) do
    retained_count(report) + new_count(report) + invalidated_count(report)
  end

  defp retained_count(report), do: length(Map.get(report, "retained_candidates", []))

  defp new_count(report), do: length(Map.get(report, "new_candidates", []))

  defp invalidated_count(report), do: length(Map.get(report, "invalidated_candidates", []))
end
