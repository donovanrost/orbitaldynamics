defmodule OrbitalDynamics.Schema.TimelineContextValidation do
  @moduledoc false

  def validate_optional_timeline_preconditions(issues, path, map, field) do
    OrbitalDynamics.Schema.TimelinePreconditionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  def validate_optional_activity_context(issues, path, map, field) do
    OrbitalDynamics.Schema.ActivityContextContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  def validate_optional_protection_decision(issues, path, map, field) do
    OrbitalDynamics.Schema.ProtectionDecisionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  def validate_optional_lifecycle_transition(issues, path, map, field) do
    OrbitalDynamics.Schema.LifecycleTransitionContracts.validate_optional(
      issues,
      path,
      map,
      field
    )
  end

  def validate_optional_timeline_identity(issues, path, map, field) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_optional_identity(
      issues,
      path,
      map,
      field
    )
  end

  def validate_timeline_identity(issues, path, identity) when is_map(identity) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_identity(
      issues,
      path,
      identity
    )
  end

  def validate_timeline_identity(issues, _path, _identity), do: issues

  def validate_optional_timeline_link(issues, path, map, field) do
    OrbitalDynamics.Schema.TimelineIdentityContracts.validate_optional_link(
      issues,
      path,
      map,
      field
    )
  end

  def validate_optional_timeline_protection_summary(issues, path, map, field) do
    OrbitalDynamics.Schema.TimelineProtectionSummaryContracts.validate_optional_summary(
      issues,
      path,
      map,
      field
    )
  end
end
