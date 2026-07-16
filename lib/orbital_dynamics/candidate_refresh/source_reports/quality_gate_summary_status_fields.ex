defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusValues

  defdelegate row_count(row_ids_by_status, summary), to: QualityGateSummaryStatusValues

  defdelegate ids_by_classification(ids_by_status, fallback), to: QualityGateSummaryStatusValues

  defdelegate status_count(row_ids_by_status, summary, status), to: QualityGateSummaryStatusValues

  defdelegate status_counts(row_ids_by_status, fallback_counts),
    to: QualityGateSummaryStatusValues

  defdelegate classification_counts(row_ids_by_status, fallback_counts),
    to: QualityGateSummaryStatusValues

  defdelegate status(row_ids_by_status, summary), to: QualityGateSummaryStatusValues

  defdelegate import_classification(row_ids_by_status, summary),
    to: QualityGateSummaryStatusValues

  defdelegate readiness_level(row_ids_by_status, summary), to: QualityGateSummaryStatusValues

  defdelegate list_values(values_by_key, key), to: QualityGateSummaryStatusValues
end
