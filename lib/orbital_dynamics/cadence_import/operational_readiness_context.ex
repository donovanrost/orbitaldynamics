defmodule OrbitalDynamics.CadenceImport.OperationalReadinessContext do
  @moduledoc false

  @adapter_boundary_fields [
    "adapter_context_count",
    "adapter_trust_boundary_declared_count",
    "adapter_trust_boundary_missing_count",
    "adapter_trust_boundary_untrusted_count",
    "adapter_boundary_status_counts"
  ]

  @resource_fields [
    "resource_availability_pressure_count",
    "resource_availability_reason_counts",
    "resource_availability_reason_ids",
    "station_availability_reason_ids",
    "station_availability_reason_counts",
    "unavailable_resource_reason_ids",
    "resource_blocking_dimension_counts",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts"
  ]

  @operator_training_fields [
    "operator_training_requirement_count",
    "operator_training_requirement_counts",
    "required_operator_roles",
    "required_training_ids",
    "required_certification_ids",
    "required_qualification_ids"
  ]

  @cadence_import_fields [
    "ready_for_import_count",
    "manifest_review_required_count",
    "blocked_import_count",
    "missing_import_count",
    "invalid_cadence_import_count",
    "current_freshness_count",
    "stale_freshness_count",
    "unknown_freshness_count",
    "freshness_status_counts",
    "schema_validation_pass_count",
    "schema_validation_fail_count",
    "schema_validation_error_count",
    "schema_validation_warning_count",
    "schema_validation_remediation_count",
    "schema_validation_status_counts",
    "import_status_counts",
    "cadence_import_status_counts"
  ]

  def adapter_boundary(%{} = row), do: project(row, @adapter_boundary_fields)
  def resource(%{} = row), do: project(row, @resource_fields)
  def operator_training(%{} = row), do: project(row, @operator_training_fields)
  def cadence_import(%{} = row), do: project(row, @cadence_import_fields)

  defp project(row, fields) do
    evidence = Map.get(row, "evidence") || %{}
    Map.new(fields, &{&1, row[&1] || evidence[&1]})
  end
end
