defmodule OrbitalDynamics.RecommendationRiskContext.TimelineActivityPrecondition do
  @moduledoc false

  @timeline_activity_precondition_context_keys [
    "timeline_activity_precondition_activity_ids",
    "timeline_activity_precondition_timeline_ids",
    "timeline_activity_precondition_activity_types",
    "timeline_activity_precondition_statuses",
    "timeline_activity_precondition_blocked_count_values",
    "timeline_activity_precondition_review_count_values",
    "timeline_activity_precondition_blocked_types",
    "timeline_activity_precondition_review_types",
    "timeline_activity_precondition_dependency_activity_ids",
    "timeline_activity_precondition_dependency_timeline_ids",
    "timeline_activity_precondition_exclusive_with_activity_ids",
    "timeline_activity_precondition_exclusive_with_timeline_ids",
    "timeline_activity_precondition_duplicate_dependency_activity_ids",
    "timeline_activity_precondition_duplicate_dependency_timeline_ids",
    "timeline_activity_precondition_duplicate_exclusivity_activity_ids",
    "timeline_activity_precondition_duplicate_exclusivity_timeline_ids",
    "timeline_activity_precondition_allow_overlap_values",
    "timeline_activity_precondition_invalid_activity_input_values",
    "timeline_activity_precondition_invalid_activity_input_reasons",
    "timeline_activity_precondition_required_operator_actions",
    "timeline_activity_precondition_requires_operator_review_values",
    "timeline_activity_precondition_feedback_sources",
    "timeline_activity_precondition_feedback_scopes",
    "timeline_activity_precondition_feedback_keys",
    "timeline_activity_precondition_trust_boundaries",
    "timeline_activity_precondition_derivation_reasons",
    "timeline_activity_precondition_assumption_maps"
  ]
  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_activity_precondition_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_activity_precondition_review" or
            Map.get(&1, "feedback_scope") == "timeline_activity_precondition")
      )

    %{
      "timeline_activity_precondition_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, "activity_id"),
      "timeline_activity_precondition_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, "timeline_id"),
      "timeline_activity_precondition_activity_types" =>
        risk_context_values(timeline_activity_precondition_risks, "activity_type"),
      "timeline_activity_precondition_statuses" =>
        risk_context_values(timeline_activity_precondition_risks, "precondition_status"),
      "timeline_activity_precondition_blocked_count_values" =>
        risk_context_values(timeline_activity_precondition_risks, "blocked_precondition_count"),
      "timeline_activity_precondition_review_count_values" =>
        risk_context_values(timeline_activity_precondition_risks, "review_precondition_count"),
      "timeline_activity_precondition_blocked_types" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "blocked_precondition_types"
        ]),
      "timeline_activity_precondition_review_types" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "review_precondition_types"
        ]),
      "timeline_activity_precondition_dependency_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "dependency_activity_ids"
        ]),
      "timeline_activity_precondition_dependency_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "dependency_timeline_ids"
        ]),
      "timeline_activity_precondition_exclusive_with_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "exclusive_with_activity_ids"
        ]),
      "timeline_activity_precondition_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "exclusive_with_timeline_ids"
        ]),
      "timeline_activity_precondition_duplicate_dependency_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_dependency_activity_ids"
        ]),
      "timeline_activity_precondition_duplicate_dependency_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_dependency_timeline_ids"
        ]),
      "timeline_activity_precondition_duplicate_exclusivity_activity_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_exclusivity_activity_ids"
        ]),
      "timeline_activity_precondition_duplicate_exclusivity_timeline_ids" =>
        risk_context_values(timeline_activity_precondition_risks, [
          "duplicate_exclusivity_timeline_ids"
        ]),
      "timeline_activity_precondition_allow_overlap_values" =>
        risk_context_values(timeline_activity_precondition_risks, "allow_overlap"),
      "timeline_activity_precondition_invalid_activity_input_values" =>
        risk_context_values(timeline_activity_precondition_risks, "invalid_activity_input"),
      "timeline_activity_precondition_invalid_activity_input_reasons" =>
        risk_context_values(
          timeline_activity_precondition_risks,
          "invalid_activity_input_reason"
        ),
      "timeline_activity_precondition_required_operator_actions" =>
        risk_context_values(timeline_activity_precondition_risks, "required_operator_action"),
      "timeline_activity_precondition_requires_operator_review_values" =>
        risk_context_values(timeline_activity_precondition_risks, "requires_operator_review"),
      "timeline_activity_precondition_feedback_sources" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_source"),
      "timeline_activity_precondition_feedback_scopes" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_scope"),
      "timeline_activity_precondition_feedback_keys" =>
        risk_context_values(timeline_activity_precondition_risks, "feedback_key"),
      "timeline_activity_precondition_trust_boundaries" =>
        risk_context_values(timeline_activity_precondition_risks, "trust_boundary"),
      "timeline_activity_precondition_derivation_reasons" =>
        risk_context_values(timeline_activity_precondition_risks, ["derivation_reasons"]),
      "timeline_activity_precondition_assumption_maps" =>
        risk_context_values(timeline_activity_precondition_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  def context_keys, do: @timeline_activity_precondition_context_keys

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
