defmodule OrbitalDynamics.CadenceImport.BranchEvidenceFields do
  @moduledoc false

  def contact_allocation do
    [
      "branch_contact_allocation_statuses",
      "branch_contact_allocation_effective_statuses",
      "branch_contact_allocation_reasons",
      "branch_contact_allocation_review_statuses",
      "branch_contact_allocation_approval_statuses",
      "branch_contact_allocation_policy_classifications",
      "branch_station_reservation_conflict_contact_ids",
      "branch_station_reservation_conflict_reservation_ids",
      "branch_station_reservation_conflict_match_statuses",
      "branch_station_reservation_expiration_statuses"
    ]
  end

  def readiness_quality_gate do
    [
      "branch_operational_readiness_levels",
      "branch_operational_readiness_import_classifications",
      "branch_operational_readiness_statuses",
      "branch_operational_readiness_source_report_paths",
      "branch_operational_readiness_gate_ids",
      "branch_operational_readiness_gate_statuses",
      "branch_operational_readiness_gate_classifications",
      "branch_operational_readiness_review_required_gate_ids",
      "branch_operational_readiness_analysis_only_gate_ids",
      "branch_operational_readiness_blocked_gate_ids",
      "branch_operational_readiness_non_passed_gate_ids",
      "branch_quality_gate_readiness_levels",
      "branch_quality_gate_import_classifications",
      "branch_quality_gate_statuses",
      "branch_quality_gate_source_report_paths",
      "branch_quality_gate_gate_classifications",
      "branch_quality_gate_review_required_gate_ids",
      "branch_quality_gate_analysis_only_gate_ids",
      "branch_quality_gate_blocked_gate_ids",
      "branch_quality_gate_non_passed_gate_ids",
      "branch_quality_gate_review_required_row_ids",
      "branch_quality_gate_analysis_only_row_ids",
      "branch_quality_gate_blocked_row_ids",
      "branch_quality_gate_non_passed_row_ids"
    ]
  end

  def timeline do
    timeline_activity() ++ timeline_publication()
  end

  defp timeline_activity do
    [
      "branch_timeline_dependency_impact_activity_ids",
      "branch_timeline_dependency_impact_timeline_ids",
      "branch_timeline_dependency_impact_scopes",
      "branch_impacted_dependency_activity_ids",
      "branch_impacted_dependency_timeline_ids",
      "branch_impacted_exclusive_with_activity_ids",
      "branch_impacted_exclusive_with_timeline_ids",
      "branch_timeline_lifecycle_state_statuses",
      "branch_timeline_lifecycle_state_review_timeline_ids",
      "branch_timeline_lifecycle_state_review_activity_ids",
      "branch_timeline_lifecycle_state_invalid_activity_input_ids",
      "branch_timeline_lifecycle_state_required_operator_actions",
      "branch_timeline_lifecycle_state_import_actions",
      "branch_timeline_activity_lifecycle_state_activity_ids",
      "branch_timeline_activity_lifecycle_state_timeline_ids",
      "branch_timeline_activity_lifecycle_state_transition_decisions",
      "branch_timeline_activity_lifecycle_state_required_operator_actions",
      "branch_timeline_activity_lifecycle_state_import_actions",
      "branch_timeline_activity_lifecycle_state_status_transition_categories",
      "branch_timeline_activity_lifecycle_state_approval_transition_categories",
      "branch_timeline_activity_lifecycle_state_invalid_activity_input_reasons",
      "branch_timeline_activity_precondition_activity_ids",
      "branch_timeline_activity_precondition_timeline_ids",
      "branch_timeline_activity_precondition_statuses",
      "branch_timeline_activity_precondition_blocked_types",
      "branch_timeline_activity_precondition_review_types",
      "branch_timeline_activity_precondition_dependency_activity_ids",
      "branch_timeline_activity_precondition_dependency_timeline_ids",
      "branch_timeline_activity_precondition_exclusive_with_activity_ids",
      "branch_timeline_activity_precondition_exclusive_with_timeline_ids",
      "branch_timeline_activity_precondition_duplicate_dependency_activity_ids",
      "branch_timeline_activity_precondition_duplicate_dependency_timeline_ids",
      "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids",
      "branch_timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
      "branch_timeline_activity_precondition_invalid_activity_input_reasons",
      "branch_timeline_preservation_activity_ids",
      "branch_timeline_preservation_timeline_ids",
      "branch_timeline_preservation_statuses",
      "branch_timeline_preservation_protection_decisions",
      "branch_timeline_preservation_protection_categories",
      "branch_timeline_preservation_protection_reasons",
      "branch_timeline_preservation_preserve_activity_ids",
      "branch_timeline_preservation_preserve_timeline_ids",
      "branch_timeline_preservation_review_change_activity_ids",
      "branch_timeline_preservation_review_change_timeline_ids",
      "branch_timeline_preservation_invalid_activity_input_reasons"
    ]
  end

  defp timeline_publication do
    [
      "branch_timeline_publication_ids",
      "branch_timeline_publication_statuses",
      "branch_timeline_publication_source_artifact_ids",
      "branch_timeline_publication_source_artifact_types",
      "branch_timeline_publication_downstream_invalidation_statuses",
      "branch_timeline_publication_invalidated_downstream_product_ids",
      "branch_timeline_publication_downstream_invalidation_reasons",
      "branch_timeline_publication_dependency_impact_statuses",
      "branch_timeline_publication_impacted_source_activity_ids",
      "branch_timeline_publication_impacted_source_timeline_ids",
      "branch_timeline_publication_dependent_activity_ids",
      "branch_timeline_publication_dependent_timeline_ids",
      "branch_timeline_publication_changed_fields",
      "branch_timeline_publication_changed_timeline_ids",
      "branch_timeline_publication_review_timeline_ids"
    ]
  end
end
