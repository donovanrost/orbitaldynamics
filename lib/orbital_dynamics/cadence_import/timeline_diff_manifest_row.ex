defmodule OrbitalDynamics.CadenceImport.TimelineDiffManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:timeline_diff:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_timeline_diff",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "timeline_id" => row["timeline_id"],
      "diff_status" => row["diff_status"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "source_activity_id" => row["source_activity_id"],
      "replacement_activity_id" => row["replacement_activity_id"],
      "source_activity_type" => row["source_activity_type"],
      "replacement_activity_type" => row["replacement_activity_type"],
      "source_spacecraft_id" => row["source_spacecraft_id"],
      "replacement_spacecraft_id" => row["replacement_spacecraft_id"],
      "source_ground_station_id" => row["source_ground_station_id"],
      "replacement_ground_station_id" => row["replacement_ground_station_id"],
      "source_target_id" => row["source_target_id"],
      "replacement_target_id" => row["replacement_target_id"],
      "source_source_window_id" => row["source_source_window_id"],
      "replacement_source_window_id" => row["replacement_source_window_id"],
      "source_starts_at_s" => row["source_starts_at_s"],
      "source_ends_at_s" => row["source_ends_at_s"],
      "replacement_starts_at_s" => row["replacement_starts_at_s"],
      "replacement_ends_at_s" => row["replacement_ends_at_s"],
      "start_delta_s" => row["start_delta_s"],
      "end_delta_s" => row["end_delta_s"],
      "source_status" => row["source_status"],
      "replacement_status" => row["replacement_status"],
      "source_approval_status" => row["source_approval_status"],
      "replacement_approval_status" => row["replacement_approval_status"],
      "source_locked" => row["source_locked"],
      "replacement_locked" => row["replacement_locked"],
      "source_protection_decision" => row["source_protection_decision"],
      "source_protection_category" => row["source_protection_category"],
      "source_protection_reason" => row["source_protection_reason"],
      "replacement_protection_decision" => row["replacement_protection_decision"],
      "replacement_protection_category" => row["replacement_protection_category"],
      "replacement_protection_reason" => row["replacement_protection_reason"],
      "source_timeline_integrity_status" => row["source_timeline_integrity_status"],
      "source_timeline_integrity_issue_count" => row["source_timeline_integrity_issue_count"],
      "source_timeline_integrity_issue_types" => row["source_timeline_integrity_issue_types"],
      "source_timeline_integrity_issues" => row["source_timeline_integrity_issues"],
      "source_missing_dependency_activity_ids" => row["source_missing_dependency_activity_ids"],
      "source_missing_dependency_timeline_ids" => row["source_missing_dependency_timeline_ids"],
      "source_self_dependency_activity_ids" => row["source_self_dependency_activity_ids"],
      "source_self_dependency_timeline_ids" => row["source_self_dependency_timeline_ids"],
      "source_dependency_cycle_activity_ids" => row["source_dependency_cycle_activity_ids"],
      "source_dependency_cycle_timeline_ids" => row["source_dependency_cycle_timeline_ids"],
      "replacement_timeline_integrity_status" => row["replacement_timeline_integrity_status"],
      "replacement_timeline_integrity_issue_count" =>
        row["replacement_timeline_integrity_issue_count"],
      "replacement_timeline_integrity_issue_types" =>
        row["replacement_timeline_integrity_issue_types"],
      "replacement_timeline_integrity_issues" => row["replacement_timeline_integrity_issues"],
      "replacement_missing_dependency_activity_ids" =>
        row["replacement_missing_dependency_activity_ids"],
      "replacement_missing_dependency_timeline_ids" =>
        row["replacement_missing_dependency_timeline_ids"],
      "replacement_self_dependency_activity_ids" =>
        row["replacement_self_dependency_activity_ids"],
      "replacement_self_dependency_timeline_ids" =>
        row["replacement_self_dependency_timeline_ids"],
      "replacement_dependency_cycle_activity_ids" =>
        row["replacement_dependency_cycle_activity_ids"],
      "replacement_dependency_cycle_timeline_ids" =>
        row["replacement_dependency_cycle_timeline_ids"],
      "status_transition" => row["status_transition"],
      "approval_transition" => row["approval_transition"],
      "changed_fields" => row["changed_fields"],
      "timeline_identity_collision" => row["timeline_identity_collision"],
      "duplicate_timeline_identity_scope" => row["duplicate_timeline_identity_scope"],
      "source_duplicate_activity_count" => row["source_duplicate_activity_count"],
      "replacement_duplicate_activity_count" => row["replacement_duplicate_activity_count"],
      "source_duplicate_activity_ids" => row["source_duplicate_activity_ids"],
      "replacement_duplicate_activity_ids" => row["replacement_duplicate_activity_ids"],
      "source_duplicate_activities" => row["source_duplicate_activities"],
      "replacement_duplicate_activities" => row["replacement_duplicate_activities"],
      "source_invalid_activity_input" => row["source_invalid_activity_input"],
      "source_invalid_activity_input_reason" => row["source_invalid_activity_input_reason"],
      "source_activity" => row["source_activity"],
      "replacement_invalid_activity_input" => row["replacement_invalid_activity_input"],
      "replacement_invalid_activity_input_reason" =>
        row["replacement_invalid_activity_input_reason"],
      "replacement_activity" => row["replacement_activity"],
      "transition_decision" => row["transition_decision"],
      "transition_decision_reason" => row["transition_decision_reason"],
      "requires_operator_review" => row["requires_operator_review"],
      "application_status" => row["application_status"],
      "selected_activity_source" => row["selected_activity_source"],
      "selected_activity" => row["selected_activity"],
      "selected_timeline_integrity_status" => row["selected_timeline_integrity_status"],
      "selected_timeline_integrity_issue_count" => row["selected_timeline_integrity_issue_count"],
      "selected_timeline_integrity_issue_types" => row["selected_timeline_integrity_issue_types"],
      "selected_timeline_integrity_issues" => row["selected_timeline_integrity_issues"],
      "selected_missing_dependency_activity_ids" =>
        row["selected_missing_dependency_activity_ids"],
      "selected_missing_dependency_timeline_ids" =>
        row["selected_missing_dependency_timeline_ids"],
      "selected_self_dependency_activity_ids" => row["selected_self_dependency_activity_ids"],
      "selected_self_dependency_timeline_ids" => row["selected_self_dependency_timeline_ids"],
      "selected_duplicate_dependency_activity_ids" =>
        row["selected_duplicate_dependency_activity_ids"],
      "selected_duplicate_dependency_timeline_ids" =>
        row["selected_duplicate_dependency_timeline_ids"],
      "selected_duplicate_exclusivity_activity_ids" =>
        row["selected_duplicate_exclusivity_activity_ids"],
      "selected_duplicate_exclusivity_timeline_ids" =>
        row["selected_duplicate_exclusivity_timeline_ids"],
      "selected_dependency_cycle_activity_ids" => row["selected_dependency_cycle_activity_ids"],
      "selected_dependency_cycle_timeline_ids" => row["selected_dependency_cycle_timeline_ids"],
      "selected_dependency_order_violation_activity_ids" =>
        row["selected_dependency_order_violation_activity_ids"],
      "selected_dependency_order_violation_timeline_ids" =>
        row["selected_dependency_order_violation_timeline_ids"],
      "selected_exclusivity_violation_activity_ids" =>
        row["selected_exclusivity_violation_activity_ids"],
      "selected_exclusivity_violation_timeline_ids" =>
        row["selected_exclusivity_violation_timeline_ids"],
      "selected_exclusivity_violation_group" => row["selected_exclusivity_violation_group"],
      "approval_status" => approval_status,
      "policy_classification" => row["policy_classification"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "source_policy_decision" => row["source_policy_decision"],
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "operator_action_reason" => row["operator_action_reason"] || row["reason"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          generic_review_activity_context(callbacks, row)
        ),
      "source_activity_context" =>
        normalize_provider_result_artifact_fields(callbacks, row["source_activity_context"]),
      "replacement_activity_context" =>
        normalize_provider_result_artifact_fields(callbacks, row["replacement_activity_context"]),
      "timeline_link" => row["timeline_link"],
      "source_timeline_identity" => row["source_timeline_identity"],
      "replacement_timeline_identity" => row["replacement_timeline_identity"],
      "source_timeline_diff" => row["source_timeline_diff"],
      "source_timeline_diff_summary" => row["source_timeline_diff_summary"],
      "source_timeline_diff_summary_source_activity_count" =>
        row["source_timeline_diff_summary_source_activity_count"],
      "source_timeline_diff_summary_replacement_activity_count" =>
        row["source_timeline_diff_summary_replacement_activity_count"],
      "source_timeline_diff_summary_row_count" => row["source_timeline_diff_summary_row_count"],
      "source_timeline_diff_summary_added_count" =>
        row["source_timeline_diff_summary_added_count"],
      "source_timeline_diff_summary_removed_count" =>
        row["source_timeline_diff_summary_removed_count"],
      "source_timeline_diff_summary_changed_count" =>
        row["source_timeline_diff_summary_changed_count"],
      "source_timeline_diff_summary_unchanged_count" =>
        row["source_timeline_diff_summary_unchanged_count"],
      "source_timeline_diff_summary_review_required_count" =>
        row["source_timeline_diff_summary_review_required_count"],
      "source_timeline_diff_summary_duplicate_timeline_identity_count" =>
        row["source_timeline_diff_summary_duplicate_timeline_identity_count"],
      "source_timeline_diff_summary_invalid_source_activity_input_count" =>
        row["source_timeline_diff_summary_invalid_source_activity_input_count"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_count" =>
        row["source_timeline_diff_summary_invalid_replacement_activity_input_count"],
      "source_timeline_diff_summary_diff_status_counts" =>
        row["source_timeline_diff_summary_diff_status_counts"],
      "source_timeline_diff_summary_transition_decision_counts" =>
        row["source_timeline_diff_summary_transition_decision_counts"],
      "source_timeline_diff_summary_required_operator_action_counts" =>
        row["source_timeline_diff_summary_required_operator_action_counts"],
      "source_timeline_diff_summary_changed_field_counts" =>
        row["source_timeline_diff_summary_changed_field_counts"],
      "source_timeline_diff_summary_status_transition_category_counts" =>
        row["source_timeline_diff_summary_status_transition_category_counts"],
      "source_timeline_diff_summary_approval_transition_category_counts" =>
        row["source_timeline_diff_summary_approval_transition_category_counts"],
      "source_timeline_diff_summary_added_timeline_ids" =>
        row["source_timeline_diff_summary_added_timeline_ids"],
      "source_timeline_diff_summary_removed_timeline_ids" =>
        row["source_timeline_diff_summary_removed_timeline_ids"],
      "source_timeline_diff_summary_changed_timeline_ids" =>
        row["source_timeline_diff_summary_changed_timeline_ids"],
      "source_timeline_diff_summary_unchanged_timeline_ids" =>
        row["source_timeline_diff_summary_unchanged_timeline_ids"],
      "source_timeline_diff_summary_duplicate_timeline_identity_ids" =>
        row["source_timeline_diff_summary_duplicate_timeline_identity_ids"],
      "source_timeline_diff_summary_invalid_source_activity_input_ids" =>
        row["source_timeline_diff_summary_invalid_source_activity_input_ids"],
      "source_timeline_diff_summary_invalid_replacement_activity_input_ids" =>
        row["source_timeline_diff_summary_invalid_replacement_activity_input_ids"],
      "source_timeline_diff_summary_review_timeline_ids" =>
        row["source_timeline_diff_summary_review_timeline_ids"],
      "source_timeline_diff_summary_review_timeline_ids_by_required_operator_action" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_required_operator_action"],
      "source_timeline_diff_summary_review_timeline_ids_by_status_transition_category" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_status_transition_category"],
      "source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category" =>
        row["source_timeline_diff_summary_review_timeline_ids_by_approval_transition_category"],
      "source_timeline_diff_summary_timeline_ids_by_changed_field" =>
        row["source_timeline_diff_summary_timeline_ids_by_changed_field"],
      "transition_application_provenance" => row["transition_application_provenance"],
      "source_timeline_application" => row["source_timeline_application"],
      "source_timeline_transition_application_summary" =>
        row["source_timeline_transition_application_summary"],
      "source_transition_application_source_activity_count" =>
        row["source_transition_application_source_activity_count"],
      "source_transition_application_replacement_activity_count" =>
        row["source_transition_application_replacement_activity_count"],
      "source_transition_application_count" => row["source_transition_application_count"],
      "source_transition_application_selected_activity_count" =>
        row["source_transition_application_selected_activity_count"],
      "source_transition_application_review_required_count" =>
        row["source_transition_application_review_required_count"],
      "source_transition_application_preserved_source_count" =>
        row["source_transition_application_preserved_source_count"],
      "source_transition_application_recorded_replacement_count" =>
        row["source_transition_application_recorded_replacement_count"],
      "source_transition_application_withheld_review_count" =>
        row["source_transition_application_withheld_review_count"],
      "source_transition_application_selected_timeline_integrity_review_count" =>
        row["source_transition_application_selected_timeline_integrity_review_count"],
      "source_transition_application_selected_timeline_integrity_issue_count" =>
        row["source_transition_application_selected_timeline_integrity_issue_count"],
      "source_transition_application_selected_timeline_integrity_issue_types" =>
        row["source_transition_application_selected_timeline_integrity_issue_types"],
      "source_transition_application_status_counts" =>
        row["source_transition_application_status_counts"],
      "source_transition_application_decision_counts" =>
        row["source_transition_application_decision_counts"],
      "source_transition_application_required_operator_action_counts" =>
        row["source_transition_application_required_operator_action_counts"],
      "source_transition_application_status_transition_category_counts" =>
        row["source_transition_application_status_transition_category_counts"],
      "source_transition_application_approval_transition_category_counts" =>
        row["source_transition_application_approval_transition_category_counts"],
      "source_transition_application_selected_activity_ids" =>
        row["source_transition_application_selected_activity_ids"],
      "source_transition_application_selected_timeline_ids" =>
        row["source_transition_application_selected_timeline_ids"],
      "source_transition_application_review_activity_ids" =>
        row["source_transition_application_review_activity_ids"],
      "source_transition_application_review_timeline_ids" =>
        row["source_transition_application_review_timeline_ids"],
      "source_transition_application_review_timeline_ids_by_required_operator_action" =>
        row["source_transition_application_review_timeline_ids_by_required_operator_action"],
      "source_transition_application_review_timeline_ids_by_status_transition_category" =>
        row["source_transition_application_review_timeline_ids_by_status_transition_category"],
      "source_transition_application_review_timeline_ids_by_approval_transition_category" =>
        row["source_transition_application_review_timeline_ids_by_approval_transition_category"],
      "source_transition_application_preserved_source_timeline_ids" =>
        row["source_transition_application_preserved_source_timeline_ids"],
      "source_transition_application_recorded_replacement_timeline_ids" =>
        row["source_transition_application_recorded_replacement_timeline_ids"],
      "source_transition_application_withheld_review_timeline_ids" =>
        row["source_transition_application_withheld_review_timeline_ids"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp generic_review_activity_context(callbacks, row),
    do: invoke(callbacks, :generic_review_activity_context, [row])

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
