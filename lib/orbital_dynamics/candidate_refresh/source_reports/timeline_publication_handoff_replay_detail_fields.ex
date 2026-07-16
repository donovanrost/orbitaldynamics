defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffReplayDetailFields do
  @moduledoc false

  def from_source_row(%{} = source_row) do
    %{
      "invalidated_downstream_product_ids" => source_row["invalidated_downstream_product_ids"],
      "downstream_invalidation_reason_counts" =>
        source_row["downstream_invalidation_reason_counts"],
      "invalidated_downstream_product_ids_by_reason" =>
        source_row["invalidated_downstream_product_ids_by_reason"],
      "dependency_impact_row_count" => source_row["dependency_impact_row_count"],
      "impacted_source_activity_ids" => source_row["impacted_source_activity_ids"],
      "impacted_source_timeline_ids" => source_row["impacted_source_timeline_ids"],
      "dependent_activity_ids" => source_row["dependent_activity_ids"],
      "dependent_timeline_ids" => source_row["dependent_timeline_ids"],
      "source_dependent_activity_ids" => source_row["source_dependent_activity_ids"],
      "source_dependent_timeline_ids" => source_row["source_dependent_timeline_ids"],
      "replacement_dependent_activity_ids" => source_row["replacement_dependent_activity_ids"],
      "replacement_dependent_timeline_ids" => source_row["replacement_dependent_timeline_ids"],
      "impacted_dependency_activity_ids" => source_row["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => source_row["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" =>
        source_row["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" =>
        source_row["impacted_exclusive_with_timeline_ids"],
      "timeline_diff_row_count" => source_row["timeline_diff_row_count"],
      "timeline_diff_changed_count" => source_row["timeline_diff_changed_count"],
      "timeline_diff_review_required_count" => source_row["timeline_diff_review_required_count"],
      "changed_field_counts" => source_row["changed_field_counts"],
      "changed_timeline_ids" => source_row["changed_timeline_ids"],
      "review_timeline_ids" => source_row["review_timeline_ids"],
      "timeline_ids_by_changed_field" => source_row["timeline_ids_by_changed_field"]
    }
  end
end
