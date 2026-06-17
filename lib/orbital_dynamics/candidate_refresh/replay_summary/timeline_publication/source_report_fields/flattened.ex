defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.SourceReportFields.Flattened do
  @moduledoc false

  alias __MODULE__.Aggregates

  def source_report_fields(source_reports) do
    %{
      "source_report_timeline_publication_contract" =>
        Aggregates.family_field(source_reports, "contract"),
      "source_report_timeline_publication_count" =>
        Aggregates.family_identity_count(source_reports, "count"),
      "source_report_timeline_publication_paths" =>
        Aggregates.family_identity_field(source_reports, "paths"),
      "source_report_timeline_publication_row_count" =>
        Aggregates.family_identity_count(source_reports, "row_count"),
      "source_report_timeline_publication_source_summary_model_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "source_summary_model_counts"),
      "source_report_timeline_publication_source_summary_schema_contract_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "source_summary_schema_contract_counts"
        ),
      "source_report_timeline_publication_status_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "publication_status_counts"),
      "source_report_timeline_publication_downstream_invalidation_status_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "downstream_invalidation_status_counts"
        ),
      "source_report_timeline_publication_downstream_invalidation_reason_counts" =>
        Aggregates.family_merge_count_maps(
          source_reports,
          "downstream_invalidation_reason_counts"
        ),
      "source_report_timeline_publication_dependency_impact_status_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "dependency_impact_status_counts"),
      "source_report_timeline_publication_authority_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "publication_authority_counts"),
      "source_report_timeline_publication_source_artifact_type_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_timeline_publication_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "publication_ids"),
      "source_report_timeline_publication_source_artifact_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "source_artifact_ids"),
      "source_report_timeline_publication_supersedes_artifact_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "supersedes_artifact_ids"),
      "source_report_timeline_publication_downstream_product_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "downstream_product_ids"),
      "source_report_timeline_publication_invalidated_downstream_product_ids" =>
        Aggregates.family_merge_string_lists(
          source_reports,
          "invalidated_downstream_product_ids"
        ),
      "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason" =>
        Aggregates.family_merge_string_list_maps(
          source_reports,
          "invalidated_downstream_product_ids_by_reason"
        ),
      "source_report_timeline_publication_dependency_impact_row_count" =>
        Aggregates.family_count(source_reports, "dependency_impact_row_count"),
      "source_report_timeline_publication_impacted_dependency_activity_ids" =>
        Aggregates.family_merge_string_lists(
          source_reports,
          "impacted_dependency_activity_ids"
        ),
      "source_report_timeline_publication_impacted_dependency_timeline_ids" =>
        Aggregates.family_merge_string_lists(
          source_reports,
          "impacted_dependency_timeline_ids"
        ),
      "source_report_timeline_publication_impacted_exclusive_with_activity_ids" =>
        Aggregates.family_merge_string_lists(
          source_reports,
          "impacted_exclusive_with_activity_ids"
        ),
      "source_report_timeline_publication_impacted_exclusive_with_timeline_ids" =>
        Aggregates.family_merge_string_lists(
          source_reports,
          "impacted_exclusive_with_timeline_ids"
        ),
      "source_report_timeline_publication_diff_row_count" =>
        Aggregates.family_count(source_reports, "timeline_diff_row_count"),
      "source_report_timeline_publication_diff_changed_count" =>
        Aggregates.family_count(source_reports, "timeline_diff_changed_count"),
      "source_report_timeline_publication_diff_review_required_count" =>
        Aggregates.family_count(source_reports, "timeline_diff_review_required_count"),
      "source_report_timeline_publication_changed_field_counts" =>
        Aggregates.family_merge_count_maps(source_reports, "changed_field_counts"),
      "source_report_timeline_publication_changed_timeline_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "changed_timeline_ids"),
      "source_report_timeline_publication_review_timeline_ids" =>
        Aggregates.family_merge_string_lists(source_reports, "review_timeline_ids"),
      "source_report_timeline_publication_timeline_ids_by_changed_field" =>
        Aggregates.family_merge_string_list_maps(
          source_reports,
          "timeline_ids_by_changed_field"
        )
    }
  end

  def dependency_id_fields(source_reports) do
    merge_publication_ids = fn field ->
      Aggregates.family_merge_string_lists(source_reports, field)
    end

    %{
      "source_report_timeline_publication_impacted_source_activity_ids" =>
        merge_publication_ids.("impacted_source_activity_ids"),
      "source_report_timeline_publication_impacted_source_timeline_ids" =>
        merge_publication_ids.("impacted_source_timeline_ids"),
      "source_report_timeline_publication_dependent_activity_ids" =>
        merge_publication_ids.("dependent_activity_ids"),
      "source_report_timeline_publication_dependent_timeline_ids" =>
        merge_publication_ids.("dependent_timeline_ids"),
      "source_report_timeline_publication_source_dependent_activity_ids" =>
        merge_publication_ids.("source_dependent_activity_ids"),
      "source_report_timeline_publication_source_dependent_timeline_ids" =>
        merge_publication_ids.("source_dependent_timeline_ids"),
      "source_report_timeline_publication_replacement_dependent_activity_ids" =>
        merge_publication_ids.("replacement_dependent_activity_ids"),
      "source_report_timeline_publication_replacement_dependent_timeline_ids" =>
        merge_publication_ids.("replacement_dependent_timeline_ids")
    }
  end
end
