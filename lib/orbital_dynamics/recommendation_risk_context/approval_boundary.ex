defmodule OrbitalDynamics.RecommendationRiskContext.ApprovalBoundary do
  @moduledoc false

  @context_keys [
    "approval_boundary_ids",
    "approval_boundary_statuses",
    "approval_boundary_reasons",
    "automation_boundaries",
    "execution_boundaries",
    "approval_boundary_import_classifications",
    "approval_boundary_required_operator_actions",
    "approval_boundary_required_authorities",
    "approval_boundary_policy_bundle_ids",
    "approval_boundary_rule_ids",
    "approval_boundary_feedback_sources",
    "approval_boundary_feedback_scopes",
    "approval_boundary_feedback_keys",
    "approval_boundary_trust_boundaries"
  ]

  def context_keys, do: @context_keys

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    approval_boundary_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "approval_boundary" or
            Map.get(&1, "type") == "approval_boundary_pressure")
      )

    %{
      "approval_boundary_ids" =>
        risk_context_values(approval_boundary_risks, "approval_boundary"),
      "approval_boundary_statuses" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_status"),
      "approval_boundary_reasons" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_reason"),
      "automation_boundaries" =>
        risk_context_values(approval_boundary_risks, "automation_boundary"),
      "execution_boundaries" =>
        risk_context_values(approval_boundary_risks, "execution_boundary"),
      "approval_boundary_import_classifications" =>
        risk_context_values(approval_boundary_risks, "import_classification"),
      "approval_boundary_required_operator_actions" =>
        risk_context_values(approval_boundary_risks, "required_operator_action"),
      "approval_boundary_required_authorities" =>
        risk_context_values(approval_boundary_risks, "required_authority"),
      "approval_boundary_policy_bundle_ids" =>
        risk_context_values(approval_boundary_risks, "policy_bundle_id"),
      "approval_boundary_rule_ids" => risk_context_values(approval_boundary_risks, "rule_id"),
      "approval_boundary_feedback_sources" =>
        risk_context_values(approval_boundary_risks, "feedback_source"),
      "approval_boundary_feedback_scopes" =>
        risk_context_values(approval_boundary_risks, "feedback_scope"),
      "approval_boundary_feedback_keys" =>
        risk_context_values(approval_boundary_risks, "feedback_key"),
      "approval_boundary_trust_boundaries" =>
        risk_context_values(approval_boundary_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

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
