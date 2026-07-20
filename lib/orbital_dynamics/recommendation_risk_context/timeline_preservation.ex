defmodule OrbitalDynamics.RecommendationRiskContext.TimelinePreservation do
  @moduledoc false

  @context_keys [
    "timeline_preservation_activity_ids",
    "timeline_preservation_timeline_ids",
    "timeline_preservation_statuses",
    "timeline_preservation_requires_preservation_values",
    "timeline_preservation_requires_operator_review_values",
    "timeline_preservation_protection_decisions",
    "timeline_preservation_protection_categories",
    "timeline_preservation_protection_reasons",
    "timeline_preservation_preserve_activity_count_values",
    "timeline_preservation_review_change_activity_count_values",
    "timeline_preservation_sensitive_activity_count_values",
    "timeline_preservation_preserve_activity_ids",
    "timeline_preservation_preserve_timeline_ids",
    "timeline_preservation_review_change_activity_ids",
    "timeline_preservation_review_change_timeline_ids",
    "timeline_preservation_sensitive_activity_ids",
    "timeline_preservation_sensitive_timeline_ids",
    "timeline_preservation_invalid_activity_input_values",
    "timeline_preservation_invalid_activity_input_reasons",
    "timeline_preservation_required_operator_actions",
    "timeline_preservation_feedback_sources",
    "timeline_preservation_feedback_scopes",
    "timeline_preservation_feedback_keys",
    "timeline_preservation_trust_boundaries",
    "timeline_preservation_derivation_reasons",
    "timeline_preservation_assumption_maps"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    preservation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_preservation_review" or
            Map.get(&1, "feedback_scope") == "timeline_preservation")
      )

    %{
      "timeline_preservation_activity_ids" =>
        risk_context_values(preservation_risks, "activity_id"),
      "timeline_preservation_timeline_ids" =>
        risk_context_values(preservation_risks, "timeline_id"),
      "timeline_preservation_statuses" =>
        risk_context_values(preservation_risks, "timeline_preservation_status"),
      "timeline_preservation_requires_preservation_values" =>
        risk_context_values(preservation_risks, "requires_preservation"),
      "timeline_preservation_requires_operator_review_values" =>
        risk_context_values(preservation_risks, "requires_operator_review"),
      "timeline_preservation_protection_decisions" =>
        risk_context_values(preservation_risks, "protection_decision"),
      "timeline_preservation_protection_categories" =>
        risk_context_values(preservation_risks, "protection_category"),
      "timeline_preservation_protection_reasons" =>
        risk_context_values(preservation_risks, "protection_reason"),
      "timeline_preservation_preserve_activity_count_values" =>
        risk_context_values(preservation_risks, "preserve_activity_count"),
      "timeline_preservation_review_change_activity_count_values" =>
        risk_context_values(preservation_risks, "review_change_activity_count"),
      "timeline_preservation_sensitive_activity_count_values" =>
        risk_context_values(preservation_risks, "preservation_sensitive_activity_count"),
      "timeline_preservation_preserve_activity_ids" =>
        risk_context_values(preservation_risks, ["preserve_activity_ids"]),
      "timeline_preservation_preserve_timeline_ids" =>
        risk_context_values(preservation_risks, ["preserve_timeline_ids"]),
      "timeline_preservation_review_change_activity_ids" =>
        risk_context_values(preservation_risks, ["review_change_activity_ids"]),
      "timeline_preservation_review_change_timeline_ids" =>
        risk_context_values(preservation_risks, ["review_change_timeline_ids"]),
      "timeline_preservation_sensitive_activity_ids" =>
        risk_context_values(preservation_risks, ["preservation_sensitive_activity_ids"]),
      "timeline_preservation_sensitive_timeline_ids" =>
        risk_context_values(preservation_risks, ["preservation_sensitive_timeline_ids"]),
      "timeline_preservation_invalid_activity_input_values" =>
        risk_context_values(preservation_risks, "invalid_activity_input"),
      "timeline_preservation_invalid_activity_input_reasons" =>
        risk_context_values(preservation_risks, "invalid_activity_input_reason"),
      "timeline_preservation_required_operator_actions" =>
        risk_context_values(preservation_risks, "required_operator_action"),
      "timeline_preservation_feedback_sources" =>
        risk_context_values(preservation_risks, "feedback_source"),
      "timeline_preservation_feedback_scopes" =>
        risk_context_values(preservation_risks, "feedback_scope"),
      "timeline_preservation_feedback_keys" =>
        risk_context_values(preservation_risks, "feedback_key"),
      "timeline_preservation_trust_boundaries" =>
        risk_context_values(preservation_risks, "trust_boundary"),
      "timeline_preservation_derivation_reasons" =>
        risk_context_values(preservation_risks, ["derivation_reasons"]),
      "timeline_preservation_assumption_maps" =>
        risk_context_values(preservation_risks, "assumptions")
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
