defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryBaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummarySourceMetrics

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatusFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields

  def fields(
        summary,
        status,
        classification,
        import_readiness_row_count,
        ready_row_ids,
        review_row_ids,
        analysis_row_ids,
        blocked_row_ids,
        row_ids_by_status
      ) do
    summary
    |> QualityGateSourceSummaryFields.fields(
      "preserved_operational_quality_gate_import_readiness_summary"
    )
    |> Map.merge(%{
      "readiness_level" =>
        QualityGateImportReadinessSummaryStatusFields.readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" => import_readiness_row_count,
      "passed_gate_count" => length(ready_row_ids),
      "review_gate_count" => length(review_row_ids),
      "analysis_gate_count" => length(analysis_row_ids),
      "blocked_gate_count" => length(blocked_row_ids),
      "gate_status_counts" =>
        QualityGateImportReadinessSummaryStatusFields.status_counts(
          summary["quality_gate_row_ids_by_status"]
        ),
      "gate_classification_counts" =>
        QualityGateImportReadinessSummaryStatusFields.classification_counts(
          summary["quality_gate_row_ids_by_status"]
        ),
      "import_readiness_row_count" => import_readiness_row_count,
      "quality_gate_row_ids_by_status" => row_ids_by_status || %{},
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"]
    })
    |> Map.merge(QualityGateImportReadinessSummarySourceMetrics.fields(summary))
  end
end
