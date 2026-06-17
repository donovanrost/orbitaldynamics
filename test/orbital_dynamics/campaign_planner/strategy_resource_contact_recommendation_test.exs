Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyResourceContactRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by resource projection by default" do
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

    blocked_resource_projection_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "resource_projection",
      feedback_source: "prior_plan.source_resource_projection_report.projected_resources",
      scenario_id: "leo_projection_blocked",
      spacecraft_id: "leo_projection_blocked",
      ground_station_id: "equator_prime",
      source_activity_id: "obs_projection_blocked",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 58.0,
      planned_downlink_mb: 0.0,
      resource_projection_status: "blocked_by_policy",
      projected_resource_status: "blocked_by_policy",
      approval_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      required_operator_action: "review_resource_projection",
      derivation_reasons: ["resource_projection_blocked_by_policy"]
    }

    shortfall_resource_projection_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "resource_projection",
      feedback_source: "prior_plan.source_resource_projection_report.projected_resources",
      scenario_id: "leo_projection_shortfall",
      spacecraft_id: "leo_projection_shortfall",
      ground_station_id: "deep_space_net",
      source_activity_id: "obs_projection_shortfall",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 62.0,
      planned_downlink_mb: 14.0,
      resource_projection_status: "shortfall",
      projected_resource_status: "shortfall",
      required_operator_action: "review_resource_projection",
      derivation_reasons: ["projected_downlink_shortfall"]
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
            id: "resource_projection_blocked",
            events: [urgent_target_event, blocked_resource_projection_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "resource_projection_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "resource_projection_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "resource_projection" and
                 &1["resource_projection_status"] == "blocked_by_policy" and
                 &1["projected_resource_status"] == "blocked_by_policy" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    shortfall_artifact =
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
            id: "resource_projection_shortfall",
            events: [urgent_target_event, shortfall_resource_projection_event]
          }
        ],
        current_epoch_s: 0.0
      )

    shortfall_branch = branch(shortfall_artifact, "resource_projection_shortfall")

    assert shortfall_artifact["recommendation"]["recommended_branch_id"] ==
             "resource_projection_shortfall"

    assert shortfall_branch["approval_status"] == "operator_review_required"

    assert shortfall_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             shortfall_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "resource_projection" and
                 &1["resource_projection_status"] == "shortfall" and
                 &1["projected_resource_status"] == "shortfall")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(shortfall_artifact)
  end

  test "strategy recommendation skips branches blocked by contact filter by default" do
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

    blocked_contact_filter_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_filter",
      feedback_source: "prior_plan.source_contact_filter_report.suppressed_candidates",
      ground_station_id: "equator_prime",
      contact_id: "dl_filter_blocked",
      source_activity_id: "dl_filter_blocked",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 46.0,
      planned_downlink_mb: 0.0,
      suppressed_reason: "station_reserved",
      contact_filter_status: "blocked_by_policy",
      suppression_status: "blocked_by_policy",
      approval_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      required_operator_action: "review_suppressed_contact",
      derivation_reasons: ["contact_filter_suppressed", "station_reserved"]
    }

    review_contact_filter_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_filter",
      feedback_source: "prior_plan.source_contact_filter_report.suppressed_candidates",
      ground_station_id: "deep_space_net",
      contact_id: "dl_filter_review",
      source_activity_id: "dl_filter_review",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 49.0,
      planned_downlink_mb: 11.0,
      suppressed_reason: "station_reserved",
      contact_filter_status: "operator_review_required",
      suppression_status: "suppressed",
      review_status: "operator_review_required",
      required_operator_action: "review_suppressed_contact",
      derivation_reasons: ["contact_filter_suppressed", "station_reserved"]
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
            id: "contact_filter_blocked",
            events: [urgent_target_event, blocked_contact_filter_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "contact_filter_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"
    assert "contact_filter_blocked" in blocked_artifact["approval_policy"]["blocked_risk_types"]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_filter" and
                 &1["contact_filter_status"] == "blocked_by_policy" and
                 &1["suppression_status"] == "blocked_by_policy" and
                 &1["policy_classification"] == "blocked_by_policy")
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
            id: "contact_filter_review",
            events: [urgent_target_event, review_contact_filter_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "contact_filter_review")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "contact_filter_review"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_filter" and
                 &1["contact_filter_status"] == "operator_review_required" and
                 &1["suppression_status"] == "suppressed")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
