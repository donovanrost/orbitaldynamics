defmodule OrbitalDynamics.CampaignPlanner.StrategyRequestNormalization do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    BranchGenerationPolicy,
    CandidateRefreshNormalization,
    CandidateRefreshOperationalFeedback,
    DerivedBranchOrchestration,
    MissionStateNormalization,
    OperationalFeedbackAggregation,
    OperationalFeedbackNormalization,
    OperationalFeedbackProvenance,
    RealizedActivitiesOperationalFeedback,
    RepairPolicySemantics,
    RepairRealizedState,
    RepairRequestNormalization,
    ScalarValues,
    StrategyBranchNormalization,
    StrategyPolicyNormalization,
    StrategyPriorPlanCandidates,
    ValueEncoding
  }

  def normalize(request) do
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

    branch_generation_policy = BranchGenerationPolicy.build(request)

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
      OperationalFeedbackProvenance.build(
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

    authority_context_mode =
      request
      |> ValueEncoding.get_key(:authority_context_mode)
      |> ValueEncoding.encode_value()

    authority_context = ValueEncoding.get_key(request, :authority_context)

    authority_context_mode_supplied? =
      Map.has_key?(request, :authority_context_mode) or
        Map.has_key?(request, "authority_context_mode")

    authority_context_supplied? =
      Map.has_key?(request, :authority_context) or Map.has_key?(request, "authority_context")

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
      authority_context_mode: authority_context_mode,
      authority_context: authority_context,
      authority_context_mode_supplied?: authority_context_mode_supplied?,
      authority_context_supplied?: authority_context_supplied?,
      repair_policy: repair_policy,
      scoring_policy:
        ValueEncoding.stringify_keys(ValueEncoding.get_key(request, :scoring_policy) || %{}),
      candidate_refresh: candidate_refresh,
      operational_feedback: operational_feedback,
      operational_feedback_provenance: operational_feedback_provenance,
      generated_at:
        RepairRequestNormalization.normalize_generated_at(
          ValueEncoding.get_key(request, :generated_at) || DateTime.utc_now()
        ),
      metadata: ValueEncoding.stringify_keys(ValueEncoding.get_key(request, :metadata) || %{})
    }
  end
end
