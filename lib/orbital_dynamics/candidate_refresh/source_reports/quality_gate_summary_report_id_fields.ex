defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportIdFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFields

  def fields(row_ids_by_status, gate_ids_by_status, summary) do
    %{
      "quality_gate_row_ids_by_status" => row_ids_by_status || %{},
      "quality_gate_ids_by_status" => gate_ids_by_status,
      "quality_gate_row_ids_by_classification" =>
        QualityGateSummaryStatusFields.ids_by_classification(
          row_ids_by_status,
          summary["quality_gate_row_ids_by_classification"]
        ),
      "quality_gate_ids_by_classification" =>
        QualityGateSummaryStatusFields.ids_by_classification(
          gate_ids_by_status,
          summary["gate_ids_by_classification"]
        ),
      "review_required_quality_gate_row_ids" =>
        QualityGateSummaryStatusFields.list_values(row_ids_by_status, "review_required"),
      "blocked_quality_gate_row_ids" =>
        QualityGateSummaryStatusFields.list_values(row_ids_by_status, "blocked"),
      "ready_quality_gate_row_ids" =>
        QualityGateSummaryStatusFields.list_values(row_ids_by_status, "passed"),
      "analysis_only_quality_gate_row_ids" =>
        QualityGateSummaryStatusFields.list_values(row_ids_by_status, "analysis_only"),
      "review_required_gate_ids" =>
        QualityGateSummaryStatusFields.list_values(gate_ids_by_status, "review_required"),
      "blocked_gate_ids" =>
        QualityGateSummaryStatusFields.list_values(gate_ids_by_status, "blocked"),
      "passed_gate_ids" =>
        QualityGateSummaryStatusFields.list_values(gate_ids_by_status, "passed"),
      "analysis_only_gate_ids" =>
        QualityGateSummaryStatusFields.list_values(gate_ids_by_status, "analysis_only")
    }
  end
end
