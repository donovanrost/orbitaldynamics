defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusScalars do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusRowIds

  def status(%{} = row_ids_by_status, _summary) do
    QualityGateSummaryStatusRowIds.status(row_ids_by_status)
  end

  def status(_row_ids_by_status, summary), do: QualityGateSummaryStatusFallbacks.status(summary)

  def import_classification(%{} = row_ids_by_status, _summary) do
    QualityGateSummaryStatusRowIds.import_classification(row_ids_by_status)
  end

  def import_classification(_row_ids_by_status, summary) do
    QualityGateSummaryStatusFallbacks.import_classification(summary)
  end

  def readiness_level(%{} = row_ids_by_status, _summary) do
    QualityGateSummaryStatusRowIds.readiness_level(row_ids_by_status)
  end

  def readiness_level(_row_ids_by_status, summary) do
    QualityGateSummaryStatusFallbacks.readiness_level(summary)
  end
end
