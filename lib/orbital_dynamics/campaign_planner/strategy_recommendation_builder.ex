defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendationBuilder do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchComparisonContext,
    PlanBranch,
    PressureRiskFields,
    RecommendationApproval,
    RecommendationBranchEvent,
    RecommendationFeedback,
    RecommendationObjective,
    RecommendationPlanChange,
    RecommendationPressureRiskContext,
    RecommendationReadinessPressure,
    RecommendationRepairLink,
    RecommendationResourceMargin,
    RecommendationResourcePressure,
    RecommendationRiskDriver,
    RecommendationTradeoff,
    StrategyRecommendation
  }

  def build(branches) when is_list(branches) do
    selectable = Enum.reject(branches, &(&1.approval_status == "blocked_by_policy"))
    ranked = if selectable == [], do: branches, else: selectable
    recommended = List.first(ranked)
    baseline = Enum.find(branches, &(&1.id == "baseline")) || List.last(branches)

    %StrategyRecommendation{
      recommended_branch_id: recommended.id,
      approval_status: recommended.approval_status,
      reason: reason(recommended),
      eligibility_status: recommended.policy_decision["eligibility_status"],
      authority_context: recommended.policy_decision["authority_context"],
      authority_context_evaluation: recommended.policy_decision["authority_context_evaluation"],
      ranked_branch_ids: Enum.map(ranked, & &1.id),
      tradeoffs: RecommendationTradeoff.dimensions(recommended, baseline),
      explanation: explanation(recommended, baseline),
      risks_remaining: recommended.risk_indicators,
      requires_approval: recommended.approval_requirements
    }
  end

  def build(branches, %{"mode" => "hard"} = eligibility) when is_list(branches) do
    ranked_branch_ids = Map.fetch!(eligibility, "eligible_ranked_branch_ids")
    recommended_branch_id = List.first(ranked_branch_ids)
    recommended = Enum.find(branches, &(&1.id == recommended_branch_id))
    baseline = Enum.find(branches, &(&1.id == "baseline")) || List.last(branches)
    counterfactual = Map.get(eligibility, "counterfactual", :null)

    case recommended do
      nil ->
        counterfactual_branch =
          case counterfactual do
            %{"branch_id" => branch_id} -> Enum.find(branches, &(&1.id == branch_id))
            _counterfactual -> nil
          end

        decision = if counterfactual_branch, do: counterfactual_branch.policy_decision, else: %{}

        %StrategyRecommendation{
          recommended_branch_id: nil,
          approval_status: "not_applicable",
          status: "no_recommendable_branch",
          reason: "all_branches_infeasible_or_policy_blocked",
          eligibility_status: decision["eligibility_status"],
          authority_context: decision["authority_context"],
          authority_context_evaluation: decision["authority_context_evaluation"],
          counterfactual: counterfactual,
          ranked_branch_ids: []
        }

      %PlanBranch{} = recommended ->
        %StrategyRecommendation{
          recommended_branch_id: recommended.id,
          approval_status: recommended.approval_status,
          status: "recommendable",
          reason: reason(recommended),
          eligibility_status: recommended.policy_decision["eligibility_status"],
          authority_context: recommended.policy_decision["authority_context"],
          authority_context_evaluation:
            recommended.policy_decision["authority_context_evaluation"],
          counterfactual: counterfactual,
          ranked_branch_ids: ranked_branch_ids,
          tradeoffs: RecommendationTradeoff.dimensions(recommended, baseline),
          explanation: explanation(recommended, baseline),
          risks_remaining: recommended.risk_indicators,
          requires_approval: recommended.approval_requirements
        }
    end
  end

  defp reason(%PlanBranch{} = recommended) do
    case recommended.approval_status do
      "auto_approvable" -> "best_expected_score_within_auto_approval_policy"
      "operator_review_required" -> "best_expected_score_requiring_operator_review"
      "blocked_by_policy" -> "all_branches_blocked_highest_score_reported_for_review"
    end
  end

  defp explanation(recommended, baseline) do
    plan_change_rows = RecommendationPlanChange.rows(recommended)
    objective_rows = RecommendationObjective.rows(recommended)
    resource_margin_rows = RecommendationResourceMargin.rows(recommended)

    risk_rows =
      RecommendationRiskDriver.rows(recommended, &recommendation_pressure_risk_context/1)

    repair_link_rows = RecommendationRepairLink.rows(recommended)
    resource_pressure_rows = RecommendationResourcePressure.rows(recommended)
    readiness_pressure_rows = RecommendationReadinessPressure.rows(recommended)
    feedback_rows = RecommendationFeedback.rows(recommended)

    branch_event_rows =
      RecommendationBranchEvent.rows(recommended, &BranchComparisonContext.event_fields/1)

    approval_rows = RecommendationApproval.rows(recommended)
    tradeoff_rows = RecommendationTradeoff.rows(recommended, baseline)

    plan_change_rows ++
      objective_rows ++
      risk_rows ++
      repair_link_rows ++
      resource_margin_rows ++
      resource_pressure_rows ++
      readiness_pressure_rows ++
      feedback_rows ++
      branch_event_rows ++
      approval_rows ++
      tradeoff_rows
  end

  defp recommendation_pressure_risk_context(risk) do
    RecommendationPressureRiskContext.context(risk, &PressureRiskFields.fields/1)
  end
end
