defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields do
  @moduledoc false

  alias __MODULE__.CapacityPack

  import __MODULE__.Aggregation

  def source_report_fields(source_reports) do
    %{
      "source_report_contact_contention_resolution_recommendation_count" =>
        source_report_family_count(source_reports, "recommendation_count"),
      "source_report_contact_contention_resolution_source_summary_model_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_contact_contention_resolution_source_summary_schema_contract_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_contact_contention_resolution_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_contact_contention_resolution_conflict_group_count" =>
        source_report_family_count(source_reports, "conflict_group_count"),
      "source_report_contact_contention_resolution_review_recommendation_count" =>
        source_report_family_count(source_reports, "review_recommendation_count"),
      "source_report_contact_contention_resolution_recommendation_group_ids" =>
        source_report_family_merge_string_lists(source_reports, "recommendation_group_ids"),
      "source_report_contact_contention_resolution_review_group_ids" =>
        source_report_family_merge_string_lists(source_reports, "review_group_ids"),
      "source_report_contact_contention_resolution_ambiguous_group_ids" =>
        source_report_family_merge_string_lists(source_reports, "ambiguous_group_ids"),
      "source_report_contact_contention_resolution_ambiguous_duplicate_contact_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "ambiguous_duplicate_contact_ids"
        ),
      "source_report_contact_contention_resolution_ambiguous_duplicate_contact_ids_by_group_id" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "ambiguous_duplicate_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_deferred_contact_count" =>
        source_report_family_count(source_reports, "deferred_contact_count"),
      "source_report_contact_contention_resolution_status_counts" =>
        source_report_family_merge_count_maps(source_reports, "resolution_status_counts"),
      "source_report_contact_contention_resolution_selection_reason_counts" =>
        source_report_family_merge_count_maps(source_reports, "selection_reason_counts"),
      "source_report_contact_contention_resolution_selected_contact_ids_by_selection_reason" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_selection_reason"
        ),
      "source_report_contact_contention_resolution_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_contact_contention_resolution_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_contact_contention_resolution_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_contact_contention_resolution_paths" =>
        source_report_family_identity_field(source_reports, "paths"),
      "source_report_contact_contention_resolution_selected_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "selected_contact_ids"),
      "source_report_contact_contention_resolution_selected_contact_ids_by_group_id" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "deferred_contact_ids"),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_group_id" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_review_contact_ids" =>
        source_report_family_merge_string_lists(source_reports, "review_contact_ids"),
      "source_report_contact_contention_resolution_review_contact_ids_by_group_id" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_group_id"
        ),
      "source_report_contact_contention_resolution_resource_scope_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_scope_counts"),
      "source_report_contact_contention_resolution_selected_contact_ids_by_resource_scope" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_resource_scope" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_review_contact_ids_by_resource_scope" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_resource_scope"
        ),
      "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "selected_contact_ids_by_ground_station"
        ),
      "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "deferred_contact_ids_by_ground_station"
        ),
      "source_report_contact_contention_resolution_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_contact_contention_resolution_contact_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "contact_ids_by_direction"),
      "source_report_contact_contention_resolution_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing"),
      "source_report_contact_contention_resolution_required_operator_action_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "required_operator_action_counts"
        ),
      "source_report_contact_contention_resolution_review_contact_ids_by_action" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "review_contact_ids_by_action"
        )
    }
    |> Map.merge(CapacityPack.fields(source_reports))
    |> compact_map()
  end
end
