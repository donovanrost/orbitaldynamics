defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperatorTrainingSummaryReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperatorTrainingSummaryStatusFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields

  def fields(%{} = summary) do
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")

    summary
    |> QualityGateSourceSummaryFields.fields(
      "preserved_operational_quality_gate_operator_training_summary"
    )
    |> Map.merge(
      QualityGateOperatorTrainingSummaryStatusFields.fields(summary, row_ids_by_status)
    )
    |> Map.merge(%{
      "operator_training_requirement_count" => summary["operator_training_requirement_count"],
      "operator_training_requirement_counts" => summary["operator_training_requirement_counts"],
      "operator_training_requirement_ids" => summary["operator_training_requirement_ids"],
      "required_operator_roles" => summary["required_operator_roles"],
      "required_training_ids" => summary["required_training_ids"],
      "required_certification_ids" => summary["required_certification_ids"],
      "required_qualification_ids" => summary["required_qualification_ids"],
      "review_only_quality_gate_row_ids" => summary["review_only_quality_gate_row_ids"],
      "operator_training_gate_ids" => summary["operator_training_gate_ids"]
    })
  end
end
