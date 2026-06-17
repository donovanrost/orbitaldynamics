Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyApprovalPolicyTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  test "strategy action-specific approval policy classifies moved contacts urgent additions and maneuver changes" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [
          downlink("dl_1", 100.0, 160.0),
          maneuver("burn_1", 300.0)
        ],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    approval_policy = %{
      "operator_review_risk_limit" => 10,
      "blocked_risk_types" => [],
      "action_rules" => [
        %{
          "id" => "moved_contact_auto",
          "action" => "approve_moved_contact",
          "classification" => "auto_approvable",
          "reason" => "low_risk_contact_move"
        },
        %{
          "id" => "urgent_review",
          "requirement_type" => "strategic_addition",
          "classification" => "operator_review_required",
          "reason" => "strategic_target_requires_operator_review"
        },
        %{
          "id" => "maneuver_block",
          "event_types" => ["delayed_maneuver"],
          "classification" => "blocked_by_policy",
          "reason" => "maneuver_timing_change_blocked"
        }
      ]
    }

    artifact =
      strategy(prior_plan,
        approval_policy: approval_policy,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          },
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                starts_at_s: 500.0,
                ends_at_s: 560.0
              }
            ]
          },
          %{
            id: "missed_contact",
            realized_state_overrides: %{activities: [%{id: "dl_1", status: "missed"}]}
          },
          %{
            id: "maneuver",
            events: [
              %{type: "delayed_maneuver", activity_id: "burn_1", actual_starts_at_s: 360.0}
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "outage")
    urgent = branch(artifact, "urgent")
    missed_contact = branch(artifact, "missed_contact")
    maneuver_branch = branch(artifact, "maneuver")

    assert Enum.any?(outage["approval_rule_matches"], &(&1["rule_id"] == "moved_contact_auto"))
    assert outage["policy_decision"]["schema_contract"] == "policy_decision.v1"
    assert missed_contact["approval_status"] == "auto_approvable"
    assert Enum.any?(urgent["approval_rule_matches"], &(&1["rule_id"] == "urgent_review"))

    assert Enum.any?(
             urgent["approval_rule_matches"],
             &(&1["requirement_type"] == "strategic_addition")
           )

    assert maneuver_branch["approval_status"] == "blocked_by_policy"

    assert Enum.any?(
             maneuver_branch["approval_requirements"],
             &(&1["requirement_type"] == "maneuver_timing_change")
           )

    assert Enum.any?(
             maneuver_branch["approval_rule_matches"],
             &(&1["rule_id"] == "maneuver_block")
           )
  end

  test "strategy plural approval rules only match listed actions and activity types" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 2_000.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_2", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        approval_policy: %{
          "operator_review_risk_limit" => 10,
          "blocked_risk_types" => [],
          "action_rules" => [
            %{
              "id" => "only_moved_contacts_block",
              "actions" => ["approve_moved_contact"],
              "activity_types" => ["downlink"],
              "classification" => "blocked_by_policy",
              "reason" => "plural rule scoped to moved downlink contacts"
            },
            %{
              "id" => "urgent_review",
              "action" => "approve_strategic_addition",
              "classification" => "operator_review_required",
              "reason" => "urgent additions still require review"
            },
            %{
              "id" => "urgent_hot_event_review",
              "event_types" => ["urgent_target"],
              "target_id" => "target_hot",
              "classification" => "operator_review_required",
              "reason" => "target_hot event requires review"
            }
          ]
        },
        branches: [
          %{id: "baseline"},
          %{
            id: "missed_contact",
            realized_state_overrides: %{activities: [%{id: "dl_1", status: "missed"}]}
          },
          %{
            id: "urgent",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_hot",
                starts_at_s: 500.0,
                ends_at_s: 560.0
              }
            ]
          },
          %{
            id: "urgent_cold",
            events: [
              %{
                type: "urgent_target",
                target_id: "target_cold",
                starts_at_s: 600.0,
                ends_at_s: 660.0
              }
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    missed_contact = branch(artifact, "missed_contact")
    urgent = branch(artifact, "urgent")
    urgent_cold = branch(artifact, "urgent_cold")

    assert missed_contact["approval_status"] == "blocked_by_policy"
    assert urgent["approval_status"] == "operator_review_required"

    refute Enum.any?(
             urgent["approval_rule_matches"],
             &(&1["rule_id"] == "only_moved_contacts_block")
           )

    assert Enum.any?(
             urgent["approval_rule_matches"],
             &(&1["rule_id"] == "urgent_hot_event_review" and
                 &1["event_type"] == "urgent_target" and &1["target_id"] == "target_hot")
           )

    refute Enum.any?(
             urgent_cold["approval_rule_matches"],
             &(&1["rule_id"] == "urgent_hot_event_review")
           )
  end
end
