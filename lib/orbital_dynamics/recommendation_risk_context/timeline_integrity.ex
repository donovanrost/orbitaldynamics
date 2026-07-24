defmodule OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity do
  @moduledoc false

  @fields [
    {"timeline_integrity_risk_types", ["type", "risk_type"]},
    {"timeline_integrity_activity_ids", "activity_id"},
    {"timeline_integrity_timeline_ids", "timeline_id"},
    {"timeline_integrity_statuses", "timeline_integrity_status"},
    {"timeline_integrity_issue_count_values", "timeline_integrity_issue_count"},
    {"timeline_integrity_issue_types", ["timeline_integrity_issue_types"]},
    {"timeline_integrity_issue_maps", "timeline_integrity_issues"},
    {"timeline_integrity_missing_dependency_activity_ids", ["missing_dependency_activity_ids"]},
    {"timeline_integrity_missing_dependency_timeline_ids", ["missing_dependency_timeline_ids"]},
    {"timeline_integrity_dependency_cycle_activity_ids", ["dependency_cycle_activity_ids"]},
    {"timeline_integrity_dependency_cycle_timeline_ids", ["dependency_cycle_timeline_ids"]},
    {"timeline_integrity_dependency_order_violation_activity_ids",
     ["dependency_order_violation_activity_ids"]},
    {"timeline_integrity_dependency_order_violation_timeline_ids",
     ["dependency_order_violation_timeline_ids"]},
    {"timeline_integrity_exclusivity_violation_activity_ids",
     ["exclusivity_violation_activity_ids"]},
    {"timeline_integrity_exclusivity_violation_timeline_ids",
     ["exclusivity_violation_timeline_ids"]},
    {"timeline_integrity_exclusivity_violation_groups", "exclusivity_violation_group"},
    {"timeline_integrity_required_operator_actions", "required_operator_action"},
    {"timeline_integrity_feedback_sources", "feedback_source"},
    {"timeline_integrity_feedback_scopes", "feedback_scope"},
    {"timeline_integrity_feedback_keys", "feedback_key"},
    {"timeline_integrity_trust_boundaries", "trust_boundary"},
    {"timeline_integrity_derivation_reasons", ["derivation_reasons"]}
  ]

  def field_pairs, do: @fields
  def context_keys, do: Enum.map(@fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    timeline_integrity_risks = Enum.filter(risks, &risk?/1)

    @fields
    |> Enum.map(fn {output_key, risk_keys} ->
      {output_key, risk_context_values(timeline_integrity_risks, risk_keys)}
    end)
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp risk?(%{"type" => "timeline_integrity_issue"}), do: true
  defp risk?(%{"risk_type" => "timeline_integrity_issue"}), do: true
  defp risk?(%{"feedback_scope" => "timeline_integrity"}), do: true
  defp risk?(_risk), do: false

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
