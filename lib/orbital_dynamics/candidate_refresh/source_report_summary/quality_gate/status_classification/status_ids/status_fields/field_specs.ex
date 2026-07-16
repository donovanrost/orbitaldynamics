defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusFields.FieldSpecs do
  @moduledoc false

  @gate_id_status_fields [
    {"passed_gate_ids", "passed", "passed_gate_ids"},
    {"review_required_gate_ids", "review_required", "review_required_gate_ids"},
    {"analysis_only_gate_ids", "analysis_only", "analysis_only_gate_ids"},
    {"blocked_gate_ids", "blocked", "blocked_gate_ids"}
  ]

  @row_id_status_fields [
    {"review_required_quality_gate_row_ids", "review_required",
     "review_required_quality_gate_row_ids"},
    {"blocked_quality_gate_row_ids", "blocked", "blocked_quality_gate_row_ids"},
    {"ready_quality_gate_row_ids", "passed", "ready_quality_gate_row_ids"},
    {"analysis_only_quality_gate_row_ids", "analysis_only", "analysis_only_quality_gate_row_ids"}
  ]

  def gate_id_status_fields, do: @gate_id_status_fields
  def row_id_status_fields, do: @row_id_status_fields
end
