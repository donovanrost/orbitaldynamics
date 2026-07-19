defmodule OrbitalDynamics.RecommendationRiskContext.TimelineLifecycleState do
  @moduledoc false

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_lifecycle_state_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_lifecycle_state_review" or
            Map.get(&1, "feedback_scope") == "timeline_lifecycle_state")
      )

    %{
      "timeline_lifecycle_state_statuses" =>
        risk_context_values(timeline_lifecycle_state_risks, "timeline_lifecycle_state_status"),
      "timeline_lifecycle_state_planned_activity_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "planned_activity_count"),
      "timeline_lifecycle_state_realized_activity_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "realized_activity_count"),
      "timeline_lifecycle_state_row_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "row_count"),
      "timeline_lifecycle_state_recordable_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "recordable_count"),
      "timeline_lifecycle_state_preserved_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "preserved_count"),
      "timeline_lifecycle_state_review_required_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "review_required_count"),
      "timeline_lifecycle_state_duplicate_identity_count_values" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "duplicate_timeline_identity_count"
        ),
      "timeline_lifecycle_state_invalid_activity_input_count_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "invalid_activity_input_count"),
      "timeline_lifecycle_state_transition_decision_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "transition_decision_counts"),
      "timeline_lifecycle_state_required_operator_action_count_maps" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "required_operator_action_counts"
        ),
      "timeline_lifecycle_state_operator_action_reason_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "operator_action_reason_counts"),
      "timeline_lifecycle_state_import_action_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "import_action_counts"),
      "timeline_lifecycle_state_planned_status_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "planned_status_category_counts"),
      "timeline_lifecycle_state_realized_status_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "realized_status_category_counts"),
      "timeline_lifecycle_state_status_transition_category_count_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "status_transition_category_counts"),
      "timeline_lifecycle_state_approval_transition_category_count_maps" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "approval_transition_category_counts"
        ),
      "timeline_lifecycle_state_recordable_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["recordable_timeline_ids"]),
      "timeline_lifecycle_state_preserved_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["preserved_timeline_ids"]),
      "timeline_lifecycle_state_review_timeline_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["review_timeline_ids"]),
      "timeline_lifecycle_state_review_activity_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["review_activity_ids"]),
      "timeline_lifecycle_state_invalid_activity_input_ids" =>
        risk_context_values(timeline_lifecycle_state_risks, ["invalid_activity_input_ids"]),
      "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_required_operator_action"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_operator_action_reason"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_status_transition_category"
        ),
      "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category" =>
        risk_context_values(
          timeline_lifecycle_state_risks,
          "review_timeline_ids_by_approval_transition_category"
        ),
      "timeline_lifecycle_state_required_operator_actions" =>
        risk_context_values(timeline_lifecycle_state_risks, "required_operator_action"),
      "timeline_lifecycle_state_requires_operator_review_values" =>
        risk_context_values(timeline_lifecycle_state_risks, "requires_operator_review"),
      "timeline_lifecycle_state_feedback_sources" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_source"),
      "timeline_lifecycle_state_feedback_scopes" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_scope"),
      "timeline_lifecycle_state_feedback_keys" =>
        risk_context_values(timeline_lifecycle_state_risks, "feedback_key"),
      "timeline_lifecycle_state_trust_boundaries" =>
        risk_context_values(timeline_lifecycle_state_risks, "trust_boundary"),
      "timeline_lifecycle_state_derivation_reasons" =>
        risk_context_values(timeline_lifecycle_state_risks, ["derivation_reasons"]),
      "timeline_lifecycle_state_assumption_maps" =>
        risk_context_values(timeline_lifecycle_state_risks, "assumptions")
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
