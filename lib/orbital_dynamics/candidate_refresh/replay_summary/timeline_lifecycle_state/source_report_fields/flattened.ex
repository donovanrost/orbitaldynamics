defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Aggregates

  def source_report_fields(source_reports) do
    %{
      "source_report_timeline_lifecycle_state_contract" =>
        Aggregates.family_field(source_reports, "contract"),
      "source_report_timeline_lifecycle_state_count" =>
        Aggregates.family_identity_count(source_reports, "count"),
      "source_report_timeline_lifecycle_state_paths" =>
        Aggregates.family_identity_field(source_reports, "paths"),
      "source_report_timeline_lifecycle_state_row_count" =>
        Aggregates.family_identity_count(source_reports, "row_count"),
      "source_report_timeline_lifecycle_state_source_summary_model_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_timeline_lifecycle_state_source_summary_schema_contract_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_timeline_lifecycle_state_planned_activity_count" =>
        Aggregates.family_count(source_reports, "planned_activity_count"),
      "source_report_timeline_lifecycle_state_realized_activity_count" =>
        Aggregates.family_count(source_reports, "realized_activity_count"),
      "source_report_timeline_lifecycle_state_recordable_count" =>
        Aggregates.family_count(source_reports, "recordable_count"),
      "source_report_timeline_lifecycle_state_preserved_count" =>
        Aggregates.family_count(source_reports, "preserved_count"),
      "source_report_timeline_lifecycle_state_review_required_count" =>
        Aggregates.family_count(source_reports, "review_required_count"),
      "source_report_timeline_lifecycle_state_duplicate_timeline_identity_count" =>
        Aggregates.family_count(source_reports, "duplicate_timeline_identity_count"),
      "source_report_timeline_lifecycle_state_invalid_activity_input_count" =>
        Aggregates.family_count(source_reports, "invalid_activity_input_count"),
      "source_report_timeline_lifecycle_state_invalid_activity_input_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "invalid_activity_input_ids"),
      "source_report_timeline_lifecycle_state_transition_decision_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "transition_decision_counts"),
      "source_report_timeline_lifecycle_state_required_operator_action_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "required_operator_action_counts"),
      "source_report_timeline_lifecycle_state_import_action_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "import_action_counts"),
      "source_report_timeline_lifecycle_state_planned_status_category_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "planned_status_category_counts"),
      "source_report_timeline_lifecycle_state_realized_status_category_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "realized_status_category_counts"),
      "source_report_timeline_lifecycle_state_planned_approval_category_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "planned_approval_category_counts"),
      "source_report_timeline_lifecycle_state_realized_approval_category_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "realized_approval_category_counts"),
      "source_report_timeline_lifecycle_state_status_transition_category_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "status_transition_category_counts"),
      "source_report_timeline_lifecycle_state_approval_transition_category_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "approval_transition_category_counts"
        ),
      "source_report_timeline_lifecycle_state_transition_application_provenance_count" =>
        Aggregates.family_count(source_reports, "transition_application_provenance_count"),
      "source_report_timeline_lifecycle_state_transition_application_provenance_helper_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "transition_application_provenance_helper_counts"
        ),
      "source_report_timeline_lifecycle_state_transition_application_provenance_category_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "transition_application_provenance_category_counts"
        ),
      "source_report_timeline_lifecycle_state_transition_application_provenance_operator_action_reason_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "transition_application_provenance_operator_action_reason_counts"
        ),
      "source_report_timeline_lifecycle_state_recordable_timeline_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "recordable_timeline_ids"),
      "source_report_timeline_lifecycle_state_preserved_timeline_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "preserved_timeline_ids"),
      "source_report_timeline_lifecycle_state_review_timeline_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "review_timeline_ids"),
      "source_report_timeline_lifecycle_state_review_activity_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "review_activity_ids"),
      "source_report_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
        Aggregates.family_merge_string_list_maps(
          source_reports,
          "review_timeline_ids_by_required_operator_action"
        ),
      "source_report_timeline_lifecycle_state_review_timeline_ids_by_status_transition_category" =>
        Aggregates.family_merge_string_list_maps(
          source_reports,
          "review_timeline_ids_by_status_transition_category"
        ),
      "source_report_timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category" =>
        Aggregates.family_merge_string_list_maps(
          source_reports,
          "review_timeline_ids_by_approval_transition_category"
        ),
      "source_report_timeline_lifecycle_state_review_routing" =>
        Aggregates.family_field(source_reports, "review_routing")
    }
  end
end
