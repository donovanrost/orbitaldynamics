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
    LinkCapacity
  }

  alias OrbitalDynamics.Constraints.CampaignLocal, as: CampaignLocalConstraint

  alias OrbitalDynamics.CampaignPlanner.{
    ApprovalPolicy,
    BuildOrchestration,
    ContactContentionResolutionPolicy,
    DownlinkObjectiveRequirements,
    ModelLimits,
    RequestIO,
    RepairArtifact,
    RepairCandidateInputs,
    RepairExecution,
    RepairMetadata,
    RepairRequestNormalization,
    RepairScoreTerms,
    RepairSourceReports,
    RepairTimelineSummary,
    ReplanRequest,
    ScoreReports,
    StrategyPolicyNormalization,
    StrategyOrchestration,
    StrategyRequestNormalization,
    ValueEncoding
  }

  alias OrbitalDynamics.{
    Policy,
    ResultSet,
    ResourceProjection,
    Timeline,
    TimelineFeedback
  }

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
    |> RepairRequestNormalization.normalize()
    |> do_repair()
  end

  def repair(%{} = request) do
    request
    |> RepairRequestNormalization.from_map()
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
    |> StrategyRequestNormalization.normalize()
    |> StrategyOrchestration.run()
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

  defp repair_approval_decision(approval_requirements, %ApprovalPolicy{} = policy) do
    Policy.decide(
      approval_requirements,
      [],
      %{"id" => "repair", "events" => []},
      %{},
      StrategyPolicyNormalization.approval_to_map(policy)
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
