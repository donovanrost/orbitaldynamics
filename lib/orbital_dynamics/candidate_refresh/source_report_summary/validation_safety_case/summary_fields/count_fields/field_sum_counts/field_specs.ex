defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.FieldSumCounts.FieldSpecs do
  @moduledoc false

  @count_fields [
    "model_accepted_count",
    "model_review_required_count",
    "model_blocked_count",
    "unknown_model_count",
    "readiness_review_required_count",
    "readiness_blocked_count",
    "ready_for_import_count",
    "quality_gate_review_count",
    "quality_gate_blocked_count",
    "schema_error_count",
    "schema_warning_count",
    "schema_validation_report_count",
    "schema_validation_failed_report_count",
    "fixture_passed_count",
    "fixture_failed_count"
  ]

  def count_fields, do: @count_fields
end
