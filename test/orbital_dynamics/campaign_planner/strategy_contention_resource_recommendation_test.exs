Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContentionResourceRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by contact contention by default" do
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

    blocked_contact_contention_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_contention",
      feedback_source: "prior_plan.source_contact_contention_report.conflict_groups",
      ground_station_id: "equator_prime",
      contact_id: "dl_contention_blocked",
      source_activity_id: "dl_contention_blocked",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 44.0,
      planned_downlink_mb: 0.0,
      contention_group_id: "station:equator_prime:blocked",
      contention_resource_scope: "ground_station",
      required_operator_action: "review_contact_contention",
      approval_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      operator_action_reason: "same_station_overlapping_contact_windows",
      derivation_reasons: [
        "contact_contention_conflict",
        "same_station_overlapping_contact_windows",
        "blocked_by_policy"
      ]
    }

    review_contention_resolution_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_contention_resolution",
      feedback_source: "prior_plan.source_contact_contention_resolution_report.recommendations",
      ground_station_id: "deep_space_net",
      contact_id: "dl_contention_review",
      source_activity_id: "dl_contention_review",
      selected_contact_id: "dl_contention_selected",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 47.0,
      planned_downlink_mb: 12.0,
      contention_group_id: "station:deep_space_net:review",
      review_status: "operator_review_required",
      approval_status: "operator_review_required",
      required_operator_action: "review_contact_contention_resolution",
      selection_reason: "highest_score_earliest_start",
      derivation_reasons: [
        "contact_contention_deferred",
        "highest_score_earliest_start"
      ]
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
            id: "contact_contention_blocked",
            events: [urgent_target_event, blocked_contact_contention_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "contact_contention_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "contact_contention_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_contention" and
                 &1["approval_status"] == "blocked_by_policy" and
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
            id: "contact_contention_review",
            events: [urgent_target_event, review_contention_resolution_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "contact_contention_review")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "contact_contention_review"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_contention_resolution" and
                 &1["approval_status"] == "operator_review_required")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end

  test "strategy recommendation skips branches blocked by resource filter availability by default" do
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

    blocked_resource_filter_event = %{
      type: "resource_availability_constraint",
      feedback_scope: "resource_filter",
      feedback_source: "prior_plan.source_resource_filter_report.suppressed_candidates",
      scenario_id: "leo_resource_blocked",
      spacecraft_id: "leo_resource_blocked",
      resource_field: "payload_available",
      available: false,
      source_activity_id: "obs_resource_blocked",
      suppressed_reason: "payload_unavailable",
      resource_filter_status: "blocked_by_policy",
      suppression_status: "blocked_by_policy",
      approval_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      required_operator_action: "review_suppressed_resource_candidate",
      derivation_reasons: ["resource_filter_suppressed", "payload_unavailable"]
    }

    review_resource_margin_event = %{
      type: "resource_margin_pressure",
      feedback_scope: "resource_filter",
      feedback_source: "prior_plan.source_resource_filter_report.suppressed_candidates",
      scenario_id: "leo_resource_review",
      spacecraft_id: "leo_resource_review",
      resource_field: "power_margin",
      power_margin: 0.12,
      power_margin_threshold: 0.2,
      source_activity_id: "obs_resource_review",
      suppressed_reason: "power_margin_below_observe_policy",
      required_operator_action: "review_resource_margin",
      derivation_reasons: [
        "resource_filter_suppressed",
        "power_margin_below_observe_policy"
      ]
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
            id: "resource_filter_blocked",
            events: [urgent_target_event, blocked_resource_filter_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "resource_filter_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "resource_filter_availability_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["feedback_scope"] == "resource_filter" and
                 &1["resource_field"] == "payload_available" and
                 &1["resource_availability_value"] == false and
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
            id: "resource_margin_review",
            events: [urgent_target_event, review_resource_margin_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "resource_margin_review")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "resource_margin_review"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "power_margin_low" and
                 &1["feedback_scope"] == "resource_filter" and
                 &1["value"] == 0.12)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
