defmodule OrbitalDynamics.Schema.StrategyRecommendationContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.SchemaContractField

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_optional_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_ids: 4, validate_stable_id_list: 3]

  def validate(
        issues,
        path,
        recommendation,
        branch_event_summary_validator,
        scoped_downlink_context_validator
      )
      when is_function(branch_event_summary_validator, 3) and
             is_function(scoped_downlink_context_validator, 3) do
    issues
    |> require_fields(path, recommendation, [
      "recommended_branch_id",
      "approval_status",
      "reason",
      "ranked_branch_ids",
      "tradeoffs",
      "explanation",
      "risks_remaining",
      "requires_approval"
    ])
    |> validate_optional_stable_ids(path, recommendation, ["recommended_branch_id"])
    |> validate_stable_id_list(
      path <> ".ranked_branch_ids",
      Map.get(recommendation, "ranked_branch_ids")
    )
    |> SchemaContractField.validate_optional(
      path,
      recommendation,
      "strategy_recommendation.v1"
    )
    |> expect_optional_type(path, recommendation, "status", :binary)
    |> expect_optional_type(path, recommendation, "authority_context", :map)
    |> expect_optional_type(path, recommendation, "authority_context_evaluation", :map)
    |> expect_optional_type(path, recommendation, "eligibility_status", :binary)
    |> expect_optional_type(path, recommendation, "counterfactual", :map)
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_recommendation_boundary(
      path,
      recommendation
    )
    |> expect_type(path, recommendation, "ranked_branch_ids", :list)
    |> expect_type(path, recommendation, "tradeoffs", :list)
    |> expect_type(path, recommendation, "requires_approval", :list)
    |> expect_type(path, recommendation, "explanation", :list)
    |> validate_consistency(path, recommendation)
    |> validate_no_recommendable(path, recommendation)
    |> validate_optional_rows(
      path <> ".tradeoffs",
      Map.get(recommendation, "tradeoffs"),
      &validate_tradeoff/3
    )
    |> validate_optional_rows(
      path <> ".explanation",
      Map.get(recommendation, "explanation"),
      fn acc, row_path, row ->
        validate_explanation(acc, row_path, row, branch_event_summary_validator)
      end
    )
    |> validate_optional_rows(
      path <> ".risks_remaining",
      Map.get(recommendation, "risks_remaining"),
      fn acc, row_path, row ->
        validate_risk(acc, row_path, row, scoped_downlink_context_validator)
      end
    )
  end

  defp validate_consistency(issues, path, recommendation) do
    recommended_branch_id = Map.get(recommendation, "recommended_branch_id")

    issues
    |> validate_ranked_branch(path, recommendation, recommended_branch_id)
    |> validate_explanation_branch_ids(path, recommendation, recommended_branch_id)
    |> validate_approval_requirements(path, recommendation)
  end

  defp validate_ranked_branch(
         issues,
         _path,
         %{"ranked_branch_ids" => [recommended_branch_id | _ids]},
         recommended_branch_id
       )
       when is_binary(recommended_branch_id),
       do: issues

  defp validate_ranked_branch(
         issues,
         path,
         %{"ranked_branch_ids" => ids},
         recommended_branch_id
       )
       when is_list(ids) and is_binary(recommended_branch_id) do
    [
      error(path <> ".recommended_branch_id", "must be first in ranked_branch_ids")
      | issues
    ]
  end

  defp validate_ranked_branch(
         issues,
         _path,
         _recommendation,
         _recommended_branch_id
       ),
       do: issues

  defp validate_explanation_branch_ids(
         issues,
         path,
         %{"explanation" => explanation},
         recommended_branch_id
       )
       when is_list(explanation) and is_binary(recommended_branch_id) do
    explanation
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      case row do
        %{"recommended_branch_id" => ^recommended_branch_id} ->
          acc

        %{"recommended_branch_id" => _other_branch_id} ->
          [
            error(
              "#{path}.explanation[#{index}].recommended_branch_id",
              "must match top-level recommended_branch_id"
            )
            | acc
          ]

        _row ->
          acc
      end
    end)
  end

  defp validate_explanation_branch_ids(
         issues,
         _path,
         _recommendation,
         _recommended_branch_id
       ),
       do: issues

  defp validate_approval_requirements(issues, path, %{
         "approval_status" => approval_status,
         "requires_approval" => rows
       })
       when is_binary(approval_status) and is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      case row do
        %{"policy_classification" => ^approval_status} ->
          acc

        %{"policy_classification" => _other_classification} ->
          [
            error(
              "#{path}.requires_approval[#{index}].policy_classification",
              "must match recommendation approval_status"
            )
            | acc
          ]

        _row ->
          acc
      end
    end)
  end

  defp validate_approval_requirements(issues, _path, _recommendation), do: issues

  defp validate_no_recommendable(
         issues,
         path,
         %{
           "status" => "no_recommendable_branch",
           "recommended_branch_id" => recommended_branch_id,
           "approval_status" => approval_status,
           "reason" => reason,
           "ranked_branch_ids" => ranked_branch_ids,
           "tradeoffs" => tradeoffs,
           "explanation" => explanation,
           "risks_remaining" => risks,
           "requires_approval" => approvals,
           "counterfactual" => %{} = counterfactual
         }
       ) do
    issues
    |> ensure(
      recommended_branch_id in [nil, :null],
      path <> ".recommended_branch_id",
      "must be JSON null when no branch is recommendable"
    )
    |> ensure(
      approval_status == "not_applicable",
      path <> ".approval_status",
      "must be not_applicable when no branch is recommendable"
    )
    |> ensure(
      reason == "all_branches_infeasible_or_policy_blocked",
      path <> ".reason",
      "must retain the typed no-recommendable-branch reason"
    )
    |> ensure(
      ranked_branch_ids == [] and tradeoffs == [] and explanation == [] and risks == [] and
        approvals == [],
      path,
      "must not retain selected-branch ranking or handoff evidence"
    )
    |> ensure(
      counterfactual["review_only"] == true and counterfactual["importable"] == false,
      path <> ".counterfactual",
      "must remain review-only and non-importable"
    )
  end

  defp validate_no_recommendable(issues, _path, _recommendation), do: issues

  defp validate_tradeoff(issues, path, row) do
    issues
    |> require_fields(path, row, ["dimension", "baseline", "recommended", "delta"])
    |> expect_type(path, row, "dimension", :binary)
    |> expect_number(path, row, "baseline")
    |> expect_number(path, row, "recommended")
    |> expect_number(path, row, "delta")
    |> validate_tradeoff_delta(path, row)
  end

  defp validate_tradeoff_delta(
         issues,
         path,
         %{"baseline" => baseline, "recommended" => recommended, "delta" => delta}
       )
       when is_number(baseline) and is_number(recommended) and is_number(delta) do
    if abs(delta - (recommended - baseline)) <= 1.0e-9 do
      issues
    else
      [error(path <> ".delta", "must equal recommended minus baseline") | issues]
    end
  end

  defp validate_tradeoff_delta(issues, _path, _row), do: issues

  defp validate_explanation(issues, path, row, branch_event_summary_validator) do
    issues
    |> require_fields(path, row, ["type"])
    |> branch_event_summary_validator.(path, row)
  end

  defp validate_risk(issues, path, risk, scoped_downlink_context_validator) do
    issues
    |> require_fields(path, risk, ["type", "severity", "reason"])
    |> scoped_downlink_context_validator.(path, risk)
  end

  defp ensure(issues, true, _path, _message), do: issues
  defp ensure(issues, false, path, message), do: [error(path, message) | issues]
end
