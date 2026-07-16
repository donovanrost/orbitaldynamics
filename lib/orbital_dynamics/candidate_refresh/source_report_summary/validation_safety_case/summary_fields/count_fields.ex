defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.FallbackSummary

  alias __MODULE__.FieldSumCounts
  alias __MODULE__.StatusCounts

  def fields(reports) do
    StatusCounts.fields(reports)
    |> Map.merge(FieldSumCounts.fields(reports))
  end

  def fallback_count(report) do
    FallbackSummary.count(report, "evidence_count")
  end
end
