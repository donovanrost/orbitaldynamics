defmodule OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition do
  @moduledoc false

  @fields [
    {"timeline_activity_precondition_activity_ids", "activity_id"},
    {"timeline_activity_precondition_timeline_ids", "timeline_id"},
    {"timeline_activity_precondition_activity_types", "activity_type"},
    {"timeline_activity_precondition_statuses", "precondition_status"},
    {"timeline_activity_precondition_blocked_count_values", "blocked_precondition_count"},
    {"timeline_activity_precondition_review_count_values", "review_precondition_count"},
    {"timeline_activity_precondition_blocked_types", ["blocked_precondition_types"]},
    {"timeline_activity_precondition_review_types", ["review_precondition_types"]},
    {"timeline_activity_precondition_dependency_activity_ids", ["dependency_activity_ids"]},
    {"timeline_activity_precondition_dependency_timeline_ids", ["dependency_timeline_ids"]},
    {"timeline_activity_precondition_exclusive_with_activity_ids",
     ["exclusive_with_activity_ids"]},
    {"timeline_activity_precondition_exclusive_with_timeline_ids",
     ["exclusive_with_timeline_ids"]},
    {"timeline_activity_precondition_duplicate_dependency_activity_ids",
     ["duplicate_dependency_activity_ids"]},
    {"timeline_activity_precondition_duplicate_dependency_timeline_ids",
     ["duplicate_dependency_timeline_ids"]},
    {"timeline_activity_precondition_duplicate_exclusivity_activity_ids",
     ["duplicate_exclusivity_activity_ids"]},
    {"timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
     ["duplicate_exclusivity_timeline_ids"]},
    {"timeline_activity_precondition_allow_overlap_values", "allow_overlap"},
    {"timeline_activity_precondition_invalid_activity_input_values", "invalid_activity_input"},
    {"timeline_activity_precondition_invalid_activity_input_reasons",
     "invalid_activity_input_reason"},
    {"timeline_activity_precondition_required_operator_actions", "required_operator_action"},
    {"timeline_activity_precondition_requires_operator_review_values",
     "requires_operator_review"},
    {"timeline_activity_precondition_feedback_sources", "feedback_source"},
    {"timeline_activity_precondition_feedback_scopes", "feedback_scope"},
    {"timeline_activity_precondition_feedback_keys", "feedback_key"},
    {"timeline_activity_precondition_trust_boundaries", "trust_boundary"},
    {"timeline_activity_precondition_derivation_reasons", ["derivation_reasons"]},
    {"timeline_activity_precondition_assumption_maps", "assumptions"}
  ]

  def field_pairs, do: @fields
  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_precondition_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_precondition_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_precondition")
      )

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(timeline_activity_precondition_risks, risk_keys)}
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
