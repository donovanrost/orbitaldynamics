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
    ActivitySourceRows,
    ActivityTiming,
    ApprovalPolicy,
    BranchCollection,
    BranchComparisonReport,
    BranchCandidateRefresh,
    BranchApprovalRequirements,
    BranchGenerationPolicy,
    BranchOperationalFeedback,
    BranchRefreshAcceptedState,
    BranchRefreshGroundNetwork,
    BranchRefreshPolicies,
    BranchRefreshRequestBuilder,
    BranchRefreshRequestOptions,
    BranchRefreshResourceSummaries,
    BranchRefreshSourceInputs,
    BranchRefreshTargets,
    BuildArtifact,
    CadenceImportDirectPressureBranches,
    CadenceImportSourceReports,
    ContactAllocationPressureFanout,
    ContactAllocationReportPressureBranches,
    ContactAllocationSummaryPressureBranches,
    ContactAllocationSourceReports,
    ContactContentionPressureBranches,
    ContactContentionSourceReports,
    ContactFilterPressureBranches,
    ContactFilterSourceReports,
    ContactIntentPressureBranches,
    ContactIntentSourceReports,
    ConstraintPressureBranches,
    CollectionLatencyBranches,
    CollectionLatencySatisfaction,
    DerivedBranchCollection,
    DerivedDegradedSpacecraftBranches,
    DerivedGroundNetworkBranches,
    CandidateDiffMetadata,
    CandidateDiffPressureEvents,
    CandidateRejectionPressureEvents,
    CandidateRefreshNormalization,
    CandidateRefreshRequest,
    CandidateRefreshOperationalFeedback,
    CandidateReviewSourceReports,
    CommandWindowOperationalFeedback,
    CandidateDiffReplacementAddition,
    DownlinkActivityNormalization,
    DownlinkConstrainedBranches,
    DownlinkCompletionStaging,
    DownlinkObjectiveRequirements,
    FuelPreservationBranches,
    LinkCapacityPressureBranches,
    LinkCapacitySourceReports,
    ManeuverReviewOperationalFeedback,
    MissionStateCandidateRefreshSourceReports,
    MissionStateNormalization,
    MissionStateResourceSources,
    MissionStateResourceConstraintBranches,
    ModelLimits,
    ModelAcceptancePressureEvents,
    ModelAcceptanceSourceReports,
    ObjectiveConstraintSourceReports,
    ObjectiveSatisfactionPressureBranches,
    ObjectiveSatisfactionReports,
    ObjectiveTradeoffPressureBranches,
    OperationalFeedbackAggregation,
    OperationalFeedbackBranches,
    OperationalFeedbackNormalization,
    OperationalFeedbackProvenance,
    OperationalTimelinePressureEvents,
    OperationalTimelineSourceRows,
    OperationalReadinessPressureEvents,
    OperationalReadinessSourceReports,
    OperatorReviewSourceReports,
    PlanBranch,
    PlanMetadata,
    PriorActivityContext,
    PriorityCommitmentSatisfaction,
    ProviderCounterofferSourceReports,
    ProviderCounterofferPressureEvents,
    QualityGatePressureEvents,
    QualityGateSourceReports,
    RealizedActivitiesOperationalFeedback,
    RealizedFeedbackPressureEvents,
    RefreshBudgetPressureEvents,
    RequestIO,
    ResourceFilterSourceReports,
    ResourceFilterPressureBranches,
    ResourceProjectionPressureBranches,
    ResourceProjectionSourceReports,
    RefreshSourceReports,
    RepairAccumulator,
    RepairActivityIdentity,
    RepairArtifact,
    RepairCandidateDiff,
    RepairCandidateInputs,
    RepairMetadata,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairReplacementSelection,
    RepairScoreTerms,
    RepairSourceReports,
    RepairTimelineSummary,
    ReplanRequest,
    RefreshFreshnessPressureEvents,
    ReviewRowSources,
    ReviewSourceReports,
    SchemaValidationPressureEvents,
    ScalarValues,
    SchemaValidationSourceReports,
    ScoreReports,
    ScoreTermPressureBranches,
    StationSourceReports,
    StationCalendarPressureBranches,
    StationCalendarReviewRows,
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
    TimelineDiffPressureEvents,
    TimelineDiffPressureEventCallbacks,
    TimelineDiffReviewRows,
    TimelinePressureBranches,
    TimelineSourceReports,
    TimelineRanking,
    UrgentTargetAdditions,
    ValueEncoding,
    ValidationSafetyCasePressureEvents,
    ValidationSafetyCaseSourceReports
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
  @realized_preserved_executed_statuses ~w(completed executed partial)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @terminal_realized_statuses @realized_preserved_executed_statuses ++ @realized_failure_statuses
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
        repair_activity(activity, acc, %{
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
      |> mark_downstream_maneuver_effects(request)

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
    prior_plan = apply_branch_plan_events(request.prior_plan, branch, request)

    candidate_refresh_request =
      BranchCandidateRefresh.request(branch, request, &derive_branch_candidate_refresh_request/2)

    candidate_refresh =
      BranchCandidateRefresh.refresh(
        branch,
        request,
        candidate_refresh_request,
        source_plan_id(request.prior_plan)
      )

    realized_state =
      request.realized_state
      |> merge_realized_state(mission_state_repair_state(request.mission_state))
      |> merge_realized_state(branch["realized_state_overrides"])
      |> apply_branch_realized_events(prior_plan, branch, request)

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

    {candidate_plan, candidate_warnings} = branch_candidate_plan(repair_result, branch, request)

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
        branch_refresh_operational_feedback(branch, request.operational_feedback)
      )

    objective_satisfaction = branch_objective_satisfaction(candidate_plan, request)
    feasibility_summary = branch_feasibility_summary(candidate_plan)

    candidate_source =
      StrategyCandidateSource.branch_source(
        branch,
        request,
        repair_result,
        &derive_branch_candidate_refresh_request/2
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

  defp apply_branch_plan_events(prior_plan, branch, _request) do
    Enum.reduce(branch["events"], prior_plan, fn event, plan ->
      case event["type"] do
        type when type in ["ground_station_outage", "ground_station_reserved"] ->
          update_candidate_activities(plan, fn activities ->
            Enum.reject(activities, &ground_station_event_match?(&1, event))
          end)

        "reduced_downlink_capacity" ->
          update_candidate_activities(plan, fn activities ->
            Enum.map(activities, &apply_downlink_capacity(&1, event))
          end)

        _type ->
          plan
      end
    end)
  end

  defp apply_branch_realized_events(realized_state, prior_plan, branch, _request) do
    Enum.reduce(branch["events"], realized_state, fn event, state ->
      case event["type"] do
        type when type in ["ground_station_outage", "ground_station_reserved"] ->
          prior_plan
          |> PriorActivityContext.activities()
          |> Enum.filter(&ground_station_event_match?(&1, event))
          |> Enum.reduce(state, fn activity, acc ->
            add_realized_activity(
              acc,
              %{
                "id" => ActivityIdentity.activity_id(ValueEncoding.stringify_keys(activity)),
                "status" => "missed",
                "reason" => branch_ground_station_event_reason(type)
              }
              |> Map.merge(branch_ground_station_realized_context(event, type))
            )
          end)

        "degraded_spacecraft" ->
          add_spacecraft_state(state, %{
            "scenario_id" => branch_event_spacecraft_id(event),
            "mode" => degraded_event_mode(event),
            "incompatible_activity_types" =>
              event
              |> degradation_activity_types()
              |> BranchOperationalFeedback.normalize_incompatible_activity_types()
          })

        "missed_maneuver" ->
          add_realized_activity(state, %{
            "id" => event["activity_id"],
            "status" => "missed",
            "reason" => "branch_missed_maneuver"
          })

        "delayed_maneuver" ->
          add_realized_activity(state, %{
            "id" => event["activity_id"],
            "status" => "delayed",
            "actual_starts_at_s" => event["actual_starts_at_s"],
            "actual_ends_at_s" => event["actual_ends_at_s"] || event["actual_starts_at_s"],
            "reason" => "branch_delayed_maneuver"
          })

        _type ->
          state
      end
    end)
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

  defp branch_event_invalid?(event, reason) do
    reason in List.wrap(Map.get(event, "invalid_branch_event_input_reasons", []))
  end

  defp branch_candidate_plan(repair_result, branch, request) do
    source_candidate_activities = Map.get(repair_result, "source_candidate_activities", [])

    candidate_diff_by_replacement_id =
      repair_result
      |> Map.get("source_candidate_diff_report")
      |> candidate_diff_replacements_by_replacement_id()

    initial = %{
      "activities" => Map.get(repair_result, "activities", []),
      "strategic_additions" => [],
      "removed_activity_ids" => [],
      "capacity_adjustments" => []
    }

    Enum.reduce(branch["events"], {initial, []}, fn event, {candidate_plan, warnings} ->
      case event["type"] do
        type
        when type in [
               "urgent_target",
               "observation_success_feedback",
               "target_priority_feedback"
             ] ->
          stage_urgent_target(
            candidate_plan,
            warnings,
            event,
            branch,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "downlink_completion_gap" ->
          stage_downlink_completion(
            candidate_plan,
            warnings,
            event,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "candidate_diff_replacement" ->
          stage_candidate_diff_replacement(
            candidate_plan,
            warnings,
            event,
            request,
            source_candidate_activities,
            candidate_diff_by_replacement_id
          )

        "reduced_downlink_capacity" ->
          if branch_event_invalid?(event, "invalid_capacity_fraction") do
            {candidate_plan, warnings}
          else
            capacity_fraction = ground_network_capacity_fraction(event)

            adjustment = %{
              "type" => "reduced_downlink_capacity",
              "ground_station_id" => event_ground_station_id(event),
              "capacity_fraction" => capacity_fraction,
              "starts_at_s" => event["starts_at_s"],
              "ends_at_s" => event["ends_at_s"]
            }

            {Map.update!(candidate_plan, "capacity_adjustments", &[adjustment | &1]), warnings}
          end

        _type ->
          {candidate_plan, warnings}
      end
    end)
    |> then(fn {candidate_plan, warnings} ->
      {
        candidate_plan
        |> Map.update!(
          "activities",
          &Enum.sort_by(&1, fn activity ->
            {ActivityTiming.activity_start(activity), ActivityIdentity.activity_id(activity)}
          end)
        )
        |> Map.update!(
          "strategic_additions",
          &Enum.sort_by(&1, fn activity -> ActivityIdentity.activity_id(activity) end)
        )
        |> Map.update!("capacity_adjustments", &Enum.reverse/1),
        warnings
      }
    end)
  end

  defp stage_candidate_diff_replacement(
         candidate_plan,
         warnings,
         event,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    replacement_id = event["replacement_candidate_id"]

    replacement =
      (source_candidate_activities ++
         PriorActivityContext.candidate_activities(request.prior_plan))
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> dedupe_by_id()
      |> Enum.find(&(ActivityIdentity.activity_id(&1) == replacement_id))

    cond do
      replacement_id in [nil, ""] ->
        {candidate_plan,
         ["candidate diff replacement not staged: missing replacement id" | warnings]}

      is_nil(replacement) ->
        {candidate_plan,
         [
           "candidate diff replacement #{replacement_id} not staged: no validated replacement candidate"
           | warnings
         ]}

      Enum.any?(
        candidate_plan["activities"],
        &(ActivityIdentity.activity_id(&1) == replacement_id)
      ) ->
        {candidate_plan, warnings}

      Enum.any?(candidate_plan["activities"], &ActivityTiming.overlaps?(replacement, &1)) ->
        {candidate_plan,
         [
           "candidate diff replacement #{replacement_id} not staged: overlaps existing activity"
           | warnings
         ]}

      true ->
        candidate_diff =
          case Map.get(event, "source_candidate_diff") do
            %{} = source ->
              source

            _source ->
              candidate_diff_for_replacement(replacement, candidate_diff_by_replacement_id)
          end

        addition = CandidateDiffReplacementAddition.build(replacement, event, candidate_diff)

        candidate_plan =
          candidate_plan
          |> Map.update!("activities", &([addition] ++ &1))
          |> Map.update!("strategic_additions", &([addition] ++ &1))

        {candidate_plan, warnings}
    end
  end

  defp stage_urgent_target(
         candidate_plan,
         warnings,
         event,
         branch,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    UrgentTargetAdditions.stage(
      candidate_plan,
      warnings,
      event,
      branch,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id
    )
  end

  defp stage_downlink_completion(
         candidate_plan,
         warnings,
         event,
         request,
         source_candidate_activities,
         candidate_diff_by_replacement_id
       ) do
    DownlinkCompletionStaging.stage(
      candidate_plan,
      warnings,
      event,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id
    )
  end

  defp activity_direction(activity),
    do: ScalarValues.normalized_status_token(Map.get(activity, "direction"))

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
      |> Kernel.++(derived_power_constrained_branches(mission_state, policy))
      |> Kernel.++(derived_thermal_constrained_branches(mission_state, policy))
      |> Kernel.++(derived_payload_constrained_branches(mission_state))
      |> Kernel.++(derived_antenna_constrained_branches(mission_state))
      |> Kernel.++(derived_resource_projection_pressure_branches(prior_plan, policy))
      |> Kernel.++(
        derived_mission_state_resource_projection_pressure_branches(mission_state, policy)
      )
      |> Kernel.++(derived_resource_filter_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_resource_filter_pressure_branches(mission_state))
      |> Kernel.++(derived_contact_filter_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_contact_filter_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_contact_contention_pressure_branches(mission_state))
      |> Kernel.++(derived_contact_contention_resolution_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_contact_contention_resolution_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_contact_allocation_pressure_branches(prior_plan))
      |> Kernel.++(derived_contact_allocation_summary_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_contact_allocation_pressure_branches(mission_state))
      |> Kernel.++(
        derived_mission_state_contact_allocation_summary_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_mission_state_candidate_diff_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_candidate_rejection_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_provider_counteroffer_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_schema_validation_pressure_branches(mission_state))
      |> Kernel.++(derived_operational_readiness_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_operational_readiness_pressure_branches(mission_state))
      |> Kernel.++(derived_quality_gate_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_quality_gate_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_model_acceptance_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_validation_safety_case_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_refresh_budget_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_refresh_freshness_pressure_branches(mission_state))
      |> Kernel.++(derived_link_capacity_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_link_capacity_pressure_branches(mission_state))
      |> Kernel.++(derived_score_term_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_score_term_pressure_branches(mission_state))
      |> Kernel.++(derived_objective_satisfaction_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_objective_satisfaction_pressure_branches(mission_state))
      |> Kernel.++(derived_objective_tradeoff_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_objective_tradeoff_pressure_branches(mission_state))
      |> Kernel.++(derived_constraint_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_constraint_pressure_branches(mission_state))
      |> Kernel.++(derived_timeline_integrity_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_timeline_integrity_pressure_branches(mission_state))
      |> Kernel.++(derived_timeline_dependency_impact_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_timeline_dependency_impact_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_timeline_publication_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_timeline_publication_pressure_branches(mission_state))
      |> Kernel.++(derived_timeline_lifecycle_state_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_timeline_lifecycle_state_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_timeline_activity_lifecycle_state_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_timeline_activity_lifecycle_state_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_timeline_activity_precondition_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_timeline_activity_precondition_pressure_branches(mission_state)
      )
      |> Kernel.++(derived_timeline_preservation_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_timeline_preservation_pressure_branches(mission_state))
      |> Kernel.++(derived_timeline_diff_pressure_branches(prior_plan, policy))
      |> Kernel.++(derived_mission_state_timeline_diff_pressure_branches(mission_state, policy))
      |> Kernel.++(derived_planned_activity_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_planned_activity_pressure_branches(mission_state))
      |> Kernel.++(derived_proposed_contact_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_proposed_contact_pressure_branches(mission_state))
      |> Kernel.++(derived_contact_intent_pressure_branches(prior_plan))
      |> Kernel.++(derived_contact_intent_summary_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_contact_intent_pressure_branches(mission_state))
      |> Kernel.++(derived_mission_state_contact_intent_summary_pressure_branches(mission_state))
      |> Kernel.++(derived_realized_activity_pressure_branches(prior_plan))
      |> Kernel.++(
        derived_mission_state_realized_activity_pressure_branches(mission_state, prior_plan)
      )
      |> Kernel.++(derived_operational_timeline_pressure_branches(prior_plan))
      |> Kernel.++(derived_mission_state_operational_timeline_pressure_branches(mission_state))
      |> Kernel.++(derived_operator_review_pressure_branches(prior_plan, policy))
      |> Kernel.++(derived_mission_state_operator_review_pressure_branches(mission_state, policy))
      |> Kernel.++(derived_cadence_import_pressure_branches(prior_plan, policy))
      |> Kernel.++(derived_mission_state_cadence_import_pressure_branches(mission_state, policy))
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

  defp derived_power_constrained_branches(mission_state, policy) do
    MissionStateResourceConstraintBranches.power(mission_state, policy)
  end

  defp derived_thermal_constrained_branches(mission_state, policy) do
    MissionStateResourceConstraintBranches.thermal(mission_state, policy)
  end

  defp derived_payload_constrained_branches(mission_state) do
    MissionStateResourceConstraintBranches.payload(mission_state)
  end

  defp derived_antenna_constrained_branches(mission_state) do
    MissionStateResourceConstraintBranches.antenna(mission_state)
  end

  defp derived_resource_projection_pressure_branches(prior_plan, policy) do
    prior_plan
    |> ResourceProjectionSourceReports.prior_plan_reports()
    |> ResourceProjectionPressureBranches.from_reports(policy)
  end

  defp derived_mission_state_resource_projection_pressure_branches(mission_state, policy) do
    mission_state
    |> ResourceProjectionSourceReports.reports()
    |> ResourceProjectionPressureBranches.from_reports(policy)
  end

  defp derived_resource_filter_pressure_branches(prior_plan) do
    prior_plan
    |> ResourceFilterSourceReports.prior_plan_reports()
    |> ResourceFilterPressureBranches.from_reports()
  end

  defp derived_mission_state_resource_filter_pressure_branches(mission_state) do
    mission_state
    |> ResourceFilterSourceReports.reports()
    |> ResourceFilterPressureBranches.from_reports()
  end

  defp derived_contact_allocation_pressure_branches(prior_plan) do
    prior_plan
    |> ContactAllocationSourceReports.prior_plan_reports()
    |> ContactAllocationReportPressureBranches.build()
  end

  defp derived_contact_allocation_summary_pressure_branches(prior_plan) do
    prior_plan
    |> ContactAllocationSourceReports.prior_plan_pressure_summaries()
    |> ContactAllocationSummaryPressureBranches.build()
  end

  defp derived_mission_state_contact_allocation_pressure_branches(mission_state) do
    mission_state
    |> ContactAllocationSourceReports.reports()
    |> ContactAllocationReportPressureBranches.build()
  end

  defp derived_mission_state_contact_allocation_summary_pressure_branches(mission_state) do
    mission_state
    |> ContactAllocationSourceReports.pressure_summaries()
    |> ContactAllocationSummaryPressureBranches.build()
  end

  defp derived_contact_filter_pressure_branches(prior_plan) do
    prior_plan
    |> ContactFilterSourceReports.prior_plan_reports()
    |> ContactFilterPressureBranches.from_reports()
  end

  defp derived_mission_state_contact_filter_pressure_branches(mission_state) do
    mission_state
    |> ContactFilterSourceReports.reports()
    |> ContactFilterPressureBranches.from_reports()
  end

  defp derived_contact_contention_resolution_pressure_branches(prior_plan) do
    prior_plan
    |> ContactContentionSourceReports.prior_resolution_reports()
    |> ContactContentionPressureBranches.resolutions_from_reports()
  end

  defp derived_mission_state_contact_contention_resolution_pressure_branches(mission_state) do
    mission_state
    |> ContactContentionSourceReports.resolution_reports()
    |> ContactContentionPressureBranches.resolutions_from_reports()
  end

  defp derived_mission_state_contact_contention_pressure_branches(mission_state) do
    mission_state
    |> ContactContentionSourceReports.contention_reports()
    |> ContactContentionPressureBranches.conflicts_from_reports()
  end

  defp contact_contention_resolution_pressure_branches(recommendation, source_path) do
    ContactContentionPressureBranches.resolution(recommendation, source_path)
  end

  defp contact_allocation_pressure_branch(row, source_path) do
    ContactAllocationPressureFanout.branches(row, source_path)
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

  defp derived_score_term_pressure_branches(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_score_term_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ScoreTermPressureBranches.branch(row, source_path, index)
    end)
  end

  defp derived_mission_state_score_term_pressure_branches(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.score_term_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ScoreTermPressureBranches.branch(row, source_path, index)
    end)
  end

  defp derived_objective_satisfaction_pressure_branches(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_objective_satisfaction_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveSatisfactionPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_objective_satisfaction_pressure_branches(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.objective_satisfaction_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveSatisfactionPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_objective_tradeoff_pressure_branches(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_objective_tradeoff_reports()
    |> ObjectiveConstraintSourceReports.objective_tradeoff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveTradeoffPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_objective_tradeoff_pressure_branches(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.objective_tradeoff_reports()
    |> ObjectiveConstraintSourceReports.objective_tradeoff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ObjectiveTradeoffPressureBranches.branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_constraint_pressure_branches(prior_plan) do
    prior_plan
    |> ObjectiveConstraintSourceReports.prior_constraint_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ConstraintPressureBranches.branch(row, source_path, index)
    end)
  end

  defp derived_mission_state_constraint_pressure_branches(mission_state) do
    mission_state
    |> ObjectiveConstraintSourceReports.constraint_reports()
    |> ObjectiveConstraintSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ConstraintPressureBranches.branch(row, source_path, index)
    end)
  end

  defp derived_timeline_diff_pressure_branches(prior_plan, policy) do
    prior_plan
    |> prior_plan_timeline_diff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      timeline_diff_pressure_branch(row, source_path, index, policy)
    end)
  end

  defp derived_timeline_integrity_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_integrity_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_integrity_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_dependency_impact_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_dependency_impact_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_dependency_impact_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_publication_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_publication_pressure_summaries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_publication_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_lifecycle_state_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_lifecycle_state_pressure_summaries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_lifecycle_state_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_activity_lifecycle_state_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_activity_lifecycle_state_pressure_states()
    |> Enum.flat_map(fn {state, source_path, index} ->
      TimelinePressureBranches.timeline_activity_lifecycle_state_pressure_branch(
        state,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_activity_precondition_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_activity_precondition_pressure_summaries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_activity_precondition_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_timeline_preservation_pressure_branches(prior_plan) do
    prior_plan
    |> prior_plan_timeline_preservation_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_preservation_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp prior_plan_timeline_dependency_impact_pressure_rows(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_dependency_impact_summaries()
    |> TimelineSourceReports.timeline_dependency_impact_pressure_rows()
  end

  defp prior_plan_timeline_publication_pressure_summaries(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_publication_summaries()
    |> TimelineSourceReports.pressure_entries()
  end

  defp prior_plan_timeline_lifecycle_state_pressure_summaries(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_lifecycle_state_summaries()
    |> TimelineSourceReports.pressure_entries()
  end

  defp prior_plan_timeline_activity_lifecycle_state_pressure_states(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_activity_lifecycle_states()
    |> TimelineSourceReports.pressure_entries()
  end

  defp prior_plan_timeline_activity_precondition_pressure_summaries(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_activity_precondition_summaries()
    |> TimelineSourceReports.pressure_entries()
  end

  defp prior_plan_timeline_preservation_pressure_rows(prior_plan) do
    report_rows =
      prior_plan
      |> TimelineSourceReports.prior_plan_timeline_preservation_reports()
      |> TimelineSourceReports.timeline_preservation_report_pressure_rows()

    status_rows =
      prior_plan
      |> TimelineSourceReports.prior_plan_timeline_preservation_statuses()
      |> TimelineSourceReports.timeline_preservation_status_pressure_rows()

    report_rows ++ status_rows
  end

  defp prior_plan_timeline_integrity_pressure_rows(prior_plan) do
    prior_plan
    |> TimelineSourceReports.prior_plan_timeline_integrity_reports()
    |> TimelineSourceReports.timeline_integrity_pressure_rows()
  end

  defp prior_plan_timeline_diff_pressure_rows(prior_plan) do
    TimelineSourceReports.timeline_diff_pressure_rows(
      TimelineSourceReports.prior_plan_timeline_diff_reports(prior_plan),
      TimelineSourceReports.prior_plan_timeline_transition_application_reports(prior_plan)
    )
  end

  defp derived_mission_state_timeline_diff_pressure_branches(mission_state, policy) do
    TimelineSourceReports.timeline_diff_pressure_rows(
      TimelineSourceReports.mission_state_timeline_diff_reports(mission_state),
      TimelineSourceReports.mission_state_timeline_transition_application_reports(mission_state)
    )
    |> Enum.flat_map(fn {row, source_path, index} ->
      timeline_diff_pressure_branch(row, source_path, index, policy)
    end)
  end

  defp derived_mission_state_timeline_integrity_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_integrity_reports()
    |> TimelineSourceReports.timeline_integrity_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_integrity_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_dependency_impact_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_dependency_impact_summaries()
    |> TimelineSourceReports.timeline_dependency_impact_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_dependency_impact_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_publication_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_publication_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_publication_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_lifecycle_state_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_lifecycle_state_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_lifecycle_state_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_activity_lifecycle_state_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_activity_lifecycle_states()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {state, source_path, index} ->
      TimelinePressureBranches.timeline_activity_lifecycle_state_pressure_branch(
        state,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_activity_precondition_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_activity_precondition_summaries()
    |> TimelineSourceReports.pressure_entries()
    |> Enum.flat_map(fn {summary, source_path, index} ->
      TimelinePressureBranches.timeline_activity_precondition_pressure_branch(
        summary,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_timeline_preservation_pressure_branches(mission_state) do
    mission_state
    |> TimelineSourceReports.mission_state_timeline_preservation_reports()
    |> TimelineSourceReports.timeline_preservation_report_pressure_rows()
    |> Kernel.++(
      mission_state
      |> TimelineSourceReports.mission_state_timeline_preservation_statuses()
      |> TimelineSourceReports.timeline_preservation_status_pressure_rows()
    )
    |> Enum.flat_map(fn {row, source_path, index} ->
      TimelinePressureBranches.timeline_preservation_pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp timeline_diff_pressure_branch(row, source_path, index, policy \\ %{}) do
    TimelineDiffPressureEvents.pressure_branch(
      row,
      source_path,
      index,
      policy,
      TimelineDiffPressureEventCallbacks.callbacks()
    )
  end

  defp derived_operator_review_pressure_branches(prior_plan, policy) do
    prior_plan
    |> OperatorReviewSourceReports.prior_plan_operator_review_packages()
    |> OperatorReviewSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      operator_review_pressure_branches(row, index, policy, source_prefix)
    end)
  end

  defp derived_mission_state_operator_review_pressure_branches(mission_state, policy) do
    mission_state
    |> OperatorReviewSourceReports.operator_review_packages()
    |> OperatorReviewSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      operator_review_pressure_branches(row, index, policy, source_prefix)
    end)
  end

  defp derived_operational_timeline_pressure_branches(prior_plan) do
    prior_plan
    |> ReviewSourceReports.prior_plan_operational_timeline_reports()
    |> OperationalTimelineSourceRows.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_operational_timeline_pressure_branches(mission_state) do
    mission_state
    |> ReviewSourceReports.operational_timeline_reports()
    |> OperationalTimelineSourceRows.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_planned_activity_pressure_branches(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_planned_activity_pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_planned_activity_pressure_branches(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_planned_activity_pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_proposed_contact_pressure_branches(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_proposed_contact_pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_proposed_contact_pressure_branches(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_proposed_contact_pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      OperationalTimelinePressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_contact_intent_pressure_branches(prior_plan) do
    prior_plan
    |> ContactIntentSourceReports.prior_plan_rows_with_source()
    |> ContactIntentPressureBranches.from_rows_with_source()
  end

  defp derived_contact_intent_summary_pressure_branches(prior_plan) do
    direct_identities =
      prior_plan
      |> ContactIntentSourceReports.prior_plan_rows_with_source()
      |> ContactIntentPressureBranches.identity_set()

    prior_plan
    |> ContactIntentSourceReports.prior_plan_summaries_with_source()
    |> ContactIntentPressureBranches.summaries_from_sources(direct_identities)
  end

  defp derived_mission_state_contact_intent_pressure_branches(mission_state) do
    mission_state
    |> ContactIntentSourceReports.mission_state_rows_with_source()
    |> ContactIntentPressureBranches.from_rows_with_source()
  end

  defp derived_mission_state_contact_intent_summary_pressure_branches(mission_state) do
    direct_identities =
      mission_state
      |> ContactIntentSourceReports.mission_state_rows_with_source()
      |> ContactIntentPressureBranches.identity_set()

    mission_state
    |> ContactIntentSourceReports.mission_state_summaries_with_source()
    |> ContactIntentPressureBranches.summaries_from_sources(direct_identities)
  end

  defp derived_realized_activity_pressure_branches(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_realized_activity_pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_path, index} ->
      RealizedFeedbackPressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_realized_activity_pressure_branches(mission_state, prior_plan) do
    mission_state
    |> ActivitySourceRows.mission_state_realized_activity_pressure_rows_with_source(prior_plan)
    |> Enum.flat_map(fn {row, source_path, index} ->
      RealizedFeedbackPressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "objective_satisfaction_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.objective_satisfaction(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ObjectiveSatisfactionPressureBranches.branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "objective_tradeoff_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.objective_tradeoff(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ObjectiveTradeoffPressureBranches.branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "constraint_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.constraint(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ConstraintPressureBranches.branch("#{source_prefix}.#{source_suffix}", index)
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "timeline_diff_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = TimelineDiffReviewRows.source(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> timeline_diff_pressure_branch("#{source_prefix}.#{source_suffix}", index)
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "operational_timeline_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.operational_timeline(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> OperationalTimelinePressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "candidate_diff_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.candidate_diff(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CandidateDiffPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "refresh_budget_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.refresh_budget(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RefreshBudgetPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "freshness_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.freshness(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RefreshFreshnessPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "plan_delta_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = TimelineDiffReviewRows.plan_delta_source(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> timeline_diff_pressure_branch("#{source_prefix}.#{source_suffix}", index)
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "command_window_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.command_window(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CommandWindowOperationalFeedback.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "maneuver_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.maneuver_review(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ManeuverReviewOperationalFeedback.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "realized_feedback"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.realized_feedback(row)

    source
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> RealizedFeedbackPressureEvents.pressure_branch(
      "#{source_prefix}.#{source_suffix}",
      index
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "resource_projection_review"} = row,
         _index,
         policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.resource_projection(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ResourceProjectionPressureBranches.build(
      "#{source_prefix}.#{source_suffix}",
      policy
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "link_capacity_review"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.link_capacity(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put_new("source_report", "operator_review_package")
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> LinkCapacityPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "contact_allocation_review"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.contact_allocation(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> contact_allocation_pressure_branch("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "contact_allocation_capacity_pack_review"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.contact_allocation_capacity_pack(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> CadenceImportDirectPressureBranches.capacity_pack_branches(
      "#{source_prefix}.#{source_suffix}"
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "contact_intent_review"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.contact_intent(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ContactIntentPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "station_calendar_review"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    StationCalendarReviewRows.pressure_branches(
      row,
      OperatorReviewSourceReports.Rows.trust_boundary(row),
      source_prefix
    )
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "contact_contention_recommendation"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = contact_contention_recommendation_source(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put_new("review_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> contact_contention_resolution_pressure_branches("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "contact_suppression"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.contact_suppression(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ContactFilterPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "resource_suppression"} = row,
         _index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.resource_suppression(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ResourceFilterPressureBranches.build("#{source_prefix}.#{source_suffix}")
  end

  defp operator_review_pressure_branches(
         %{"review_type" => "score_term_review"} = row,
         index,
         _policy,
         source_prefix
       ) do
    {source, source_suffix} = ReviewRowSources.score_term(row)

    source
    |> ValueEncoding.stringify_keys()
    |> Map.put_new("approval_status", row["approval_status"])
    |> OperatorReviewSourceReports.Rows.put_source_report_trust_boundary(row)
    |> ScoreTermPressureBranches.branch("#{source_prefix}.#{source_suffix}", index)
  end

  defp operator_review_pressure_branches(_row, _index, _policy, _source_prefix), do: []

  defp derived_cadence_import_pressure_branches(prior_plan, policy) do
    prior_plan
    |> CadenceImportSourceReports.prior_plan_cadence_import_manifests()
    |> CadenceImportSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      cadence_import_pressure_branches(row, index, policy, source_prefix)
    end)
  end

  defp derived_mission_state_cadence_import_pressure_branches(mission_state, policy) do
    mission_state
    |> CadenceImportSourceReports.cadence_import_manifests()
    |> CadenceImportSourceReports.pressure_rows_with_source()
    |> Enum.flat_map(fn {row, source_prefix, index} ->
      cadence_import_pressure_branches(row, index, policy, source_prefix)
    end)
  end

  defp cadence_import_pressure_branches(
         row,
         index,
         policy,
         source_prefix
       ) do
    source_review_row =
      case Map.get(row, "source_review_row") do
        %{} = source ->
          source
          |> ValueEncoding.stringify_keys()
          |> Map.put_new("approval_status", row["approval_status"])
          |> CadenceImportSourceReports.Rows.put_source_report_trust_boundary(row)

        _source ->
          %{}
      end

    source_review_branches =
      if source_review_row == %{} do
        []
      else
        operator_review_pressure_branches(
          source_review_row,
          index,
          policy,
          "#{source_prefix}.source_review_row"
        )
      end

    if source_review_branches != [] do
      source_review_branches
    else
      CadenceImportDirectPressureBranches.branches(
        row,
        source_review_row,
        index,
        policy,
        source_prefix
      )
    end
  end

  defp contact_contention_recommendation_source(%{"source_recommendation" => %{} = source})
       when map_size(source) > 0,
       do: {source, "source_recommendation"}

  defp contact_contention_recommendation_source(row),
    do: {row, "contact_contention_recommendation"}

  defp derived_mission_state_candidate_diff_pressure_branches(mission_state) do
    mission_state
    |> CandidateReviewSourceReports.candidate_diff_reports()
    |> CandidateReviewSourceReports.candidate_diff_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      CandidateDiffPressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_candidate_rejection_pressure_branches(mission_state) do
    mission_state
    |> CandidateReviewSourceReports.candidate_rejection_reports()
    |> CandidateReviewSourceReports.candidate_rejection_pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      CandidateRejectionPressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_provider_counteroffer_pressure_branches(mission_state) do
    ProviderCounterofferSourceReports.pressure_sources(mission_state)
    |> ProviderCounterofferSourceReports.pressure_rows()
    |> Enum.flat_map(fn {row, source_path, index} ->
      ProviderCounterofferPressureEvents.pressure_branch(
        row,
        source_path,
        index
      )
    end)
  end

  defp derived_mission_state_refresh_budget_pressure_branches(mission_state) do
    mission_state
    |> RefreshSourceReports.refresh_budget_reports()
    |> RefreshSourceReports.pressure_rows()
    |> Enum.flat_map(fn {report, source_path, index} ->
      RefreshBudgetPressureEvents.pressure_branch(
        report,
        source_path,
        index
      )
    end)
  end

  defp derived_operational_readiness_pressure_branches(prior_plan) do
    prior_plan
    |> OperationalReadinessSourceReports.prior_plan_pressure_sources()
    |> OperationalReadinessPressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_operational_readiness_pressure_branches(mission_state) do
    mission_state
    |> OperationalReadinessSourceReports.pressure_sources()
    |> OperationalReadinessPressureEvents.pressure_branches_from_sources()
  end

  defp derived_quality_gate_pressure_branches(prior_plan) do
    prior_plan
    |> QualityGateSourceReports.prior_plan_pressure_sources()
    |> QualityGatePressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_quality_gate_pressure_branches(mission_state) do
    mission_state
    |> QualityGateSourceReports.pressure_sources()
    |> QualityGatePressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_model_acceptance_pressure_branches(mission_state) do
    mission_state
    |> ModelAcceptanceSourceReports.model_acceptance_reports()
    |> ModelAcceptancePressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_validation_safety_case_pressure_branches(mission_state) do
    mission_state
    |> ValidationSafetyCaseSourceReports.validation_safety_case_summaries()
    |> ValidationSafetyCasePressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_schema_validation_pressure_branches(mission_state) do
    mission_state
    |> SchemaValidationSourceReports.schema_validation_reports()
    |> SchemaValidationPressureEvents.pressure_branches_from_sources()
  end

  defp derived_mission_state_refresh_freshness_pressure_branches(mission_state) do
    mission_state
    |> RefreshSourceReports.freshness_reports()
    |> RefreshFreshnessPressureEvents.pressure_branches_from_sources()
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

  defp mission_state_candidate_refresh_source_reports(mission_state) do
    MissionStateCandidateRefreshSourceReports.build(mission_state)
  end

  defp derive_branch_candidate_refresh_request(%{"id" => "baseline"}, _request), do: nil

  defp derive_branch_candidate_refresh_request(%{"events" => []}, _request), do: nil

  defp derive_branch_candidate_refresh_request(branch, request) do
    with %{} = accepted_state <-
           branch_accepted_planning_state(branch, request.mission_state, request.prior_plan) do
      defaults = Map.get(request.mission_state, "candidate_refresh_defaults", %{})

      operational_feedback =
        branch_refresh_operational_feedback(branch, request.operational_feedback)

      targets =
        mission_state_refresh_targets(
          branch,
          request.mission_state,
          operational_feedback
        )

      ground_stations = mission_state_refresh_ground_stations(branch, request.mission_state)
      outputs = branch_refresh_outputs(targets, ground_stations)

      BranchRefreshRequestBuilder.build(branch, request, defaults, %{
        accepted_state: accepted_state,
        outputs: outputs,
        ground_stations: ground_stations,
        remaining_horizon: branch_refresh_horizon(request, defaults),
        targets: targets,
        ground_network:
          branch_refresh_ground_network(
            branch,
            request.mission_state,
            operational_feedback
          ),
        constraints: branch_refresh_constraints(request, defaults),
        resource_filter_policy: branch_refresh_resource_filter_policy(branch, defaults),
        candidate_limit_policy: branch_refresh_candidate_limit_policy(branch, defaults),
        source_timeline_feedback_report:
          BranchRefreshSourceInputs.timeline_feedback_source_report(request.mission_state),
        timeline_feedback_report:
          BranchRefreshSourceInputs.timeline_feedback_report_input(request.mission_state),
        source_operational_timeline_report:
          BranchRefreshSourceInputs.operational_timeline_source_report(request.mission_state),
        operational_timeline_report:
          BranchRefreshSourceInputs.operational_timeline_report_input(request.mission_state),
        mission_state: mission_state_candidate_refresh_source_reports(request.mission_state),
        operational_feedback: operational_feedback,
        scoring_policy: branch_refresh_scoring_policy(request, defaults),
        resource_summaries: branch_refresh_resource_summaries(branch, request.mission_state),
        prior_candidate_activities: PriorActivityContext.candidate_activities(request.prior_plan),
        approval_policy: branch_refresh_approval_policy(request)
      })
    else
      _missing -> nil
    end
  end

  defp branch_refresh_operational_feedback(branch, operational_feedback) do
    BranchOperationalFeedback.derive(branch, operational_feedback,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1,
      normalize_resource_margin_aliases:
        &OperationalFeedbackNormalization.normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases:
        &OperationalFeedbackNormalization.normalize_resource_availability_aliases/1,
      event_ground_station_id: &event_ground_station_id/1,
      branch_event_spacecraft_id: &branch_event_spacecraft_id/1
    )
  end

  defp branch_refresh_approval_policy(request),
    do: BranchRefreshRequestOptions.approval_policy(request)

  defp mission_state_accepted_planning_state(mission_state, prior_plan) do
    BranchRefreshAcceptedState.from_mission_state(mission_state, prior_plan)
  end

  defp branch_accepted_planning_state(branch, mission_state, prior_plan) do
    BranchRefreshAcceptedState.for_branch(branch, mission_state, prior_plan)
  end

  defp mission_state_refresh_targets(branch, mission_state, operational_feedback) do
    BranchRefreshTargets.build(branch, mission_state, operational_feedback)
  end

  defp mission_state_refresh_ground_stations(_branch, mission_state) do
    BranchRefreshGroundNetwork.ground_stations(mission_state)
  end

  defp branch_refresh_ground_network(branch, mission_state, operational_feedback) do
    BranchRefreshGroundNetwork.build(branch, mission_state, operational_feedback)
  end

  defp ground_network_capacity_fraction(entry, default \\ 1.0) do
    BranchRefreshGroundNetwork.ground_network_capacity_fraction(entry, default)
  end

  defp branch_ground_station_event_reason("ground_station_reserved"),
    do: "branch_ground_station_reserved"

  defp branch_ground_station_event_reason(_type), do: "branch_ground_station_outage"

  defp branch_ground_station_realized_context(event, type) do
    %{
      "ground_station_id" => event_ground_station_id(event),
      "station_availability" => branch_ground_station_event_availability(type),
      "station_calendar_entry_id" => event["station_calendar_entry_id"],
      "station_calendar_provider_id" => event["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => event["station_calendar_provider_entry_id"],
      "station_calendar_directions" => event["station_calendar_directions"],
      "station_calendar_status" => event["station_calendar_status"],
      "station_contention_status" =>
        if(type == "ground_station_reserved", do: "reserved_overlap"),
      "station_reservation_id" => event["station_reservation_id"] || event["reservation_id"],
      "station_reserved_by" => event["station_reserved_by"] || event["reserved_by"],
      "station_reservation_status" =>
        event["station_reservation_status"] || event["reservation_status"],
      "station_reservation_match_status" => event["station_reservation_match_status"],
      "station_calendar_trust_boundary_status" => event["station_calendar_trust_boundary_status"],
      "trust_boundary" => event["trust_boundary"],
      "provenance" => event["provenance"]
    }
    |> ValueEncoding.compact_map()
  end

  defp branch_ground_station_event_availability("ground_station_reserved"), do: "reserved"
  defp branch_ground_station_event_availability(_type), do: "unavailable"

  defp branch_refresh_outputs(targets, ground_stations) do
    BranchRefreshRequestOptions.outputs(targets, ground_stations)
  end

  defp branch_refresh_horizon(request, defaults) do
    BranchRefreshRequestOptions.horizon(request, defaults)
  end

  defp branch_refresh_constraints(request, defaults) do
    BranchRefreshRequestOptions.constraints(request, defaults)
  end

  defp branch_refresh_scoring_policy(request, defaults) do
    BranchRefreshRequestOptions.scoring_policy(request, defaults)
  end

  defp branch_refresh_resource_filter_policy(branch, defaults) do
    BranchRefreshPolicies.resource_filter_policy(branch, defaults)
  end

  defp branch_refresh_candidate_limit_policy(branch, defaults) do
    BranchRefreshPolicies.candidate_limit_policy(branch, defaults)
  end

  defp branch_refresh_resource_summaries(branch, mission_state) do
    base_summaries =
      case Map.get(mission_state, "resource_summaries") do
        summaries when is_list(summaries) and summaries != [] ->
          summaries

        _other ->
          MissionStateResourceSources.summaries(mission_state)
      end
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Enum.map(&RepairRealizedState.spacecraft_state_booleans/1)

    branch
    |> BranchRefreshResourceSummaries.build(base_summaries,
      branch_event_spacecraft_id: &branch_event_spacecraft_id/1,
      degraded_event_mode: &degraded_event_mode/1,
      normalize_incompatible_activity_types:
        &BranchOperationalFeedback.normalize_incompatible_activity_types/1
    )
  end

  defp dedupe_by_id(items) do
    items
    |> Map.new(&{&1["id"], &1})
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
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

  defp update_candidate_activities(plan, fun) do
    Map.update(plan, "candidate_activities", [], fn activities ->
      activities
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> fun.()
    end)
  end

  defp apply_downlink_capacity(activity, event) do
    activity = ValueEncoding.stringify_keys(activity)

    if DownlinkActivityNormalization.downlink?(activity) and
         branch_event_activity_match?(activity, event) and event_overlap?(activity, event) do
      fraction = ground_network_capacity_fraction(event)
      score = candidate_score(activity) * fraction

      activity
      |> Map.put("score", score)
      |> Map.put("capacity_fraction", fraction)
      |> put_station_capacity(fraction)
      |> Map.update("score_terms", %{}, fn terms ->
        Map.put(terms, "capacity_factor", fraction)
      end)
    else
      activity
    end
  end

  defp put_station_capacity(activity, 1.0), do: activity

  defp put_station_capacity(activity, capacity_fraction) do
    activity
    |> Map.put("station_capacity_fraction", capacity_fraction)
    |> Map.update(
      "throughput_model",
      %{"station_capacity_fraction" => capacity_fraction},
      fn model ->
        Map.put(model, "station_capacity_fraction", capacity_fraction)
      end
    )
  end

  defp ground_station_event_match?(activity, event) do
    activity = ValueEncoding.stringify_keys(activity)

    station_event_suppressed_activity?(activity) and branch_event_activity_match?(activity, event) and
      event_overlap?(activity, event)
  end

  defp station_event_suppressed_activity?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = activity_direction(activity)

    DownlinkActivityNormalization.downlink?(activity) or
      type in ["tracking", "health_check"] or
      (type in ["planned_contact", "contact"] and direction in ["tracking", "health_check"])
  end

  defp branch_event_activity_match?(activity, event) do
    event_station_id = event_ground_station_id(event)

    station_match? =
      is_nil(event_station_id) or
        RepairActivityIdentity.ground_station_id(activity) == event_station_id

    scenario_match? =
      is_nil(event["scenario_id"]) or activity["scenario_id"] == event["scenario_id"]

    station_match? and scenario_match?
  end

  defp event_ground_station_id(event) do
    case ValueEncoding.encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             DownlinkActivityNormalization.nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp event_overlap?(activity, event) do
    event_start = Map.get(event, "starts_at_s", ActivityTiming.activity_start(activity))
    event_end = Map.get(event, "ends_at_s", ActivityTiming.activity_end(activity))

    ActivityTiming.activity_start(activity) < event_end and
      event_start < ActivityTiming.activity_end(activity)
  end

  defp merge_realized_state(realized_state, overrides) do
    overrides = RepairRealizedState.normalize(overrides || %{})

    %{
      "activities" =>
        merge_by_id(
          Map.get(realized_state, "activities", []),
          Map.get(overrides, "activities", [])
        ),
      "spacecraft_states" =>
        merge_spacecraft_states(
          Map.get(realized_state, "spacecraft_states", []),
          Map.get(overrides, "spacecraft_states", [])
        ),
      "metadata" =>
        Map.merge(Map.get(realized_state, "metadata", %{}), Map.get(overrides, "metadata", %{}))
    }
  end

  defp mission_state_repair_state(mission_state) do
    %{
      "activities" => Map.get(mission_state, "realized_activities", []),
      "spacecraft_states" =>
        mission_state
        |> DerivedDegradedSpacecraftBranches.states()
        |> merge_spacecraft_states([]),
      "metadata" => %{
        "mission_state_snapshot_id" => Map.get(mission_state, "snapshot_id")
      }
    }
  end

  defp degradation_activity_types(degradation) do
    explicit =
      Map.get(degradation, "incompatible_activity_types") ||
        Map.get(degradation, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        explicit

      Map.get(degradation, "spacecraft_available") == false or
          Map.get(degradation, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      true ->
        ["observe"]
    end
  end

  defp degraded_event_mode(event) do
    case ValueEncoding.encode_value(Map.get(event, "mode", "degraded")) do
      value when value in [nil, ""] -> "degraded"
      value -> value
    end
  end

  defp branch_event_spacecraft_id(event) do
    case ValueEncoding.encode_value(
           Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")
         ) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp merge_by_id(left, right) do
    (left ++ right)
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.sort_by(&{&1["id"], &1["status"] || "", &1["reason"] || ""})
  end

  defp merge_spacecraft_states(left, right) do
    (left ++ right)
    |> RepairRealizedState.spacecraft_states()
    |> elem(0)
    |> Map.new(fn item -> {Map.get(item, "scenario_id"), item} end)
    |> Map.values()
    |> Enum.sort_by(& &1["scenario_id"])
  end

  defp add_realized_activity(realized_state, activity) do
    activity = RepairRealizedState.activity(activity)

    Map.update!(realized_state, "activities", fn activities ->
      merge_by_id(activities, [activity])
    end)
  end

  defp add_spacecraft_state(realized_state, spacecraft_state) do
    spacecraft_state = ValueEncoding.stringify_keys(spacecraft_state)

    Map.update!(realized_state, "spacecraft_states", fn states ->
      merge_spacecraft_states(states, [spacecraft_state])
    end)
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

  defp repair_activity(activity, acc, context) do
    activity = ValueEncoding.stringify_keys(activity)
    activity_id = ActivityIdentity.activity_id(activity)

    case RepairRealizedState.activity_match(context.realized_by_id, activity_id) do
      {:ambiguous, realized_rows} ->
        review_ambiguous_realized_activity(activity, realized_rows, acc)

      {:ok, realized} ->
        status = realized_status(activity, realized, context.current_epoch_s)

        repair_activity_with_status(activity, realized, status, acc, context)
    end
  end

  defp repair_activity_with_status(activity, realized, status, acc, context) do
    cond do
      status in @realized_preserved_executed_statuses and
          context.repair_policy.preserve_executed? ->
        preserve_executed_activity(activity, realized, status, acc)

      preserve_locked_before_repair?(activity, status, context) ->
        preserve_locked_activity(activity, realized, status, acc)

      degraded_incompatible?(activity, context.degraded_modes, context.repair_policy) ->
        suppress_degraded_activity(activity, realized, status, acc)

      status == "missed" and DownlinkActivityNormalization.downlink?(activity) ->
        move_missed_downlink(activity, realized, acc, context)

      status == "failed" and activity["type"] == "observe" ->
        replace_failed_observation(activity, realized, acc, context)

      status == "delayed" and maneuver_activity?(activity) ->
        move_delayed_maneuver(activity, realized, acc)

      status in @terminal_realized_statuses ->
        cancel_activity(activity, realized, status, acc)

      ActivityTiming.within_remaining_horizon?(activity, context.remaining_horizon) ->
        preserve_activity(activity, realized, status, acc)

      true ->
        acc
    end
  end

  defp review_ambiguous_realized_activity(activity, realized_rows, acc) do
    reason = "ambiguous_realized_activity_feedback"

    activity =
      put_repair_metadata(activity, %{
        "action" => "review_realized_feedback",
        "reason" => reason,
        "realized_status" => "ambiguous",
        "realized_feedback_count" => length(realized_rows),
        "realized_feedback_statuses" => RepairRealizedState.feedback_statuses(realized_rows),
        "requires_approval" => true
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_ambiguous_realized_delta(activity, realized_rows, reason)
    |> RepairAccumulator.add_approval_requirement(activity, "review_realized_feedback", reason)
    |> RepairAccumulator.add_warning(
      "ambiguous realized feedback for #{ActivityIdentity.activity_id(activity)} requires operator review"
    )
  end

  defp suppress_degraded_activity(activity, realized, status, acc) do
    reason = "spacecraft_degraded_mode_suppressed_incompatible_payload_activity"

    acc
    |> RepairAccumulator.add_delta(activity, realized, status, "suppressed", reason, nil, true)
    |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
    |> RepairAccumulator.add_warning(
      "spacecraft degraded mode suppressed #{ActivityIdentity.activity_id(activity)}"
    )
  end

  defp preserve_executed_activity(activity, realized, status, acc) do
    activity =
      put_repair_metadata(
        activity,
        %{
          "action" => "preserved_executed",
          "reason" => "activity_already_#{status}",
          "realized_status" => status,
          "completed_fraction" => Map.get(realized || %{}, "completed_fraction"),
          "actual_starts_at_s" => Map.get(realized || %{}, "actual_starts_at_s"),
          "actual_ends_at_s" => Map.get(realized || %{}, "actual_ends_at_s"),
          "requires_approval" => false
        }
        |> ValueEncoding.compact_map()
      )

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved_executed",
      "already_#{status}",
      nil,
      false
    )
  end

  defp preserve_locked_before_repair?(activity, status, context) do
    decision =
      Timeline.protection_decision(activity,
        realized_status: status,
        preserve_approved?: context.repair_policy.preserve_approved?,
        preserve_executed?: context.repair_policy.preserve_executed?,
        allow_locked_changes?: context.repair_policy.allow_locked_changes?
      )

    decision["protection_decision"] == "preserve" and
      decision["protection_category"] == "locked_or_approved" and
      status not in @terminal_realized_statuses
  end

  defp move_missed_downlink(activity, realized, acc, context) do
    case RepairReplacementSelection.downlink_candidate(activity, acc, context) do
      nil ->
        reason = "missed_contact_no_viable_later_access_window"

        acc
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "missed",
          "canceled",
          reason,
          nil,
          true
        )
        |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
        |> RepairAccumulator.add_warning(
          "missed downlink #{ActivityIdentity.activity_id(activity)} could not be repaired"
        )

      replacement ->
        reason = "missed_contact_rescheduled_to_next_viable_access_window"
        candidate_diff = RepairReplacementSelection.candidate_diff(activity, replacement, context)

        replacement =
          put_repair_metadata(
            replacement,
            %{
              "action" => "moved",
              "source_activity_id" => ActivityIdentity.activity_id(activity),
              "source_timeline_id" => RepairActivityIdentity.timeline_id(activity),
              "replacement_timeline_id" => RepairActivityIdentity.timeline_id(replacement),
              "timeline_link" => RepairActivityIdentity.timeline_link(activity, replacement),
              "source_activity_context" => RepairActivityIdentity.context(activity),
              "reason" => reason,
              "requires_approval" => true,
              "schedule_churn_s" =>
                abs(
                  ActivityTiming.activity_start(replacement) -
                    ActivityTiming.activity_start(activity)
                )
            }
            |> maybe_put_candidate_diff(candidate_diff)
          )

        acc
        |> RepairAccumulator.add_activity(replacement)
        |> RepairAccumulator.use_replacement(replacement)
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "missed",
          "moved",
          reason,
          ActivityIdentity.activity_id(replacement),
          true,
          replacement
        )
        |> RepairAccumulator.add_approval_requirement(
          replacement,
          "approve_moved_contact",
          reason
        )
    end
  end

  defp replace_failed_observation(activity, realized, acc, context) do
    case RepairReplacementSelection.candidate(activity, "observe", acc, context) do
      nil ->
        reason = "failed_observation_no_viable_replacement_window"

        acc
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "failed",
          "canceled",
          reason,
          nil,
          true
        )
        |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
        |> RepairAccumulator.add_warning(
          "failed observation #{ActivityIdentity.activity_id(activity)} could not be reassigned"
        )

      replacement ->
        reason = "failed_observation_reassigned_to_viable_spacecraft_or_later_window"
        candidate_diff = RepairReplacementSelection.candidate_diff(activity, replacement, context)

        replacement =
          put_repair_metadata(
            replacement,
            %{
              "action" => "replaced",
              "source_activity_id" => ActivityIdentity.activity_id(activity),
              "source_timeline_id" => RepairActivityIdentity.timeline_id(activity),
              "replacement_timeline_id" => RepairActivityIdentity.timeline_id(replacement),
              "timeline_link" => RepairActivityIdentity.timeline_link(activity, replacement),
              "source_activity_context" => RepairActivityIdentity.context(activity),
              "reason" => reason,
              "requires_approval" => true,
              "schedule_churn_s" =>
                abs(
                  ActivityTiming.activity_start(replacement) -
                    ActivityTiming.activity_start(activity)
                )
            }
            |> maybe_put_candidate_diff(candidate_diff)
          )

        acc
        |> RepairAccumulator.add_activity(replacement)
        |> RepairAccumulator.use_replacement(replacement)
        |> RepairAccumulator.add_delta(
          activity,
          realized,
          "failed",
          "replaced",
          reason,
          ActivityIdentity.activity_id(replacement),
          true,
          replacement
        )
        |> RepairAccumulator.add_approval_requirement(
          replacement,
          "approve_reassigned_observation",
          reason
        )
    end
  end

  defp move_delayed_maneuver(activity, realized, acc) do
    actual_start = realized["actual_starts_at_s"] || realized["actual_start_s"]

    delay_s =
      max(
        0.0,
        ScalarValues.numeric!(actual_start, "actual_starts_at_s") -
          ActivityTiming.activity_start(activity)
      )

    reason = "delayed_maneuver_shifted_and_downstream_windows_marked_affected"

    moved =
      activity
      |> ActivityTiming.shift_activity(delay_s)
      |> put_repair_metadata(%{
        "action" => "moved",
        "reason" => reason,
        "realized_status" => "delayed",
        "requires_approval" => true,
        "schedule_churn_s" => delay_s
      })

    acc
    |> RepairAccumulator.add_activity(moved)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      "delayed",
      "moved",
      reason,
      ActivityIdentity.activity_id(moved),
      true,
      moved
    )
    |> RepairAccumulator.add_approval_requirement(moved, "approve_delayed_maneuver", reason)
    |> Map.update!(:delayed_maneuvers, fn maneuvers ->
      [%{"activity" => activity, "delay_s" => delay_s} | maneuvers]
    end)
  end

  defp cancel_activity(activity, realized, status, acc) do
    reason = "realized_status_#{status}_removed_from_remaining_plan"

    acc
    |> RepairAccumulator.add_delta(activity, realized, status, "canceled", reason, nil, true)
    |> RepairAccumulator.add_approval_requirement(activity, "cancel", reason)
  end

  defp preserve_locked_activity(activity, realized, status, acc) do
    activity =
      put_repair_metadata(activity, %{
        "action" => "preserved",
        "reason" => "activity_locked_or_approved",
        "realized_status" => status,
        "requires_approval" => false
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved",
      "activity_locked_or_approved",
      nil,
      false
    )
  end

  defp preserve_activity(activity, realized, status, acc) do
    activity =
      put_repair_metadata(activity, %{
        "action" => "preserved",
        "reason" => "still_viable_in_remaining_horizon",
        "realized_status" => status,
        "requires_approval" => false
      })

    acc
    |> RepairAccumulator.add_activity(activity)
    |> RepairAccumulator.add_delta(
      activity,
      realized,
      status,
      "preserved",
      "still_viable_in_remaining_horizon",
      nil,
      false
    )
  end

  defp mark_downstream_maneuver_effects(%{delayed_maneuvers: []} = acc, _request), do: acc

  defp mark_downstream_maneuver_effects(acc, _request) do
    affected =
      acc.delayed_maneuvers
      |> Enum.flat_map(fn %{"activity" => maneuver} ->
        acc.activities
        |> Enum.reject(
          &(ActivityIdentity.activity_id(&1) == ActivityIdentity.activity_id(maneuver))
        )
        |> Enum.filter(fn activity ->
          ActivityIdentity.same_scenario?(activity, maneuver) and
            ActivityTiming.activity_start(activity) > ActivityTiming.activity_start(maneuver)
        end)
        |> Enum.map(&{maneuver, &1})
      end)

    Enum.reduce(affected, acc, fn {_maneuver, activity}, repaired ->
      reason = "affected_by_delayed_maneuver_requires_operator_review"

      activities =
        Enum.map(repaired.activities, fn existing ->
          if ActivityIdentity.activity_id(existing) == ActivityIdentity.activity_id(activity) do
            put_repair_metadata(existing, %{
              "action" => get_in(existing, ["repair", "action"]) || "preserved",
              "reason" => reason,
              "affected_by_delayed_maneuver" => true,
              "requires_approval" => true
            })
          else
            existing
          end
        end)

      repaired
      |> Map.put(:activities, activities)
      |> RepairAccumulator.add_approval_requirement(activity, "review_downstream_window", reason)
      |> RepairAccumulator.add_warning(
        "#{ActivityIdentity.activity_id(activity)} affected by delayed maneuver"
      )
    end)
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

  defp maybe_put_candidate_diff(metadata, nil), do: metadata

  defp maybe_put_candidate_diff(metadata, row) do
    CandidateDiffMetadata.put(metadata, row)
  end

  defp candidate_diff_for_replacement(candidate, context) do
    context
    |> Map.get("candidate_diff_by_replacement_id", %{})
    |> Map.get(ActivityIdentity.activity_id(candidate))
    |> RepairCandidateDiff.match("replacement")
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
      mission_state_accepted_planning_state(mission_state, prior_plan)
    )
    |> put_if_absent(
      "targets",
      mission_state_refresh_targets(%{"events" => []}, mission_state, operational_feedback)
    )
  end

  defp inherit_candidate_refresh_manifest_inputs(request, mission_state) do
    put_if_absent(
      request,
      "ground_stations",
      mission_state_refresh_ground_stations(%{"events" => []}, mission_state)
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

  defp candidate_diff_replacements_by_replacement_id(nil), do: %{}

  defp candidate_diff_replacements_by_replacement_id(%{} = report) do
    RepairCandidateDiff.replacements_by_replacement_id(report)
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

  defp realized_status(activity, nil, current_epoch_s) do
    if ActivityTiming.activity_end(activity) <= current_epoch_s,
      do: "unreported_past",
      else: "planned"
  end

  defp realized_status(_activity, realized, _current_epoch_s),
    do: RepairRealizedState.normalize_status_value(realized["status"])

  defp degraded_incompatible?(activity, degraded_modes, repair_policy) do
    RepairPolicySemantics.degraded_incompatible?(activity, degraded_modes, repair_policy)
  end

  defp maneuver_activity?(activity), do: activity["type"] in ["maneuver", "impulsive_burn"]

  defp put_repair_metadata(activity, metadata) do
    Map.update(activity, "repair", metadata, &Map.merge(&1, metadata))
  end

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end
end
