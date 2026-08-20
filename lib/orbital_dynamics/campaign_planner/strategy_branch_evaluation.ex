defmodule OrbitalDynamics.CampaignPlanner.StrategyBranchEvaluation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    BranchApprovalRequirements,
    BranchCandidatePlan,
    BranchCandidateRefresh,
    BranchEventApplication,
    BranchEventNormalizer,
    CollectionLatencySatisfaction,
    PlanBranch,
    PriorityCommitmentSatisfaction,
    RepairMetadata,
    RepairPolicySemantics,
    ReplanRequest,
    StrategicScoreTerms,
    StrategyCandidateSource,
    StrategyFeedbackAdjustments,
    StrategyMetrics,
    StrategyPolicyNormalization,
    StrategyResourceImpacts,
    StrategyRiskIndicators,
    ValueEncoding
  }

  alias OrbitalDynamics.{Policy, ResourceProjection}

  def evaluate(branch, request, repair_fun) when is_function(repair_fun, 1) do
    prior_plan = BranchEventApplication.apply_plan(request.prior_plan, branch)

    candidate_refresh_request =
      BranchCandidateRefresh.request(branch, request, &BranchCandidateRefresh.derive/2)

    candidate_refresh =
      BranchCandidateRefresh.refresh(
        branch,
        request,
        candidate_refresh_request,
        RepairMetadata.source_plan_id(request.prior_plan)
      )

    realized_state =
      request.realized_state
      |> BranchEventApplication.merge_realized_state(
        BranchEventApplication.mission_state_repair_state(request.mission_state)
      )
      |> BranchEventApplication.merge_realized_state(branch["realized_state_overrides"])
      |> BranchEventApplication.apply_realized(prior_plan, branch)

    policy_overrides = Map.get(branch, "policy_overrides", %{})

    repair_policy =
      request.repair_policy
      |> RepairPolicySemantics.to_map()
      |> Map.merge(Map.get(policy_overrides, "repair_policy", %{}))
      |> RepairPolicySemantics.normalize()

    scoring_policy =
      request.scoring_policy
      |> Map.merge(Map.get(policy_overrides, "scoring_policy", %{}))

    repair_result =
      repair_fun.(%ReplanRequest{
        prior_plan: prior_plan,
        realized_state: realized_state,
        current_epoch_s: request.current_epoch_s,
        remaining_horizon: request.remaining_horizon,
        repair_policy: repair_policy,
        approval_policy: request.approval_policy,
        scoring_policy: scoring_policy,
        candidate_refresh: candidate_refresh,
        candidate_refresh_request: candidate_refresh_request,
        mission_state: request.mission_state,
        generated_at: request.generated_at,
        metadata: %{"branch_id" => branch["id"]}
      })

    {candidate_plan, candidate_warnings} =
      BranchCandidatePlan.build(
        repair_result,
        branch,
        request,
        event_ground_station_id: &BranchEventNormalizer.ground_station_id/1
      )

    resource_projection_report =
      resource_projection_report(
        candidate_plan,
        repair_result,
        StrategyPolicyNormalization.approval_to_map(request.approval_policy)
      )

    resource_impacts = StrategyResourceImpacts.build(candidate_plan, branch, request)

    feedback_adjustments =
      StrategyFeedbackAdjustments.build(
        candidate_plan,
        repair_result,
        branch,
        BranchCandidateRefresh.operational_feedback(branch, request.operational_feedback)
      )

    objective_satisfaction = objective_satisfaction(candidate_plan, request)
    feasibility_summary = feasibility_summary(candidate_plan)

    candidate_source =
      StrategyCandidateSource.branch_source(
        branch,
        request,
        repair_result,
        &BranchCandidateRefresh.derive/2
      )

    risk_indicators =
      StrategyRiskIndicators.build(
        branch,
        repair_result,
        candidate_plan,
        request,
        resource_impacts,
        resource_projection_report,
        feedback_adjustments,
        candidate_source
      )

    approval_requirements = BranchApprovalRequirements.build(repair_result, candidate_plan)

    {approval_status, approval_requirements, approval_rule_matches, policy_decision} =
      policy_decision(
        approval_requirements,
        risk_indicators,
        branch,
        candidate_plan,
        request
      )

    score_terms =
      StrategicScoreTerms.build(
        candidate_plan,
        repair_result,
        risk_indicators,
        branch,
        request,
        resource_impacts,
        feedback_adjustments
      )

    %PlanBranch{
      id: branch["id"],
      label: branch["label"],
      probability: branch["probability"],
      events: branch["events"],
      candidate_plan: candidate_plan,
      repair_result: repair_result,
      score: Map.get(score_terms, "expected_score", 0.0),
      score_terms: score_terms,
      warnings: warnings(repair_result, candidate_warnings, branch, resource_impacts),
      risk_indicators: risk_indicators,
      approval_status: approval_status,
      approval_requirements: approval_requirements,
      approval_rule_matches: approval_rule_matches,
      policy_decision: policy_decision,
      derived_source: get_in(branch, ["metadata", "derived_source"]),
      resource_impacts: resource_impacts,
      resource_projection_report: resource_projection_report,
      feedback_adjustments: feedback_adjustments,
      objective_satisfaction: objective_satisfaction,
      feasibility_summary: feasibility_summary,
      assumptions: assumptions(branch, request, repair_policy, scoring_policy, candidate_source),
      provenance: provenance(request.prior_plan, branch, candidate_source),
      tradeoffs: []
    }
  end

  defp policy_decision(approval_requirements, risk_indicators, branch, candidate_plan, request) do
    policy = StrategyPolicyNormalization.approval_to_map(request.approval_policy)

    if request.authority_context_mode_supplied? or request.authority_context_supplied? do
      opts =
        []
        |> maybe_put_authority_option(
          :authority_context_mode,
          request.authority_context_mode_supplied?,
          request.authority_context_mode
        )
        |> maybe_put_authority_option(
          :authority_context,
          request.authority_context_supplied?,
          request.authority_context
        )

      Policy.decide(
        approval_requirements,
        risk_indicators,
        branch,
        candidate_plan,
        policy,
        opts
      )
    else
      Policy.decide(approval_requirements, risk_indicators, branch, candidate_plan, policy)
    end
  end

  defp maybe_put_authority_option(opts, _key, false, _value), do: opts
  defp maybe_put_authority_option(opts, key, true, value), do: Keyword.put(opts, key, value)

  defp warnings(repair_result, candidate_warnings, branch, resource_impacts) do
    (Map.get(repair_result, "warnings", []) ++
       candidate_warnings ++
       branch_event_warnings(branch) ++
       Map.get(resource_impacts, "warnings", []))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_warnings(branch) do
    branch
    |> Map.get("events", [])
    |> Enum.flat_map(fn event ->
      event
      |> Map.get("invalid_branch_event_input_reasons", [])
      |> List.wrap()
      |> Enum.map(fn reason ->
        field = String.replace_prefix(reason, "invalid_", "")
        value = get_in(event, ["invalid_branch_event_values", field])
        branch_id = Map.get(branch, "id")
        event_type = Map.get(event, "type", "branch_event")

        "branch #{branch_id} #{event_type} ignored invalid #{field} #{ValueEncoding.encode_value(value)}"
      end)
    end)
  end

  defp objective_satisfaction(candidate_plan, request) do
    activities = Map.get(candidate_plan, "activities", [])

    priority_commitments =
      request.mission_state
      |> PriorityCommitmentSatisfaction.objectives()
      |> PriorityCommitmentSatisfaction.rows(activities)
      |> PriorityCommitmentSatisfaction.summary_from_rows()

    %{
      "priority_commitments" => priority_commitments,
      "downlink_completion" =>
        StrategyMetrics.downlink_completion_satisfaction(activities, request),
      "coverage" => %{"observed_target_count" => StrategyMetrics.target_count(activities)},
      "revisit" => %{"revisit_count" => StrategyMetrics.revisit_count(activities)}
    }
    |> CollectionLatencySatisfaction.put(activities, request.mission_state)
  end

  defp feasibility_summary(candidate_plan) do
    additions = Map.get(candidate_plan, "strategic_additions", [])

    %{
      "strategic_additions" =>
        Enum.map(additions, fn activity ->
          Map.get(activity, "feasibility", %{
            "status" => "not_applicable",
            "target_id" => activity["target_id"],
            "requires_approval" => get_in(activity, ["repair", "requires_approval"]) || false
          })
        end)
    }
  end

  defp resource_projection_report(candidate_plan, repair_result, approval_policy) do
    activities =
      (Map.get(candidate_plan, "activities", []) ++
         Map.get(candidate_plan, "strategic_additions", []))
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Map.new(&{ActivityIdentity.activity_id(&1), &1})
      |> Map.values()

    case Map.get(repair_result, "source_resource_summaries", []) do
      [] ->
        nil

      summaries ->
        ResourceProjection.report(activities, summaries,
          model: "thin_strategy_branch_activity_resource_projection",
          source: "branch.repair_result.source_resource_summaries",
          approval_policy: approval_policy
        )
    end
  end

  defp assumptions(branch, request, repair_policy, scoring_policy, candidate_source) do
    %{
      "branch_id" => branch["id"],
      "what_if_events" => branch["events"],
      "repair_policy" => RepairPolicySemantics.to_map(repair_policy),
      "repair_scoring_policy" => scoring_policy,
      "strategy_policy" => StrategyPolicyNormalization.strategy_to_map(request.strategy_policy),
      "candidate_source" => candidate_source,
      "model_limits" => [
        "thin_resource_summary_only",
        "no_autonomous_execution",
        "no_external_astrodynamics_backend"
      ]
    }
  end

  defp provenance(prior_plan, branch, candidate_source) do
    %{
      "source_plan_id" => RepairMetadata.source_plan_id(prior_plan),
      "branch_id" => branch["id"],
      "branch_metadata" => branch["metadata"],
      "candidate_source" => candidate_source
    }
  end
end
