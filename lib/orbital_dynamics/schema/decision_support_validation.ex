defmodule OrbitalDynamics.Schema.DecisionSupportValidation do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_integer: 4,
      expect_optional_probability: 4,
      require_fields: 4
    ]

  @objective_tradeoff_report "objective_tradeoff_report.v1"
  @objective_satisfaction_report "objective_satisfaction_report.v1"
  @ranking_comparison_report "ranking_comparison_report.v1"
  @pareto_frontier_report "pareto_frontier_report.v1"
  @branch_comparison_report "branch_comparison_report.v1"
  @optimizer_contract "optimizer_contract.v1"
  @constraint_report "constraint_report.v1"
  @score_term_report "score_term_report.v1"
  @maneuver_recommendation "maneuver_recommendation.v1"
  @maneuver_review_report "maneuver_review_report.v1"

  def validate_maneuver_recommendation_artifact(issues, path, maneuver) do
    issues
    |> require_registered_fields(
      path,
      maneuver,
      OrbitalDynamics.Schema.StrategyManeuverRegistryContracts,
      @maneuver_recommendation
    )
    |> validate_maneuver_recommendation(path, maneuver)
  end

  def validate_maneuver_review_artifact(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.StrategyManeuverRegistryContracts,
      @maneuver_review_report
    )
    |> validate_maneuver_review_report(path, report)
  end

  def validate_optional_maneuver_review_artifact(issues, _path, nil), do: issues

  def validate_optional_maneuver_review_artifact(issues, path, %{} = report),
    do: validate_maneuver_review_artifact(issues, path, report)

  def validate_optional_maneuver_review_artifact(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_maneuver_recommendation(issues, path, maneuver),
    do:
      validate_maneuver_recommendation(
        issues,
        path,
        maneuver,
        OrbitalDynamics.Schema.ManeuverReviewCapabilityContext.maneuver_recommendation_model_limits()
      )

  def validate_maneuver_recommendation(issues, path, maneuver, model_limits) do
    OrbitalDynamics.Schema.ManeuverRecommendationContracts.validate(
      issues,
      path,
      maneuver,
      model_limits
    )
  end

  def validate_maneuver_review_report(issues, path, report),
    do:
      validate_maneuver_review_report(
        issues,
        path,
        report,
        OrbitalDynamics.Schema.ManeuverReviewCapabilityContext.maneuver_review_report_model_limits()
      )

  def validate_maneuver_review_report(issues, path, report, model_limits) do
    OrbitalDynamics.Schema.ManeuverReviewReportContracts.validate(
      issues,
      path,
      report,
      model_limits
    )
  end

  def validate_objective_tradeoff_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts,
      @objective_tradeoff_report
    )
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_objective_tradeoff_report(
      path,
      report
    )
  end

  def validate_objective_satisfaction_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts,
      @objective_satisfaction_report
    )
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_objective_satisfaction_report(
      path,
      report
    )
  end

  def validate_ranking_comparison_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts,
      @ranking_comparison_report
    )
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_ranking_comparison_report(
      path,
      report
    )
  end

  def validate_pareto_frontier_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.ObjectiveAnalysisRegistryContracts,
      @pareto_frontier_report
    )
    |> OrbitalDynamics.Schema.ParetoFrontierContracts.validate(path, report)
  end

  def validate_branch_comparison_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.OptimizationRegistryContracts,
      @branch_comparison_report
    )
    |> OrbitalDynamics.Schema.BranchComparisonReportContracts.validate(path, report)
  end

  def validate_optimizer_contract(issues, path, contract) do
    issues
    |> require_registered_fields(
      path,
      contract,
      OrbitalDynamics.Schema.OptimizationRegistryContracts,
      @optimizer_contract
    )
    |> OrbitalDynamics.Schema.OptimizerContractContracts.validate(path, contract)
  end

  def validate_constraint_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.OptimizationRegistryContracts,
      @constraint_report
    )
    |> OrbitalDynamics.Schema.ConstraintReportContracts.validate(path, report)
  end

  def validate_optional_constraint_report(issues, report),
    do:
      validate_optional_report(
        issues,
        report,
        "$.constraint_report",
        &validate_constraint_report([], "$", &1)
      )

  def validate_optional_constraint_report_at(issues, path, report),
    do:
      validate_optional_report(
        issues,
        report,
        path,
        &validate_constraint_report([], path, &1)
      )

  def validate_score_term_report(issues, path, report) do
    issues
    |> require_registered_fields(
      path,
      report,
      OrbitalDynamics.Schema.OptimizationRegistryContracts,
      @score_term_report
    )
    |> OrbitalDynamics.Schema.OptimizerObjectiveContracts.validate_score_term_report(path, report)
  end

  def validate_optional_objective_tradeoff_report(issues, report),
    do:
      validate_optional_objective_tradeoff_report(
        issues,
        report,
        &validate_objective_tradeoff_report([], "$", &1)
      )

  def validate_optional_objective_tradeoff_report(issues, report, validate_contract),
    do:
      validate_optional_report(
        issues,
        report,
        "$.objective_tradeoff_report",
        validate_contract
      )

  def validate_optional_objective_tradeoff_report_at(issues, path, report),
    do:
      validate_optional_report(
        issues,
        report,
        path,
        &validate_objective_tradeoff_report([], path, &1)
      )

  def validate_optional_objective_satisfaction_report(issues, report),
    do:
      validate_optional_objective_satisfaction_report(
        issues,
        report,
        &validate_objective_satisfaction_report([], "$", &1)
      )

  def validate_optional_objective_satisfaction_report(issues, report, validate_contract),
    do:
      validate_optional_report(
        issues,
        report,
        "$.objective_satisfaction_report",
        validate_contract
      )

  def validate_optional_objective_satisfaction_report_at(issues, path, report),
    do:
      validate_optional_report(
        issues,
        report,
        path,
        &validate_objective_satisfaction_report([], path, &1)
      )

  def validate_optional_branch_comparison_report(issues, report),
    do:
      validate_optional_branch_comparison_report(
        issues,
        report,
        &validate_branch_comparison_report([], "$", &1)
      )

  def validate_optional_branch_comparison_report(issues, nil, _validate_contract), do: issues

  def validate_optional_branch_comparison_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_branch_comparison_report(issues, _report, _validate_contract),
    do: [error("$.branch_comparison_report", "must be an object") | issues]

  def validate_optional_ranking_comparison_report(issues, report),
    do:
      validate_optional_ranking_comparison_report(
        issues,
        report,
        &validate_ranking_comparison_report([], "$", &1)
      )

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

  def validate_optional_optimizer_contract(issues, contract),
    do:
      validate_optional_optimizer_contract(
        issues,
        contract,
        &validate_optimizer_contract([], "$", &1)
      )

  def validate_optional_optimizer_contract(issues, nil, _validate_contract), do: issues

  def validate_optional_optimizer_contract(issues, %{} = contract, validate_contract),
    do: validate_contract.(contract) ++ issues

  def validate_optional_optimizer_contract(issues, _contract, _validate_contract),
    do: [error("$.optimizer_contract", "must be an object") | issues]

  def validate_optional_score_term_report(issues, report),
    do:
      validate_optional_score_term_report(
        issues,
        report,
        &validate_score_term_report([], "$", &1)
      )

  def validate_optional_score_term_report(issues, nil, _validate_contract), do: issues

  def validate_optional_score_term_report(issues, %{} = report, validate_contract),
    do: validate_contract.(report) ++ issues

  def validate_optional_score_term_report(issues, _report, _validate_contract),
    do: [error("$.score_term_report", "must be an object") | issues]

  def validate_optional_score_term_report_at(issues, path, report),
    do:
      validate_optional_report(
        issues,
        report,
        path,
        &validate_score_term_report([], path, &1)
      )

  defp validate_optional_report(issues, nil, _path, _validate_contract), do: issues

  defp validate_optional_report(issues, %{} = report, _path, validate_contract),
    do: validate_contract.(report) ++ issues

  defp validate_optional_report(issues, _report, path, _validate_contract),
    do: [error(path, "must be an object") | issues]

  defp require_registered_fields(issues, path, artifact, registry_module, contract_name) do
    required_fields =
      registry_module.contracts()
      |> OrbitalDynamics.Schema.Registry.fetch!(contract_name)
      |> Map.fetch!("required_fields")

    require_fields(issues, path, artifact, required_fields)
  end
end
