defmodule OrbitalDynamics.CampaignPlanner.RepairOrchestration do
  @moduledoc false

  alias OrbitalDynamics.Communications.{ContactAllocation, LinkCapacity}
  alias OrbitalDynamics.Constraints.CampaignLocal, as: CampaignLocalConstraint

  alias OrbitalDynamics.CampaignPlanner.{
    ApprovalPolicy,
    ContactContentionResolutionPolicy,
    ModelLimits,
    RepairArtifact,
    RepairCandidateDiff,
    RepairCandidateInputs,
    RepairExecution,
    RepairLinkCapacityPolicy,
    RepairMetadata,
    RepairScoreTerms,
    RepairSourceReports,
    RepairTimelineSummary,
    ScoreReports,
    StrategyPolicyNormalization
  }

  alias OrbitalDynamics.{Policy, ResourceProjection, Timeline, TimelineFeedback}

  def run(%{} = request) do
    prior_plan = request.prior_plan
    link_capacity_policy = RepairLinkCapacityPolicy.build(request)
    source_resource_summaries = repair_resource_summaries(request.candidate_refresh)

    execution =
      RepairExecution.run(request, link_capacity_policy, source_resource_summaries)

    planned_activities = execution.planned_activities
    candidates = execution.candidates
    activities = execution.activities
    deltas = execution.deltas
    approval_requirements = execution.approval_requirements

    {approval_status, approval_requirements, approval_rule_matches, policy_decision} =
      repair_approval_decision(approval_requirements, request.approval_policy)

    warnings =
      execution.warnings
      |> Kernel.++(repair_refresh_warnings(request.candidate_refresh))
      |> Enum.uniq()
      |> Enum.sort()

    source_resource_projection_report =
      repair_resource_projection_report(
        activities,
        source_resource_summaries,
        StrategyPolicyNormalization.approval_to_map(request.approval_policy)
      )

    link_capacity_report =
      link_capacity_report(
        activities,
        activities,
        link_capacity_policy,
        "campaign_repair.activities",
        request.approval_policy
      )

    score_terms =
      repair_score_terms(
        activities,
        deltas,
        source_resource_projection_report,
        link_capacity_report,
        execution.station_calendar_report,
        repair_contact_filter_report(request.candidate_refresh),
        repair_contact_allocation_report(request.candidate_refresh),
        RepairSourceReports.contact_contention_resolution(request.candidate_refresh),
        RepairCandidateInputs.contact_intents(request.candidate_refresh),
        repair_resource_filter_report(request.candidate_refresh),
        RepairCandidateDiff.report(request.candidate_refresh),
        RepairSourceReports.freshness(request.candidate_refresh),
        repair_refresh_budget_report(request.candidate_refresh),
        repair_candidate_rejection_report(request),
        RepairSourceReports.operational_readiness(request.candidate_refresh),
        RepairSourceReports.quality_gate(request.candidate_refresh),
        request.scoring_policy
      )

    score = score(score_terms)
    repair_score_timeline = repair_score_timeline(prior_plan, activities, score_terms, score)

    source_timeline_feedback_report =
      repair_timeline_feedback_report(planned_activities, request.realized_state)

    timeline_protection = RepairTimelineSummary.protection_summary(activities, deltas)

    timeline_transition_application_report =
      repair_timeline_transition_application_report(planned_activities, activities)

    RepairArtifact.build(request, %{
      prior_plan: prior_plan,
      activities: activities,
      candidates: candidates,
      deltas: deltas,
      approval_requirements: approval_requirements,
      approval_status: approval_status,
      approval_rule_matches: approval_rule_matches,
      policy_decision: policy_decision,
      warnings: warnings,
      source_resource_summaries: source_resource_summaries,
      score: score,
      score_terms: score_terms,
      score_term_report: repair_score_term_report(repair_score_timeline, request.scoring_policy),
      objective_tradeoff_report:
        repair_objective_tradeoff_report(repair_score_timeline, request.scoring_policy),
      constraint_report:
        repair_constraint_report(
          activities,
          repair_score_timeline,
          request,
          source_resource_projection_report,
          link_capacity_report
        ),
      link_capacity_report: link_capacity_report,
      contact_allocation_report: repair_contact_allocation_report(activities, request),
      source_resource_projection_report: source_resource_projection_report,
      source_timeline_feedback_report: source_timeline_feedback_report,
      station_calendar_report: execution.station_calendar_report,
      timeline_protection: timeline_protection,
      timeline_transition_application_report: timeline_transition_application_report
    })
  end

  defp repair_approval_decision(approval_requirements, %ApprovalPolicy{} = policy) do
    Policy.decide(
      approval_requirements,
      [],
      %{"id" => "repair", "events" => []},
      %{},
      StrategyPolicyNormalization.approval_to_map(policy)
    )
  end

  defp link_capacity_report(
         candidates,
         selected_activities,
         policy,
         source,
         approval_policy
       ) do
    LinkCapacity.report(candidates, selected_activities,
      policy: policy,
      source: source,
      approval_policy: approval_policy
    )
  end

  defp repair_timeline_transition_application_report(planned_activities, repaired_activities) do
    Timeline.transition_application_report(planned_activities, repaired_activities,
      source: "campaign_repair.timeline_transition_application",
      source_assumption: "source campaign activities compared with repaired campaign activities"
    )
  end

  defp repair_constraint_report(
         activities,
         repair_score_timeline,
         request,
         source_resource_projection_report,
         link_capacity_report
       ) do
    CampaignLocalConstraint.report(
      activities,
      [repair_score_timeline],
      request.constraints,
      source_resource_projection_report,
      link_capacity_report,
      model: "campaign_repair_local_constraint_summary",
      source: "campaign_repair.assumptions.constraints",
      constraint_model: "campaign_repair_v2_planner_local_constraints"
    )
  end

  defp repair_score_timeline(prior_plan, activities, score_terms, score) do
    %{
      "scenario_id" => RepairMetadata.source_plan_id(prior_plan),
      "score" => score,
      "score_terms" => score_terms,
      "activities" => activities,
      "activity_count" => length(activities)
    }
  end

  defp repair_objective_tradeoff_report(timeline, policy) do
    ScoreReports.repair_objective_tradeoff_report(
      timeline,
      policy,
      ModelLimits.score_report_model_limits()
    )
  end

  defp repair_score_term_report(timeline, policy) do
    ScoreReports.repair_score_term_report(
      timeline,
      policy,
      ModelLimits.score_report_model_limits()
    )
  end

  defp repair_score_terms(
         activities,
         deltas,
         resource_projection_report,
         link_capacity_report,
         station_calendar_report,
         contact_filter_report,
         contact_allocation_report,
         contact_contention_resolution_report,
         contact_intents,
         resource_filter_report,
         candidate_diff_report,
         freshness_report,
         refresh_budget_report,
         candidate_rejection_report,
         operational_readiness_report,
         quality_gate_report,
         scoring_policy
       ) do
    RepairScoreTerms.build(
      activities,
      deltas,
      resource_projection_report,
      link_capacity_report,
      station_calendar_report,
      contact_filter_report,
      contact_allocation_report,
      contact_contention_resolution_report,
      contact_intents,
      resource_filter_report,
      candidate_diff_report,
      freshness_report,
      refresh_budget_report,
      candidate_rejection_report,
      operational_readiness_report,
      quality_gate_report,
      scoring_policy
    )
  end

  defp repair_resource_summaries(nil), do: []

  defp repair_resource_summaries(%{} = candidate_refresh) do
    RepairCandidateInputs.resource_summaries(candidate_refresh)
  end

  defp repair_contact_filter_report(nil), do: nil

  defp repair_contact_filter_report(%{} = candidate_refresh) do
    RepairSourceReports.contact_filter(candidate_refresh)
  end

  defp repair_contact_allocation_report(nil), do: nil

  defp repair_contact_allocation_report(%{} = candidate_refresh) do
    RepairSourceReports.contact_allocation(candidate_refresh)
  end

  defp repair_contact_allocation_report(activities, request) do
    ContactAllocation.report(activities, request.ground_network,
      source: "campaign_repair.activities",
      policy: ContactContentionResolutionPolicy.build(request.scoring_policy),
      approval_policy: request.approval_policy
    )
  end

  defp repair_resource_filter_report(nil), do: nil

  defp repair_resource_filter_report(%{} = candidate_refresh) do
    RepairSourceReports.resource_filter(candidate_refresh)
  end

  defp repair_resource_projection_report(activities, summaries, approval_policy) do
    resource_projection_report(
      activities,
      summaries,
      "thin_repaired_activity_resource_projection",
      "source_resource_summaries",
      approval_policy
    )
  end

  defp repair_timeline_feedback_report(_planned_activities, %{"activities" => []}), do: nil
  defp repair_timeline_feedback_report(_planned_activities, %{"activities" => nil}), do: nil

  defp repair_timeline_feedback_report(planned_activities, %{"activities" => realized_activities})
       when is_list(realized_activities) do
    TimelineFeedback.reconcile(planned_activities, realized_activities)
    |> Map.put("source", "campaign_repair.realized_state_snapshot.activities")
  end

  defp repair_timeline_feedback_report(_planned_activities, _realized_state), do: nil

  defp resource_projection_report(_activities, [], _model, _source, _approval_policy), do: nil

  defp resource_projection_report(activities, summaries, model, source, approval_policy) do
    ResourceProjection.report(activities, summaries,
      model: model,
      source: source,
      approval_policy: approval_policy
    )
  end

  defp repair_candidate_rejection_report(%{} = request) do
    RepairSourceReports.candidate_rejection_report(request)
  end

  defp repair_refresh_budget_report(nil), do: nil

  defp repair_refresh_budget_report(%{} = candidate_refresh) do
    RepairSourceReports.refresh_budget(candidate_refresh)
  end

  defp repair_refresh_warnings(nil), do: []

  defp repair_refresh_warnings(%{} = candidate_refresh) do
    RepairSourceReports.refresh_warnings(candidate_refresh)
  end

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end
end
