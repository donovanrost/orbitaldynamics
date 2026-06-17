defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext.Fields do
  @moduledoc false

  alias __MODULE__.Pressure

  def fields(summary, allow_source_artifact_type_fallback?) do
    publication_status_counts = Map.get(summary, "publication_status_counts", %{})

    dependency_impact_status_counts =
      Map.get(summary, "dependency_impact_status_counts", %{})

    publication_authority_counts =
      Map.get(summary, "publication_authority_counts", %{})

    source_artifact_type_counts =
      timeline_publication_source_artifact_type_counts(
        summary,
        allow_source_artifact_type_fallback?
      )

    publication_ids = Map.get(summary, "publication_ids", [])
    source_artifact_ids = Map.get(summary, "source_artifact_ids", [])
    supersedes_artifact_ids = Map.get(summary, "supersedes_artifact_ids", [])
    downstream_product_ids = Map.get(summary, "downstream_product_ids", [])

    invalidated_downstream_product_ids =
      Map.get(summary, "invalidated_downstream_product_ids", [])

    dependency_impact_row_count = summary_integer(summary, "dependency_impact_row_count")

    impacted_source_activity_ids = Map.get(summary, "impacted_source_activity_ids", [])
    impacted_source_timeline_ids = Map.get(summary, "impacted_source_timeline_ids", [])
    dependent_activity_ids = Map.get(summary, "dependent_activity_ids", [])
    dependent_timeline_ids = Map.get(summary, "dependent_timeline_ids", [])
    source_dependent_activity_ids = Map.get(summary, "source_dependent_activity_ids", [])
    source_dependent_timeline_ids = Map.get(summary, "source_dependent_timeline_ids", [])

    replacement_dependent_activity_ids =
      Map.get(summary, "replacement_dependent_activity_ids", [])

    replacement_dependent_timeline_ids =
      Map.get(summary, "replacement_dependent_timeline_ids", [])

    impacted_dependency_activity_ids =
      Map.get(summary, "impacted_dependency_activity_ids", [])

    impacted_dependency_timeline_ids =
      Map.get(summary, "impacted_dependency_timeline_ids", [])

    impacted_exclusive_with_activity_ids =
      Map.get(summary, "impacted_exclusive_with_activity_ids", [])

    impacted_exclusive_with_timeline_ids =
      Map.get(summary, "impacted_exclusive_with_timeline_ids", [])

    timeline_diff_row_count = summary_integer(summary, "timeline_diff_row_count")
    timeline_diff_changed_count = summary_integer(summary, "timeline_diff_changed_count")

    timeline_diff_review_required_count =
      summary_integer(summary, "timeline_diff_review_required_count")

    changed_field_counts = Map.get(summary, "changed_field_counts", %{})
    changed_timeline_ids = Map.get(summary, "changed_timeline_ids", [])
    review_timeline_ids = Map.get(summary, "review_timeline_ids", [])

    timeline_ids_by_changed_field =
      Map.get(summary, "timeline_ids_by_changed_field", %{})

    fields = %{
      "publication_status_counts" => publication_status_counts,
      "dependency_impact_status_counts" => dependency_impact_status_counts,
      "publication_authority_counts" => publication_authority_counts,
      "timeline_publication_source_artifact_type_counts" => source_artifact_type_counts,
      "publication_ids" => publication_ids,
      "source_artifact_ids" => source_artifact_ids,
      "supersedes_artifact_ids" => supersedes_artifact_ids,
      "downstream_product_ids" => downstream_product_ids,
      "invalidated_downstream_product_ids" => invalidated_downstream_product_ids,
      "dependency_impact_row_count" => dependency_impact_row_count,
      "impacted_source_activity_ids" => impacted_source_activity_ids,
      "impacted_source_timeline_ids" => impacted_source_timeline_ids,
      "dependent_activity_ids" => dependent_activity_ids,
      "dependent_timeline_ids" => dependent_timeline_ids,
      "source_dependent_activity_ids" => source_dependent_activity_ids,
      "source_dependent_timeline_ids" => source_dependent_timeline_ids,
      "replacement_dependent_activity_ids" => replacement_dependent_activity_ids,
      "replacement_dependent_timeline_ids" => replacement_dependent_timeline_ids,
      "impacted_dependency_activity_ids" => impacted_dependency_activity_ids,
      "impacted_dependency_timeline_ids" => impacted_dependency_timeline_ids,
      "impacted_exclusive_with_activity_ids" => impacted_exclusive_with_activity_ids,
      "impacted_exclusive_with_timeline_ids" => impacted_exclusive_with_timeline_ids,
      "timeline_diff_row_count" => timeline_diff_row_count,
      "timeline_diff_changed_count" => timeline_diff_changed_count,
      "timeline_diff_review_required_count" => timeline_diff_review_required_count,
      "changed_field_counts" => changed_field_counts,
      "changed_timeline_ids" => changed_timeline_ids,
      "review_timeline_ids" => review_timeline_ids,
      "timeline_ids_by_changed_field" => timeline_ids_by_changed_field
    }

    Map.merge(fields, Pressure.fields(fields))
  end

  defp timeline_publication_source_artifact_type_counts(
         summary,
         true = _allow_source_artifact_type_fallback?
       ) do
    Map.get(
      summary,
      "timeline_publication_source_artifact_type_counts",
      Map.get(summary, "source_artifact_type_counts", %{})
    )
  end

  defp timeline_publication_source_artifact_type_counts(
         summary,
         false = _allow_source_artifact_type_fallback?
       ) do
    Map.get(summary, "timeline_publication_source_artifact_type_counts", %{})
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
end
