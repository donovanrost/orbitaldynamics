defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.StatusCounts.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.StatusCounts.StatusValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def sum(reports, status, fallback_field) do
    sum_report_count(
      reports,
      &evidence_status_count(&1, status, fallback_field)
    )
  end

  defp evidence_status_count(report, status, fallback_field) do
    StatusValue.count(report, status, fallback_field)
  end
end
