defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.Summary.Pressure do
  @moduledoc false

  def fields(
        publication_fields,
        row_count,
        dependency_impact_row_count,
        timeline_diff_row_count,
        timeline_diff_changed_count,
        timeline_diff_review_required_count
      ) do
    publication_status_counts = Map.get(publication_fields, "publication_status_counts", %{})

    downstream_invalidation_status_counts =
      Map.get(publication_fields, "downstream_invalidation_status_counts", %{})

    dependency_impact_status_counts =
      Map.get(publication_fields, "dependency_impact_status_counts", %{})

    publication_authority_counts =
      Map.get(publication_fields, "publication_authority_counts", %{})

    source_artifact_type_counts =
      Map.get(publication_fields, "source_artifact_type_counts", %{})

    publication_ids = Map.get(publication_fields, "publication_ids", [])
    source_artifact_ids = Map.get(publication_fields, "source_artifact_ids", [])
    supersedes_artifact_ids = Map.get(publication_fields, "supersedes_artifact_ids", [])
    downstream_product_ids = Map.get(publication_fields, "downstream_product_ids", [])

    invalidated_downstream_product_ids =
      Map.get(publication_fields, "invalidated_downstream_product_ids", [])

    downstream_invalidation_reason_counts =
      Map.get(publication_fields, "downstream_invalidation_reason_counts", %{})

    invalidated_downstream_product_ids_by_reason =
      Map.get(publication_fields, "invalidated_downstream_product_ids_by_reason", %{})

    impacted_source_activity_ids =
      Map.get(publication_fields, "impacted_source_activity_ids", [])

    impacted_source_timeline_ids =
      Map.get(publication_fields, "impacted_source_timeline_ids", [])

    dependent_activity_ids = Map.get(publication_fields, "dependent_activity_ids", [])
    dependent_timeline_ids = Map.get(publication_fields, "dependent_timeline_ids", [])

    source_dependent_activity_ids =
      Map.get(publication_fields, "source_dependent_activity_ids", [])

    source_dependent_timeline_ids =
      Map.get(publication_fields, "source_dependent_timeline_ids", [])

    replacement_dependent_activity_ids =
      Map.get(publication_fields, "replacement_dependent_activity_ids", [])

    replacement_dependent_timeline_ids =
      Map.get(publication_fields, "replacement_dependent_timeline_ids", [])

    impacted_dependency_activity_ids =
      Map.get(publication_fields, "impacted_dependency_activity_ids", [])

    impacted_dependency_timeline_ids =
      Map.get(publication_fields, "impacted_dependency_timeline_ids", [])

    impacted_exclusive_with_activity_ids =
      Map.get(publication_fields, "impacted_exclusive_with_activity_ids", [])

    impacted_exclusive_with_timeline_ids =
      Map.get(publication_fields, "impacted_exclusive_with_timeline_ids", [])

    changed_field_counts = Map.get(publication_fields, "changed_field_counts", %{})
    changed_timeline_ids = Map.get(publication_fields, "changed_timeline_ids", [])
    review_timeline_ids = Map.get(publication_fields, "review_timeline_ids", [])

    timeline_ids_by_changed_field =
      Map.get(publication_fields, "timeline_ids_by_changed_field", %{})

    dependency_pressure =
      dependency_impact_row_count > 0 or impacted_source_activity_ids != [] or
        impacted_source_timeline_ids != [] or dependent_activity_ids != [] or
        dependent_timeline_ids != [] or source_dependent_activity_ids != [] or
        source_dependent_timeline_ids != [] or replacement_dependent_activity_ids != [] or
        replacement_dependent_timeline_ids != [] or impacted_dependency_activity_ids != [] or
        impacted_dependency_timeline_ids != [] or impacted_exclusive_with_activity_ids != [] or
        impacted_exclusive_with_timeline_ids != [] or
        summary_integer(dependency_impact_status_counts, "review_required") > 0

    changed_field_pressure =
      timeline_diff_row_count + timeline_diff_changed_count > 0 or
        map_size(changed_field_counts) > 0 or changed_timeline_ids != [] or
        map_size(timeline_ids_by_changed_field) > 0

    invalidation_pressure =
      invalidated_downstream_product_ids != [] or
        map_size(downstream_invalidation_reason_counts) > 0 or
        map_size(invalidated_downstream_product_ids_by_reason) > 0 or
        summary_integer(downstream_invalidation_status_counts, "invalidated") > 0 or
        summary_integer(publication_status_counts, "published_with_downstream_invalidations") > 0

    review_pressure =
      timeline_diff_review_required_count > 0 or review_timeline_ids != [] or
        summary_integer(publication_status_counts, "review_required") > 0 or dependency_pressure

    publication_pressure =
      row_count > 0 or map_size(publication_status_counts) > 0 or
        map_size(publication_authority_counts) > 0 or map_size(source_artifact_type_counts) > 0 or
        publication_ids != [] or source_artifact_ids != [] or supersedes_artifact_ids != [] or
        downstream_product_ids != []

    %{
      "branch_local_timeline_publication_pressure" =>
        publication_pressure or dependency_pressure or changed_field_pressure or
          invalidation_pressure or review_pressure,
      "branch_local_timeline_publication_dependency_pressure" => dependency_pressure,
      "branch_local_timeline_publication_changed_field_pressure" => changed_field_pressure,
      "branch_local_timeline_publication_invalidation_pressure" => invalidation_pressure,
      "branch_local_timeline_publication_review_pressure" => review_pressure
    }
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0
end
