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
    ContactAllocation,
    LinkCapacity,
    StationCalendar
  }

  alias OrbitalDynamics.Constraints.CampaignLocal, as: CampaignLocalConstraint
  alias OrbitalDynamics.Study.Manifest

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    ApprovalPolicy,
    BranchComparisonReport,
    BranchGenerationPolicy,
    BranchRefreshAcceptedState,
    BranchRefreshGroundNetwork,
    BranchRefreshTargets,
    BuildOrchestration,
    DerivedBranchOrchestration,
    CandidateRefreshNormalization,
    CandidateRefreshRequest,
    CandidateRefreshOperationalFeedback,
    ContactContentionResolutionPolicy,
    DownlinkActivityNormalization,
    DownlinkObjectiveRequirements,
    MissionStateNormalization,
    ModelLimits,
    OperationalFeedbackAggregation,
    OperationalFeedbackNormalization,
    OperationalFeedbackProvenance,
    RealizedActivitiesOperationalFeedback,
    RequestIO,
    RepairArtifact,
    RepairCandidateInputs,
    RepairExecution,
    RepairMetadata,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairScoreTerms,
    RepairSourceReports,
    RepairTimelineSummary,
    ReplanRequest,
    ScalarValues,
    ScoreReports,
    StrategyBranchNormalization,
    StrategyBranchEvaluation,
    StrategyPolicyNormalization,
    StrategyArtifact,
    StrategyPriorPlanCandidates,
    StrategyRecommendationBuilder,
    StrategyReport,
    ValueEncoding
  }

  alias OrbitalDynamics.{
    CandidateRefresh,
    CadenceImport,
    OperatorReview,
    Policy,
    ResultSet,
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

    BuildOrchestration.build(result_set, campaign, generated_at)
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
    do: MissionStateNormalization.normalize(mission_state)

  defp do_repair(%{} = request) do
    prior_plan = request.prior_plan
    execution = RepairExecution.run(request)
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
        RepairSourceReports.operational_readiness(request.candidate_refresh),
        RepairSourceReports.quality_gate(request.candidate_refresh),
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

  defp normalize_strategy_request(request) do
    prior_plan =
      ValueEncoding.get_key(request, :prior_plan) ||
        ValueEncoding.get_key(request, :campaign_plan) ||
        ValueEncoding.get_key(request, :source_plan)

    prior_plan = StrategyPriorPlanCandidates.normalize(prior_plan)

    current_epoch_s =
      ScalarValues.numeric!(ValueEncoding.get_key(request, :current_epoch_s), "current_epoch_s")

    mission_state =
      request
      |> ValueEncoding.get_key(:mission_state)
      |> MissionStateNormalization.normalize()

    branches =
      request
      |> ValueEncoding.get_key(:branches)
      |> StrategyBranchNormalization.normalize_branches()

    branch_generation_policy =
      request
      |> BranchGenerationPolicy.build()

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
      DerivedBranchOrchestration.merge(
        branches,
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
      |> Enum.map(fn branch ->
        StrategyBranchEvaluation.evaluate(branch, request, &repair/1)
      end)

    branches =
      input_order_branches
      |> Enum.sort_by(&{-&1.score, &1.id})

    recommendation = StrategyRecommendationBuilder.build(branches)
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

  defp repair_approval_decision(approval_requirements, %ApprovalPolicy{} = policy) do
    Policy.decide(
      approval_requirements,
      [],
      %{"id" => "repair", "events" => []},
      %{},
      StrategyPolicyNormalization.approval_to_map(policy)
    )
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end

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

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(objective)
  end

  defp objective_required_downlink_mb(_objective), do: nil

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
    |> DownlinkObjectiveRequirements.objectives()
    |> Enum.map(&objective_required_downlink_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
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

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end
end
