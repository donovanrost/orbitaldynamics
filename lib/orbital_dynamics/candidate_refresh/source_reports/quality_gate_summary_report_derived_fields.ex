defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportDerivedFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportIdFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFields

  def fields(%{} = summary) do
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    gate_ids_by_status = Map.get(summary, "gate_ids_by_status", %{})

    %{
      "readiness_level" =>
        QualityGateSummaryStatusFields.readiness_level(row_ids_by_status, summary),
      "import_classification" =>
        QualityGateSummaryStatusFields.import_classification(row_ids_by_status, summary),
      "status" => QualityGateSummaryStatusFields.status(row_ids_by_status, summary),
      "gate_count" => QualityGateSummaryStatusFields.row_count(row_ids_by_status, summary),
      "passed_gate_count" =>
        QualityGateSummaryStatusFields.status_count(row_ids_by_status, summary, "passed"),
      "review_gate_count" =>
        QualityGateSummaryStatusFields.status_count(
          row_ids_by_status,
          summary,
          "review_required"
        ),
      "analysis_gate_count" =>
        QualityGateSummaryStatusFields.status_count(row_ids_by_status, summary, "analysis_only"),
      "blocked_gate_count" =>
        QualityGateSummaryStatusFields.status_count(row_ids_by_status, summary, "blocked"),
      "gate_status_counts" =>
        QualityGateSummaryStatusFields.status_counts(
          row_ids_by_status,
          summary["gate_status_counts"]
        ),
      "gate_classification_counts" =>
        QualityGateSummaryStatusFields.classification_counts(
          row_ids_by_status,
          summary["gate_classification_counts"]
        )
    }
    |> Map.merge(
      QualityGateSummaryReportIdFields.fields(row_ids_by_status, gate_ids_by_status, summary)
    )
  end
end
