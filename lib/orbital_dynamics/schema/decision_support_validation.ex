defmodule OrbitalDynamics.Schema.DecisionSupportValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_integer: 4,
      expect_optional_probability: 4
    ]

  def validate_maneuver_recommendation(issues, path, maneuver, model_limits) do
    OrbitalDynamics.Schema.ManeuverRecommendationContracts.validate(
      issues,
      path,
      maneuver,
      model_limits
    )
  end

  def validate_maneuver_review_report(issues, path, report, model_limits) do
    OrbitalDynamics.Schema.ManeuverReviewReportContracts.validate(
      issues,
      path,
      report,
      model_limits
    )
  end

  def validate_optional_objective_tradeoff_report(issues, report, validate_contract),
    do:
      validate_optional_report(
        issues,
        report,
        "$.objective_tradeoff_report",
        validate_contract
      )

  def validate_optional_objective_satisfaction_report(issues, report, validate_contract),
    do:
      validate_optional_report(
        issues,
        report,
        "$.objective_satisfaction_report",
        validate_contract
      )

  def validate_optional_branch_comparison_report(issues, nil, _validate_contract), do: issues

  def validate_optional_branch_comparison_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_branch_comparison_report(issues, _report, _validate_contract),
    do: [error("$.branch_comparison_report", "must be an object") | issues]

  def validate_optional_ranking_comparison_report(issues, nil, _validate_contract), do: issues

  def validate_optional_ranking_comparison_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_ranking_comparison_report(issues, _report, _validate_contract),
    do: [error("$.ranking_comparison_report", "must be an object") | issues]

  def validate_optional_branch_comparison_source_row(issues, _path, nil), do: issues

  def validate_optional_branch_comparison_source_row(issues, path, %{} = row) do
    issues
    |> expect_optional_non_negative_integer(path, row, "downlink_completion_required_contacts")
    |> expect_optional_non_negative_integer(path, row, "downlink_completion_planned_contacts")
    |> expect_optional_probability(path, row, "downlink_completion_ratio")
    |> expect_optional_probability(path, row, "observation_success_factor")
    |> OrbitalDynamics.Schema.BranchComparisonReportContracts.validate_row_counts(
      path,
      row
    )
  end

  def validate_optional_branch_comparison_source_row(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  def validate_optional_optimizer_contract(issues, nil, _validate_contract), do: issues

  def validate_optional_optimizer_contract(issues, %{} = contract, validate_contract),
    do: validate_contract.(contract) ++ issues

  def validate_optional_optimizer_contract(issues, _contract, _validate_contract),
    do: [error("$.optimizer_contract", "must be an object") | issues]

  def validate_optional_score_term_report(issues, nil, _validate_contract), do: issues

  def validate_optional_score_term_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_score_term_report(issues, _report, _validate_contract),
    do: [error("$.score_term_report", "must be an object") | issues]

  defp validate_optional_report(issues, nil, _path, _validate_contract), do: issues

  defp validate_optional_report(issues, %{} = report, _path, validate_contract),
    do: validate_contract.(report) ++ issues

  defp validate_optional_report(issues, _report, path, _validate_contract),
    do: [error(path, "must be an object") | issues]
end
