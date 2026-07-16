defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.StatusCounts.StatusValue do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.{
    EvidenceRows,
    FallbackSummary
  }

  def count(report, status, fallback_field) do
    EvidenceRows.evidence_status_count(report, status, fn ->
      FallbackSummary.status_count(report, status, fallback_field)
    end)
  end
end
