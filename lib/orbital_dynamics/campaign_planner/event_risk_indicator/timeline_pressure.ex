defmodule OrbitalDynamics.CampaignPlanner.EventRiskIndicator.TimelinePressure do
  @moduledoc false

  def indicators(%{"type" => "timeline_integrity_feedback"} = event) do
    [
      %{
        "type" => "timeline_integrity_issue",
        "severity" => "high",
        "reason" =>
          "activity #{event["activity_id"] || event["timeline_id"]} has dependency or exclusivity integrity issues",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "timeline_integrity_status" => event["timeline_integrity_status"],
        "timeline_integrity_issue_count" => event["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => event["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => event["timeline_integrity_issues"],
        "missing_dependency_activity_ids" => event["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => event["missing_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => event["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => event["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          event["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          event["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => event["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => event["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => event["exclusivity_violation_group"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_dependency_impact_pressure"} = event) do
    [
      %{
        "type" => "timeline_dependency_impact",
        "severity" => "high",
        "reason" =>
          "activity #{event["activity_id"] || event["timeline_id"]} has dependency or exclusivity links impacted by changed source timeline evidence",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "dependency_impact_scope" => event["dependency_impact_scope"],
        "dependency_impact_status" => event["dependency_impact_status"],
        "operator_action_reason" => event["operator_action_reason"],
        "required_operator_action" => event["required_operator_action"],
        "dependency_activity_ids" => event["dependency_activity_ids"],
        "dependency_timeline_ids" => event["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => event["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => event["exclusive_with_timeline_ids"],
        "impacted_dependency_activity_ids" => event["impacted_dependency_activity_ids"],
        "impacted_dependency_timeline_ids" => event["impacted_dependency_timeline_ids"],
        "impacted_exclusive_with_activity_ids" => event["impacted_exclusive_with_activity_ids"],
        "impacted_exclusive_with_timeline_ids" => event["impacted_exclusive_with_timeline_ids"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_publication_pressure"} = event) do
    [
      %{
        "type" => "timeline_publication_pressure",
        "severity" => "high",
        "reason" =>
          "timeline publication #{event["publication_id"] || event["source_artifact_id"]} carries review, dependency-impact, changed-field, or downstream invalidation pressure",
        "publication_id" => event["publication_id"],
        "publication_sequence" => event["publication_sequence"],
        "publication_status" => event["publication_status"],
        "downstream_invalidation_status" => event["downstream_invalidation_status"],
        "dependency_impact_status" => event["dependency_impact_status"],
        "source_artifact_id" => event["source_artifact_id"],
        "source_artifact_type" => event["source_artifact_type"],
        "publication_authority" => event["publication_authority"],
        "supersedes_artifact_ids" => event["supersedes_artifact_ids"],
        "downstream_product_ids" => event["downstream_product_ids"],
        "dependency_impact_row_count" => event["dependency_impact_row_count"],
        "timeline_diff_review_required_count" => event["timeline_diff_review_required_count"],
        "invalidated_downstream_product_ids" => event["invalidated_downstream_product_ids"],
        "downstream_invalidation_reason_counts" => event["downstream_invalidation_reason_counts"],
        "downstream_invalidation_reasons" => event["downstream_invalidation_reasons"],
        "invalidated_downstream_product_ids_by_reason" =>
          event["invalidated_downstream_product_ids_by_reason"],
        "timeline_diff_row_count" => event["timeline_diff_row_count"],
        "timeline_diff_changed_count" => event["timeline_diff_changed_count"],
        "changed_field_counts" => event["changed_field_counts"],
        "changed_fields" => event["changed_fields"],
        "changed_timeline_ids" => event["changed_timeline_ids"],
        "review_timeline_ids" => event["review_timeline_ids"],
        "timeline_ids_by_changed_field" => event["timeline_ids_by_changed_field"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_transition_application_pressure"} = event) do
    [
      %{
        "type" => "timeline_transition_application_pressure",
        "severity" => "high",
        "reason" =>
          "timeline transition application #{event["timeline_id"] || event["activity_id"]} carries review, withhold, or duplicate-identity pressure",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "application_status" => event["application_status"],
        "transition_decision" => event["transition_decision"],
        "required_operator_action" => event["required_operator_action"],
        "operator_action_reason" => event["operator_action_reason"],
        "selected_activity_source" => event["selected_activity_source"],
        "selected_activity" => event["selected_activity"],
        "timeline_identity_collision" => event["timeline_identity_collision"],
        "duplicate_timeline_identity_scope" => event["duplicate_timeline_identity_scope"],
        "source_duplicate_activity_count" => event["source_duplicate_activity_count"],
        "replacement_duplicate_activity_count" => event["replacement_duplicate_activity_count"],
        "source_duplicate_activity_ids" => event["source_duplicate_activity_ids"],
        "replacement_duplicate_activity_ids" => event["replacement_duplicate_activity_ids"],
        "policy_classification" => event["policy_classification"],
        "policy_bundle_id" => event["policy_bundle_id"],
        "approval_status" => event["approval_status"],
        "approval_requirements" => event["approval_requirements"],
        "approval_rule_matches" => event["approval_rule_matches"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_lifecycle_state_pressure"} = event) do
    [
      %{
        "type" => "timeline_lifecycle_state_review",
        "severity" => "high",
        "reason" =>
          "timeline lifecycle summary carries review, import, duplicate identity, or invalid activity pressure",
        "timeline_lifecycle_state_status" => event["timeline_lifecycle_state_status"],
        "planned_activity_count" => event["planned_activity_count"],
        "realized_activity_count" => event["realized_activity_count"],
        "row_count" => event["row_count"],
        "recordable_count" => event["recordable_count"],
        "preserved_count" => event["preserved_count"],
        "review_required_count" => event["review_required_count"],
        "duplicate_timeline_identity_count" => event["duplicate_timeline_identity_count"],
        "invalid_activity_input_count" => event["invalid_activity_input_count"],
        "transition_decision_counts" => event["transition_decision_counts"],
        "required_operator_action_counts" => event["required_operator_action_counts"],
        "operator_action_reason_counts" => event["operator_action_reason_counts"],
        "import_action_counts" => event["import_action_counts"],
        "planned_status_category_counts" => event["planned_status_category_counts"],
        "realized_status_category_counts" => event["realized_status_category_counts"],
        "status_transition_category_counts" => event["status_transition_category_counts"],
        "approval_transition_category_counts" => event["approval_transition_category_counts"],
        "recordable_timeline_ids" => event["recordable_timeline_ids"],
        "preserved_timeline_ids" => event["preserved_timeline_ids"],
        "review_timeline_ids" => event["review_timeline_ids"],
        "review_activity_ids" => event["review_activity_ids"],
        "invalid_activity_input_ids" => event["invalid_activity_input_ids"],
        "review_timeline_ids_by_required_operator_action" =>
          event["review_timeline_ids_by_required_operator_action"],
        "review_timeline_ids_by_operator_action_reason" =>
          event["review_timeline_ids_by_operator_action_reason"],
        "review_timeline_ids_by_status_transition_category" =>
          event["review_timeline_ids_by_status_transition_category"],
        "review_timeline_ids_by_approval_transition_category" =>
          event["review_timeline_ids_by_approval_transition_category"],
        "requires_operator_review" => event["requires_operator_review"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_activity_lifecycle_state_pressure"} = event) do
    [
      %{
        "type" => "timeline_activity_lifecycle_state_review",
        "severity" => "high",
        "reason" =>
          "activity #{event["activity_id"] || event["timeline_id"]} carries lifecycle-state review or import pressure",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "planned_activity_id" => event["planned_activity_id"],
        "realized_activity_id" => event["realized_activity_id"],
        "planned_timeline_id" => event["planned_timeline_id"],
        "realized_timeline_id" => event["realized_timeline_id"],
        "transition_decision" => event["transition_decision"],
        "status_transition_decision" => event["status_transition_decision"],
        "approval_transition_decision" => event["approval_transition_decision"],
        "review_required" => event["review_required"],
        "requires_operator_review" => event["requires_operator_review"],
        "required_operator_action" => event["required_operator_action"],
        "required_operator_actions" => event["required_operator_actions"],
        "operator_action_reasons" => event["operator_action_reasons"],
        "import_action" => event["import_action"],
        "invalid_activity_input" => event["invalid_activity_input"],
        "invalid_activity_input_count" => event["invalid_activity_input_count"],
        "invalid_activity_input_reasons" => event["invalid_activity_input_reasons"],
        "planned_status" => event["planned_status"],
        "realized_status" => event["realized_status"],
        "planned_status_category" => event["planned_status_category"],
        "realized_status_category" => event["realized_status_category"],
        "planned_approval_status" => event["planned_approval_status"],
        "realized_approval_status" => event["realized_approval_status"],
        "planned_approval_category" => event["planned_approval_category"],
        "realized_approval_category" => event["realized_approval_category"],
        "planned_locked" => event["planned_locked"],
        "realized_locked" => event["realized_locked"],
        "planned_executed" => event["planned_executed"],
        "realized_executed" => event["realized_executed"],
        "status_transition" => event["status_transition"],
        "approval_transition" => event["approval_transition"],
        "planned_protection_decision" => event["planned_protection_decision"],
        "realized_protection_decision" => event["realized_protection_decision"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_activity_precondition_pressure"} = event) do
    [
      %{
        "type" => "timeline_activity_precondition_review",
        "severity" => "high",
        "reason" =>
          "activity #{event["activity_id"] || event["timeline_id"]} carries blocked, review, dependency, exclusivity, or invalid-input precondition pressure",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "activity_type" => event["activity_type"],
        "precondition_status" => event["precondition_status"],
        "blocked_precondition_count" => event["blocked_precondition_count"],
        "review_precondition_count" => event["review_precondition_count"],
        "blocked_precondition_types" => event["blocked_precondition_types"],
        "review_precondition_types" => event["review_precondition_types"],
        "dependency_activity_ids" => event["dependency_activity_ids"],
        "dependency_timeline_ids" => event["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => event["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => event["exclusive_with_timeline_ids"],
        "duplicate_dependency_activity_ids" => event["duplicate_dependency_activity_ids"],
        "duplicate_dependency_timeline_ids" => event["duplicate_dependency_timeline_ids"],
        "duplicate_exclusivity_activity_ids" => event["duplicate_exclusivity_activity_ids"],
        "duplicate_exclusivity_timeline_ids" => event["duplicate_exclusivity_timeline_ids"],
        "allow_overlap" => event["allow_overlap"],
        "invalid_activity_input" => event["invalid_activity_input"],
        "invalid_activity_input_reason" => event["invalid_activity_input_reason"],
        "requires_operator_review" => event["requires_operator_review"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(%{"type" => "timeline_preservation_pressure"} = event) do
    [
      %{
        "type" => "timeline_preservation_review",
        "severity" => "high",
        "reason" =>
          "activity #{event["activity_id"] || event["timeline_id"]} carries lifecycle preservation, review-change, or invalid-input pressure",
        "activity_id" => event["activity_id"],
        "timeline_id" => event["timeline_id"],
        "timeline_preservation_status" => event["timeline_preservation_status"],
        "requires_preservation" => event["requires_preservation"],
        "requires_operator_review" => event["requires_operator_review"],
        "status" => event["status"],
        "approval_status" => event["approval_status"],
        "locked" => event["locked"],
        "approved" => event["approved"],
        "protection_decision" => event["protection_decision"],
        "protection_category" => event["protection_category"],
        "protection_reason" => event["protection_reason"],
        "activity_count" => event["activity_count"],
        "preserve_activity_count" => event["preserve_activity_count"],
        "review_change_activity_count" => event["review_change_activity_count"],
        "preservation_sensitive_activity_count" => event["preservation_sensitive_activity_count"],
        "preserve_activity_ids" => event["preserve_activity_ids"],
        "preserve_timeline_ids" => event["preserve_timeline_ids"],
        "review_change_activity_ids" => event["review_change_activity_ids"],
        "review_change_timeline_ids" => event["review_change_timeline_ids"],
        "preservation_sensitive_activity_ids" => event["preservation_sensitive_activity_ids"],
        "preservation_sensitive_timeline_ids" => event["preservation_sensitive_timeline_ids"],
        "invalid_activity_input" => event["invalid_activity_input"],
        "invalid_activity_input_reason" => event["invalid_activity_input_reason"],
        "required_operator_action" => event["required_operator_action"],
        "feedback_source" => event["feedback_source"],
        "feedback_scope" => event["feedback_scope"],
        "feedback_key" => event["feedback_key"],
        "trust_boundary" => event["trust_boundary"],
        "derivation_reasons" => event["derivation_reasons"],
        "assumptions" => event["assumptions"]
      }
      |> compact_map()
    ]
  end

  def indicators(_event), do: []

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
