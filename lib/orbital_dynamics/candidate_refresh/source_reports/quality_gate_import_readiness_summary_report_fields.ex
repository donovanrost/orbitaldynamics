defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryBaseFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryImpactFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryRowContextFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatusContext

  def fields(%{} = summary) do
    context = QualityGateImportReadinessSummaryStatusContext.from_summary(summary)

    summary
    |> QualityGateImportReadinessSummaryBaseFields.fields(
      context.status,
      context.classification,
      context.import_readiness_row_count,
      context.ready_row_ids,
      context.review_row_ids,
      context.analysis_row_ids,
      context.blocked_row_ids,
      context.row_ids_by_status
    )
    |> Map.merge(QualityGateImportReadinessSummaryImpactFields.fields(summary))
    |> Map.merge(
      QualityGateImportReadinessSummaryRowContextFields.fields(
        summary,
        context.ready_row_ids,
        context.review_row_ids,
        context.analysis_row_ids,
        context.blocked_row_ids
      )
    )
  end
end
