defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusRowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields

  def row_count(row_ids_by_status, fallback_count) do
    QualityGateStatusFields.row_count(row_ids_by_status, fallback_count)
  end

  def ids_by_classification(ids_by_status) do
    QualityGateStatusFields.ids_by_classification(ids_by_status)
  end

  def status_count(row_ids_by_status, status) do
    QualityGateStatusFields.status_count(row_ids_by_status, status)
  end

  def status_counts(row_ids_by_status) do
    QualityGateStatusFields.status_counts(row_ids_by_status)
  end

  def classification_counts(row_ids_by_status) do
    QualityGateStatusFields.classification_counts(row_ids_by_status)
  end

  def status(row_ids_by_status) do
    QualityGateStatusFields.status_from_row_ids(row_ids_by_status)
  end

  def import_classification(row_ids_by_status) do
    row_ids_by_status
    |> QualityGateStatusFields.status_from_row_ids()
    |> QualityGateStatusFields.import_classification()
  end

  def readiness_level(row_ids_by_status) do
    row_ids_by_status
    |> QualityGateStatusFields.status_from_row_ids()
    |> QualityGateStatusFields.import_classification()
    |> QualityGateStatusFields.readiness_level()
  end

  def list_values(values_by_key, key) do
    QualityGateStatusFields.list_values(values_by_key, key)
  end
end
