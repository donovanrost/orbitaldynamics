defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.FieldSumCounts.CountValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.{
    EvidenceRows,
    FallbackSummary
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def sum(reports, field) do
    sum_report_count(reports, &evidence_field_sum(&1, field))
  end

  defp evidence_field_sum(report, field) do
    EvidenceRows.evidence_field_sum(report, field, fn ->
      FallbackSummary.integer(report, field)
    end)
  end
end
