defmodule OrbitalDynamics.Schema.OperatorReviewValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2, require_fields: 4]

  @operator_review_package "operator_review_package.v1"

  def validate_optional_package(issues, nil), do: issues

  def validate_optional_package(issues, %{} = package),
    do: validate_package([], "$", package) ++ issues

  def validate_optional_package(issues, _package),
    do: [error("$.operator_review_package", "must be an object") | issues]

  def validate_optional_package_at(issues, _path, nil), do: issues

  def validate_optional_package_at(issues, path, %{} = package),
    do: validate_package(issues, path, package)

  def validate_optional_package_at(issues, path, _package),
    do: [error(path, "must be an object") | issues]

  def validate_optional_package(issues, nil, _validate_contract), do: issues

  def validate_optional_package(issues, %{} = package, validate_contract),
    do: validate_contract.(package) ++ issues

  def validate_optional_package(issues, _package, _validate_contract),
    do: [error("$.operator_review_package", "must be an object") | issues]

  def validate_package(issues, path, package) do
    issues
    |> require_fields(path, package, required_fields())
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_operator_review_boundary(
      path,
      package
    )
    |> validate_package(
      path,
      package,
      OrbitalDynamics.Schema.OperatorReviewCapabilityContext.operator_review_source_artifact_types(),
      OrbitalDynamics.Schema.OperatorReviewCapabilityContext.operator_review_package_model_limits(),
      package_callbacks()
    )
  end

  def validate_package(
        issues,
        path,
        package,
        source_artifact_types,
        model_limits,
        callbacks
      ) do
    OrbitalDynamics.Schema.OperatorReviewPackageContracts.validate(
      issues,
      path,
      package,
      source_artifact_types,
      model_limits,
      callbacks
    )
  end

  def validate_row(issues, path, row) do
    validate_row(
      issues,
      path,
      row,
      OrbitalDynamics.Schema.OperatorReviewCapabilityContext.operator_review_types(),
      OrbitalDynamics.Schema.StationCalendarCapabilityContext.station_calendar_provider_counteroffer_negotiation_states(),
      row_callbacks()
    )
  end

  def validate_row(issues, path, row, review_types, counteroffer_states, callbacks) do
    issues
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_operator_review_row_boundary(
      path,
      row
    )
    |> OrbitalDynamics.Schema.OperatorReviewRowContracts.validate(
      path,
      row,
      review_types,
      counteroffer_states,
      callbacks
    )
  end

  def validate_row_links(issues, path, row) do
    OrbitalDynamics.Schema.ReviewRowLinkContracts.validate(issues, path, row)
  end

  defp package_callbacks do
    [
      validate_contact_allocation_expiration_handoff_summary:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_expiration_summary/3,
      validate_quality_gate_handoff_summary:
        &OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_summary/3,
      validate_operator_review_row: &validate_row/3,
      validate_suppression_duplicate_handoff_groups:
        &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups/3
    ]
  end

  defp row_callbacks do
    OrbitalDynamics.Schema.OperatorReviewRowCallbacks.build(
      validate_optional_activity_context:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_protection_decision:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_protection_decision/4,
      validate_contact_allocation_capacity_pack_group:
        &OrbitalDynamics.Schema.ContactAllocationValidation.validate_capacity_pack_group/3,
      validate_optional_actual_data_rate_throughput_derivation:
        &OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation/4,
      validate_optional_lifecycle_transition:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_lifecycle_transition/4,
      validate_optional_branch_comparison_source_row:
        &OrbitalDynamics.Schema.DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_optional_policy_decision_evidence:
        &OrbitalDynamics.Schema.PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation:
        &OrbitalDynamics.Schema.PolicyValidation.validate_optional_escalation/4,
      validate_optional_timeline_dependency_impact_source_row:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_source_evidence_fields:
        &OrbitalDynamics.Schema.SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &OrbitalDynamics.Schema.SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &OrbitalDynamics.Schema.SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &OrbitalDynamics.Schema.SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_selected_timeline_integrity_fields:
        &OrbitalDynamics.Schema.TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3,
      validate_optional_timeline_diff_summary_source:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &OrbitalDynamics.Schema.TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &OrbitalDynamics.Schema.TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &OrbitalDynamics.Schema.TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_activity_state_source:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &OrbitalDynamics.Schema.TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_timeline_identity:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_optional_timeline_link:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_protection_summary:
        &OrbitalDynamics.Schema.TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_operational_readiness_resource_context:
        &OrbitalDynamics.Schema.OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_contact_allocation_handoff_fields:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_fields/3,
      validate_operator_review_row_links: &validate_row_links/3
    )
  end

  defp required_fields do
    OrbitalDynamics.Schema.OperatorReviewRegistryContracts.contracts()
    |> Map.fetch!(@operator_review_package)
    |> Map.fetch!("required_fields")
  end
end
