Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRefreshFreshnessRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by stale refresh freshness by default" do
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

    stale_freshness_event = %{
      type: "refresh_freshness_pressure",
      feedback_scope: "refresh_freshness",
      feedback_source: "mission_state.source_freshness_report",
      freshness_status: "stale",
      freshness_statuses: ["stale"],
      state_quality_status: "stale",
      accepted_snapshot_age_s: 3_600.0,
      max_snapshot_age_s: 60.0,
      stale_reason_count: 1,
      stale_reasons: ["accepted_snapshot_older_than_policy"],
      unknown_reason_count: 0,
      branch_local_stale_pressure: true,
      branch_local_freshness_pressure: true,
      required_operator_action: "review_refresh_freshness",
      derivation_reasons: ["refresh_freshness_pressure"]
    }

    unknown_freshness_event = %{
      type: "refresh_freshness_pressure",
      feedback_scope: "refresh_freshness",
      feedback_source: "mission_state.source_freshness_report",
      freshness_status: "unknown",
      freshness_statuses: ["unknown"],
      state_quality_status: "unknown",
      stale_reason_count: 0,
      unknown_reason_count: 1,
      unknown_reasons: ["accepted_snapshot_missing"],
      branch_local_unknown_pressure: true,
      branch_local_freshness_pressure: true,
      required_operator_action: "review_refresh_freshness",
      derivation_reasons: ["refresh_freshness_pressure"]
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
            id: "stale_refresh_freshness",
            events: [urgent_target_event, stale_freshness_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "stale_refresh_freshness")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "refresh_freshness_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "refresh_freshness_pressure" and
                 &1["feedback_scope"] == "refresh_freshness" and
                 &1["freshness_status"] == "stale" and
                 &1["state_quality_status"] == "stale")
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
            id: "unknown_refresh_freshness",
            events: [urgent_target_event, unknown_freshness_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "unknown_refresh_freshness")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "unknown_refresh_freshness"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "refresh_freshness_pressure" and
                 &1["feedback_scope"] == "refresh_freshness" and
                 &1["freshness_status"] == "unknown" and
                 &1["state_quality_status"] == "unknown")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
