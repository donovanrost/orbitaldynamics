defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublication.Summary.PublicationFields do
  @moduledoc false

  def fields(publication_summary) do
    %{
      "publication_status_counts" =>
        Map.get(publication_summary, "publication_status_counts", %{}),
      "downstream_invalidation_status_counts" =>
        Map.get(publication_summary, "downstream_invalidation_status_counts", %{}),
      "dependency_impact_status_counts" =>
        Map.get(publication_summary, "dependency_impact_status_counts", %{}),
      "publication_authority_counts" =>
        Map.get(publication_summary, "publication_authority_counts", %{}),
      "source_artifact_type_counts" =>
        Map.get(publication_summary, "source_artifact_type_counts", %{}),
      "publication_ids" => Map.get(publication_summary, "publication_ids", []),
      "source_artifact_ids" => Map.get(publication_summary, "source_artifact_ids", []),
      "supersedes_artifact_ids" => Map.get(publication_summary, "supersedes_artifact_ids", []),
      "downstream_product_ids" => Map.get(publication_summary, "downstream_product_ids", []),
      "invalidated_downstream_product_ids" =>
        Map.get(publication_summary, "invalidated_downstream_product_ids", []),
      "downstream_invalidation_reason_counts" =>
        publication_summary
        |> Map.get("downstream_invalidation_reason_counts")
        |> map_value(),
      "invalidated_downstream_product_ids_by_reason" =>
        publication_summary
        |> Map.get("invalidated_downstream_product_ids_by_reason")
        |> map_value(),
      "impacted_source_activity_ids" =>
        Map.get(publication_summary, "impacted_source_activity_ids", []),
      "impacted_source_timeline_ids" =>
        Map.get(publication_summary, "impacted_source_timeline_ids", []),
      "dependent_activity_ids" => Map.get(publication_summary, "dependent_activity_ids", []),
      "dependent_timeline_ids" => Map.get(publication_summary, "dependent_timeline_ids", []),
      "source_dependent_activity_ids" =>
        Map.get(publication_summary, "source_dependent_activity_ids", []),
      "source_dependent_timeline_ids" =>
        Map.get(publication_summary, "source_dependent_timeline_ids", []),
      "replacement_dependent_activity_ids" =>
        Map.get(publication_summary, "replacement_dependent_activity_ids", []),
      "replacement_dependent_timeline_ids" =>
        Map.get(publication_summary, "replacement_dependent_timeline_ids", []),
      "impacted_dependency_activity_ids" =>
        Map.get(publication_summary, "impacted_dependency_activity_ids", []),
      "impacted_dependency_timeline_ids" =>
        Map.get(publication_summary, "impacted_dependency_timeline_ids", []),
      "impacted_exclusive_with_activity_ids" =>
        Map.get(publication_summary, "impacted_exclusive_with_activity_ids", []),
      "impacted_exclusive_with_timeline_ids" =>
        Map.get(publication_summary, "impacted_exclusive_with_timeline_ids", []),
      "changed_field_counts" => Map.get(publication_summary, "changed_field_counts", %{}),
      "changed_timeline_ids" => Map.get(publication_summary, "changed_timeline_ids", []),
      "review_timeline_ids" => Map.get(publication_summary, "review_timeline_ids", []),
      "timeline_ids_by_changed_field" =>
        Map.get(publication_summary, "timeline_ids_by_changed_field", %{})
    }
  end

  defp map_value(%{} = value), do: value
  defp map_value(_value), do: %{}
end
