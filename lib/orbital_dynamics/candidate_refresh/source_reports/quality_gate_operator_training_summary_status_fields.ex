defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperatorTrainingSummaryStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields

  def fields(%{} = summary, row_ids_by_status) do
    gate_ids_by_status = Map.get(summary, "quality_gate_ids_by_status", %{})

    operator_training_row_count =
      QualityGateStatusFields.row_count(row_ids_by_status, summary["operator_training_row_count"])

    status = QualityGateStatusFields.status_from_row_ids(row_ids_by_status)
    classification = QualityGateStatusFields.import_classification(status)

    %{
      "readiness_level" => QualityGateStatusFields.readiness_level(classification),
      "import_classification" => classification,
      "status" => status,
      "gate_count" => operator_training_row_count,
      "passed_gate_count" => QualityGateStatusFields.status_count(row_ids_by_status, "passed"),
      "review_gate_count" =>
        QualityGateStatusFields.status_count(row_ids_by_status, "review_required"),
      "analysis_gate_count" =>
        QualityGateStatusFields.status_count(row_ids_by_status, "analysis_only"),
      "blocked_gate_count" => QualityGateStatusFields.status_count(row_ids_by_status, "blocked"),
      "gate_status_counts" => QualityGateStatusFields.status_counts(row_ids_by_status),
      "gate_classification_counts" =>
        QualityGateStatusFields.classification_counts(row_ids_by_status),
      "operator_training_row_count" => operator_training_row_count,
      "quality_gate_row_ids_by_status" => row_ids_by_status || %{},
      "quality_gate_ids_by_status" => gate_ids_by_status,
      "review_required_quality_gate_row_ids" =>
        QualityGateStatusFields.list_values(row_ids_by_status, "review_required"),
      "blocked_quality_gate_row_ids" =>
        QualityGateStatusFields.list_values(row_ids_by_status, "blocked"),
      "trust_boundary" => summary["trust_boundary"],
      "trust_boundaries" => summary["trust_boundaries"],
      "assumptions" => summary["assumptions"]
    }
  end
end
