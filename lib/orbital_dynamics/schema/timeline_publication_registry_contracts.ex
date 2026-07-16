defmodule OrbitalDynamics.Schema.TimelinePublicationRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "timeline_publication_summary.v1" => %{
        "schema_contract" => "timeline_publication_summary.v1",
        "artifact_family" => "timeline_publication_summary",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "validation_level",
          "source",
          "publication_id",
          "publication_sequence",
          "publication_status",
          "publication_authority",
          "source_artifact_id",
          "source_artifact_type",
          "supersedes_artifact_ids",
          "downstream_product_ids",
          "invalidated_downstream_product_ids",
          "dependency_impact_status",
          "dependency_impact_row_count",
          "assumptions",
          "model_limits"
        ],
        "optional_fields" => [
          "source_timeline_dependency_impact_summary",
          "impacted_source_activity_ids",
          "impacted_source_timeline_ids",
          "dependent_activity_ids",
          "dependent_timeline_ids",
          "source_dependent_activity_ids",
          "source_dependent_timeline_ids",
          "replacement_dependent_activity_ids",
          "replacement_dependent_timeline_ids",
          "impacted_dependency_activity_ids",
          "impacted_dependency_timeline_ids",
          "impacted_exclusive_with_activity_ids",
          "impacted_exclusive_with_timeline_ids",
          "source_timeline_diff_summary",
          "downstream_invalidation_status",
          "downstream_invalidation_reason_counts",
          "invalidated_downstream_product_ids_by_reason",
          "timeline_diff_row_count",
          "timeline_diff_changed_count",
          "timeline_diff_review_required_count",
          "changed_field_counts",
          "changed_timeline_ids",
          "review_timeline_ids",
          "timeline_ids_by_changed_field"
        ],
        "nested_contracts" => [
          "timeline_dependency_impact_summary.v1",
          "timeline_diff_summary.v1"
        ]
      }
    }
  end
end
