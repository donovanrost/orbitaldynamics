defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.FieldSets.CountFields do
  @moduledoc false

  @fields [
    "ready_for_import_count",
    "manifest_review_required_count",
    "blocked_import_count",
    "missing_import_count",
    "invalid_cadence_import_count",
    "review_required_count",
    "current_freshness_count",
    "stale_freshness_count",
    "unknown_freshness_count",
    "schema_validation_pass_count",
    "schema_validation_fail_count",
    "schema_validation_error_count",
    "schema_validation_warning_count",
    "schema_validation_remediation_count",
    "source_model_limit_count",
    "adapter_context_count",
    "adapter_trust_boundary_declared_count",
    "adapter_trust_boundary_missing_count",
    "adapter_trust_boundary_untrusted_count",
    "resource_availability_pressure_count"
  ]

  def fields, do: @fields
end
