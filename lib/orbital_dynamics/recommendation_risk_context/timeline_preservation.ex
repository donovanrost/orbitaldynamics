defmodule OrbitalDynamics.RecommendationRiskContext.TimelinePreservation do
  @moduledoc false

  @fields [
    {"timeline_preservation_activity_ids", "activity_id"},
    {"timeline_preservation_timeline_ids", "timeline_id"},
    {"timeline_preservation_statuses", "timeline_preservation_status"},
    {"timeline_preservation_requires_preservation_values", "requires_preservation"},
    {"timeline_preservation_requires_operator_review_values", "requires_operator_review"},
    {"timeline_preservation_protection_decisions", "protection_decision"},
    {"timeline_preservation_protection_categories", "protection_category"},
    {"timeline_preservation_protection_reasons", "protection_reason"},
    {"timeline_preservation_preserve_activity_count_values", "preserve_activity_count"},
    {"timeline_preservation_review_change_activity_count_values", "review_change_activity_count"},
    {"timeline_preservation_sensitive_activity_count_values",
     "preservation_sensitive_activity_count"},
    {"timeline_preservation_preserve_activity_ids", ["preserve_activity_ids"]},
    {"timeline_preservation_preserve_timeline_ids", ["preserve_timeline_ids"]},
    {"timeline_preservation_review_change_activity_ids", ["review_change_activity_ids"]},
    {"timeline_preservation_review_change_timeline_ids", ["review_change_timeline_ids"]},
    {"timeline_preservation_sensitive_activity_ids", ["preservation_sensitive_activity_ids"]},
    {"timeline_preservation_sensitive_timeline_ids", ["preservation_sensitive_timeline_ids"]},
    {"timeline_preservation_invalid_activity_input_values", "invalid_activity_input"},
    {"timeline_preservation_invalid_activity_input_reasons", "invalid_activity_input_reason"},
    {"timeline_preservation_required_operator_actions", "required_operator_action"},
    {"timeline_preservation_feedback_sources", "feedback_source"},
    {"timeline_preservation_feedback_scopes", "feedback_scope"},
    {"timeline_preservation_feedback_keys", "feedback_key"},
    {"timeline_preservation_trust_boundaries", "trust_boundary"},
    {"timeline_preservation_derivation_reasons", ["derivation_reasons"]},
    {"timeline_preservation_assumption_maps", "assumptions"}
  ]

  def field_pairs, do: @fields
  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    preservation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_preservation_review" or
            Map.get(&1, "feedback_scope") == "timeline_preservation")
      )

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(preservation_risks, risk_keys)}
    end)
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
