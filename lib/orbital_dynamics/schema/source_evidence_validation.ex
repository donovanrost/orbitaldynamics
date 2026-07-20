defmodule OrbitalDynamics.Schema.SourceEvidenceValidation do
  @moduledoc false

  @freshness_statuses ["current", "stale", "unknown"]
  @schema_validation_statuses ["pass", "fail"]

  def freshness_statuses, do: @freshness_statuses
  def schema_validation_statuses, do: @schema_validation_statuses

  def validate_fields(issues, path, row) do
    OrbitalDynamics.Schema.SourceEvidenceContracts.validate_fields(
      issues,
      path,
      row,
      &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_fields/3,
      &OrbitalDynamics.Schema.ResourceProjectionHandoffContracts.validate_battery_handoff_matches_own_flow/3
    )
  end

  def validate_freshness_status_matches(issues, path, row, statuses) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_freshness_matches(
      issues,
      path,
      row,
      statuses
    )
  end

  def validate_freshness_status_matches(issues, path, row),
    do: validate_freshness_status_matches(issues, path, row, freshness_statuses())

  def validate_schema_validation_status_matches(issues, path, row, statuses) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_schema_validation_matches(
      issues,
      path,
      row,
      statuses
    )
  end

  def validate_schema_validation_status_matches(issues, path, row),
    do:
      validate_schema_validation_status_matches(
        issues,
        path,
        row,
        schema_validation_statuses()
      )

  def validate_execution_status_matches(issues, path, row) do
    OrbitalDynamics.Schema.SourceStatusContracts.validate_execution_matches(
      issues,
      path,
      row,
      OrbitalDynamics.Schema.ExecutionReportContracts.statuses()
    )
  end
end
