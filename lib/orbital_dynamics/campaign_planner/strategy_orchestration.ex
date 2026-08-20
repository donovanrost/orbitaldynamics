defmodule OrbitalDynamics.CampaignPlanner.StrategyOrchestration do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    BranchComparisonReport,
    DownlinkActivityNormalization,
    ModelLimits,
    RepairMetadata,
    StrategyArtifact,
    StrategyBranchEvaluation,
    StrategyPolicyNormalization,
    StrategyRecommendationEligibility,
    StrategyRecommendationBuilder,
    StrategyReport
  }

  alias OrbitalDynamics.{CadenceImport, OperatorReview}

  @schema_version 3

  def run(%{branches: branches} = request) do
    cond do
      length(branches) < 2 ->
        raise ArgumentError,
              "V3 strategy requires a baseline branch and at least one what-if branch"

      not Enum.any?(branches, &(&1["id"] == "baseline")) ->
        raise ArgumentError,
              "V3 strategy requires a baseline branch and at least one what-if branch"

      true ->
        run_with_baseline(request)
    end
  end

  defp run_with_baseline(%{} = request) do
    input_order_branches =
      request.branches
      |> Enum.map(fn branch ->
        StrategyBranchEvaluation.evaluate(branch, request, &CampaignPlanner.repair/1)
      end)

    branches = Enum.sort_by(input_order_branches, &{-&1.score, &1.id})

    recommendation_eligibility =
      StrategyRecommendationEligibility.evaluate(branches, request.recommendation_eligibility)

    recommendation =
      case recommendation_eligibility do
        :legacy -> StrategyRecommendationBuilder.build(branches)
        eligibility -> StrategyRecommendationBuilder.build(branches, eligibility)
      end

    source_plan_id = RepairMetadata.source_plan_id(request.prior_plan)

    branch_comparison =
      case recommendation_eligibility do
        :legacy ->
          BranchComparisonReport.report(
            branches,
            recommendation,
            ModelLimits.branch_comparison_model_limits()
          )

        eligibility ->
          BranchComparisonReport.report(
            branches,
            recommendation,
            ModelLimits.branch_comparison_model_limits(),
            eligibility
          )
      end

    branch_maps = Enum.map(branches, &StrategyArtifact.branch_map/1)

    score_term_report =
      StrategyReport.score_term_report(
        branches,
        recommendation,
        request.strategy_policy,
        ModelLimits.score_report_model_limits()
      )

    objective_tradeoff_report =
      StrategyReport.objective_tradeoff_report(
        branches,
        recommendation,
        request.strategy_policy,
        ModelLimits.score_report_model_limits(),
        &ActivityIdentity.activity_id/1,
        &DownlinkActivityNormalization.downlink?/1
      )

    StrategyArtifact.base_artifact(
      request,
      source_plan_id,
      %{
        branch_maps: branch_maps,
        recommendation: recommendation,
        recommendation_eligibility: recommendation_eligibility,
        branch_comparison: branch_comparison,
        score_term: score_term_report,
        objective_tradeoff: objective_tradeoff_report,
        ranking_comparison: BranchComparisonReport.ranking_report(input_order_branches, branches),
        pareto_frontier: BranchComparisonReport.pareto_frontier_report(branch_comparison)
      },
      %{
        strategy: StrategyPolicyNormalization.strategy_to_map(request.strategy_policy),
        approval: StrategyPolicyNormalization.approval_to_map(request.approval_policy)
      },
      @schema_version
    )
    |> then(fn artifact ->
      Map.put(
        artifact,
        "operator_review_package",
        OperatorReview.from_strategy_artifact(artifact)
      )
    end)
    |> then(fn artifact ->
      Map.put(
        artifact,
        "cadence_import_manifest",
        CadenceImport.from_strategy_artifact(artifact)
      )
    end)
  end
end
