defmodule OrbitalDynamics.Schema.StrategyBranchContracts do
  @moduledoc false

  @required_fields [
    "branch_id",
    "probability",
    "events",
    "candidate_plan",
    "repair_result",
    "score",
    "score_terms",
    "warnings",
    "risk_indicators",
    "approval_status",
    "approval_requirements",
    "policy_decision"
  ]

  def validate(issues, path, branch, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, branch, @required_fields)
    |> validate_stable_ids(callbacks, path, branch, ["branch_id"])
    |> expect_number(callbacks, path, branch, "probability")
    |> expect_probability_range(callbacks, path, branch, "probability")
    |> expect_number(callbacks, path, branch, "score")
    |> expect_type(callbacks, path, branch, "events", :list)
    |> expect_type(callbacks, path, branch, "candidate_plan", :map)
    |> expect_type(callbacks, path, branch, "repair_result", :map)
    |> expect_type(callbacks, path, branch, "score_terms", :map)
    |> expect_type(callbacks, path, branch, "approval_requirements", :list)
    |> expect_type(callbacks, path, branch, "policy_decision", :map)
    |> validate_numeric_map(callbacks, path <> ".score_terms", Map.get(branch, "score_terms"))
    |> validate_rows(
      callbacks,
      path <> ".events",
      Map.get(branch, "events", []),
      &validate_branch_event(&1, callbacks, &2, &3)
    )
    |> validate_optional_resource_projection_report(
      callbacks,
      path <> ".resource_projection_report",
      Map.get(branch, "resource_projection_report")
    )
    |> validate_policy_decision(
      callbacks,
      path <> ".policy_decision",
      Map.get(branch, "policy_decision", %{})
    )
    |> validate_summary_consistency(callbacks, path, branch)
    |> validate_rows(
      callbacks,
      path <> ".approval_requirements",
      Map.get(branch, "approval_requirements", []),
      &validate_approval_requirement(&1, callbacks, &2, &3)
    )
  end

  defp validate_summary_consistency(issues, callbacks, path, branch) do
    policy_decision = Map.get(branch, "policy_decision", %{})
    approval_requirements = Map.get(branch, "approval_requirements", [])
    risk_indicators = Map.get(branch, "risk_indicators", [])

    issues =
      issues
      |> validate_expected_score(callbacks, path, branch)
      |> expect_field_equals(
        callbacks,
        path <> ".policy_decision",
        policy_decision,
        "classification",
        Map.get(branch, "approval_status"),
        "must match branch approval_status"
      )

    if policy_decision_has_rule_matches?(policy_decision) do
      issues
    else
      issues
      |> expect_field_equals(
        callbacks,
        path <> ".policy_decision",
        policy_decision,
        "approval_requirement_count",
        if(is_list(approval_requirements), do: length(approval_requirements)),
        "must match branch approval_requirements count"
      )
      |> expect_field_equals(
        callbacks,
        path <> ".policy_decision",
        policy_decision,
        "risk_count",
        if(is_list(risk_indicators), do: length(risk_indicators)),
        "must match branch risk_indicators count"
      )
    end
  end

  defp policy_decision_has_rule_matches?(%{"rule_matches" => rule_matches})
       when is_list(rule_matches) and rule_matches != [],
       do: true

  defp policy_decision_has_rule_matches?(_policy_decision), do: false

  defp validate_expected_score(
         issues,
         callbacks,
         path,
         %{"score" => score, "score_terms" => %{"expected_score" => expected_score}}
       )
       when is_number(score) and is_number(expected_score) do
    if abs(score - expected_score) <= 1.0e-9 do
      issues
    else
      [error(callbacks, path <> ".score", "must match score_terms.expected_score") | issues]
    end
  end

  defp validate_expected_score(issues, _callbacks, _path, _branch), do: issues

  defp error(callbacks, path, message), do: callback!(callbacks, :error).(path, message)

  defp expect_field_equals(issues, callbacks, path, branch, field, expected, message) do
    callback!(callbacks, :expect_field_equals_with_message).(
      issues,
      path,
      branch,
      field,
      expected,
      message
    )
  end

  defp expect_number(issues, callbacks, path, branch, field) do
    callback!(callbacks, :expect_number).(issues, path, branch, field)
  end

  defp expect_probability_range(issues, callbacks, path, branch, field) do
    callback!(callbacks, :expect_probability_range).(issues, path, branch, field)
  end

  defp expect_type(issues, callbacks, path, branch, field, type) do
    callback!(callbacks, :expect_type).(issues, path, branch, field, type)
  end

  defp require_fields(issues, callbacks, path, branch, fields) do
    callback!(callbacks, :require_fields).(issues, path, branch, fields)
  end

  defp validate_approval_requirement(issues, callbacks, path, requirement) do
    callback!(callbacks, :validate_approval_requirement).(issues, path, requirement)
  end

  defp validate_branch_event(issues, callbacks, path, event) do
    callback!(callbacks, :validate_branch_event).(issues, path, event)
  end

  defp validate_numeric_map(issues, callbacks, path, values) do
    callback!(callbacks, :validate_numeric_map).(issues, path, values)
  end

  defp validate_optional_resource_projection_report(issues, callbacks, path, report) do
    callback!(callbacks, :validate_optional_resource_projection_report).(issues, path, report)
  end

  defp validate_policy_decision(issues, callbacks, path, decision) do
    callback!(callbacks, :validate_policy_decision).(issues, path, decision)
  end

  defp validate_rows(issues, callbacks, path, rows, validator) do
    callback!(callbacks, :validate_rows).(issues, path, rows, validator)
  end

  defp validate_stable_ids(issues, callbacks, path, branch, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, branch, fields)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
