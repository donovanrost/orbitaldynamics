defmodule OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState do
  @moduledoc false

  @fields [
    {"timeline_activity_lifecycle_state_activity_ids", "activity_id"},
    {"timeline_activity_lifecycle_state_timeline_ids", "timeline_id"},
    {"timeline_activity_lifecycle_state_planned_activity_ids", "planned_activity_id"},
    {"timeline_activity_lifecycle_state_realized_activity_ids", "realized_activity_id"},
    {"timeline_activity_lifecycle_state_planned_timeline_ids", "planned_timeline_id"},
    {"timeline_activity_lifecycle_state_realized_timeline_ids", "realized_timeline_id"},
    {"timeline_activity_lifecycle_state_transition_decisions", "transition_decision"},
    {"timeline_activity_lifecycle_state_status_transition_decisions",
     "status_transition_decision"},
    {"timeline_activity_lifecycle_state_approval_transition_decisions",
     "approval_transition_decision"},
    {"timeline_activity_lifecycle_state_review_required_values", "review_required"},
    {"timeline_activity_lifecycle_state_requires_operator_review_values",
     "requires_operator_review"},
    {"timeline_activity_lifecycle_state_required_operator_actions",
     ["required_operator_action", "required_operator_actions"]},
    {"timeline_activity_lifecycle_state_operator_action_reasons", ["operator_action_reasons"]},
    {"timeline_activity_lifecycle_state_import_actions", "import_action"},
    {"timeline_activity_lifecycle_state_invalid_activity_input_values", "invalid_activity_input"},
    {"timeline_activity_lifecycle_state_invalid_activity_input_count_values",
     "invalid_activity_input_count"},
    {"timeline_activity_lifecycle_state_invalid_activity_input_reasons",
     ["invalid_activity_input_reasons"]},
    {"timeline_activity_lifecycle_state_planned_statuses", "planned_status"},
    {"timeline_activity_lifecycle_state_realized_statuses", "realized_status"},
    {"timeline_activity_lifecycle_state_planned_status_categories", "planned_status_category"},
    {"timeline_activity_lifecycle_state_realized_status_categories", "realized_status_category"},
    {"timeline_activity_lifecycle_state_planned_approval_statuses", "planned_approval_status"},
    {"timeline_activity_lifecycle_state_realized_approval_statuses", "realized_approval_status"},
    {"timeline_activity_lifecycle_state_planned_approval_categories",
     "planned_approval_category"},
    {"timeline_activity_lifecycle_state_realized_approval_categories",
     "realized_approval_category"},
    {"timeline_activity_lifecycle_state_planned_locked_values", "planned_locked"},
    {"timeline_activity_lifecycle_state_realized_locked_values", "realized_locked"},
    {"timeline_activity_lifecycle_state_planned_executed_values", "planned_executed"},
    {"timeline_activity_lifecycle_state_realized_executed_values", "realized_executed"},
    {"timeline_activity_lifecycle_state_status_transitions", "status_transition"},
    {"timeline_activity_lifecycle_state_approval_transitions", "approval_transition"},
    {"timeline_activity_lifecycle_state_planned_protection_decisions",
     "planned_protection_decision"},
    {"timeline_activity_lifecycle_state_realized_protection_decisions",
     "realized_protection_decision"},
    {"timeline_activity_lifecycle_state_feedback_sources", "feedback_source"},
    {"timeline_activity_lifecycle_state_feedback_scopes", "feedback_scope"},
    {"timeline_activity_lifecycle_state_feedback_keys", "feedback_key"},
    {"timeline_activity_lifecycle_state_trust_boundaries", "trust_boundary"},
    {"timeline_activity_lifecycle_state_derivation_reasons", ["derivation_reasons"]},
    {"timeline_activity_lifecycle_state_assumption_maps", "assumptions"}
  ]

  def field_pairs, do: @fields
  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_lifecycle_state_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_lifecycle_state_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_lifecycle_state")
      )

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(timeline_activity_lifecycle_state_risks, risk_keys)}
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
