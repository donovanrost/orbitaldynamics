defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummarySourceMetrics do
  @moduledoc false

  def fields(summary) do
    %{
      "schema_validation_pass_count" => summary["schema_validation_pass_count"],
      "schema_validation_fail_count" => summary["schema_validation_fail_count"],
      "schema_validation_error_count" => summary["schema_validation_error_count"],
      "schema_validation_warning_count" => summary["schema_validation_warning_count"],
      "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
      "schema_validation_status_counts" => summary["schema_validation_status_counts"],
      "schema_validation_status_ids" => summary["schema_validation_status_ids"],
      "failed_schema_validation_quality_gate_row_ids" =>
        summary["failed_schema_validation_quality_gate_row_ids"],
      "schema_validation_gate_ids" => summary["schema_validation_gate_ids"]
    }
  end
end
