Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyProviderCounterofferRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by provider counteroffers by default" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_target_event = %{
      type: "urgent_target",
      target_id: "target_hot",
      starts_at_s: 500.0,
      ends_at_s: 560.0,
      priority: 20.0,
      candidate_windows: [
        %{
          id: "candidate_obs_hot",
          type: "observe",
          target_id: "target_hot",
          scenario_id: "leo_1",
          starts_at_s: 500.0,
          ends_at_s: 560.0,
          duration_s: 60.0,
          score: 10.0
        }
      ]
    }

    expired_counteroffer_event = %{
      type: "provider_counteroffer_pressure",
      feedback_scope: "provider_counteroffer",
      feedback_source: "mission_state.source_provider_counteroffer_import_readiness_summary",
      provider_counteroffer_id: "counteroffer_expired_lock",
      provider_counteroffer_status: "proposed",
      provider_counteroffer_negotiation_state: "counteroffered",
      provider_counteroffer_import_status: "review_required_before_import",
      import_readiness_status: "review_required",
      import_classification: "review_only",
      provider_counteroffer_lock_deadline_s: 120.0,
      provider_counteroffer_lock_deadline_status: "expired",
      provider_counteroffer_cost_delta: 75.0,
      required_operator_action: "review_provider_counteroffer",
      trust_boundary: "provider_counteroffer_import_readiness",
      derivation_reasons: ["provider_counteroffer_import_readiness"]
    }

    active_counteroffer_event = %{
      type: "provider_counteroffer_pressure",
      feedback_scope: "provider_counteroffer",
      feedback_source: "mission_state.source_provider_counteroffer_import_readiness_summary",
      provider_counteroffer_id: "counteroffer_active_review",
      provider_counteroffer_status: "proposed",
      provider_counteroffer_negotiation_state: "counteroffered",
      provider_counteroffer_import_status: "review_required_before_import",
      import_readiness_status: "review_required",
      import_classification: "review_only",
      provider_counteroffer_lock_deadline_s: 1_200.0,
      provider_counteroffer_lock_deadline_status: "active",
      provider_counteroffer_cost_delta: 75.0,
      required_operator_action: "review_provider_counteroffer",
      trust_boundary: "provider_counteroffer_import_readiness",
      derivation_reasons: ["provider_counteroffer_import_readiness"]
    }

    blocked_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "expired_provider_counteroffer",
            events: [urgent_target_event, expired_counteroffer_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "expired_provider_counteroffer")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "provider_counteroffer_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_pressure" and
                 &1["feedback_scope"] == "provider_counteroffer" and
                 &1["provider_counteroffer_lock_deadline_status"] == "expired" and
                 &1["provider_counteroffer_import_status"] == "review_required_before_import")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    review_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "priority_commitment", "target_id" => "target_hot"}]),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "active_provider_counteroffer",
            events: [urgent_target_event, active_counteroffer_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "active_provider_counteroffer")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "active_provider_counteroffer"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_pressure" and
                 &1["feedback_scope"] == "provider_counteroffer" and
                 &1["provider_counteroffer_lock_deadline_status"] == "active" and
                 &1["provider_counteroffer_import_status"] == "review_required_before_import")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
