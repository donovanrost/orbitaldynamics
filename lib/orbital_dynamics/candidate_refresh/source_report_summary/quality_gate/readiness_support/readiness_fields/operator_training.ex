defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.OperatorTraining do
  @moduledoc false

  alias __MODULE__.FieldValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def fields(reports) do
    %{
      "operator_training_requirement_count" =>
        FieldValues.row_count(reports, "operator_training_requirement_count"),
      "operator_training_requirement_counts" =>
        FieldValues.count_map(reports, "operator_training_requirement_counts"),
      "operator_training_requirement_ids" =>
        FieldValues.string_values(reports, "operator_training_requirement_ids"),
      "required_operator_roles" => FieldValues.string_values(reports, "required_operator_roles"),
      "required_training_ids" => FieldValues.string_values(reports, "required_training_ids"),
      "required_certification_ids" =>
        FieldValues.string_values(reports, "required_certification_ids"),
      "required_qualification_ids" =>
        FieldValues.string_values(reports, "required_qualification_ids"),
      "review_only_quality_gate_row_ids" =>
        FieldValues.string_values(reports, "review_only_quality_gate_row_ids"),
      "operator_training_gate_ids" =>
        FieldValues.string_values(reports, "operator_training_gate_ids")
    }
    |> compact_map()
  end
end
