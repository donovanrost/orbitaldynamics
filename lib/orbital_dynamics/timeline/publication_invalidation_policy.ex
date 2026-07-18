defmodule OrbitalDynamics.Timeline.PublicationInvalidationPolicy do
  @moduledoc false

  def publication_invalidation_ids(
        [],
        downstream_product_ids,
        dependency_impact_summary,
        supersedes
      ) do
    cond do
      publication_dependency_impact_review_required?(dependency_impact_summary) ->
        downstream_product_ids

      supersedes != [] ->
        downstream_product_ids

      true ->
        []
    end
  end

  def publication_invalidation_ids(
        invalidated,
        downstream_product_ids,
        _summary,
        _supersedes
      ) do
    unknown_ids = invalidated -- downstream_product_ids

    if unknown_ids == [] do
      invalidated
    else
      raise ArgumentError,
            "invalidated_downstream_product_ids must be included in downstream_product_ids"
    end
  end

  def publication_invalidation_reason([], _dependency_impact_summary, _supersedes), do: nil

  def publication_invalidation_reason(invalidated, dependency_impact_summary, supersedes)
      when invalidated != [] do
    cond do
      publication_dependency_impact_review_required?(dependency_impact_summary) ->
        "dependency_impact_review_required"

      supersedes != [] ->
        "superseded_publication"

      true ->
        "explicit_downstream_invalidation"
    end
  end

  def publication_invalidation_ids_by_reason(_invalidated, nil), do: %{}

  def publication_invalidation_ids_by_reason(invalidated, reason) do
    %{reason => invalidated}
  end

  def publication_invalidation_reason_counts(ids_by_reason) do
    ids_by_reason
    |> Enum.map(fn {reason, ids} -> {reason, length(ids)} end)
    |> Map.new()
  end

  defp publication_dependency_impact_review_required?(%{
         "dependency_impact_status" => "review_required"
       }),
       do: true

  defp publication_dependency_impact_review_required?(_summary), do: false

  def publication_status(invalidated_downstream_product_ids, dependency_impact_summary) do
    cond do
      invalidated_downstream_product_ids != [] ->
        "published_with_downstream_invalidations"

      publication_dependency_impact_review_required?(dependency_impact_summary) ->
        "review_required"

      true ->
        "published"
    end
  end

  def publication_downstream_invalidation_status([]), do: "clear"

  def publication_downstream_invalidation_status(_invalidated_downstream_product_ids),
    do: "invalidated"

  def publication_summary_id(source_artifact_id, publication_sequence, supersedes_artifact_ids) do
    supersedes =
      case supersedes_artifact_ids do
        [] -> "initial"
        ids -> Enum.join(ids, "_")
      end

    "timeline_publication:#{publication_sequence}:#{source_artifact_id}:#{supersedes}"
  end
end
