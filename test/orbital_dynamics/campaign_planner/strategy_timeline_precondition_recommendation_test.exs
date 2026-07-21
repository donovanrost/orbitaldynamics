Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelinePreconditionRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips explicitly blocked activity preconditions by default" do
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

    blocked_precondition_event = %{
      type: "timeline_activity_precondition_pressure",
      activity_id: "cmd_blocked",
      timeline_id: "timeline:cmd_blocked",
      activity_type: "command",
      precondition_status: "blocked",
      blocked_precondition_count: 1,
      review_precondition_count: 0,
      blocked_precondition_types: ["command_safety_failed"],
      requires_operator_review: true,
      required_operator_action: "review_blocked_activity_precondition",
      feedback_source: "mission_state.source_timeline_activity_precondition_summary",
      feedback_scope: "timeline_activity_precondition",
      feedback_key: "cmd_blocked",
      derivation_reasons: ["timeline_activity_precondition_summary_pressure"]
    }

    review_precondition_event = %{
      type: "timeline_activity_precondition_pressure",
      activity_id: "cmd_review",
      timeline_id: "timeline:cmd_review",
      activity_type: "command",
      precondition_status: "review_required",
      blocked_precondition_count: 0,
      review_precondition_count: 1,
      review_precondition_types: ["command_authority_missing"],
      requires_operator_review: true,
      required_operator_action: "review_activity_precondition",
      feedback_source: "mission_state.source_timeline_activity_precondition_summary",
      feedback_scope: "timeline_activity_precondition",
      feedback_key: "cmd_review",
      derivation_reasons: ["timeline_activity_precondition_summary_pressure"]
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
            id: "blocked_timeline_precondition",
            events: [urgent_target_event, blocked_precondition_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "blocked_timeline_precondition")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "blocked_by_policy",
             "fallback_policy" => %{"blocked_risk_types" => blocked_risk_types}
           } = blocked_branch["policy_decision"]

    assert "timeline_activity_precondition_blocked" in blocked_risk_types

    assert "timeline_activity_precondition_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "timeline_activity_precondition_review" and
                 &1["feedback_scope"] == "timeline_activity_precondition" and
                 &1["precondition_status"] == "blocked" and
                 &1["blocked_precondition_count"] == 1)
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
            id: "review_timeline_precondition",
            events: [urgent_target_event, review_precondition_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "review_timeline_precondition")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "review_timeline_precondition"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "timeline_activity_precondition_review" and
                 &1["feedback_scope"] == "timeline_activity_precondition" and
                 &1["precondition_status"] == "review_required" and
                 &1["blocked_precondition_count"] == 0 and
                 &1["review_precondition_count"] == 1)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
