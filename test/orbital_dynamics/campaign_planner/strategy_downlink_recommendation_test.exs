Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyDownlinkRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches blocked by contact intent by default" do
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

    blocked_contact_intent_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_intent",
      feedback_source: "prior_plan.operator_review_package.rows.source_contact_intent",
      contact_id: "contact_intent:blocked",
      source_activity_id: "dl_intent_blocked",
      ground_station_id: "equator_prime",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 36.0,
      planned_downlink_mb: 0.0,
      approval_status: "blocked_by_policy",
      contact_intent_gate_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      required_operator_action: "review_contact_intent",
      derivation_reasons: ["contact_intent_blocked_by_policy"]
    }

    missing_import_contact_intent_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_intent",
      feedback_source: "prior_plan.cadence_import_manifest.rows.source_contact_intent",
      contact_id: "contact_intent:missing",
      source_activity_id: "dl_intent_missing_import",
      ground_station_id: "deep_space_net",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 41.0,
      planned_downlink_mb: 0.0,
      cadence_import_status: "missing",
      contact_intent_gate_status: "cadence_import_missing",
      required_operator_action: "review_contact_intent",
      derivation_reasons: ["contact_intent_cadence_import_missing"]
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
            id: "contact_intent_blocked",
            events: [urgent_target_event, blocked_contact_intent_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "contact_intent_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"
    assert "contact_intent_blocked" in blocked_artifact["approval_policy"]["blocked_risk_types"]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_intent" and
                 &1["contact_intent_gate_status"] == "blocked_by_policy" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(blocked_artifact)

    missing_import_artifact =
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
            id: "contact_intent_missing_import",
            events: [urgent_target_event, missing_import_contact_intent_event]
          }
        ],
        current_epoch_s: 0.0
      )

    missing_import_branch = branch(missing_import_artifact, "contact_intent_missing_import")

    assert missing_import_artifact["recommendation"]["recommended_branch_id"] ==
             "contact_intent_missing_import"

    assert missing_import_branch["approval_status"] == "operator_review_required"

    assert missing_import_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             missing_import_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_intent" and
                 &1["contact_intent_gate_status"] == "cadence_import_missing" and
                 &1["cadence_import_status"] == "missing")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(missing_import_artifact)
  end

  test "strategy recommendation skips branches blocked by link capacity by default" do
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

    blocked_link_capacity_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "link_capacity",
      feedback_source: "prior_plan.source_link_capacity_report.rows",
      ground_station_id: "equator_prime",
      source_activity_id: "dl_link_blocked",
      source_window_id: "window_link_blocked",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 48.0,
      planned_downlink_mb: 0.0,
      link_capacity_status: "blocked_by_policy",
      downlink_requirement_status: "blocked_by_policy",
      actual_downlink_requirement_status: "blocked_by_policy",
      approval_status: "blocked_by_policy",
      policy_classification: "blocked_by_policy",
      required_operator_action: "review_link_capacity",
      derivation_reasons: ["link_capacity_blocked_by_policy"]
    }

    shortfall_link_capacity_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "link_capacity",
      feedback_source: "prior_plan.source_link_capacity_report.rows",
      ground_station_id: "deep_space_net",
      source_activity_id: "dl_link_shortfall",
      source_window_id: "window_link_shortfall",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 52.0,
      planned_downlink_mb: 12.0,
      link_capacity_status: "shortfall",
      downlink_requirement_status: "shortfall",
      actual_downlink_requirement_status: "shortfall",
      required_operator_action: "review_link_capacity",
      derivation_reasons: ["link_capacity_selected_downlink_shortfall"]
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
            id: "link_capacity_blocked",
            events: [urgent_target_event, blocked_link_capacity_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "link_capacity_blocked")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"
    assert "link_capacity_blocked" in blocked_artifact["approval_policy"]["blocked_risk_types"]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "link_capacity" and
                 &1["link_capacity_status"] == "blocked_by_policy" and
                 &1["downlink_requirement_status"] == "blocked_by_policy" and
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
            id: "link_capacity_shortfall",
            events: [urgent_target_event, shortfall_link_capacity_event]
          }
        ],
        current_epoch_s: 0.0
      )

    shortfall_branch = branch(shortfall_artifact, "link_capacity_shortfall")

    assert shortfall_artifact["recommendation"]["recommended_branch_id"] ==
             "link_capacity_shortfall"

    assert shortfall_branch["approval_status"] == "operator_review_required"

    assert shortfall_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             shortfall_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "link_capacity" and
                 &1["link_capacity_status"] == "shortfall" and
                 &1["downlink_requirement_status"] == "shortfall")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(shortfall_artifact)
  end
end
