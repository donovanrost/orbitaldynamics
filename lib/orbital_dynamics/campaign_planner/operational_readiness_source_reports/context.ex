defmodule OrbitalDynamics.CampaignPlanner.OperationalReadinessSourceReports.Context do
  @moduledoc false

  def operator_training_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "operator_training_requirement_count" =>
        row["operator_training_requirement_count"] ||
          evidence["operator_training_requirement_count"],
      "operator_training_requirement_counts" =>
        row["operator_training_requirement_counts"] ||
          evidence["operator_training_requirement_counts"],
      "required_operator_roles" =>
        row["required_operator_roles"] || evidence["required_operator_roles"],
      "required_training_ids" =>
        row["required_training_ids"] || evidence["required_training_ids"],
      "required_certification_ids" =>
        row["required_certification_ids"] || evidence["required_certification_ids"],
      "required_qualification_ids" =>
        row["required_qualification_ids"] || evidence["required_qualification_ids"]
    }
  end

  def import_readiness_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "import_readiness_row_count" =>
        row_or_evidence(row, evidence, "import_readiness_row_count"),
      "ready_for_import_count" => row_or_evidence(row, evidence, "ready_for_import_count"),
      "manifest_review_required_count" =>
        row_or_evidence(row, evidence, "manifest_review_required_count"),
      "blocked_import_count" => row_or_evidence(row, evidence, "blocked_import_count"),
      "missing_import_count" => row_or_evidence(row, evidence, "missing_import_count"),
      "invalid_cadence_import_count" =>
        row_or_evidence(row, evidence, "invalid_cadence_import_count"),
      "current_freshness_count" => row_or_evidence(row, evidence, "current_freshness_count"),
      "stale_freshness_count" => row_or_evidence(row, evidence, "stale_freshness_count"),
      "unknown_freshness_count" => row_or_evidence(row, evidence, "unknown_freshness_count"),
      "freshness_status_counts" => row_or_evidence(row, evidence, "freshness_status_counts"),
      "freshness_status_ids" => row_or_evidence(row, evidence, "freshness_status_ids"),
      "import_status_counts" => row_or_evidence(row, evidence, "import_status_counts"),
      "import_status_ids" => row_or_evidence(row, evidence, "import_status_ids"),
      "cadence_import_status_counts" =>
        row_or_evidence(row, evidence, "cadence_import_status_counts"),
      "cadence_import_status_ids" => row_or_evidence(row, evidence, "cadence_import_status_ids"),
      "freshness_review_required" => row_or_evidence(row, evidence, "freshness_review_required"),
      "import_preparation_required" =>
        row_or_evidence(row, evidence, "import_preparation_required"),
      "import_blocked" => row_or_evidence(row, evidence, "import_blocked"),
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "stale_or_unknown_freshness_quality_gate_row_ids"),
      "import_preparation_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "import_preparation_quality_gate_row_ids"),
      "blocked_import_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "blocked_import_quality_gate_row_ids")
    }
  end

  def schema_validation_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "schema_validation_row_count" =>
        row_or_evidence(row, evidence, "schema_validation_row_count"),
      "schema_validation_pass_count" =>
        row_or_evidence(row, evidence, "schema_validation_pass_count"),
      "schema_validation_fail_count" =>
        row_or_evidence(row, evidence, "schema_validation_fail_count"),
      "schema_validation_error_count" =>
        row_or_evidence(row, evidence, "schema_validation_error_count"),
      "schema_validation_warning_count" =>
        row_or_evidence(row, evidence, "schema_validation_warning_count"),
      "schema_validation_remediation_count" =>
        row_or_evidence(row, evidence, "schema_validation_remediation_count"),
      "schema_validation_status_counts" =>
        row_or_evidence(row, evidence, "schema_validation_status_counts"),
      "schema_validation_status_ids" =>
        row_or_evidence(row, evidence, "schema_validation_status_ids"),
      "schema_validation_import_blocked" =>
        row_or_evidence(row, evidence, "schema_validation_import_blocked"),
      "failed_schema_validation_quality_gate_row_ids" =>
        row_or_evidence(row, evidence, "failed_schema_validation_quality_gate_row_ids")
    }
  end

  def resource_availability_context(%{} = row) do
    evidence = Map.get(row, "evidence") || %{}

    %{
      "resource_availability_pressure_count" =>
        row["resource_availability_pressure_count"] ||
          evidence["resource_availability_pressure_count"],
      "resource_availability_reason_counts" =>
        row["resource_availability_reason_counts"] ||
          evidence["resource_availability_reason_counts"],
      "resource_availability_reason_ids" =>
        row["resource_availability_reason_ids"] || evidence["resource_availability_reason_ids"],
      "unavailable_resource_reason_counts" =>
        row["unavailable_resource_reason_counts"] ||
          evidence["unavailable_resource_reason_counts"],
      "unavailable_resource_reason_ids" =>
        row["unavailable_resource_reason_ids"] || evidence["unavailable_resource_reason_ids"],
      "station_availability_reason_counts" =>
        row["station_availability_reason_counts"] ||
          evidence["station_availability_reason_counts"],
      "station_availability_reason_ids" =>
        row["station_availability_reason_ids"] || evidence["station_availability_reason_ids"],
      "resource_blocking_dimension_counts" =>
        row["resource_blocking_dimension_counts"] ||
          evidence["resource_blocking_dimension_counts"],
      "blocked_contact_ids_by_blocking_dimension" =>
        row["blocked_contact_ids_by_blocking_dimension"] ||
          evidence["blocked_contact_ids_by_blocking_dimension"],
      "blocked_contact_ids_by_spacecraft_id" =>
        row["blocked_contact_ids_by_spacecraft_id"] ||
          evidence["blocked_contact_ids_by_spacecraft_id"],
      "blocked_contact_ids_by_status" =>
        row["blocked_contact_ids_by_status"] || evidence["blocked_contact_ids_by_status"]
    }
  end

  defp row_or_evidence(row, evidence, key) do
    if Map.has_key?(row, key), do: row[key], else: evidence[key]
  end
end
