Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationConflictRecommendationTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy recommendation skips branches with station reservation conflicts by default" do
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

    conflict_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_allocation",
      feedback_source: "mission_state.source_contact_allocation_reservation_conflict_summary",
      contact_id: "dl_reservation_conflict",
      source_activity_id: "dl_reservation_conflict",
      source_activity_ids: ["dl_reservation_conflict"],
      ground_station_id: "equator_prime",
      direction: "downlink",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 41.0,
      planned_downlink_mb: 0.0,
      station_reservation_id: "reservation_partner_overlap",
      station_reserved_by: "partner_calendar",
      station_reservation_status: "confirmed",
      station_reservation_match_status: "overlap",
      required_operator_action: "review_station_reservation_overlap",
      derivation_reasons: ["contact_allocation_reservation_conflict"]
    }

    matched_event = %{
      type: "downlink_completion_gap",
      feedback_scope: "contact_allocation",
      feedback_source: "mission_state.source_contact_allocation_summary",
      contact_id: "dl_reservation_matched",
      source_activity_id: "dl_reservation_matched",
      source_activity_ids: ["dl_reservation_matched"],
      ground_station_id: "equator_prime",
      direction: "downlink",
      required_contacts: 1,
      planned_contacts: 0,
      required_downlink_mb: 41.0,
      planned_downlink_mb: 0.0,
      station_reservation_id: "reservation_ops_owned",
      station_reserved_by: "ops_calendar",
      station_reservation_status: "confirmed",
      station_reservation_match_status: "matched",
      required_operator_action: "review_contact_allocation",
      derivation_reasons: ["contact_allocation_review"]
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
            id: "station_reservation_conflict",
            events: [urgent_target_event, conflict_event]
          }
        ],
        current_epoch_s: 0.0
      )

    blocked_branch = branch(blocked_artifact, "station_reservation_conflict")

    assert blocked_branch["score_terms"]["mission_value_score"] >
             branch(blocked_artifact, "baseline")["score_terms"]["mission_value_score"]

    assert blocked_artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert blocked_branch["approval_status"] == "blocked_by_policy"

    assert "station_reservation_conflict_blocked" in blocked_artifact["approval_policy"][
             "blocked_risk_types"
           ]

    assert Enum.any?(
             blocked_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_allocation" and
                 &1["station_reservation_match_status"] == "overlap")
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
            id: "matched_station_reservation",
            events: [urgent_target_event, matched_event]
          }
        ],
        current_epoch_s: 0.0
      )

    review_branch = branch(review_artifact, "matched_station_reservation")

    assert review_artifact["recommendation"]["recommended_branch_id"] ==
             "matched_station_reservation"

    assert review_branch["approval_status"] == "operator_review_required"

    assert review_artifact["recommendation"]["approval_status"] ==
             "operator_review_required"

    assert Enum.any?(
             review_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and
                 &1["feedback_scope"] == "contact_allocation" and
                 &1["station_reservation_match_status"] == "matched")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(review_artifact)
  end
end
