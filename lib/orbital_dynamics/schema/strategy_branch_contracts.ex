defmodule OrbitalDynamics.Schema.StrategyBranchContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_numeric_map: 3, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_equals: 6,
      expect_number: 4,
      expect_probability_range: 4,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(
        issues,
        path,
        branch,
        branch_event_validator,
        resource_projection_report_validator,
        policy_decision_validator,
        approval_requirement_validator
      )
      when is_function(branch_event_validator, 3) and
             is_function(resource_projection_report_validator, 3) and
             is_function(policy_decision_validator, 3) and
             is_function(approval_requirement_validator, 3) do
    issues
    |> require_fields(path, branch, @required_fields)
    |> validate_stable_ids(path, branch, ["branch_id"])
    |> expect_number(path, branch, "probability")
    |> expect_probability_range(path, branch, "probability")
    |> expect_number(path, branch, "score")
    |> expect_type(path, branch, "events", :list)
    |> expect_type(path, branch, "candidate_plan", :map)
    |> expect_type(path, branch, "repair_result", :map)
    |> expect_type(path, branch, "score_terms", :map)
    |> expect_type(path, branch, "approval_requirements", :list)
    |> expect_type(path, branch, "policy_decision", :map)
    |> validate_numeric_map(path <> ".score_terms", Map.get(branch, "score_terms"))
    |> validate_rows(
      path <> ".events",
      Map.get(branch, "events", []),
      branch_event_validator
    )
    |> resource_projection_report_validator.(
      path <> ".resource_projection_report",
      Map.get(branch, "resource_projection_report")
    )
    |> policy_decision_validator.(
      path <> ".policy_decision",
      Map.get(branch, "policy_decision", %{})
    )
    |> validate_summary_consistency(path, branch)
    |> validate_rows(
      path <> ".approval_requirements",
      Map.get(branch, "approval_requirements", []),
      approval_requirement_validator
    )
  end

  defp validate_summary_consistency(issues, path, branch) do
    policy_decision =
      case Map.get(branch, "policy_decision") do
        %{} = decision -> decision
        _decision -> %{}
      end

    approval_requirements = Map.get(branch, "approval_requirements", [])
    risk_indicators = Map.get(branch, "risk_indicators", [])

    issues =
      issues
      |> validate_expected_score(path, branch)
      |> expect_field_equals(
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
        path <> ".policy_decision",
        policy_decision,
        "approval_requirement_count",
        if(is_list(approval_requirements), do: length(approval_requirements)),
        "must match branch approval_requirements count"
      )
      |> expect_field_equals(
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
         path,
         %{"score" => score, "score_terms" => %{"expected_score" => expected_score}}
       )
       when is_number(score) and is_number(expected_score) do
    if abs(score - expected_score) <= 1.0e-9 do
      issues
    else
      [error(path <> ".score", "must match score_terms.expected_score") | issues]
    end
  end

  defp validate_expected_score(issues, _path, _branch), do: issues
end
