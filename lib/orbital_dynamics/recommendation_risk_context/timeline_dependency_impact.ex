defmodule OrbitalDynamics.RecommendationRiskContext.TimelineDependencyImpact do
  @moduledoc false

  @context_keys [
    "timeline_dependency_impact_activity_ids",
    "timeline_dependency_impact_timeline_ids",
    "timeline_dependency_impact_scopes",
    "timeline_dependency_impact_statuses",
    "timeline_dependency_impact_required_operator_actions",
    "timeline_dependency_impact_operator_action_reasons",
    "timeline_dependency_impact_dependency_activity_ids",
    "timeline_dependency_impact_dependency_timeline_ids",
    "timeline_dependency_impact_exclusive_with_activity_ids",
    "timeline_dependency_impact_exclusive_with_timeline_ids",
    "timeline_dependency_impact_impacted_dependency_activity_ids",
    "timeline_dependency_impact_impacted_dependency_timeline_ids",
    "timeline_dependency_impact_impacted_exclusive_with_activity_ids",
    "timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
    "timeline_dependency_impact_feedback_sources",
    "timeline_dependency_impact_feedback_scopes",
    "timeline_dependency_impact_feedback_keys",
    "timeline_dependency_impact_trust_boundaries",
    "timeline_dependency_impact_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_dependency_impact_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_dependency_impact" or
            Map.get(&1, "feedback_scope") == "timeline_dependency_impact")
      )

    %{
      "timeline_dependency_impact_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "activity_id"),
      "timeline_dependency_impact_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "timeline_id"),
      "timeline_dependency_impact_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_scope"),
      "timeline_dependency_impact_statuses" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_status"),
      "timeline_dependency_impact_required_operator_actions" =>
        risk_context_values(timeline_dependency_impact_risks, "required_operator_action"),
      "timeline_dependency_impact_operator_action_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, "operator_action_reason"),
      "timeline_dependency_impact_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_activity_ids"]),
      "timeline_dependency_impact_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_timeline_ids"]),
      "timeline_dependency_impact_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_feedback_sources" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_source"),
      "timeline_dependency_impact_feedback_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_scope"),
      "timeline_dependency_impact_feedback_keys" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_key"),
      "timeline_dependency_impact_trust_boundaries" =>
        risk_context_values(timeline_dependency_impact_risks, "trust_boundary"),
      "timeline_dependency_impact_derivation_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, ["derivation_reasons"])
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
