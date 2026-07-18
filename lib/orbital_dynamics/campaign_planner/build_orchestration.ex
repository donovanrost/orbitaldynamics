defmodule OrbitalDynamics.CampaignPlanner.BuildOrchestration do
  @moduledoc false

  alias OrbitalDynamics.Communications.{
    ContactAllocation,
    ContactContention,
    ContactFilter,
    ContactIntent,
    LinkCapacity,
    StationCalendar
  }

  alias OrbitalDynamics.Constraints.CampaignLocal, as: CampaignLocalConstraint

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityCandidate,
    BuildArtifact,
    ContactContentionResolutionPolicy,
    DownlinkActivityNormalization,
    DownlinkObjectiveRequirements,
    ModelLimits,
    ObjectiveSatisfactionReports,
    PlanMetadata,
    ScalarValues,
    ScoreReports,
    TimelineRanking,
    ValueEncoding
  }

  alias OrbitalDynamics.{Optimizer, ResourceFilter, ResourceProjection, ResultSet, Timeline}

  def build(%ResultSet{} = result_set, campaign, generated_at) do
    policy = Map.get(campaign, "scoring_policy", %{})
    constraints = Map.get(campaign, "constraints", %{})

    sorted_candidates =
      result_set.event_results
      |> ActivityCandidate.build(campaign, constraints, policy)
      |> Enum.sort_by(&{&1["scenario_id"], &1["starts_at_s"], &1["id"]})

    {calendar_candidates, station_calendar_report} =
      apply_station_calendar(sorted_candidates, campaign)

    {resource_candidates, resource_filter_report} =
      apply_resource_filters(calendar_candidates, campaign)

    {contact_candidates, contact_filter_report} =
      apply_contact_filters(resource_candidates, campaign)

    {candidates, contact_contention_report} =
      ContactContention.annotate_contacts(contact_candidates,
        source: "campaign_plan.candidate_activities"
      )

    contact_allocation_report = contact_allocation_report(candidates, campaign)

    timelines =
      candidates
      |> Enum.group_by(& &1["scenario_id"])
      |> Enum.map(fn {scenario_id, scenario_candidates} ->
        TimelineRanking.ranked_timeline(
          scenario_id,
          scenario_candidates,
          constraints,
          policy,
          campaign
        )
      end)
      |> Enum.sort_by(&{-candidate_score(&1), &1["scenario_id"]})
      |> Enum.take(policy_count_value(policy, "rank_limit", 10))

    best_timeline = List.first(timelines)
    selected_activities = if best_timeline, do: best_timeline["activities"], else: []
    approval_policy = Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    contact_intents = ContactIntent.from_activities(candidates, approval_policy: approval_policy)
    plan_id = plan_id(result_set.study_id, generated_at)

    link_capacity_report =
      LinkCapacity.report(candidates, selected_activities,
        policy: link_capacity_policy(campaign, policy),
        source: "campaign_plan.candidate_activities",
        approval_policy: approval_policy
      )

    resource_projection_report =
      resource_projection_report(selected_activities, campaign, approval_policy)

    resource_projection_flow_summary =
      resource_projection_flow_summary(resource_projection_report)

    timeline_activity_precondition_summaries =
      timeline_activity_precondition_summaries(selected_activities)

    timeline_integrity_report =
      timeline_integrity_report(selected_activities)

    target_commitments =
      ObjectiveSatisfactionReports.target_commitments(campaign, candidates, selected_activities)

    objective_satisfaction_report =
      ObjectiveSatisfactionReports.report(
        campaign,
        candidates,
        selected_activities,
        ModelLimits.objective_satisfaction_model_limits()
      )

    objective_tradeoff_report =
      ScoreReports.objective_tradeoff_report(
        timelines,
        policy,
        ModelLimits.score_report_model_limits()
      )

    optimizer_contract =
      Optimizer.greedy_timeline_contract(candidates, timelines,
        plan_id: plan_id,
        constraints: constraints,
        scoring_policy: policy
      )

    BuildArtifact.build(result_set, campaign, %{
      generated_at: generated_at,
      plan_id: plan_id,
      activities: selected_activities,
      proposed_contacts: DownlinkActivityNormalization.proposed_contacts(candidates),
      contact_intents: contact_intents,
      contact_filter_report: contact_filter_report,
      resource_filter_report: resource_filter_report,
      station_calendar_report: station_calendar_report,
      contact_contention_report: contact_contention_report,
      contact_contention_resolution_report:
        ContactContention.resolution_report(candidates, contact_contention_report,
          policy: ContactContentionResolutionPolicy.build(campaign)
        ),
      contact_allocation_report: contact_allocation_report,
      link_capacity_report: link_capacity_report,
      resource_projection_report: resource_projection_report,
      resource_projection_flow_summary: resource_projection_flow_summary,
      timeline_activity_precondition_summaries: timeline_activity_precondition_summaries,
      timeline_integrity_report: timeline_integrity_report,
      target_commitments: target_commitments,
      objective_satisfaction_report: objective_satisfaction_report,
      operational_timeline_report: operational_timeline_report(selected_activities),
      candidate_activities: candidates,
      ranked_timelines: timelines,
      optimizer_contract: optimizer_contract,
      constraint_report:
        CampaignLocalConstraint.report(
          candidates,
          timelines,
          constraints,
          resource_projection_report,
          link_capacity_report
        ),
      objective_tradeoff_report: objective_tradeoff_report,
      score_term_report:
        ScoreReports.score_term_report(
          timelines,
          policy,
          ModelLimits.score_report_model_limits()
        ),
      warnings:
        PlanMetadata.warnings(
          campaign,
          candidates,
          timelines,
          result_set,
          resource_filter_report,
          contact_filter_report
        ),
      assumptions: PlanMetadata.assumptions(campaign),
      provenance: PlanMetadata.provenance(result_set),
      ranking_explanation: PlanMetadata.ranking_explanation(policy),
      approval_policy: approval_policy
    })
  end

  defp apply_station_calendar(candidates, campaign) do
    station_calendar = ValueEncoding.get_key(campaign, "ground_network") || []
    approval_policy = Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)

    StationCalendar.overlay_contacts(candidates, station_calendar,
      source: "campaign.ground_network",
      approval_policy: approval_policy
    )
  end

  defp apply_resource_filters(candidates, campaign) do
    summaries =
      campaign
      |> Map.get("resource_summaries", [])
      |> List.wrap()
      |> Enum.map(&ValueEncoding.stringify_keys/1)

    if summaries == [] do
      {candidates, nil}
    else
      ResourceFilter.filter_candidates(candidates, summaries,
        policy:
          campaign
          |> Map.get("resource_filter_policy", %{})
          |> ResourceFilter.resource_filter_policy(),
        approval_policy:
          Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
      )
    end
  end

  defp apply_contact_filters(candidates, campaign) do
    ContactFilter.filter_candidates(candidates, Map.get(campaign, "ground_network", []),
      approval_policy: Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    )
  end

  defp contact_allocation_report(candidates, campaign) do
    ContactAllocation.report(candidates, Map.get(campaign, "ground_network", []),
      source: "campaign_plan.candidate_activities",
      policy: ContactContentionResolutionPolicy.build(campaign),
      approval_policy: Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    )
  end

  defp link_capacity_policy(campaign, policy) do
    policy = ValueEncoding.stringify_keys(policy || %{})

    case required_downlink_mb(campaign) do
      value when is_number(value) -> Map.put_new(policy, "required_downlink_mb", value)
      _value -> policy
    end
  end

  defp required_downlink_mb(campaign) do
    campaign
    |> DownlinkObjectiveRequirements.objectives()
    |> Enum.map(&DownlinkObjectiveRequirements.required_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp resource_projection_report(activities, campaign, approval_policy) do
    summaries = Map.get(campaign, "resource_summaries", [])

    case summaries do
      [] ->
        nil

      _summaries ->
        ResourceProjection.report(activities, summaries,
          model: "thin_campaign_selected_activity_resource_projection",
          source: "campaign.resource_summaries",
          approval_policy: approval_policy
        )
    end
  end

  defp resource_projection_flow_summary(nil), do: nil

  defp resource_projection_flow_summary(%{} = report) do
    ResourceProjection.flow_summary(report)
  end

  defp timeline_activity_precondition_summaries(selected_activities) do
    selected_activities
    |> Enum.map(&Timeline.activity_precondition_summary/1)
    |> Enum.map(&Map.put(&1, "source", "campaign_plan.activities"))
  end

  defp timeline_integrity_report(selected_activities) do
    Timeline.integrity_report(selected_activities,
      source: "campaign_plan.activities",
      validate_missing_dependencies?: false
    )
  end

  defp operational_timeline_report(selected_activities) do
    Timeline.operational_report(selected_activities,
      source: "campaign_plan.activities",
      source_assumption: "selected campaign_plan.activities"
    )
  end

  defp policy_count_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> max(trunc(value), 0)
      _value -> default
    end
  end

  defp candidate_score(candidate) do
    ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0
  end

  defp plan_id(study_id, generated_at) do
    "campaign_plan:" <>
      ValueEncoding.encode_value(study_id) <> ":" <> DateTime.to_iso8601(generated_at)
  end
end
