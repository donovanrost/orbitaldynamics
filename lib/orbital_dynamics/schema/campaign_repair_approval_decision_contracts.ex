defmodule OrbitalDynamics.Schema.CampaignRepairApprovalDecisionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @fallback_policy_fields [
    "auto_approvable_approval_count_limit",
    "auto_approvable_risk_limit",
    "operator_review_risk_limit",
    "blocked_risk_types"
  ]

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
    |> validate_requirement_enrichment(artifact, decision)
    |> validate_fallback_policy(artifact, decision)
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

  defp validate_requirement_enrichment(issues, artifact, decision) do
    requirements = Map.get(artifact, "approval_requirements")
    rule_matches = Map.get(decision, "rule_matches")

    if is_list(requirements) and is_list(rule_matches) do
      requirements
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {%{} = requirement, index}, acc ->
          validate_requirement(
            acc,
            "$.approval_requirements[#{index}]",
            requirement,
            matching_rule_matches(rule_matches, requirement)
          )

        {_requirement, _index}, acc ->
          acc
      end)
    else
      issues
    end
  end

  defp validate_requirement(issues, _path, _requirement, []), do: issues

  defp validate_requirement(issues, path, requirement, matches) do
    issues
    |> validate_optional_equal(
      path <> ".approval_rule_matches",
      requirement,
      "approval_rule_matches",
      matches,
      "must match the enclosing decision rule matches for this requirement"
    )
    |> validate_optional_equal(
      path <> ".policy_classification",
      requirement,
      "policy_classification",
      strongest_classification(matches),
      "must match the strongest enclosing decision rule classification for this requirement"
    )
  end

  defp matching_rule_matches(rule_matches, requirement) do
    Enum.filter(rule_matches, fn
      %{} = match ->
        cond do
          not is_nil(Map.get(match, "activity_id")) ->
            Map.get(match, "activity_id") == Map.get(requirement, "activity_id")

          not is_nil(Map.get(match, "action")) ->
            Map.get(match, "action") == Map.get(requirement, "action")

          true ->
            false
        end

      _match ->
        false
    end)
  end

  defp strongest_classification(matches) do
    cond do
      Enum.any?(matches, &(Map.get(&1, "classification") == "blocked_by_policy")) ->
        "blocked_by_policy"

      Enum.any?(matches, &(Map.get(&1, "classification") == "operator_review_required")) ->
        "operator_review_required"

      true ->
        "auto_approvable"
    end
  end

  defp validate_optional_equal(issues, path, map, field, expected, message) do
    if Map.has_key?(map, field) do
      validate_equal(issues, path, Map.get(map, field), expected, message)
    else
      issues
    end
  end

  defp validate_fallback_policy(issues, artifact, decision) do
    approval_policy = Map.get(artifact, "approval_policy")

    case Map.fetch(decision, "fallback_policy") do
      :error ->
        issues

      {:ok, %{} = fallback_policy} when is_map(approval_policy) ->
        Enum.reduce(@fallback_policy_fields, issues, fn field, acc ->
          validate_shared_policy_field(acc, approval_policy, fallback_policy, field)
        end)

      {:ok, %{} = _fallback_policy} ->
        issues

      {:ok, _fallback_policy} ->
        [error("$.policy_decision.fallback_policy", "must be an object") | issues]
    end
  end

  defp validate_shared_policy_field(issues, approval_policy, fallback_policy, field) do
    if Map.has_key?(approval_policy, field) and Map.has_key?(fallback_policy, field) do
      validate_equal(
        issues,
        "$.policy_decision.fallback_policy.#{field}",
        Map.get(fallback_policy, field),
        Map.get(approval_policy, field),
        "must match enclosing Repair approval_policy.#{field}"
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
