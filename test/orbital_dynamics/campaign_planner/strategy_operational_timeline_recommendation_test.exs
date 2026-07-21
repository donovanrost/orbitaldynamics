Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperationalTimelineRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips policy-blocked operational timeline replay by default" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [],
        "candidate_activities" => []
      })

    urgent_target_event = %{
      type: "urgent_target",
      target_id: "target_a",
      starts_at_s: 500.0,
      ends_at_s: 560.0,
      priority: 20.0,
      candidate_windows: [
        %{
          id: "candidate_obs_hot",
          type: "observe",
          target_id: "target_a",
          scenario_id: "leo_1",
          starts_at_s: 500.0,
          ends_at_s: 560.0,
          duration_s: 60.0,
          score: 10.0
        }
      ]
    }

    blocked_timeline_report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            id: :cmd_blocked,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 130.0,
            status: :planned,
            approval_status: :blocked_by_policy,
            provenance: %{trust_boundary: :blocked_operational_timeline_boundary},
            metadata: %{timeline_id: :"timeline:cmd_blocked"}
          }
        ],
        source: "campaign_planner_test.blocked_operational_timeline"
      )

    review_timeline_report =
      OrbitalDynamics.operational_timeline_report(
        [
          %{
            id: :cmd_review,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 130.0,
            status: :planned,
            approval_status: :operator_review_required,
            provenance: %{trust_boundary: :review_operational_timeline_boundary},
            metadata: %{timeline_id: :"timeline:cmd_review"}
          }
        ],
        source: "campaign_planner_test.review_operational_timeline"
      )

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(blocked_timeline_report)

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(review_timeline_report)

    blocked_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [%{"type" => "priority_commitment", "target_id" => "target_a"}])
          |> Map.put("source_operational_timeline_report", blocked_timeline_report),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{id: "blocked_operational_timeline", events: [urgent_target_event]}
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "blocked_operational_timeline")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "blocked_by_policy",
             "fallback_policy" => %{"blocked_risk_types" => blocked_risk_types}
           } = blocked_branch["policy_decision"]

    assert "operational_timeline_policy_blocked" in blocked_risk_types

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "operational_timeline_pressure" and
                 &1["feedback_scope"] == "operational_timeline" and
                 &1["approval_status_counts"] == %{"blocked_by_policy" => 1})
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    review_artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:objectives, [%{"type" => "priority_commitment", "target_id" => "target_a"}])
          |> Map.put("source_operational_timeline_report", review_timeline_report),
        strategy_policy: %{
          "mission_value_weight" => 10.0,
          "risk_weight" => 0.0,
          "approval_load_weight" => 0.0
        },
        branches: [
          %{id: "baseline"},
          %{id: "review_operational_timeline", events: [urgent_target_event]}
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "review_operational_timeline")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "review_operational_timeline"

    assert review_branch["approval_status"] == "operator_review_required"
    assert review_artifact["recommendation"]["approval_status"] == "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "operational_timeline_pressure" and
                 &1["feedback_scope"] == "operational_timeline" and
                 &1["approval_status_counts"] == %{"operator_review_required" => 1})
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
