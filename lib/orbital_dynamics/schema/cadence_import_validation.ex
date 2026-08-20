defmodule OrbitalDynamics.Schema.CadenceImportValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{
    CadenceImportCapabilityContext,
    CadenceImportManifestContracts,
    CadenceImportRegistryContracts,
    CadenceImportRowCallbacks,
    CadenceImportRowContracts,
    CadenceImportRowHandoffCallbacks,
    CadenceSourceReviewRowCallbacks,
    CadenceSourceReviewRowContracts,
    CandidateRejectionValidation,
    ContactAllocationValidation,
    DecisionSupportValidation,
    OperationalReadinessValidation,
    OperatorReviewValidation,
    PolicyValidation,
    PrimitiveValidation,
    SourceEvidenceValidation,
    StableIdValidation,
    TimelineContextValidation,
    TimelineSourceValidation,
    TimelineTransitionValidation
  }

  @cadence_import_manifest "cadence_import_manifest.v1"

  def validate_manifest_artifact(issues, path, manifest) do
    {issues, manifest} =
      OrbitalDynamics.Schema.CollectionValidation.sanitize_list_field(
        issues,
        path,
        manifest,
        "rows"
      )

    issues
    |> PrimitiveValidation.require_fields(path, manifest, manifest_required_fields())
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_cadence_import_manifest_boundary(
      path,
      manifest
    )
    |> validate_manifest(path, manifest)
  end

  def validate_optional_manifest(issues, nil), do: issues

  def validate_optional_manifest(issues, %{} = manifest) do
    validate_manifest_artifact(issues, "$.cadence_import_manifest", manifest)
  end

  def validate_optional_manifest(issues, _manifest) do
    [PrimitiveValidation.error("$.cadence_import_manifest", "must be an object") | issues]
  end

  def validate_manifest(issues, path, manifest) do
    CadenceImportManifestContracts.validate(
      issues,
      path,
      manifest,
      CadenceImportCapabilityContext.cadence_import_supported_sources(),
      CadenceImportCapabilityContext.cadence_import_manifest_model_limits(),
      CadenceImportCapabilityContext.cadence_import_manifest_scalar_count_fields(),
      &validate_row/3,
      &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_expiration_summary/3,
      &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_groups/3
    )
  end

  def validate_row(issues, path, row) do
    capability = CadenceImportCapabilityContext.cadence_import_capability()
    callbacks = row_callbacks()

    issues
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_cadence_import_row_boundary(
      path,
      row
    )
    |> CadenceImportRowContracts.validate_import_station_and_target_fields(
      path,
      row,
      capability,
      callbacks
    )
    |> CadenceImportRowContracts.validate_source_context_fields(path, row, callbacks)
    |> CadenceImportRowContracts.validate_handoff_and_timeline_source_fields(
      path,
      row,
      callbacks
    )
  end

  def validate_source_review_row(issues, path, row) do
    CadenceSourceReviewRowContracts.validate(issues, path, row, source_review_row_callbacks())
  end

  defp row_callbacks do
    CadenceImportRowCallbacks.build(
      validate_contact_allocation_capacity_pack_group:
        &ContactAllocationValidation.validate_capacity_pack_group/3,
      validate_optional_policy_decision_evidence:
        &PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation: &PolicyValidation.validate_optional_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &CandidateRejectionValidation.validate_optional_source_row/3,
      validate_optional_branch_comparison_source_row:
        &DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_nested_id_match: &StableIdValidation.validate_nested_id_match/7,
      validate_optional_activity_context:
        &TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_timeline_link:
        &TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_identity:
        &TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_cadence_source_review_row: &validate_source_review_row/3,
      validate_operational_readiness_resource_context:
        &OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_operational_readiness_cadence_import_context:
        &OperationalReadinessValidation.validate_operational_readiness_cadence_import_context/3
    )
    |> Keyword.merge(row_handoff_callbacks())
  end

  defp source_review_row_callbacks do
    CadenceSourceReviewRowCallbacks.build(
      expect_optional_one_of: &PrimitiveValidation.expect_optional_one_of/5,
      expect_optional_type: &PrimitiveValidation.expect_optional_type/5,
      expect_optional_probability: &PrimitiveValidation.expect_optional_probability/4,
      validate_selected_timeline_integrity_fields:
        &TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3,
      validate_stable_ids: &StableIdValidation.validate_stable_ids/4,
      expect_optional_number: &PrimitiveValidation.expect_optional_number/4,
      validate_optional_stable_id_list: &StableIdValidation.validate_optional_stable_id_list/4,
      validate_optional_policy_decision_evidence:
        &PolicyValidation.validate_optional_decision_evidence/3,
      validate_optional_policy_escalation: &PolicyValidation.validate_optional_escalation/4,
      validate_optional_candidate_rejection_source_row:
        &CandidateRejectionValidation.validate_optional_source_row/3,
      validate_optional_timeline_dependency_impact_source_row:
        &TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_branch_comparison_source_row:
        &DecisionSupportValidation.validate_optional_branch_comparison_source_row/3,
      validate_source_evidence_fields: &SourceEvidenceValidation.validate_fields/3,
      validate_freshness_source_status_matches:
        &SourceEvidenceValidation.validate_freshness_status_matches/3,
      validate_schema_validation_source_status_matches:
        &SourceEvidenceValidation.validate_schema_validation_status_matches/3,
      validate_execution_source_status_matches:
        &SourceEvidenceValidation.validate_execution_status_matches/3,
      validate_operational_readiness_resource_context:
        &OperationalReadinessValidation.validate_operational_readiness_resource_context/3,
      validate_contact_allocation_handoff_fields:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_fields/3,
      validate_operator_review_row_links: &OperatorReviewValidation.validate_row_links/3,
      validate_contact_allocation_capacity_pack_group:
        &ContactAllocationValidation.validate_capacity_pack_group/3,
      validate_optional_timeline_link:
        &TimelineContextValidation.validate_optional_timeline_link/4,
      validate_optional_timeline_identity:
        &TimelineContextValidation.validate_optional_timeline_identity/4,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_activity_state_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_preservation_source_row:
        &TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_activity_context:
        &TimelineContextValidation.validate_optional_activity_context/4,
      validate_optional_timeline_diff_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_optional_timeline_transition_application_row:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_integrity_source_row:
        &TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      error: &PrimitiveValidation.error/2
    )
  end

  defp row_handoff_callbacks do
    CadenceImportRowHandoffCallbacks.build(
      validate_contact_allocation_handoff_fields:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_allocation_fields/3,
      validate_operator_review_row_links: &OperatorReviewValidation.validate_row_links/3,
      validate_optional_timeline_activity_precondition_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_precondition_summary_source/3,
      validate_optional_timeline_activity_state_source:
        &TimelineSourceValidation.validate_optional_timeline_activity_state_source/3,
      validate_optional_timeline_dependency_impact_source_row:
        &TimelineSourceValidation.validate_optional_timeline_dependency_impact_source_row/3,
      validate_optional_timeline_diff_summary_source:
        &TimelineSourceValidation.validate_optional_timeline_diff_summary_source/3,
      validate_optional_timeline_integrity_source_row:
        &TimelineTransitionValidation.validate_optional_timeline_integrity_source_row/3,
      validate_optional_timeline_lifecycle_state_source_row:
        &TimelineSourceValidation.validate_optional_timeline_lifecycle_state_source_row/3,
      validate_optional_timeline_preservation_source_row:
        &TimelineSourceValidation.validate_optional_timeline_preservation_source_row/3,
      validate_optional_timeline_protection_summary:
        &TimelineContextValidation.validate_optional_timeline_protection_summary/4,
      validate_optional_timeline_transition_application_row:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_row/3,
      validate_optional_timeline_transition_application_summary_source:
        &TimelineTransitionValidation.validate_optional_timeline_transition_application_summary_source/3,
      validate_selected_timeline_integrity_fields:
        &TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3
    )
  end

  defp manifest_required_fields do
    CadenceImportRegistryContracts.contracts()
    |> Map.fetch!(@cadence_import_manifest)
    |> Map.fetch!("required_fields")
  end
end
