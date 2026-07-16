defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummarySourceMetrics

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryStatusFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields

  def report_from_schema_validation_summary(%{} = summary) do
    summary = QualityGateSchemaValidationSummaryValues.stringify_keys(summary)
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    summary
    |> QualityGateSourceSummaryFields.fields(
      "preserved_operational_quality_gate_schema_validation_summary"
    )
    |> Map.merge(
      QualityGateSchemaValidationSummaryStatusFields.fields(summary, row_ids_by_status)
    )
    |> Map.merge(QualityGateSchemaValidationSummarySourceMetrics.fields(summary))
    |> QualityGateSchemaValidationSummaryValues.maybe_put("provenance", summary["provenance"])
    |> compact_map()
  end
end
