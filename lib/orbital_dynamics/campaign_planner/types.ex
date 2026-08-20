defmodule OrbitalDynamics.CampaignPlanner.RealizedActivity do
  @moduledoc """
  Realized operational outcome for one planned activity or contact.
  """

  @enforce_keys [:id, :status]
  defstruct [
    :id,
    :status,
    :actual_starts_at_s,
    :actual_ends_at_s,
    :completed_fraction,
    :reason,
    metadata: %{}
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.RepairPolicy do
  @moduledoc """
  Policy knobs for campaign-plan repair.
  """

  defstruct preserve_approved?: true,
            preserve_executed?: true,
            allow_locked_changes?: false,
            schedule_churn_cost_weight: 100.0,
            schedule_move_cost_weight: 0.01,
            degraded_payload_activity_types: ["observe"],
            command_health_activity_types: ["command", "health_check"]
end

defmodule OrbitalDynamics.CampaignPlanner.PlanDelta do
  @moduledoc """
  Planned-vs-realized comparison row.
  """

  @enforce_keys [:activity_id, :activity_type, :status]
  defstruct [
    :activity_id,
    :activity_type,
    :status,
    :planned,
    :realized,
    :repair_action,
    :reason,
    :replacement_activity_id,
    :source_timeline_id,
    :replacement_timeline_id,
    :timeline_link,
    :source_activity_context,
    :replacement_activity_context,
    :realized_feedback_rows,
    :realized_feedback_count,
    :requires_approval
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.ReplanRequest do
  @moduledoc """
  Input object for rolling campaign repair.
  """

  @enforce_keys [:prior_plan, :realized_state, :current_epoch_s]
  defstruct [
    :prior_plan,
    :mission_state,
    :realized_state,
    :current_epoch_s,
    :remaining_horizon,
    :constraints,
    :scoring_policy,
    :repair_policy,
    :approval_policy,
    :candidate_refresh,
    :candidate_refresh_request,
    :ground_network,
    :generated_at,
    metadata: %{}
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.ReplanResult do
  @moduledoc """
  JSON-serializable V2 repair artifact wrapper.
  """

  @enforce_keys [:artifact]
  defstruct [:artifact]
end

defmodule OrbitalDynamics.CampaignPlanner.MissionState do
  @moduledoc """
  Living constellation state snapshot used by V3 branch strategy evaluation.
  """

  @enforce_keys [:snapshot_id]
  defstruct [
    :snapshot_id,
    :captured_at,
    spacecraft_states: [],
    ground_network: [],
    ground_stations: [],
    targets: [],
    accepted_planning_state: nil,
    candidate_refresh_defaults: %{},
    resources: %{},
    resource_summaries: [],
    degradations: [],
    objectives: [],
    timeline_feedback_report: nil,
    operational_feedback: %{},
    prior_plan_history: [],
    operational_status: %{},
    assumptions: %{}
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.WhatIfScenario do
  @moduledoc """
  Explicit future assumptions for one V3 branch.
  """

  @enforce_keys [:id]
  defstruct [
    :id,
    :label,
    probability: 1.0,
    events: [],
    policy_overrides: %{},
    realized_state_overrides: %{},
    metadata: %{}
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.PlanBranch do
  @moduledoc """
  Evaluated V3 future branch.
  """

  @enforce_keys [:id, :repair_result, :score, :score_terms]
  defstruct [
    :id,
    :label,
    :probability,
    :repair_result,
    :score,
    :score_terms,
    events: [],
    candidate_plan: %{},
    warnings: [],
    risk_indicators: [],
    approval_status: "operator_review_required",
    approval_requirements: [],
    approval_rule_matches: [],
    policy_decision: %{},
    derived_source: nil,
    resource_impacts: %{},
    resource_projection_report: nil,
    feedback_adjustments: %{},
    objective_satisfaction: %{},
    feasibility_summary: %{},
    assumptions: %{},
    provenance: %{},
    tradeoffs: []
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.StrategyRecommendation do
  @moduledoc """
  Ranked branch recommendation with explicit tradeoffs and approval boundary.
  """

  @enforce_keys [:recommended_branch_id, :approval_status, :reason]
  defstruct [
    :recommended_branch_id,
    :approval_status,
    :reason,
    :eligibility_status,
    :authority_context,
    :authority_context_evaluation,
    ranked_branch_ids: [],
    tradeoffs: [],
    explanation: [],
    risks_remaining: [],
    requires_approval: []
  ]
end

defmodule OrbitalDynamics.CampaignPlanner.StrategicScoringPolicy do
  @moduledoc """
  Campaign-level scoring weights for V3 branch comparison.
  """

  defstruct mission_value_weight: 1.0,
            coverage_weight: 25.0,
            revisit_weight: 5.0,
            latency_weight: 0.01,
            downlink_completion_weight: 50.0,
            fuel_preservation_weight: 25.0,
            schedule_stability_weight: 1.0,
            asset_balance_weight: 10.0,
            priority_commitment_weight: 50.0,
            risk_weight: 100.0,
            approval_load_weight: 20.0,
            probability_weight: 1.0
end

defmodule OrbitalDynamics.CampaignPlanner.ApprovalPolicy do
  @moduledoc """
  Human-approval boundary policy for V3 recommendations.
  """

  defstruct auto_approvable_risk_limit: 0,
            auto_approvable_approval_count_limit: 0,
            operator_review_risk_limit: 3,
            blocked_risk_types: [
              "spacecraft_degraded_unprotected",
              "no_viable_downlink",
              "storage_overflow",
              "downlink_shortfall",
              "operational_readiness_blocked",
              "quality_gate_blocked",
              "import_readiness_blocked",
              "contact_intent_blocked",
              "link_capacity_blocked",
              "resource_projection_blocked",
              "contact_filter_blocked",
              "contact_contention_blocked",
              "resource_filter_availability_blocked",
              "model_acceptance_blocked",
              "validation_safety_case_blocked",
              "schema_validation_blocked",
              "refresh_budget_blocked",
              "refresh_freshness_blocked",
              "timeline_activity_precondition_blocked",
              "operational_timeline_policy_blocked",
              "station_calendar_unavailable_blocked",
              "station_reservation_conflict_blocked",
              "station_reservation_expiration_blocked",
              "provider_counteroffer_blocked",
              "provider_reservation_request_blocked"
            ],
            action_rules: []
end

defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedback do
  @moduledoc """
  Thin calibration inputs from prior operations.
  """

  defstruct contact_success_rate: %{},
            observation_success_rate: %{},
            image_quality_score: %{},
            image_quality_status: %{},
            image_quality_source: %{},
            cloud_cover_fraction: %{},
            blur_score: %{},
            maneuver_success_rate: %{},
            maneuver_execution_uncertainty: %{},
            command_success_rate: %{},
            station_throughput_factor: %{},
            downlink_demand_mb: %{},
            target_priority_overrides: %{},
            resource_margin_overrides: %{},
            resource_availability_overrides: %{},
            availability_overrides: %{}
end
