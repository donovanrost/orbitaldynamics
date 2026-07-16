defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryImpactFields do
  @moduledoc false

  def fields(%{} = summary) do
    %{
      "publication_status_counts" => summary["publication_status_counts"],
      "dependency_impact_status_counts" => summary["dependency_impact_status_counts"],
      "publication_authority_counts" => summary["publication_authority_counts"],
      "source_artifact_type_counts" => summary["source_artifact_type_counts"],
      "publication_ids" => summary["publication_ids"],
      "source_artifact_ids" => summary["source_artifact_ids"],
      "supersedes_artifact_ids" => summary["supersedes_artifact_ids"],
      "downstream_product_ids" => summary["downstream_product_ids"],
      "invalidated_downstream_product_ids" => summary["invalidated_downstream_product_ids"],
      "dependency_impact_row_count" => summary["dependency_impact_row_count"],
      "impacted_dependency_activity_ids" => summary["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => summary["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" => summary["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" => summary["impacted_exclusive_with_timeline_ids"],
      "timeline_diff_row_count" => summary["timeline_diff_row_count"],
      "timeline_diff_changed_count" => summary["timeline_diff_changed_count"],
      "timeline_diff_review_required_count" => summary["timeline_diff_review_required_count"],
      "changed_field_counts" => summary["changed_field_counts"],
      "changed_timeline_ids" => summary["changed_timeline_ids"],
      "review_timeline_ids" => summary["review_timeline_ids"],
      "timeline_ids_by_changed_field" => summary["timeline_ids_by_changed_field"]
    }
  end
end
