defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext.Fields.Pressure do
  @moduledoc false

  def fields(fields) do
    dependency_pressure = dependency_pressure?(fields)
    changed_field_pressure = changed_field_pressure?(fields)
    invalidation_pressure = invalidation_pressure?(fields)
    review_pressure = review_pressure?(fields, dependency_pressure)

    publication_pressure =
      publication_pressure?(fields) or dependency_pressure or changed_field_pressure or
        invalidation_pressure or review_pressure

    %{
      "branch_local_timeline_publication_pressure" => publication_pressure,
      "branch_local_timeline_publication_dependency_pressure" => dependency_pressure,
      "branch_local_timeline_publication_changed_field_pressure" => changed_field_pressure,
      "branch_local_timeline_publication_invalidation_pressure" => invalidation_pressure,
      "branch_local_timeline_publication_review_pressure" => review_pressure
    }
  end

  defp dependency_pressure?(fields) do
    dependency_impact_status_counts = Map.get(fields, "dependency_impact_status_counts", %{})

    Map.get(fields, "dependency_impact_row_count", 0) > 0 or
      Map.get(fields, "impacted_source_activity_ids", []) != [] or
      Map.get(fields, "impacted_source_timeline_ids", []) != [] or
      Map.get(fields, "dependent_activity_ids", []) != [] or
      Map.get(fields, "dependent_timeline_ids", []) != [] or
      Map.get(fields, "source_dependent_activity_ids", []) != [] or
      Map.get(fields, "source_dependent_timeline_ids", []) != [] or
      Map.get(fields, "replacement_dependent_activity_ids", []) != [] or
      Map.get(fields, "replacement_dependent_timeline_ids", []) != [] or
      Map.get(fields, "impacted_dependency_activity_ids", []) != [] or
      Map.get(fields, "impacted_dependency_timeline_ids", []) != [] or
      Map.get(fields, "impacted_exclusive_with_activity_ids", []) != [] or
      Map.get(fields, "impacted_exclusive_with_timeline_ids", []) != [] or
      summary_integer(dependency_impact_status_counts, "review_required") > 0
  end

  defp changed_field_pressure?(fields) do
    Map.get(fields, "timeline_diff_row_count", 0) +
      Map.get(fields, "timeline_diff_changed_count", 0) > 0 or
      map_size(Map.get(fields, "changed_field_counts", %{})) > 0 or
      Map.get(fields, "changed_timeline_ids", []) != [] or
      map_size(Map.get(fields, "timeline_ids_by_changed_field", %{})) > 0
  end

  defp invalidation_pressure?(fields) do
    publication_status_counts = Map.get(fields, "publication_status_counts", %{})

    Map.get(fields, "invalidated_downstream_product_ids", []) != [] or
      summary_integer(publication_status_counts, "published_with_downstream_invalidations") > 0
  end

  defp review_pressure?(fields, dependency_pressure) do
    publication_status_counts = Map.get(fields, "publication_status_counts", %{})

    Map.get(fields, "timeline_diff_review_required_count", 0) > 0 or
      Map.get(fields, "review_timeline_ids", []) != [] or
      summary_integer(publication_status_counts, "review_required") > 0 or dependency_pressure
  end

  defp publication_pressure?(fields) do
    map_size(Map.get(fields, "publication_status_counts", %{})) > 0 or
      map_size(Map.get(fields, "publication_authority_counts", %{})) > 0 or
      map_size(Map.get(fields, "timeline_publication_source_artifact_type_counts", %{})) > 0 or
      Map.get(fields, "publication_ids", []) != [] or
      Map.get(fields, "source_artifact_ids", []) != [] or
      Map.get(fields, "supersedes_artifact_ids", []) != [] or
      Map.get(fields, "downstream_product_ids", []) != []
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
