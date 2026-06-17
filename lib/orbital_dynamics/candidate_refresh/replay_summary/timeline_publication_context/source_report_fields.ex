defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Aggregates

  def source_report_fields(source_reports, family, prefix) do
    %{
      "#{prefix}_publication_status_counts" =>
        Aggregates.merge_count_maps(source_reports, family, "publication_status_counts"),
      "#{prefix}_dependency_impact_status_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          family,
          "dependency_impact_status_counts"
        ),
      "#{prefix}_publication_authority_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          family,
          "publication_authority_counts"
        ),
      "#{prefix}_timeline_publication_source_artifact_type_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          family,
          "timeline_publication_source_artifact_type_counts"
        ),
      "#{prefix}_publication_ids" =>
        Aggregates.merge_string_lists(source_reports, family, "publication_ids"),
      "#{prefix}_source_artifact_ids" =>
        Aggregates.merge_string_lists(source_reports, family, "source_artifact_ids"),
      "#{prefix}_supersedes_artifact_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "supersedes_artifact_ids"
        ),
      "#{prefix}_downstream_product_ids" =>
        Aggregates.merge_string_lists(source_reports, family, "downstream_product_ids"),
      "#{prefix}_invalidated_downstream_product_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "invalidated_downstream_product_ids"
        ),
      "#{prefix}_downstream_invalidation_reason_counts" =>
        Aggregates.merge_count_maps(
          source_reports,
          family,
          "downstream_invalidation_reason_counts"
        ),
      "#{prefix}_invalidated_downstream_product_ids_by_reason" =>
        Aggregates.merge_string_list_maps(
          source_reports,
          family,
          "invalidated_downstream_product_ids_by_reason"
        ),
      "#{prefix}_dependency_impact_row_count" =>
        Aggregates.count(source_reports, family, "dependency_impact_row_count"),
      "#{prefix}_impacted_dependency_activity_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "impacted_dependency_activity_ids"
        ),
      "#{prefix}_impacted_dependency_timeline_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "impacted_dependency_timeline_ids"
        ),
      "#{prefix}_impacted_exclusive_with_activity_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "impacted_exclusive_with_activity_ids"
        ),
      "#{prefix}_impacted_exclusive_with_timeline_ids" =>
        Aggregates.merge_string_lists(
          source_reports,
          family,
          "impacted_exclusive_with_timeline_ids"
        ),
      "#{prefix}_timeline_diff_row_count" =>
        Aggregates.count(source_reports, family, "timeline_diff_row_count"),
      "#{prefix}_timeline_diff_changed_count" =>
        Aggregates.count(source_reports, family, "timeline_diff_changed_count"),
      "#{prefix}_timeline_diff_review_required_count" =>
        Aggregates.count(
          source_reports,
          family,
          "timeline_diff_review_required_count"
        ),
      "#{prefix}_changed_field_counts" =>
        Aggregates.merge_count_maps(source_reports, family, "changed_field_counts"),
      "#{prefix}_changed_timeline_ids" =>
        Aggregates.merge_string_lists(source_reports, family, "changed_timeline_ids"),
      "#{prefix}_review_timeline_ids" =>
        Aggregates.merge_string_lists(source_reports, family, "review_timeline_ids"),
      "#{prefix}_timeline_ids_by_changed_field" =>
        Aggregates.merge_string_list_maps(
          source_reports,
          family,
          "timeline_ids_by_changed_field"
        )
    }
  end
end
