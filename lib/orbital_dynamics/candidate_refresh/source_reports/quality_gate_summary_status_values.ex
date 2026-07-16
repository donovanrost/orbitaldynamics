defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusRowIds
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusScalars

  def row_count(row_ids_by_status, summary) do
    QualityGateSummaryStatusRowIds.row_count(row_ids_by_status, summary["gate_count"])
  end

  def ids_by_classification(%{} = ids_by_status, _fallback) do
    QualityGateSummaryStatusRowIds.ids_by_classification(ids_by_status)
  end

  def ids_by_classification(_ids_by_status, fallback) do
    QualityGateSummaryStatusFallbacks.ids_by_classification(fallback)
  end

  def status_count(%{} = row_ids_by_status, _summary, status) do
    QualityGateSummaryStatusRowIds.status_count(row_ids_by_status, status)
  end

  def status_count(_row_ids_by_status, summary, status) do
    QualityGateSummaryStatusFallbacks.status_count(summary, status)
  end

  def status_counts(%{} = row_ids_by_status, _fallback_counts) do
    QualityGateSummaryStatusRowIds.status_counts(row_ids_by_status)
  end

  def status_counts(_row_ids_by_status, fallback_counts) do
    QualityGateSummaryStatusFallbacks.status_counts(fallback_counts)
  end

  def classification_counts(%{} = row_ids_by_status, _fallback_counts) do
    QualityGateSummaryStatusRowIds.classification_counts(row_ids_by_status)
  end

  def classification_counts(_row_ids_by_status, fallback_counts) do
    QualityGateSummaryStatusFallbacks.classification_counts(fallback_counts)
  end

  defdelegate status(row_ids_by_status, summary), to: QualityGateSummaryStatusScalars

  defdelegate import_classification(row_ids_by_status, summary),
    to: QualityGateSummaryStatusScalars

  defdelegate readiness_level(row_ids_by_status, summary), to: QualityGateSummaryStatusScalars

  def list_values(values_by_key, key) do
    QualityGateSummaryStatusRowIds.list_values(values_by_key, key)
  end
end
