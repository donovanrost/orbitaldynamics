defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusClassification
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusCollections

  defdelegate list_values(values_by_key, key), to: QualityGateStatusCollections

  defdelegate row_count(row_ids_by_status, fallback_count), to: QualityGateStatusCollections

  defdelegate status_count(row_ids_by_status, status), to: QualityGateStatusCollections

  def status_from_row_ids(row_ids_by_status, fallback \\ "passed") do
    QualityGateStatusClassification.status_from_row_ids(row_ids_by_status, fallback)
  end

  defdelegate import_classification(status), to: QualityGateStatusClassification

  defdelegate readiness_level(classification), to: QualityGateStatusClassification

  defdelegate status_counts(row_ids_by_status), to: QualityGateStatusCollections

  defdelegate classification_counts(row_ids_by_status), to: QualityGateStatusClassification

  def ids_by_classification(ids_by_status, fallback \\ %{}) do
    QualityGateStatusClassification.ids_by_classification(ids_by_status, fallback)
  end
end
