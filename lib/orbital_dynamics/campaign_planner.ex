defmodule OrbitalDynamics.CampaignPlanner do
  @moduledoc """
  Deterministic campaign planner for LEO constellation studies.

  The planner consumes propagated event products and emits a compact,
  reproducible plan artifact. V1 deliberately uses transparent greedy timeline
  selection over candidate observation and contact windows instead of hidden
  optimization machinery.

  V2 adds a rolling repair pass over a prior campaign artifact. It compares the
  prior plan against realized operations, preserves approved or executed work
  where policy allows, and repairs the remaining horizon from the prior
  candidate windows.

  V3 compares explicit future branches from a common mission-state snapshot,
  reuses V2 repair inside each branch, and recommends a strategy with
  campaign-level tradeoffs and approval boundaries.
  """

  alias OrbitalDynamics.Communications.{
    ContactContention,
    ContactAllocation,
    ContactFilter,
    ContactIntent,
    LinkCapacity,
    StationCalendar
  }

  alias OrbitalDynamics.Constraints.CampaignLocal, as: CampaignLocalConstraint
  alias OrbitalDynamics.Study.Manifest

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityCandidate,
    ActivityIdentity,
    ActivityTiming,
    ApprovalPolicy,
    BranchCollection,
    BranchCandidatePlan,
    BranchEventApplication,
    BranchEventNormalizer,
    BranchComparisonReport,
    BranchCandidateRefresh,
    BranchApprovalRequirements,
    BranchGenerationPolicy,
    BranchRefreshAcceptedState,
    BranchRefreshGroundNetwork,
    BranchRefreshTargets,
    BuildArtifact,
    CadenceImportPressureBranches,
    CollectionLatencyBranches,
    CollectionLatencySatisfaction,
    DerivedBranchCollection,
    DerivedActivityPressureBranches,
    DerivedContactPressureBranches,
    DerivedDegradedSpacecraftBranches,
    DerivedGroundNetworkBranches,
    DerivedObjectivePressureBranches,
    DerivedOperationalReviewPressureBranches,
    DerivedReviewReadinessPressureBranches,
    DerivedResourcePressureBranches,
    DerivedTimelinePressureBranches,
    CandidateRefreshNormalization,
    CandidateRefreshRequest,
    CandidateRefreshOperationalFeedback,
    DownlinkActivityNormalization,
    DownlinkConstrainedBranches,
    DownlinkObjectiveRequirements,
    FuelPreservationBranches,
    LinkCapacityPressureBranches,
    LinkCapacitySourceReports,
    MissionStateNormalization,
    ModelLimits,
    ObjectiveSatisfactionReports,
    OperationalFeedbackAggregation,
    OperationalFeedbackBranches,
    OperationalFeedbackNormalization,
    OperationalFeedbackProvenance,
    PlanBranch,
    PlanMetadata,
    PriorityCommitmentSatisfaction,
    RealizedActivitiesOperationalFeedback,
    RequestIO,
    RepairActivityDispatch,
    RepairArtifact,
    RepairCandidateDiff,
    RepairCandidateInputs,
    RepairManeuverTransitions,
    RepairMetadata,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairScoreTerms,
    RepairSourceReports,
    RepairTimelineSummary,
    ReplanRequest,
    ScalarValues,
    ScoreReports,
    StationSourceReports,
    StationCalendarPressureBranches,
    StationReservationPressureReports,
    StrategicScoreTerms,
    StrategyBranchNormalization,
    StrategyPolicyNormalization,
    StrategyRiskIndicators,
    TargetObjectiveBranches,
    StrategyArtifact,
    StrategyCandidateSource,
    StrategyFeedbackAdjustments,
    StrategyMetrics,
    StrategyPriorPlanCandidates,
    StrategyRecommendationBuilder,
    StrategyReport,
    StrategyResourceImpacts,
    TimelineRanking,
    ValueEncoding
  }

  alias OrbitalDynamics.{
    CandidateRefresh,
    CadenceImport,
    Optimizer,
    OperatorReview,
    Policy,
    ResultSet,
    ResourceFilter,
    ResourceProjection,
    StudyRunner,
    Timeline,
    TimelineFeedback
  }

  @strategy_schema_version 3
  @doc """
  Returns the declared model limits for score explanation reports.
  """
  def score_report_model_limits, do: ModelLimits.score_report_model_limits()

  @doc """
  Returns the declared model limits for objective satisfaction reports.
  """
  def objective_satisfaction_model_limits, do: ModelLimits.objective_satisfaction_model_limits()

  @doc """
  Returns the declared model limits for branch comparison reports.
  """
  def branch_comparison_model_limits, do: ModelLimits.branch_comparison_model_limits()

  @doc """
  Returns the declared model limits for realized state snapshot reports.
  """
  def realized_state_snapshot_model_limits, do: ModelLimits.realized_state_snapshot_model_limits()

  @doc """
  Builds a campaign-plan artifact from a completed result set.
  """
  def build(%ResultSet{} = result_set, opts \\ []) do
    campaign = Keyword.fetch!(opts, :campaign)
    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)
    policy = Map.get(campaign, "scoring_policy", %{})
    constraints = Map.get(campaign, "constraints", %{})

    sorted_candidates =
      result_set.event_results
      |> candidate_activities(campaign, constraints, policy)
      |> Enum.sort_by(&{&1["scenario_id"], &1["starts_at_s"], &1["id"]})

    {calendar_candidates, station_calendar_report} =
      apply_station_calendar(sorted_candidates, campaign)

    {resource_candidates, resource_filter_report} =
      apply_campaign_resource_filters(calendar_candidates, campaign)

    {contact_candidates, contact_filter_report} =
      apply_campaign_contact_filters(resource_candidates, campaign)

    {candidates, contact_contention_report} = annotate_contact_contention(contact_candidates)
    contact_allocation_report = contact_allocation_report(candidates, campaign)

    timelines =
      candidates
      |> Enum.group_by(& &1["scenario_id"])
      |> Enum.map(fn {scenario_id, scenario_candidates} ->
        ranked_timeline(scenario_id, scenario_candidates, constraints, policy, campaign)
      end)
      |> Enum.sort_by(&{-candidate_score(&1), &1["scenario_id"]})
      |> Enum.take(policy_count_value(policy, "rank_limit", 10))

    best_timeline = List.first(timelines)
    selected_activities = if best_timeline, do: best_timeline["activities"], else: []
    approval_policy = Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    contact_intents = ContactIntent.from_activities(candidates, approval_policy: approval_policy)
    plan_id = plan_id(result_set.study_id, generated_at)

    link_capacity_report =
      link_capacity_report(
        candidates,
        selected_activities,
        campaign_link_capacity_policy(campaign, policy),
        "campaign_plan.candidate_activities",
        approval_policy
      )

    resource_projection_report =
      campaign_resource_projection_report(selected_activities, campaign)

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
        contact_contention_resolution_report(candidates, contact_contention_report, campaign),
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
        campaign_constraint_report(
          candidates,
          timelines,
          constraints,
          resource_projection_report,
          link_capacity_report
        ),
      objective_tradeoff_report: objective_tradeoff_report,
      score_term_report: score_term_report(timelines, policy),
      warnings:
        warnings(
          campaign,
          candidates,
          timelines,
          result_set,
          resource_filter_report,
          contact_filter_report
        ),
      assumptions: assumptions(campaign),
      provenance: provenance(result_set),
      ranking_explanation: ranking_explanation(policy),
      approval_policy: approval_policy
    })
  end

  @doc """
  Repairs a prior campaign plan against realized operations.

  The request may be a `%ReplanRequest{}` or a map with string or atom keys:

    * `prior_plan` / `"prior_plan"` - V1 campaign plan artifact.
    * `realized_state` / `"realized_state"` - realized activities plus optional
      spacecraft degraded-mode inputs.
    * `current_epoch_s` / `"current_epoch_s"` - repair epoch in seconds since
      the source plan epoch.
    * `remaining_horizon` / `"remaining_horizon"` - optional map containing
      `starts_at_s` and `ends_at_s`.
    * `constraints`, `scoring_policy`, `repair_policy`, and `approval_policy`
      override source plan defaults for the repair pass.
    * `candidate_refresh_request` / `"candidate_refresh_request"` - optional
      executable refresh manifest. When present and no prebuilt
      `candidate_refresh` is supplied, repair runs the refresh before selecting
      replacement candidates.
    * `ground_network` / `"ground_network"` or `station_calendar` /
      `"station_calendar"` - optional repair-time station availability and
      capacity intervals that annotate source contact candidates.
  """
  def repair(%ReplanRequest{} = request) do
    request
    |> normalize_replan_request()
    |> do_repair()
  end

  def repair(%{} = request) do
    request
    |> replan_request_from_map()
    |> repair()
  end

  def repair!(request) do
    case repair(request) do
      %{} = artifact -> artifact
    end
  end

  @doc """
  Loads a JSON V2 repair request file and returns a repair artifact.

  The request may contain either an inline `prior_plan` or a `source_plan_ref`
  object with `path` and optional `artifact_key`. Relative source paths are
  resolved from the current working directory first, then relative to the
  request file directory. This keeps checked-in example requests executable
  while preserving the artifact-only boundary.
  """
  def repair_from_file!(path, opts \\ []) when is_binary(path) do
    path
    |> RequestIO.load_json_request!()
    |> RequestIO.put_referenced_prior_plan!(path, opts)
    |> repair!()
  end

  @doc """
  Compares explicit future branches and returns a V3 strategy artifact.

  The strategy layer reuses V2 repair inside every branch. Branch events alter
  the prior plan, realized state, and policy inputs before repair; branch
  scoring then compares mission value, risk, approvals, schedule stability,
  downlink completion, fuel preservation, and asset balance.
  """
  def strategy(%{} = request) do
    request
    |> normalize_strategy_request()
    |> do_strategy()
  end

  def strategy!(request), do: strategy(request)

  @doc """
  Loads a JSON V3 strategy request file and returns a strategy artifact.

  The request may contain either an inline `prior_plan` or a `source_plan_ref`
  object with `path` and optional `artifact_key`. Relative source paths are
  resolved from the current working directory first, then relative to the
  request file directory.
  """
  def strategy_from_file!(path, opts \\ []) when is_binary(path) do
    path
    |> RequestIO.load_json_request!()
    |> RequestIO.put_referenced_prior_plan!(path, opts)
    |> strategy!()
  end

  @doc """
  Validates a JSON campaign repair or strategy request without running planning.

  The report checks the request file can be read and decoded as an object, that
  it matches the requested type when `request_type` is present, and that the
  prior campaign plan can be resolved either inline or through `source_plan_ref`.
  It intentionally does not run V2 repair, V3 strategy, candidate refresh, or
  write output artifacts.
  """
  def request_validation_report(type, path, opts \\ [])

  def request_validation_report(type, path, opts) when is_binary(path) do
    RequestIO.validation_report(type, path, opts)
  end

  defp replan_request_from_map(request) do
    %ReplanRequest{
      prior_plan:
        ValueEncoding.get_key(request, :prior_plan) ||
          ValueEncoding.get_key(request, :campaign_plan) ||
          ValueEncoding.get_key(request, :source_plan),
      mission_state: ValueEncoding.get_key(request, :mission_state),
      realized_state: ValueEncoding.get_key(request, :realized_state) || %{},
      current_epoch_s: ValueEncoding.get_key(request, :current_epoch_s),
      remaining_horizon: ValueEncoding.get_key(request, :remaining_horizon),
      constraints: ValueEncoding.get_key(request, :constraints),
      scoring_policy: ValueEncoding.get_key(request, :scoring_policy),
      repair_policy: ValueEncoding.get_key(request, :repair_policy),
      approval_policy: ValueEncoding.get_key(request, :approval_policy),
      candidate_refresh:
        ValueEncoding.get_key(request, :candidate_refresh) ||
          ValueEncoding.get_key(request, :refreshed_candidates),
      candidate_refresh_request:
        ValueEncoding.get_key(request, :candidate_refresh_request) ||
          ValueEncoding.get_key(request, :refresh_request),
      ground_network:
        ValueEncoding.get_key(request, :ground_network) ||
          ValueEncoding.get_key(request, :station_calendar),
      generated_at: ValueEncoding.get_key(request, :generated_at),
      metadata: ValueEncoding.get_key(request, :metadata) || %{}
    }
  end

  defp normalize_replan_request(%ReplanRequest{} = request) do
    prior_plan = ValueEncoding.stringify_keys(request.prior_plan || %{})
    mission_state = normalize_repair_mission_state(request.mission_state)
    realized_state = RepairRealizedState.normalize(request.realized_state || %{})
    current_epoch_s = ScalarValues.numeric!(request.current_epoch_s, "current_epoch_s")

    remaining_horizon =
      ActivityTiming.remaining_horizon(prior_plan, request.remaining_horizon, current_epoch_s)

    generated_at = normalize_generated_at(request.generated_at || DateTime.utc_now())

    candidate_refresh_request =
      CandidateRefreshNormalization.request(request.candidate_refresh_request)
      |> inherit_candidate_refresh_approval_policy(request.approval_policy)
      |> inherit_candidate_refresh_mission_state(mission_state, prior_plan)

    prebuilt_candidate_refresh = CandidateRefreshNormalization.artifact(request.candidate_refresh)

    candidate_refresh =
      prebuilt_candidate_refresh ||
        execute_repair_candidate_refresh_request(
          prior_plan,
          current_epoch_s,
          candidate_refresh_request,
          generated_at
        )

    scoring_policy =
      prior_plan
      |> ValueEncoding.get_key("ranking_explanation")
      |> case do
        %{} = explanation -> ValueEncoding.get_key(explanation, "policy") || %{}
        _explanation -> %{}
      end
      |> Map.merge(ValueEncoding.stringify_keys(request.scoring_policy || %{}))

    repair_policy = RepairPolicySemantics.normalize(request.repair_policy || %{})
    approval_policy = StrategyPolicyNormalization.approval(request.approval_policy || %{})
    ground_network = normalize_repair_ground_network(request.ground_network)

    %{
      prior_plan: prior_plan,
      mission_state: mission_state,
      realized_state: realized_state,
      current_epoch_s: current_epoch_s,
      remaining_horizon: remaining_horizon,
      constraints:
        Map.merge(
          ValueEncoding.stringify_keys(ValueEncoding.get_key(prior_plan, "assumptions") || %{})
          |> ValueEncoding.get_key("constraints") ||
            %{},
          ValueEncoding.stringify_keys(request.constraints || %{})
        ),
      scoring_policy:
        scoring_policy
        |> Map.put_new("schedule_churn_cost_weight", repair_policy.schedule_churn_cost_weight)
        |> Map.put_new("schedule_move_cost_weight", repair_policy.schedule_move_cost_weight),
      repair_policy: repair_policy,
      approval_policy: approval_policy,
      candidate_refresh: candidate_refresh,
      candidate_refresh_request: candidate_refresh_request,
      candidate_source:
        repair_candidate_source(
          prior_plan,
          candidate_refresh,
          candidate_refresh_request
        ),
      ground_network: ground_network,
      generated_at: generated_at,
      metadata: ValueEncoding.stringify_keys(request.metadata || %{})
    }
  end

  defp normalize_repair_mission_state(nil), do: %{"objectives" => []}

  defp normalize_repair_mission_state(%{} = mission_state),
    do: normalize_mission_state(mission_state)

  defp do_repair(%{} = request) do
    prior_plan = request.prior_plan

    planned_activities =
      prior_plan
      |> Map.get("activities", [])
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Enum.map(&DownlinkActivityNormalization.normalize/1)

    source_candidates = repair_candidates(prior_plan, request.candidate_refresh)

    {candidates, station_calendar_report} =
      apply_repair_station_calendar(source_candidates, request)

    realized_by_id = RepairRealizedState.activities_by_id(request.realized_state)
    degraded_modes = degraded_modes_by_scenario(request.realized_state, request.repair_policy)
    selected_activity_ids = selected_activity_ids(planned_activities)
    rejected_replacement_candidate_ids = repair_rejected_candidate_ids(request)

    initial = %{
      activities: [],
      deltas: [],
      approval_requirements: [],
      warnings: [],
      used_replacement_ids: MapSet.new(),
      delayed_maneuvers: []
    }

    repaired =
      planned_activities
      |> Enum.sort_by(&{ActivityTiming.activity_start(&1), ActivityIdentity.activity_id(&1)})
      |> Enum.reduce(initial, fn activity, acc ->
        RepairActivityDispatch.repair(activity, acc, %{
          candidates: candidates,
          current_epoch_s: request.current_epoch_s,
          remaining_horizon: request.remaining_horizon,
          realized_by_id: realized_by_id,
          degraded_modes: degraded_modes,
          rejected_replacement_candidate_ids: rejected_replacement_candidate_ids,
          selected_activity_ids: selected_activity_ids,
          repair_policy: request.repair_policy,
          scoring_policy: request.scoring_policy,
          candidate_diff_replacements:
            repair_candidate_diff_replacements(request.candidate_refresh)
        })
      end)
      |> RepairManeuverTransitions.mark_downstream_effects()

    activities =
      Enum.sort_by(
        repaired.activities,
        &{ActivityTiming.activity_start(&1), ActivityIdentity.activity_id(&1)}
      )

    deltas = Enum.sort_by(repaired.deltas, &{&1.activity_id, &1.status})
    approval_requirements = Enum.sort_by(repaired.approval_requirements, & &1["activity_id"])

    {approval_status, approval_requirements, approval_rule_matches, policy_decision} =
      repair_approval_decision(approval_requirements, request.approval_policy)

    warnings =
      repaired.warnings
      |> Kernel.++(repair_refresh_warnings(request.candidate_refresh))
      |> Enum.uniq()
      |> Enum.sort()

    source_resource_summaries = repair_resource_summaries(request.candidate_refresh)

    source_resource_projection_report =
      repair_resource_projection_report(
        activities,
        source_resource_summaries,
        StrategyPolicyNormalization.approval_to_map(request.approval_policy)
      )

    score_terms =
      repair_score_terms(
        activities,
        deltas,
        source_resource_projection_report,
        repair_contact_filter_report(request.candidate_refresh),
        repair_contact_allocation_report(request.candidate_refresh),
        repair_resource_filter_report(request.candidate_refresh),
        repair_refresh_budget_report(request.candidate_refresh),
        repair_candidate_rejection_report(request),
        repair_operational_readiness_report(request.candidate_refresh),
        repair_quality_gate_report(request.candidate_refresh),
        request.scoring_policy
      )

    score = score(score_terms)
    repair_score_timeline = repair_score_timeline(prior_plan, activities, score_terms, score)

    source_timeline_feedback_report =
      repair_timeline_feedback_report(planned_activities, request.realized_state)

    link_capacity_report =
      link_capacity_report(
        activities,
        activities,
        repair_link_capacity_policy(request),
        "campaign_repair.activities",
        request.approval_policy
      )

    timeline_protection = timeline_protection_summary(activities, deltas)

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
      station_calendar_report: station_calendar_report,
      timeline_protection: timeline_protection,
      timeline_transition_application_report: timeline_transition_application_report
    })
  end

  defp normalize_strategy_request(request) do
    prior_plan =
      ValueEncoding.get_key(request, :prior_plan) ||
        ValueEncoding.get_key(request, :campaign_plan) ||
        ValueEncoding.get_key(request, :source_plan)

    prior_plan = normalize_strategy_prior_plan(prior_plan)

    current_epoch_s =
      ScalarValues.numeric!(ValueEncoding.get_key(request, :current_epoch_s), "current_epoch_s")

    mission_state =
      request
      |> ValueEncoding.get_key(:mission_state)
      |> normalize_mission_state()

    branches =
      request
      |> ValueEncoding.get_key(:branches)
      |> normalize_strategy_branches()

    branch_generation_policy =
      request
      |> branch_generation_policy()

    candidate_refresh =
      CandidateRefreshNormalization.artifact(
        ValueEncoding.get_key(request, :candidate_refresh) ||
          ValueEncoding.get_key(request, :refreshed_candidates)
      )

    explicit_operational_feedback = ValueEncoding.get_key(request, :operational_feedback)
    prior_operational_feedback = OperationalFeedbackAggregation.prior_plan(prior_plan)

    candidate_refresh_operational_feedback =
      CandidateRefreshOperationalFeedback.feedback(candidate_refresh)

    realized_activities_operational_feedback =
      RealizedActivitiesOperationalFeedback.feedback(mission_state, prior_plan)

    mission_state_operational_feedback =
      OperationalFeedbackAggregation.mission_state(
        mission_state,
        prior_plan,
        realized_activities_operational_feedback
      )

    operational_feedback =
      prior_operational_feedback
      |> OperationalFeedbackNormalization.merge(mission_state_operational_feedback)
      |> OperationalFeedbackNormalization.merge(candidate_refresh_operational_feedback)
      |> OperationalFeedbackNormalization.merge(
        OperationalFeedbackNormalization.normalize(explicit_operational_feedback)
      )

    operational_feedback_provenance =
      strategy_operational_feedback_provenance(
        prior_plan,
        mission_state,
        candidate_refresh,
        explicit_operational_feedback,
        realized_activities_operational_feedback,
        operational_feedback
      )

    branches =
      branches
      |> maybe_add_derived_branches(
        prior_plan,
        mission_state,
        operational_feedback,
        operational_feedback_provenance,
        branch_generation_policy
      )

    strategic_policy =
      request
      |> ValueEncoding.get_key(:strategy_policy)
      |> StrategyPolicyNormalization.strategy()

    approval_policy =
      request
      |> ValueEncoding.get_key(:approval_policy)
      |> StrategyPolicyNormalization.approval()

    raw_approval_policy = ValueEncoding.get_key(request, :approval_policy)
    approval_policy_supplied? = not is_nil(raw_approval_policy)

    repair_policy =
      request
      |> ValueEncoding.get_key(:repair_policy)
      |> RepairPolicySemantics.normalize()

    %{
      prior_plan: prior_plan,
      mission_state: mission_state,
      realized_state:
        RepairRealizedState.normalize(ValueEncoding.get_key(request, :realized_state) || %{}),
      current_epoch_s: current_epoch_s,
      remaining_horizon:
        ActivityTiming.remaining_horizon(
          prior_plan,
          ValueEncoding.get_key(request, :remaining_horizon) ||
            Map.get(mission_state, "remaining_horizon"),
          current_epoch_s
        ),
      branches: branches,
      branch_generation_policy: branch_generation_policy,
      strategy_policy: strategic_policy,
      approval_policy: approval_policy,
      approval_policy_source: ValueEncoding.stringify_keys(raw_approval_policy || %{}),
      approval_policy_supplied?: approval_policy_supplied?,
      repair_policy: repair_policy,
      scoring_policy:
        ValueEncoding.stringify_keys(ValueEncoding.get_key(request, :scoring_policy) || %{}),
      candidate_refresh: candidate_refresh,
      operational_feedback: operational_feedback,
      operational_feedback_provenance: operational_feedback_provenance,
      generated_at:
        normalize_generated_at(
          ValueEncoding.get_key(request, :generated_at) || DateTime.utc_now()
        ),
      metadata: ValueEncoding.stringify_keys(ValueEncoding.get_key(request, :metadata) || %{})
    }
  end

  defp do_strategy(%{branches: branches} = request) do
    cond do
      length(branches) < 2 ->
        raise ArgumentError,
              "V3 strategy requires a baseline branch and at least one what-if branch"

      not Enum.any?(branches, &(&1["id"] == "baseline")) ->
        raise ArgumentError,
              "V3 strategy requires a baseline branch and at least one what-if branch"

      true ->
        do_strategy_with_baseline(request)
    end
  end

  defp do_strategy_with_baseline(%{} = request) do
    input_order_branches =
      request.branches
      |> Enum.map(&evaluate_branch(&1, request))

    branches =
      input_order_branches
      |> Enum.sort_by(&{-&1.score, &1.id})

    recommendation = strategy_recommendation(branches, request.approval_policy)
    source_plan_id = source_plan_id(request.prior_plan)

    branch_comparison =
      BranchComparisonReport.report(
        branches,
        recommendation,
        ModelLimits.branch_comparison_model_limits()
      )

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
      @strategy_schema_version
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

  defp evaluate_branch(branch, request) do
    prior_plan = BranchEventApplication.apply_plan(request.prior_plan, branch)

    candidate_refresh_request =
      BranchCandidateRefresh.request(branch, request, &BranchCandidateRefresh.derive/2)

    candidate_refresh =
      BranchCandidateRefresh.refresh(
        branch,
        request,
        candidate_refresh_request,
        source_plan_id(request.prior_plan)
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
      repair(%ReplanRequest{
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
      branch_resource_projection_report(
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

    objective_satisfaction = branch_objective_satisfaction(candidate_plan, request)
    feasibility_summary = branch_feasibility_summary(candidate_plan)

    candidate_source =
      StrategyCandidateSource.branch_source(
        branch,
        request,
        repair_result,
        &BranchCandidateRefresh.derive/2
      )

    risk_indicators =
      branch_risk_indicators(
        branch,
        repair_result,
        candidate_plan,
        request,
        resource_impacts,
        resource_projection_report,
        feedback_adjustments,
        candidate_source
      )

    approval_requirements = branch_approval_requirements(repair_result, candidate_plan)

    {approval_status, approval_requirements, approval_rule_matches, policy_decision} =
      approval_decision(
        approval_requirements,
        risk_indicators,
        branch,
        candidate_plan,
        request.approval_policy
      )

    score_terms =
      strategic_score_terms(
        candidate_plan,
        repair_result,
        risk_indicators,
        branch,
        request,
        resource_impacts,
        feedback_adjustments
      )

    score = Map.get(score_terms, "expected_score", 0.0)

    warnings =
      (Map.get(repair_result, "warnings", []) ++
         candidate_warnings ++
         branch_event_warnings(branch) ++
         Map.get(resource_impacts, "warnings", []))
      |> Enum.uniq()
      |> Enum.sort()

    %PlanBranch{
      id: branch["id"],
      label: branch["label"],
      probability: branch["probability"],
      events: branch["events"],
      candidate_plan: candidate_plan,
      repair_result: repair_result,
      score: score,
      score_terms: score_terms,
      warnings: warnings,
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
      assumptions:
        branch_assumptions(
          branch,
          request,
          repair_policy,
          scoring_policy,
          candidate_source
        ),
      provenance:
        branch_provenance(
          request.prior_plan,
          branch,
          candidate_source
        ),
      tradeoffs: []
    }
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

  defp strategic_score_terms(
         candidate_plan,
         repair_result,
         risk_indicators,
         branch,
         request,
         resource_impacts,
         feedback_adjustments
       ) do
    StrategicScoreTerms.build(
      candidate_plan,
      repair_result,
      risk_indicators,
      branch,
      request,
      resource_impacts,
      feedback_adjustments
    )
  end

  defp branch_risk_indicators(
         branch,
         repair_result,
         candidate_plan,
         request,
         resource_impacts,
         resource_projection_report,
         feedback_adjustments,
         candidate_source
       ) do
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
  end

  defp branch_approval_requirements(repair_result, candidate_plan) do
    BranchApprovalRequirements.build(repair_result, candidate_plan)
  end

  defp approval_decision(
         approval_requirements,
         risk_indicators,
         branch,
         candidate_plan,
         %ApprovalPolicy{} = policy
       ) do
    Policy.decide(
      approval_requirements,
      risk_indicators,
      branch,
      candidate_plan,
      StrategyPolicyNormalization.approval_to_map(policy)
    )
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

  defp strategy_recommendation(branches, _approval_policy) do
    StrategyRecommendationBuilder.build(branches)
  end

  defp normalize_strategy_prior_plan(prior_plan) do
    StrategyPriorPlanCandidates.normalize(prior_plan)
  end

  defp normalize_mission_state(state) do
    MissionStateNormalization.normalize(state)
  end

  defp branch_generation_policy(request), do: BranchGenerationPolicy.build(request)

  defp maybe_add_derived_branches(
         branches,
         _prior_plan,
         _mission_state,
         _operational_feedback,
         _operational_feedback_provenance,
         %{
           "derive_branches" => false
         }
       ),
       do: branches

  defp maybe_add_derived_branches(
         branches,
         prior_plan,
         mission_state,
         operational_feedback,
         operational_feedback_provenance,
         policy
       ) do
    individual_derived =
      []
      |> Kernel.++(derived_degraded_spacecraft_branches(mission_state))
      |> Kernel.++(derived_ground_network_branches(mission_state, prior_plan))
      |> Kernel.++(derived_station_calendar_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_station_calendar_pressure_branches(mission_state))
      |> Kernel.++(
        derived_mission_state_station_reservation_review_summary_pressure_branches(mission_state)
      )
      |> Kernel.++(
        derived_mission_state_station_reservation_hold_pressure_branches(mission_state)
      )
      |> Kernel.++(
        derived_operational_feedback_branches(
          mission_state,
          prior_plan,
          operational_feedback,
          operational_feedback_provenance,
          policy
        )
      )
      |> Kernel.++(DerivedResourcePressureBranches.build(prior_plan, mission_state, policy))
      |> Kernel.++(DerivedContactPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(DerivedReviewReadinessPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(derived_link_capacity_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_link_capacity_pressure_branches(mission_state))
      |> Kernel.++(DerivedObjectivePressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(DerivedTimelinePressureBranches.build(prior_plan, mission_state, policy))
      |> Kernel.++(DerivedActivityPressureBranches.build(prior_plan, mission_state))
      |> Kernel.++(
        DerivedOperationalReviewPressureBranches.build(prior_plan, mission_state, policy)
      )
      |> Kernel.++(CadenceImportPressureBranches.from_prior_plan(prior_plan, policy))
      |> Kernel.++(CadenceImportPressureBranches.from_mission_state(mission_state, policy))
      |> Kernel.++(derived_fuel_preservation_branches(mission_state, policy))
      |> Kernel.++(derived_urgent_target_branches(mission_state, prior_plan, policy))
      |> Kernel.++(derived_collection_latency_branches(mission_state, prior_plan))
      |> Kernel.++(derived_downlink_constrained_branches(mission_state, prior_plan, policy))
      |> BranchCollection.dedupe_contact_intent_pressure()

    DerivedBranchCollection.merge(branches, individual_derived, policy)
  end

  defp derived_degraded_spacecraft_branches(mission_state) do
    DerivedDegradedSpacecraftBranches.build(mission_state)
  end

  defp derived_ground_network_branches(mission_state, prior_plan) do
    DerivedGroundNetworkBranches.build(mission_state, prior_plan)
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end

  defp derived_station_calendar_pressure_branches(prior_plan) do
    prior_plan
    |> StationSourceReports.prior_plan_station_calendar_reports()
    |> StationCalendarPressureBranches.from_reports()
  end

  defp derived_mission_state_station_calendar_pressure_branches(mission_state) do
    mission_state
    |> StationSourceReports.station_calendar_reports()
    |> StationCalendarPressureBranches.from_reports()
  end

  defp derived_mission_state_station_reservation_review_summary_pressure_branches(mission_state) do
    mission_state
    |> StationReservationPressureReports.review_summary_reports()
    |> StationCalendarPressureBranches.from_reports(
      provider_contention_source_path: fn _report, source_path ->
        "#{source_path}.review_rows"
      end
    )
  end

  defp derived_mission_state_station_reservation_hold_pressure_branches(mission_state) do
    mission_state
    |> StationReservationPressureReports.hold_pressure_reports()
    |> StationCalendarPressureBranches.from_reports(
      provider_contention_source_path: fn report, source_path ->
        "#{source_path}.#{report["source_row_collection"] || "review_rows"}"
      end
    )
  end

  defp derived_operational_feedback_branches(
         mission_state,
         prior_plan,
         operational_feedback,
         operational_feedback_provenance,
         policy
       ) do
    OperationalFeedbackBranches.branches(
      mission_state,
      prior_plan,
      operational_feedback,
      operational_feedback_provenance,
      policy
    )
  end

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp policy_count_value(policy, key, default) do
    case numeric_policy_value(policy, key, default) do
      value when is_number(value) -> max(trunc(value), 0)
      _value -> default
    end
  end

  defp derived_fuel_preservation_branches(mission_state, policy) do
    FuelPreservationBranches.build(mission_state, policy)
  end

  defp derived_link_capacity_pressure_branches(prior_plan) do
    prior_plan
    |> LinkCapacitySourceReports.prior_plan_reports()
    |> LinkCapacityPressureBranches.from_reports()
    |> LinkCapacityPressureBranches.disambiguate()
  end

  defp derived_mission_state_link_capacity_pressure_branches(mission_state) do
    mission_state
    |> LinkCapacitySourceReports.reports()
    |> LinkCapacityPressureBranches.from_reports()
    |> LinkCapacityPressureBranches.disambiguate()
  end

  defp derived_urgent_target_branches(mission_state, prior_plan, policy) do
    TargetObjectiveBranches.build(mission_state, prior_plan, policy)
  end

  defp derived_collection_latency_branches(mission_state, prior_plan) do
    CollectionLatencyBranches.build(mission_state, prior_plan)
  end

  defp derived_downlink_constrained_branches(mission_state, prior_plan, policy) do
    DownlinkConstrainedBranches.build(mission_state, prior_plan, policy)
  end

  defp normalize_strategy_branches(branches),
    do: StrategyBranchNormalization.normalize_branches(branches)

  defp strategy_operational_feedback_provenance(
         prior_plan,
         mission_state,
         candidate_refresh,
         explicit_operational_feedback,
         realized_activities_operational_feedback,
         operational_feedback
       ) do
    OperationalFeedbackProvenance.build(
      prior_plan,
      mission_state,
      candidate_refresh,
      explicit_operational_feedback,
      realized_activities_operational_feedback,
      operational_feedback
    )
  end

  defp branch_assumptions(branch, request, repair_policy, scoring_policy, candidate_source) do
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

  defp branch_provenance(prior_plan, branch, candidate_source) do
    %{
      "source_plan_id" => source_plan_id(prior_plan),
      "branch_id" => branch["id"],
      "branch_metadata" => branch["metadata"],
      "candidate_source" => candidate_source
    }
  end

  defp target_count(activities) do
    StrategyMetrics.target_count(activities)
  end

  defp revisit_count(activities) do
    StrategyMetrics.revisit_count(activities)
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(objective)
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp downlink_completion_objectives(mission_state) do
    DownlinkObjectiveRequirements.objectives(mission_state)
  end

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp branch_objective_satisfaction(candidate_plan, request) do
    activities = Map.get(candidate_plan, "activities", [])
    priority_commitments = priority_commitment_satisfaction(request.mission_state, activities)

    %{
      "priority_commitments" => priority_commitments,
      "downlink_completion" =>
        StrategyMetrics.downlink_completion_satisfaction(activities, request),
      "coverage" => %{"observed_target_count" => target_count(activities)},
      "revisit" => %{"revisit_count" => revisit_count(activities)}
    }
    |> maybe_put_collection_latency_satisfaction(activities, request.mission_state)
  end

  defp priority_commitment_satisfaction(mission_state, activities) do
    mission_state
    |> priority_commitment_satisfaction_rows(activities)
    |> PriorityCommitmentSatisfaction.summary_from_rows()
  end

  defp priority_commitment_satisfaction_rows(mission_state, activities) do
    objectives = priority_commitment_objectives(mission_state)

    PriorityCommitmentSatisfaction.rows(objectives, activities)
  end

  defp priority_commitment_objectives(mission_state) do
    PriorityCommitmentSatisfaction.objectives(mission_state)
  end

  defp maybe_put_collection_latency_satisfaction(satisfaction, activities, mission_state) do
    CollectionLatencySatisfaction.put(satisfaction, activities, mission_state)
  end

  defp branch_feasibility_summary(candidate_plan) do
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

  defp candidate_activities(event_results, campaign, constraints, policy) do
    ActivityCandidate.build(
      event_results,
      campaign,
      constraints,
      policy
    )
  end

  defp apply_station_calendar(candidates, campaign),
    do: apply_station_calendar(candidates, campaign, "campaign.ground_network")

  defp apply_station_calendar(candidates, campaign, source) do
    station_calendar = ValueEncoding.get_key(campaign, "ground_network") || []
    approval_policy = Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)

    StationCalendar.overlay_contacts(candidates, station_calendar,
      source: source,
      approval_policy: approval_policy
    )
  end

  defp apply_repair_station_calendar(candidates, %{ground_network: nil}), do: {candidates, nil}

  defp apply_repair_station_calendar(candidates, %{ground_network: ground_network} = request) do
    apply_station_calendar(
      candidates,
      %{
        "ground_network" => ground_network,
        "approval_policy" => Map.get(request, :approval_policy)
      },
      "repair.ground_network"
    )
  end

  defp apply_campaign_resource_filters(candidates, campaign) do
    summaries =
      campaign
      |> Map.get("resource_summaries", [])
      |> List.wrap()
      |> Enum.map(&ValueEncoding.stringify_keys/1)

    if summaries == [] do
      {candidates, nil}
    else
      ResourceFilter.filter_candidates(candidates, summaries,
        policy: campaign_resource_filter_policy(campaign),
        approval_policy:
          Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
      )
    end
  end

  defp campaign_resource_filter_policy(campaign) do
    campaign
    |> Map.get("resource_filter_policy", %{})
    |> ResourceFilter.resource_filter_policy()
  end

  defp apply_campaign_contact_filters(candidates, campaign) do
    ContactFilter.filter_candidates(candidates, Map.get(campaign, "ground_network", []),
      approval_policy: Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    )
  end

  defp annotate_contact_contention(candidates) do
    ContactContention.annotate_contacts(candidates, source: "campaign_plan.candidate_activities")
  end

  defp contact_contention_resolution_report(candidates, contention_report, campaign) do
    ContactContention.resolution_report(candidates, contention_report,
      policy: contact_contention_resolution_policy(campaign)
    )
  end

  defp contact_contention_resolution_policy(campaign) do
    policy =
      campaign
      |> ValueEncoding.get_key("contact_contention_resolution_policy")
      |> case do
        %{} = policy -> ValueEncoding.stringify_keys(policy)
        _policy -> %{}
      end

    Map.merge(
      %{
        "selection_rule" => Map.get(policy, "selection_rule", "highest_score_earliest_start"),
        "tie_breakers" => Map.get(policy, "tie_breakers", ["starts_at_s", "id"]),
        "action" => Map.get(policy, "action", "recommend_preferred_contact_for_operator_review")
      },
      policy
    )
  end

  defp contact_allocation_report(candidates, campaign) do
    ContactAllocation.report(candidates, Map.get(campaign, "ground_network", []),
      source: "campaign_plan.candidate_activities",
      policy: contact_contention_resolution_policy(campaign),
      approval_policy: Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
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

  defp campaign_link_capacity_policy(campaign, policy) do
    policy = ValueEncoding.stringify_keys(policy || %{})

    case campaign_required_downlink_mb(campaign) do
      value when is_number(value) ->
        Map.put_new(policy, "required_downlink_mb", value)

      _value ->
        policy
    end
  end

  defp repair_link_capacity_policy(request) do
    policy = ValueEncoding.stringify_keys(request.scoring_policy || %{})

    request.mission_state
    |> mission_required_downlink_mb()
    |> case do
      value when is_number(value) -> Map.put_new(policy, "required_downlink_mb", value)
      _value -> policy
    end
  end

  defp mission_required_downlink_mb(mission_state) do
    mission_state
    |> downlink_completion_objectives()
    |> Enum.map(&objective_required_downlink_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp operational_timeline_report(selected_activities) do
    Timeline.operational_report(selected_activities,
      source: "campaign_plan.activities",
      source_assumption: "selected campaign_plan.activities"
    )
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

  defp repair_timeline_transition_application_report(planned_activities, repaired_activities) do
    Timeline.transition_application_report(planned_activities, repaired_activities,
      source: "campaign_repair.timeline_transition_application",
      source_assumption: "source campaign activities compared with repaired campaign activities"
    )
  end

  defp campaign_required_downlink_mb(campaign) do
    campaign
    |> downlink_completion_objectives()
    |> Enum.map(&objective_required_downlink_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp ranked_timeline(scenario_id, candidates, constraints, policy, campaign) do
    TimelineRanking.ranked_timeline(
      scenario_id,
      candidates,
      constraints,
      policy,
      campaign
    )
  end

  defp campaign_constraint_report(
         candidates,
         timelines,
         constraints,
         resource_projection_report,
         link_capacity_report
       ) do
    CampaignLocalConstraint.report(
      candidates,
      timelines,
      constraints,
      resource_projection_report,
      link_capacity_report
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
      "scenario_id" => source_plan_id(prior_plan),
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

  defp score_term_report(timelines, policy) do
    ScoreReports.score_term_report(
      timelines,
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

  defp warnings(
         campaign,
         candidates,
         timelines,
         result_set,
         resource_filter_report,
         contact_filter_report
       ) do
    PlanMetadata.warnings(
      campaign,
      candidates,
      timelines,
      result_set,
      resource_filter_report,
      contact_filter_report
    )
  end

  defp assumptions(campaign) do
    PlanMetadata.assumptions(campaign)
  end

  defp provenance(%ResultSet{} = result_set) do
    PlanMetadata.provenance(result_set)
  end

  defp ranking_explanation(policy) do
    PlanMetadata.ranking_explanation(policy)
  end

  defp timeline_protection_summary(activities, deltas) do
    RepairTimelineSummary.protection_summary(activities, deltas)
  end

  defp repair_score_terms(
         activities,
         deltas,
         resource_projection_report,
         contact_filter_report,
         contact_allocation_report,
         resource_filter_report,
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
      contact_filter_report,
      contact_allocation_report,
      resource_filter_report,
      refresh_budget_report,
      candidate_rejection_report,
      operational_readiness_report,
      quality_gate_report,
      scoring_policy
    )
  end

  defp inherit_candidate_refresh_approval_policy(nil, _approval_policy), do: nil

  defp inherit_candidate_refresh_approval_policy(request, nil), do: request

  defp inherit_candidate_refresh_approval_policy(
         %{"candidate_refresh" => %{} = refresh} = request,
         approval_policy
       ) do
    Map.put(
      request,
      "candidate_refresh",
      Map.put_new(refresh, "approval_policy", ValueEncoding.stringify_keys(approval_policy))
    )
  end

  defp inherit_candidate_refresh_approval_policy(%{} = request, approval_policy) do
    Map.put_new(request, "approval_policy", ValueEncoding.stringify_keys(approval_policy))
  end

  defp inherit_candidate_refresh_mission_state(nil, _mission_state, _prior_plan), do: nil

  defp inherit_candidate_refresh_mission_state(request, nil, _prior_plan), do: request

  defp inherit_candidate_refresh_mission_state(
         request,
         %{"objectives" => []} = mission_state,
         _prior_plan
       )
       when map_size(mission_state) == 1,
       do: request

  defp inherit_candidate_refresh_mission_state(
         %{"candidate_refresh" => %{} = refresh} = request,
         mission_state,
         prior_plan
       ) do
    refresh =
      refresh
      |> Map.put_new("mission_state", mission_state)
      |> inherit_candidate_refresh_mission_state_inputs(mission_state, prior_plan)

    Map.put(
      request,
      "candidate_refresh",
      refresh
    )
    |> inherit_candidate_refresh_manifest_inputs(mission_state)
  end

  defp inherit_candidate_refresh_mission_state(%{} = request, mission_state, prior_plan) do
    request
    |> Map.put_new("mission_state", mission_state)
    |> inherit_candidate_refresh_mission_state_inputs(mission_state, prior_plan)
    |> inherit_candidate_refresh_manifest_inputs(mission_state)
  end

  defp inherit_candidate_refresh_mission_state_inputs(refresh, mission_state, prior_plan) do
    operational_feedback = Map.get(refresh, "operational_feedback", %{})

    refresh
    |> put_if_absent(
      "accepted_planning_state",
      BranchRefreshAcceptedState.from_mission_state(mission_state, prior_plan)
    )
    |> put_if_absent(
      "targets",
      BranchRefreshTargets.build(%{"events" => []}, mission_state, operational_feedback)
    )
  end

  defp inherit_candidate_refresh_manifest_inputs(request, mission_state) do
    put_if_absent(
      request,
      "ground_stations",
      BranchRefreshGroundNetwork.ground_stations(mission_state)
    )
  end

  defp execute_repair_candidate_refresh_request(
         _prior_plan,
         _current_epoch_s,
         nil,
         _generated_at
       ),
       do: nil

  defp execute_repair_candidate_refresh_request(
         prior_plan,
         current_epoch_s,
         candidate_refresh_request,
         generated_at
       ) do
    manifest_source =
      candidate_refresh_request
      |> CandidateRefreshRequest.manifest(
        "repair_refresh_#{source_plan_id(prior_plan)}",
        %{
          "repair_source_plan_id" => source_plan_id(prior_plan),
          "repair_current_epoch_s" => current_epoch_s
        }
      )

    with {:ok, manifest} <- Manifest.from_map(manifest_source),
         {:ok, result_set} <- StudyRunner.run(manifest.study, manifest.run_opts) do
      CandidateRefresh.build(result_set,
        candidate_refresh: manifest.study.metadata["candidate_refresh"],
        generated_at: generated_at
      )
    else
      {:error, reason} ->
        raise ArgumentError, "invalid repair candidate_refresh_request: #{inspect(reason)}"
    end
  end

  defp normalize_repair_ground_network(nil), do: nil

  defp normalize_repair_ground_network(ground_network) when is_list(ground_network),
    do: Enum.map(ground_network, &ValueEncoding.stringify_keys/1)

  defp normalize_repair_ground_network(%{} = station_calendar_provider),
    do: StationCalendar.to_ground_network(station_calendar_provider)

  defp normalize_repair_ground_network(_ground_network) do
    raise ArgumentError, "ground_network must be a list or station calendar provider object"
  end

  defp normalize_generated_at(%DateTime{} = generated_at), do: generated_at

  defp normalize_generated_at(generated_at) when is_binary(generated_at) do
    case DateTime.from_iso8601(generated_at) do
      {:ok, datetime, _offset} ->
        datetime

      {:error, reason} ->
        raise ArgumentError, "invalid generated_at: #{inspect(reason)}"
    end
  end

  defp normalize_generated_at(generated_at) do
    raise ArgumentError, "invalid generated_at: #{inspect(generated_at)}"
  end

  defp repair_candidates(prior_plan, nil) do
    RepairCandidateInputs.candidates(prior_plan, nil)
  end

  defp repair_candidates(_prior_plan, %{} = candidate_refresh) do
    RepairCandidateInputs.candidates(nil, candidate_refresh)
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
      policy: contact_contention_resolution_policy(request.scoring_policy),
      approval_policy: request.approval_policy
    )
  end

  defp repair_resource_filter_report(nil), do: nil

  defp repair_resource_filter_report(%{} = candidate_refresh) do
    RepairSourceReports.resource_filter(candidate_refresh)
  end

  defp campaign_resource_projection_report(activities, %{} = campaign) do
    resource_projection_report(
      activities,
      Map.get(campaign, "resource_summaries", []),
      "thin_campaign_selected_activity_resource_projection",
      "campaign.resource_summaries",
      Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
    )
  end

  defp resource_projection_flow_summary(nil), do: nil

  defp resource_projection_flow_summary(%{} = report) do
    ResourceProjection.flow_summary(report)
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

  defp branch_resource_projection_report(candidate_plan, repair_result, approval_policy) do
    activities =
      (Map.get(candidate_plan, "activities", []) ++
         Map.get(candidate_plan, "strategic_additions", []))
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Map.new(&{ActivityIdentity.activity_id(&1), &1})
      |> Map.values()

    resource_projection_report(
      activities,
      Map.get(repair_result, "source_resource_summaries", []),
      "thin_strategy_branch_activity_resource_projection",
      "branch.repair_result.source_resource_summaries",
      approval_policy
    )
  end

  defp resource_projection_report(_activities, [], _model, _source, _approval_policy), do: nil

  defp resource_projection_report(activities, summaries, model, source, approval_policy) do
    ResourceProjection.report(activities, summaries,
      model: model,
      source: source,
      approval_policy: approval_policy
    )
  end

  defp repair_candidate_diff_replacements(nil), do: %{}

  defp repair_candidate_diff_replacements(%{} = candidate_refresh) do
    RepairCandidateDiff.replacements(candidate_refresh)
  end

  defp repair_candidate_rejection_report(%{} = request) do
    RepairSourceReports.candidate_rejection_report(request)
  end

  defp repair_rejected_candidate_ids(%{} = request) do
    RepairSourceReports.rejected_candidate_ids(request)
  end

  defp repair_operational_readiness_report(candidate_refresh) do
    RepairSourceReports.operational_readiness(candidate_refresh)
  end

  defp repair_quality_gate_report(candidate_refresh) do
    RepairSourceReports.quality_gate(candidate_refresh)
  end

  defp repair_refresh_budget_report(nil), do: nil

  defp repair_refresh_budget_report(%{} = candidate_refresh) do
    RepairSourceReports.refresh_budget(candidate_refresh)
  end

  defp repair_refresh_warnings(nil), do: []

  defp repair_refresh_warnings(%{} = candidate_refresh) do
    RepairSourceReports.refresh_warnings(candidate_refresh)
  end

  defp repair_candidate_source(prior_plan, candidate_refresh, candidate_refresh_request)

  defp repair_candidate_source(prior_plan, nil, _candidate_refresh_request) do
    RepairMetadata.candidate_source(prior_plan, nil, nil)
  end

  defp repair_candidate_source(_prior_plan, %{} = candidate_refresh, candidate_refresh_request) do
    RepairMetadata.candidate_source(
      nil,
      candidate_refresh,
      candidate_refresh_request
    )
  end

  defp source_plan_id(prior_plan) do
    RepairMetadata.source_plan_id(prior_plan)
  end

  defp plan_id(study_id, generated_at) do
    "campaign_plan:" <>
      ValueEncoding.encode_value(study_id) <> ":" <> DateTime.to_iso8601(generated_at)
  end

  defp selected_activity_ids(planned_activities) do
    planned_activities
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.map(&ActivityIdentity.activity_id/1)
    |> MapSet.new()
  end

  defp degraded_modes_by_scenario(realized_state, repair_policy) do
    RepairPolicySemantics.degraded_modes_by_scenario(realized_state, repair_policy)
  end

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end
end
