defmodule OrbitalDynamics.RecommendationRiskContext.TimelinePublication do
  @moduledoc false

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_publication_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_publication_pressure" or
            Map.get(&1, "feedback_scope") == "timeline_publication")
      )

    %{
      "timeline_publication_ids" =>
        risk_context_values(timeline_publication_risks, "publication_id"),
      "timeline_publication_sequences" =>
        risk_context_values(timeline_publication_risks, "publication_sequence"),
      "timeline_publication_statuses" =>
        risk_context_values(timeline_publication_risks, "publication_status"),
      "timeline_publication_downstream_invalidation_statuses" =>
        risk_context_values(timeline_publication_risks, "downstream_invalidation_status"),
      "timeline_publication_dependency_impact_statuses" =>
        risk_context_values(timeline_publication_risks, "dependency_impact_status"),
      "timeline_publication_source_artifact_ids" =>
        risk_context_values(timeline_publication_risks, "source_artifact_id"),
      "timeline_publication_source_artifact_types" =>
        risk_context_values(timeline_publication_risks, "source_artifact_type"),
      "timeline_publication_authorities" =>
        risk_context_values(timeline_publication_risks, "publication_authority"),
      "timeline_publication_supersedes_artifact_ids" =>
        risk_context_values(timeline_publication_risks, ["supersedes_artifact_ids"]),
      "timeline_publication_downstream_product_ids" =>
        risk_context_values(timeline_publication_risks, ["downstream_product_ids"]),
      "timeline_publication_invalidated_downstream_product_ids" =>
        risk_context_values(timeline_publication_risks, [
          "invalidated_downstream_product_ids"
        ]),
      "timeline_publication_downstream_invalidation_reason_count_maps" =>
        risk_context_values(
          timeline_publication_risks,
          "downstream_invalidation_reason_counts"
        ),
      "timeline_publication_downstream_invalidation_reasons" =>
        risk_context_values(timeline_publication_risks, [
          "downstream_invalidation_reasons"
        ]),
      "timeline_publication_invalidated_downstream_product_ids_by_reason" =>
        risk_context_values(
          timeline_publication_risks,
          "invalidated_downstream_product_ids_by_reason"
        ),
      "timeline_publication_dependency_impact_row_count_values" =>
        risk_context_values(timeline_publication_risks, "dependency_impact_row_count"),
      "timeline_publication_timeline_diff_row_count_values" =>
        risk_context_values(timeline_publication_risks, "timeline_diff_row_count"),
      "timeline_publication_timeline_diff_changed_count_values" =>
        risk_context_values(timeline_publication_risks, "timeline_diff_changed_count"),
      "timeline_publication_timeline_diff_review_required_count_values" =>
        risk_context_values(
          timeline_publication_risks,
          "timeline_diff_review_required_count"
        ),
      "timeline_publication_changed_field_count_maps" =>
        risk_context_values(timeline_publication_risks, "changed_field_counts"),
      "timeline_publication_changed_fields" =>
        risk_context_values(timeline_publication_risks, ["changed_fields"]),
      "timeline_publication_changed_timeline_ids" =>
        risk_context_values(timeline_publication_risks, ["changed_timeline_ids"]),
      "timeline_publication_review_timeline_ids" =>
        risk_context_values(timeline_publication_risks, ["review_timeline_ids"]),
      "timeline_publication_timeline_ids_by_changed_field" =>
        risk_context_values(timeline_publication_risks, "timeline_ids_by_changed_field"),
      "timeline_publication_feedback_sources" =>
        risk_context_values(timeline_publication_risks, "feedback_source"),
      "timeline_publication_feedback_scopes" =>
        risk_context_values(timeline_publication_risks, "feedback_scope"),
      "timeline_publication_feedback_keys" =>
        risk_context_values(timeline_publication_risks, "feedback_key"),
      "timeline_publication_trust_boundaries" =>
        risk_context_values(timeline_publication_risks, "trust_boundary"),
      "timeline_publication_derivation_reasons" =>
        risk_context_values(timeline_publication_risks, ["derivation_reasons"]),
      "timeline_publication_assumption_maps" =>
        risk_context_values(timeline_publication_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
