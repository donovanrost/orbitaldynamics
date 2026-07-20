defmodule OrbitalDynamics.RecommendationRiskContext.TimelineIntegrity do
  @moduledoc false

  @context_keys [
    "timeline_integrity_risk_types",
    "timeline_integrity_activity_ids",
    "timeline_integrity_timeline_ids",
    "timeline_integrity_statuses",
    "timeline_integrity_issue_count_values",
    "timeline_integrity_issue_types",
    "timeline_integrity_issue_maps",
    "timeline_integrity_missing_dependency_activity_ids",
    "timeline_integrity_missing_dependency_timeline_ids",
    "timeline_integrity_dependency_cycle_activity_ids",
    "timeline_integrity_dependency_cycle_timeline_ids",
    "timeline_integrity_dependency_order_violation_activity_ids",
    "timeline_integrity_dependency_order_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_activity_ids",
    "timeline_integrity_exclusivity_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_groups",
    "timeline_integrity_required_operator_actions",
    "timeline_integrity_feedback_sources",
    "timeline_integrity_feedback_scopes",
    "timeline_integrity_feedback_keys",
    "timeline_integrity_trust_boundaries",
    "timeline_integrity_derivation_reasons"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)
    timeline_integrity_risks = Enum.filter(risks, &risk?/1)

    %{
      "timeline_integrity_risk_types" =>
        risk_context_values(timeline_integrity_risks, ["type", "risk_type"]),
      "timeline_integrity_activity_ids" =>
        risk_context_values(timeline_integrity_risks, "activity_id"),
      "timeline_integrity_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, "timeline_id"),
      "timeline_integrity_statuses" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_status"),
      "timeline_integrity_issue_count_values" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" =>
        risk_context_values(timeline_integrity_risks, ["timeline_integrity_issue_types"]),
      "timeline_integrity_issue_maps" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issues"),
      "timeline_integrity_missing_dependency_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_activity_ids"]),
      "timeline_integrity_missing_dependency_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_timeline_ids"]),
      "timeline_integrity_dependency_cycle_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_activity_ids"]),
      "timeline_integrity_dependency_cycle_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_timeline_ids"]),
      "timeline_integrity_dependency_order_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_activity_ids"
        ]),
      "timeline_integrity_dependency_order_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_timeline_ids"
        ]),
      "timeline_integrity_exclusivity_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_activity_ids"]),
      "timeline_integrity_exclusivity_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_timeline_ids"]),
      "timeline_integrity_exclusivity_violation_groups" =>
        risk_context_values(timeline_integrity_risks, "exclusivity_violation_group"),
      "timeline_integrity_required_operator_actions" =>
        risk_context_values(timeline_integrity_risks, "required_operator_action"),
      "timeline_integrity_feedback_sources" =>
        risk_context_values(timeline_integrity_risks, "feedback_source"),
      "timeline_integrity_feedback_scopes" =>
        risk_context_values(timeline_integrity_risks, "feedback_scope"),
      "timeline_integrity_feedback_keys" =>
        risk_context_values(timeline_integrity_risks, "feedback_key"),
      "timeline_integrity_trust_boundaries" =>
        risk_context_values(timeline_integrity_risks, "trust_boundary"),
      "timeline_integrity_derivation_reasons" =>
        risk_context_values(timeline_integrity_risks, ["derivation_reasons"])
    }
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
