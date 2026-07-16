defmodule OrbitalDynamics.Schema.PolicyDecisionCountContracts do
  @moduledoc false

  def validate(issues, path, decision, callbacks) when is_list(callbacks) do
    rule_matches = Map.get(decision, "rule_matches")

    issues
    |> expect_field_equals(
      path,
      decision,
      "classification",
      classification(rule_matches),
      callbacks
    )
    |> expect_field_equals(
      path,
      decision,
      "approval_requirement_count",
      approval_requirement_count(rule_matches),
      callbacks
    )
    |> expect_field_equals(path, decision, "risk_count", risk_count(rule_matches), callbacks)
    |> validate_escalation_rule_ids(path, decision, callbacks)
  end

  defp classification(rule_matches) when is_list(rule_matches) do
    cond do
      Enum.any?(rule_matches, &rule_match_classification?(&1, "blocked_by_policy")) ->
        "blocked_by_policy"

      Enum.any?(rule_matches, &rule_match_classification?(&1, "operator_review_required")) ->
        "operator_review_required"

      Enum.any?(rule_matches, &rule_match_classification?(&1, "auto_approvable")) ->
        "auto_approvable"

      true ->
        nil
    end
  end

  defp classification(_rule_matches), do: nil

  defp approval_requirement_count(rule_matches)
       when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &rule_match_classification?(&1, "operator_review_required"))
  end

  defp approval_requirement_count(_rule_matches), do: nil

  defp risk_count(rule_matches) when is_list(rule_matches) and rule_matches != [] do
    Enum.count(rule_matches, &(is_map(&1) and is_binary(Map.get(&1, "risk_type"))))
  end

  defp risk_count(_rule_matches), do: nil

  defp rule_match_classification?(match, classification) when is_map(match) do
    Map.get(match, "classification") == classification
  end

  defp rule_match_classification?(_match, _classification), do: false

  defp validate_escalation_rule_ids(issues, path, decision, callbacks) do
    rule_matches = Map.get(decision, "rule_matches")
    escalations = Map.get(decision, "escalations")

    if is_list(rule_matches) and rule_matches != [] and is_list(escalations) do
      rule_ids =
        rule_matches
        |> Enum.map(&if(is_map(&1), do: Map.get(&1, "rule_id")))
        |> Enum.reject(&is_nil/1)
        |> MapSet.new()

      stale_escalation? =
        Enum.any?(escalations, fn
          %{} = escalation ->
            rule_id = Map.get(escalation, "rule_id")
            is_binary(rule_id) and not MapSet.member?(rule_ids, rule_id)

          _escalation ->
            false
        end)

      if stale_escalation? do
        [
          error(path <> ".escalations", "must reference rule_matches rule_id values", callbacks)
          | issues
        ]
      else
        issues
      end
    else
      issues
    end
  end

  defp expect_field_equals(issues, path, map, field, expected, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
