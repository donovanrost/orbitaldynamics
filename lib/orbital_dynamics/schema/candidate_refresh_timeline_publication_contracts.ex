defmodule OrbitalDynamics.Schema.CandidateRefreshTimelinePublicationContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_id_array_map: 3]

  def validate(issues, path, summary) do
    issues =
      Enum.reduce(
        [
          "publication_status_counts",
          "downstream_invalidation_status_counts",
          "dependency_impact_status_counts",
          "publication_authority_counts",
          "source_artifact_type_counts",
          "timeline_publication_source_artifact_type_counts",
          "changed_field_counts"
        ],
        issues,
        fn field, acc ->
          validate_non_negative_integer_count_map(
            acc,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    issues =
      Enum.reduce(
        [
          "dependency_impact_row_count",
          "timeline_diff_row_count",
          "timeline_diff_changed_count",
          "timeline_diff_review_required_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "publication_ids",
          "source_artifact_ids",
          "supersedes_artifact_ids",
          "downstream_product_ids",
          "invalidated_downstream_product_ids",
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
          "changed_timeline_ids",
          "review_timeline_ids"
        ],
        issues,
        fn field, acc ->
          validate_optional_stable_id_list(acc, path, summary, field)
        end
      )

    [
      "timeline_ids_by_changed_field",
      "invalidated_downstream_product_ids_by_reason"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      validate_stable_id_array_map(acc, path <> ".#{field}", Map.get(summary, field))
    end)
  end
end
