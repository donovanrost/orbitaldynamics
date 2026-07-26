defmodule OrbitalDynamics.Schema.CampaignRepairApprovalDecisionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, %{"policy_decision" => %{} = decision} = artifact) do
    issues
    |> validate_equal(
      "$.approval_status",
      Map.get(artifact, "approval_status"),
      Map.get(decision, "classification"),
      "must match policy_decision.classification"
    )
    |> validate_fallback_requirement_count(decision, Map.get(artifact, "approval_requirements"))
    |> validate_optional_rule_matches(artifact, decision)
  end

  def validate(issues, _artifact), do: issues

  defp validate_fallback_requirement_count(
         issues,
         %{"rule_matches" => []} = decision,
         requirements
       )
       when is_list(requirements) do
    validate_equal(
      issues,
      "$.policy_decision.approval_requirement_count",
      Map.get(decision, "approval_requirement_count"),
      length(requirements),
      "must match enclosing Repair approval requirement count"
    )
  end

  defp validate_fallback_requirement_count(issues, _decision, _requirements), do: issues

  defp validate_optional_rule_matches(issues, artifact, decision) do
    if Map.has_key?(artifact, "approval_rule_matches") do
      validate_equal(
        issues,
        "$.approval_rule_matches",
        Map.get(artifact, "approval_rule_matches"),
        Map.get(decision, "rule_matches"),
        "must match policy_decision.rule_matches"
      )
    else
      issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
