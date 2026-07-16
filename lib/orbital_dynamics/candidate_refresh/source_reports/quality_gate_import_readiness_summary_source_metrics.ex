defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummarySourceMetrics do
  @moduledoc false

  def fields(summary) do
    %{
      "ready_for_import_count" => summary["ready_for_import_count"],
      "manifest_review_required_count" => summary["manifest_review_required_count"],
      "blocked_import_count" => summary["blocked_import_count"],
      "missing_import_count" => summary["missing_import_count"],
      "invalid_cadence_import_count" => summary["invalid_cadence_import_count"],
      "current_freshness_count" => summary["current_freshness_count"],
      "stale_freshness_count" => summary["stale_freshness_count"],
      "unknown_freshness_count" => summary["unknown_freshness_count"],
      "freshness_status_counts" => summary["freshness_status_counts"],
      "freshness_status_ids" => summary["freshness_status_ids"],
      "schema_validation_pass_count" => summary["schema_validation_pass_count"],
      "schema_validation_fail_count" => summary["schema_validation_fail_count"],
      "schema_validation_error_count" => summary["schema_validation_error_count"],
      "schema_validation_warning_count" => summary["schema_validation_warning_count"],
      "schema_validation_remediation_count" => summary["schema_validation_remediation_count"],
      "schema_validation_status_counts" => summary["schema_validation_status_counts"],
      "import_status_counts" => summary["import_status_counts"],
      "import_status_ids" => summary["import_status_ids"],
      "cadence_import_status_counts" => summary["cadence_import_status_counts"],
      "cadence_import_status_ids" => summary["cadence_import_status_ids"]
    }
  end
end
