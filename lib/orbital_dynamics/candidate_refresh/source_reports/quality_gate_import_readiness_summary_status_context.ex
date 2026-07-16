defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatusContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatusFields

  def from_summary(%{} = summary) do
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    status = QualityGateImportReadinessSummaryStatusFields.status(summary)

    %{
      row_ids_by_status: row_ids_by_status,
      ready_row_ids: row_ids(row_ids_by_status, summary, "passed"),
      review_row_ids: row_ids(row_ids_by_status, summary, "review_required"),
      analysis_row_ids: row_ids(row_ids_by_status, summary, "analysis_only"),
      blocked_row_ids: row_ids(row_ids_by_status, summary, "blocked"),
      import_readiness_row_count:
        QualityGateImportReadinessSummaryStatusFields.row_count(row_ids_by_status, summary),
      status: status,
      classification: QualityGateImportReadinessSummaryStatusFields.classification(status)
    }
  end

  defp row_ids(row_ids_by_status, summary, status) do
    QualityGateImportReadinessSummaryStatusFields.row_ids(row_ids_by_status, summary, status)
  end
end
