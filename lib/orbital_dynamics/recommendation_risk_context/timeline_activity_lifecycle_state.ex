defmodule OrbitalDynamics.RecommendationRiskContext.TimelineActivityLifecycleState do
  @moduledoc false

  @timeline_activity_lifecycle_state_context_keys [
    "timeline_activity_lifecycle_state_activity_ids",
    "timeline_activity_lifecycle_state_timeline_ids",
    "timeline_activity_lifecycle_state_planned_activity_ids",
    "timeline_activity_lifecycle_state_realized_activity_ids",
    "timeline_activity_lifecycle_state_planned_timeline_ids",
    "timeline_activity_lifecycle_state_realized_timeline_ids",
    "timeline_activity_lifecycle_state_transition_decisions",
    "timeline_activity_lifecycle_state_status_transition_decisions",
    "timeline_activity_lifecycle_state_approval_transition_decisions",
    "timeline_activity_lifecycle_state_review_required_values",
    "timeline_activity_lifecycle_state_requires_operator_review_values",
    "timeline_activity_lifecycle_state_required_operator_actions",
    "timeline_activity_lifecycle_state_operator_action_reasons",
    "timeline_activity_lifecycle_state_import_actions",
    "timeline_activity_lifecycle_state_invalid_activity_input_values",
    "timeline_activity_lifecycle_state_invalid_activity_input_count_values",
    "timeline_activity_lifecycle_state_invalid_activity_input_reasons",
    "timeline_activity_lifecycle_state_planned_statuses",
    "timeline_activity_lifecycle_state_realized_statuses",
    "timeline_activity_lifecycle_state_planned_status_categories",
    "timeline_activity_lifecycle_state_realized_status_categories",
    "timeline_activity_lifecycle_state_planned_approval_statuses",
    "timeline_activity_lifecycle_state_realized_approval_statuses",
    "timeline_activity_lifecycle_state_planned_approval_categories",
    "timeline_activity_lifecycle_state_realized_approval_categories",
    "timeline_activity_lifecycle_state_planned_locked_values",
    "timeline_activity_lifecycle_state_realized_locked_values",
    "timeline_activity_lifecycle_state_planned_executed_values",
    "timeline_activity_lifecycle_state_realized_executed_values",
    "timeline_activity_lifecycle_state_status_transitions",
    "timeline_activity_lifecycle_state_approval_transitions",
    "timeline_activity_lifecycle_state_planned_protection_decisions",
    "timeline_activity_lifecycle_state_realized_protection_decisions",
    "timeline_activity_lifecycle_state_feedback_sources",
    "timeline_activity_lifecycle_state_feedback_scopes",
    "timeline_activity_lifecycle_state_feedback_keys",
    "timeline_activity_lifecycle_state_trust_boundaries",
    "timeline_activity_lifecycle_state_derivation_reasons",
    "timeline_activity_lifecycle_state_assumption_maps"
  ]

  def context_keys, do: @timeline_activity_lifecycle_state_context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_lifecycle_state_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_lifecycle_state_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_lifecycle_state")
      )

    %{
      "timeline_activity_lifecycle_state_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "activity_id"),
      "timeline_activity_lifecycle_state_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "timeline_id"),
      "timeline_activity_lifecycle_state_planned_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_activity_id"),
      "timeline_activity_lifecycle_state_realized_activity_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_activity_id"),
      "timeline_activity_lifecycle_state_planned_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_timeline_id"),
      "timeline_activity_lifecycle_state_realized_timeline_ids" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_timeline_id"),
      "timeline_activity_lifecycle_state_transition_decisions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "transition_decision"),
      "timeline_activity_lifecycle_state_status_transition_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "status_transition_decision"
        ),
      "timeline_activity_lifecycle_state_approval_transition_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "approval_transition_decision"
        ),
      "timeline_activity_lifecycle_state_review_required_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "review_required"),
      "timeline_activity_lifecycle_state_requires_operator_review_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "requires_operator_review"
        ),
      "timeline_activity_lifecycle_state_required_operator_actions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "required_operator_action",
          "required_operator_actions"
        ]),
      "timeline_activity_lifecycle_state_operator_action_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "operator_action_reasons"
        ]),
      "timeline_activity_lifecycle_state_import_actions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "import_action"),
      "timeline_activity_lifecycle_state_invalid_activity_input_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "invalid_activity_input"
        ),
      "timeline_activity_lifecycle_state_invalid_activity_input_count_values" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "invalid_activity_input_count"
        ),
      "timeline_activity_lifecycle_state_invalid_activity_input_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "invalid_activity_input_reasons"
        ]),
      "timeline_activity_lifecycle_state_planned_statuses" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_status"),
      "timeline_activity_lifecycle_state_realized_statuses" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_status"),
      "timeline_activity_lifecycle_state_planned_status_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_status_category"
        ),
      "timeline_activity_lifecycle_state_realized_status_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_status_category"
        ),
      "timeline_activity_lifecycle_state_planned_approval_statuses" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_approval_status"
        ),
      "timeline_activity_lifecycle_state_realized_approval_statuses" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_approval_status"
        ),
      "timeline_activity_lifecycle_state_planned_approval_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_approval_category"
        ),
      "timeline_activity_lifecycle_state_realized_approval_categories" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_approval_category"
        ),
      "timeline_activity_lifecycle_state_planned_locked_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_locked"),
      "timeline_activity_lifecycle_state_realized_locked_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_locked"),
      "timeline_activity_lifecycle_state_planned_executed_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "planned_executed"),
      "timeline_activity_lifecycle_state_realized_executed_values" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "realized_executed"),
      "timeline_activity_lifecycle_state_status_transitions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "status_transition"),
      "timeline_activity_lifecycle_state_approval_transitions" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "approval_transition"),
      "timeline_activity_lifecycle_state_planned_protection_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "planned_protection_decision"
        ),
      "timeline_activity_lifecycle_state_realized_protection_decisions" =>
        risk_context_values(
          timeline_activity_lifecycle_state_risks,
          "realized_protection_decision"
        ),
      "timeline_activity_lifecycle_state_feedback_sources" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_source"),
      "timeline_activity_lifecycle_state_feedback_scopes" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_scope"),
      "timeline_activity_lifecycle_state_feedback_keys" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "feedback_key"),
      "timeline_activity_lifecycle_state_trust_boundaries" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "trust_boundary"),
      "timeline_activity_lifecycle_state_derivation_reasons" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, [
          "derivation_reasons"
        ]),
      "timeline_activity_lifecycle_state_assumption_maps" =>
        risk_context_values(timeline_activity_lifecycle_state_risks, "assumptions")
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
