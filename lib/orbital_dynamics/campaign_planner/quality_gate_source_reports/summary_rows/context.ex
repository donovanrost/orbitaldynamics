defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.Context do
  @moduledoc false

  def resource_context(%{} = row) do
    %{
      "resource_availability_pressure_count" => row["resource_availability_pressure_count"],
      "resource_availability_reason_counts" => row["resource_availability_reason_counts"],
      "resource_availability_reason_ids" => row["resource_availability_reason_ids"],
      "unavailable_resource_reason_counts" => row["unavailable_resource_reason_counts"],
      "unavailable_resource_reason_ids" => row["unavailable_resource_reason_ids"],
      "station_availability_reason_counts" => row["station_availability_reason_counts"],
      "station_availability_reason_ids" => row["station_availability_reason_ids"],
      "resource_blocking_dimension_counts" => row["resource_blocking_dimension_counts"],
      "blocked_contact_ids_by_blocking_dimension" =>
        row["blocked_contact_ids_by_blocking_dimension"],
      "blocked_contact_ids_by_spacecraft_id" => row["blocked_contact_ids_by_spacecraft_id"],
      "blocked_contact_ids_by_status" => row["blocked_contact_ids_by_status"]
    }
  end

  def schema_validation_context(%{} = row) do
    %{
      "schema_validation_row_count" => row["schema_validation_row_count"],
      "schema_validation_pass_count" => row["schema_validation_pass_count"],
      "schema_validation_fail_count" => row["schema_validation_fail_count"],
      "schema_validation_error_count" => row["schema_validation_error_count"],
      "schema_validation_warning_count" => row["schema_validation_warning_count"],
      "schema_validation_remediation_count" => row["schema_validation_remediation_count"],
      "schema_validation_status_counts" => row["schema_validation_status_counts"],
      "schema_validation_status_ids" => row["schema_validation_status_ids"],
      "schema_validation_import_blocked" => row["schema_validation_import_blocked"],
      "failed_schema_validation_quality_gate_row_ids" =>
        row["failed_schema_validation_quality_gate_row_ids"]
    }
  end

  def import_readiness_context(%{} = row) do
    %{
      "import_readiness_row_count" => row["import_readiness_row_count"],
      "ready_for_import_count" => row["ready_for_import_count"],
      "manifest_review_required_count" => row["manifest_review_required_count"],
      "blocked_import_count" => row["blocked_import_count"],
      "missing_import_count" => row["missing_import_count"],
      "invalid_cadence_import_count" => row["invalid_cadence_import_count"],
      "current_freshness_count" => row["current_freshness_count"],
      "stale_freshness_count" => row["stale_freshness_count"],
      "unknown_freshness_count" => row["unknown_freshness_count"],
      "freshness_status_counts" => row["freshness_status_counts"],
      "freshness_status_ids" => row["freshness_status_ids"],
      "import_status_counts" => row["import_status_counts"],
      "import_status_ids" => row["import_status_ids"],
      "cadence_import_status_counts" => row["cadence_import_status_counts"],
      "cadence_import_status_ids" => row["cadence_import_status_ids"],
      "freshness_review_required" => row["freshness_review_required"],
      "import_preparation_required" => row["import_preparation_required"],
      "import_blocked" => row["import_blocked"],
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        row["stale_or_unknown_freshness_quality_gate_row_ids"],
      "import_preparation_quality_gate_row_ids" => row["import_preparation_quality_gate_row_ids"],
      "blocked_import_quality_gate_row_ids" => row["blocked_import_quality_gate_row_ids"]
    }
  end
end
